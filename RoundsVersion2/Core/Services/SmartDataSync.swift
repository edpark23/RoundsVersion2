import Foundation
import FirebaseFirestore
import os

// MARK: - Smart Data Synchronization Service
// Intelligent Firebase data caching with offline-first architecture

@MainActor
class SmartDataSync: ObservableObject {
    static let shared = SmartDataSync()
    
    // MARK: - Configuration
    private let cacheTimeout: TimeInterval = 5 * 60 // 5 minutes
    
    // MARK: - Dependencies
    private let db = Firestore.firestore()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.rounds", category: "DataSync")
    
    // MARK: - Cache Storage
    private var memoryCache: [String: CachedData] = [:]
    
    // MARK: - Sync State
    @Published var syncStats = SyncStatistics()
    @Published var isOnline = true
    
    struct SyncStatistics {
        var cacheHits: Int = 0
        var networkRequests: Int = 0
        var syncOperations: Int = 0
        
        var efficiency: Double {
            let total = cacheHits + networkRequests
            guard total > 0 else { return 0 }
            return Double(cacheHits) / Double(total)
        }
    }
    
    // MARK: - Initialization
    private init() {
        setupDataSync()
    }
    
    private func setupDataSync() {
        // Setup Firestore offline persistence
        if FeatureFlags.enableOfflineMode {
            db.settings = FirestoreSettings()
            db.settings.cacheSettings = PersistentCacheSettings()
        }
    }
    
    // MARK: - Public Data Access Interface
    func getData<T: Codable>(
        collection: String,
        documentId: String,
        type: T.Type,
        forceRefresh: Bool = false
    ) async -> T? {
        if FeatureFlags.useSmartDataSync {
            return await optimizedDataRetrieval(collection: collection, documentId: documentId, type: type, forceRefresh: forceRefresh)
        } else {
            return await standardDataRetrieval(collection: collection, documentId: documentId, type: type)
        }
    }
    
    private func optimizedDataRetrieval<T: Codable>(
        collection: String,
        documentId: String,
        type: T.Type,
        forceRefresh: Bool
    ) async -> T? {
        let cacheKey = "\(collection)/\(documentId)"
        
        // 1. Check memory cache first (if not forcing refresh)
        if !forceRefresh, let cachedData = memoryCache[cacheKey],
           !cachedData.isExpired(timeout: cacheTimeout) {
            await incrementCacheHits()
            
            do {
                return try JSONDecoder().decode(type, from: cachedData.data)
            } catch {
                logger.error("Failed to decode cached data: \(error.localizedDescription)")
            }
        }
        
        // 2. Try network fetch with caching
        return await fetchAndCache(collection: collection, documentId: documentId, type: type)
    }
    
    private func standardDataRetrieval<T: Codable>(
        collection: String,
        documentId: String,
        type: T.Type
    ) async -> T? {
        // Fallback to direct Firestore access
        do {
            let document = try await db.collection(collection).document(documentId).getDocument()
            
            guard let data = document.data(),
                  let jsonData = try? JSONSerialization.data(withJSONObject: data) else {
                return nil
            }
            
            return try JSONDecoder().decode(type, from: jsonData)
        } catch {
            logger.error("Failed to fetch data: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Network Fetch with Caching
    private func fetchAndCache<T: Codable>(
        collection: String,
        documentId: String,
        type: T.Type
    ) async -> T? {
        await incrementNetworkRequests()
        
        do {
            let document = try await db.collection(collection).document(documentId).getDocument()
            
            guard let data = document.data(),
                  let jsonData = try? JSONSerialization.data(withJSONObject: data) else {
                return nil
            }
            
            // Cache the data
            await cacheData(jsonData, key: "\(collection)/\(documentId)")
            
            return try JSONDecoder().decode(type, from: jsonData)
        } catch {
            logger.error("Failed to fetch and cache data: \(error.localizedDescription)")
            
            // Try to return stale cached data if network fails
            if let cachedData = memoryCache["\(collection)/\(documentId)"] {
                logger.info("Returning stale cached data due to network error")
                return try? JSONDecoder().decode(type, from: cachedData.data)
            }
            
            return nil
        }
    }
    
    // MARK: - Data Writing
    func setData<T: Codable>(
        collection: String,
        documentId: String,
        data: T,
        merge: Bool = false
    ) async -> Bool {
        if FeatureFlags.useSmartDataSync {
            return await optimizedDataWrite(collection: collection, documentId: documentId, data: data, merge: merge)
        } else {
            return await standardDataWrite(collection: collection, documentId: documentId, data: data, merge: merge)
        }
    }
    
    private func optimizedDataWrite<T: Codable>(
        collection: String,
        documentId: String,
        data: T,
        merge: Bool
    ) async -> Bool {
        do {
            let jsonData = try JSONEncoder().encode(data)
            guard let dataDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                return false
            }
            
            if isOnline {
                // Try immediate sync
                try await db.collection(collection).document(documentId).setData(dataDict, merge: merge)
                
                // Update cache
                await cacheData(jsonData, key: "\(collection)/\(documentId)")
                await incrementSyncOperations()
                
                return true
            } else {
                // Cache optimistically for offline mode
                await cacheData(jsonData, key: "\(collection)/\(documentId)")
                return true
            }
        } catch {
            logger.error("Failed to write data: \(error.localizedDescription)")
            return false
        }
    }
    
    private func standardDataWrite<T: Codable>(
        collection: String,
        documentId: String,
        data: T,
        merge: Bool
    ) async -> Bool {
        do {
            let jsonData = try JSONEncoder().encode(data)
            guard let dataDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                return false
            }
            
            try await db.collection(collection).document(documentId).setData(dataDict, merge: merge)
            return true
        } catch {
            logger.error("Failed to write data: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Cache Management
    private func cacheData(_ data: Data, key: String) async {
        let cachedData = CachedData(data: data, timestamp: Date())
        memoryCache[key] = cachedData
    }
    
    // MARK: - Statistics
    private func incrementCacheHits() async {
        syncStats.cacheHits += 1
    }
    
    private func incrementNetworkRequests() async {
        syncStats.networkRequests += 1
    }
    
    private func incrementSyncOperations() async {
        syncStats.syncOperations += 1
    }
    
    // MARK: - Public Interface
    func clearCache() {
        memoryCache.removeAll()
    }
    
    func getSyncReport() -> String {
        return """
        📊 Data Sync Report:
        - Cache Hits: \(syncStats.cacheHits)
        - Network Requests: \(syncStats.networkRequests)
        - Sync Operations: \(syncStats.syncOperations)
        - Efficiency: \(String(format: "%.1f", syncStats.efficiency * 100))%
        """
    }
}

// MARK: - Supporting Types
private struct CachedData {
    let data: Data
    let timestamp: Date
    
    func isExpired(timeout: TimeInterval) -> Bool {
        return Date().timeIntervalSince(timestamp) > timeout
    }
} 