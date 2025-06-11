import Foundation
import UIKit
import os

// MARK: - Advanced Image Caching System
// High-performance, disk-persistent image cache with smart eviction

@MainActor
class AdvancedImageCache: ObservableObject {
    static let shared = AdvancedImageCache()
    
    // MARK: - Configuration
    private let maxMemorySize: Int = 50 * 1024 * 1024 // 50MB memory cache
    private let maxDiskSize: Int = 200 * 1024 * 1024 // 200MB disk cache
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    // MARK: - Cache Storage
    private var memoryCache = NSCache<NSString, UIImage>()
    private let diskCacheURL: URL
    private let cacheQueue = DispatchQueue(label: "com.rounds.imageCache", qos: .utility)
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.rounds", category: "ImageCache")
    
    // MARK: - Cache Statistics
    @Published var cacheStats = CacheStatistics()
    
    struct CacheStatistics {
        var memoryHits: Int = 0
        var diskHits: Int = 0
        var networkRequests: Int = 0
        var memorySize: Int = 0
        var diskSize: Int = 0
        var totalRequests: Int = 0
        
        var hitRate: Double {
            guard totalRequests > 0 else { return 0 }
            return Double(memoryHits + diskHits) / Double(totalRequests)
        }
    }
    
    // MARK: - Initialization
    private init() {
        // Setup cache directory
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = cacheDir.appendingPathComponent("RoundsImageCache")
        
        setupCache()
        scheduleCleanup()
    }
    
    private func setupCache() {
        // Configure memory cache
        memoryCache.countLimit = 100 // Max 100 images in memory
        memoryCache.totalCostLimit = maxMemorySize
        
        // Create disk cache directory
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }
    
    // MARK: - Public Cache Interface
    func cachedImage(for url: String) async -> UIImage? {
        await incrementTotalRequests()
        
        if FeatureFlags.useAdvancedImageCache {
            return await optimizedImageRetrieval(for: url)
        } else {
            return await standardImageRetrieval(for: url)
        }
    }
    
    private func optimizedImageRetrieval(for url: String) async -> UIImage? {
        let cacheKey = cacheKeyForURL(url)
        
        // 1. Check memory cache first (fastest)
        if let memoryImage = memoryCache.object(forKey: cacheKey as NSString) {
            await incrementMemoryHits()
            return memoryImage
        }
        
        // 2. Check disk cache (fast)
        if FeatureFlags.enableDiskCaching,
           let diskImage = await loadFromDisk(cacheKey: cacheKey) {
            await incrementDiskHits()
            // Store in memory for next time
            memoryCache.setObject(diskImage, forKey: cacheKey as NSString)
            return diskImage
        }
        
        // 3. Download from network (slow)
        return await downloadAndCache(url: url, cacheKey: cacheKey)
    }
    
    private func standardImageRetrieval(for url: String) async -> UIImage? {
        // Fallback to basic URLSession download
        guard let imageURL = URL(string: url) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            return UIImage(data: data)
        } catch {
            logger.error("Failed to download image: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Network Download with Caching
    private func downloadAndCache(url: String, cacheKey: String) async -> UIImage? {
        await incrementNetworkRequests()
        
        guard let imageURL = URL(string: url) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            
            guard let image = UIImage(data: data) else { return nil }
            
            // Cache the image
            await cacheImage(image, data: data, key: cacheKey)
            
            return image
        } catch {
            logger.error("Failed to download image from \(url): \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Cache Storage
    private func cacheImage(_ image: UIImage, data: Data, key: String) async {
        // Store in memory cache
        memoryCache.setObject(image, forKey: key as NSString, cost: data.count)
        
        // Store in disk cache if enabled
        if FeatureFlags.enableDiskCaching {
            await storeToDisk(data: data, key: key)
        }
        
        await updateMemorySize()
    }
    
    private func storeToDisk(data: Data, key: String) async {
        let fileURL = diskCacheURL.appendingPathComponent(key)
        let metadataURL = diskCacheURL.appendingPathComponent("\(key).metadata")
        
        cacheQueue.async {
            do {
                // Write image data
                try data.write(to: fileURL)
                
                // Write metadata
                let metadata = CacheMetadata(
                    cacheDate: Date(),
                    dataSize: data.count
                )
                let metadataData = try JSONEncoder().encode(metadata)
                try metadataData.write(to: metadataURL)
            } catch {
                print("Failed to cache image to disk: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadFromDisk(cacheKey: String) async -> UIImage? {
        let fileURL = diskCacheURL.appendingPathComponent(cacheKey)
        let metadataURL = diskCacheURL.appendingPathComponent("\(cacheKey).metadata")
        
        // Check if files exist and are not expired
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let metadataData = try? Data(contentsOf: metadataURL),
              let metadata = try? JSONDecoder().decode(CacheMetadata.self, from: metadataData),
              !metadata.isExpired(maxAge: maxCacheAge) else {
            return nil
        }
        
        // Load image data
        guard let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData) else {
            return nil
        }
        
        return image
    }
    
    // MARK: - Background Prefetching
    func prefetchImages(_ urls: [String]) async {
        guard FeatureFlags.enableBackgroundPrefetch else { return }
        
        // Prefetch up to 5 images concurrently
        await withTaskGroup(of: Void.self) { group in
            for url in urls.prefix(5) {
                group.addTask {
                    _ = await self.cachedImage(for: url)
                }
            }
        }
    }
    
    // MARK: - Cache Management
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
        Task { @MainActor in
            await updateMemorySize()
            logger.info("Memory cache cleared")
        }
    }
    
    // MARK: - Cache Cleanup
    private func scheduleCleanup() {
        Timer.scheduledTimer(withTimeInterval: 60 * 60, repeats: true) { [weak self] _ in
            Task {
                await self?.performCleanup()
            }
        }
    }
    
    private func performCleanup() async {
        cacheQueue.async {
            do {
                let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("RoundsImageCache")
                let files = try FileManager.default.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil)
                
                for file in files {
                    if file.pathExtension == "metadata" {
                        if let metadataData = try? Data(contentsOf: file),
                           let metadata = try? JSONDecoder().decode(CacheMetadata.self, from: metadataData),
                           metadata.isExpired(maxAge: 7 * 24 * 60 * 60) {
                            
                            // Remove both image and metadata files
                            let imageFile = file.deletingPathExtension()
                            try? FileManager.default.removeItem(at: imageFile)
                            try? FileManager.default.removeItem(at: file)
                        }
                    }
                }
            } catch {
                print("Failed to cleanup expired files: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Statistics & Monitoring
    private func incrementTotalRequests() async {
        cacheStats.totalRequests += 1
    }
    
    private func incrementMemoryHits() async {
        cacheStats.memoryHits += 1
    }
    
    private func incrementDiskHits() async {
        cacheStats.diskHits += 1
    }
    
    private func incrementNetworkRequests() async {
        cacheStats.networkRequests += 1
    }
    
    private func updateMemorySize() async {
        cacheStats.memorySize = memoryCache.totalCostLimit
    }
    
    // MARK: - Utilities
    private func cacheKeyForURL(_ url: String) -> String {
        return url.data(using: .utf8)?.base64EncodedString() ?? url.replacingOccurrences(of: "/", with: "_")
    }
}

// MARK: - Cache Metadata
private struct CacheMetadata: Codable {
    let cacheDate: Date
    let dataSize: Int
    
    func isExpired(maxAge: TimeInterval) -> Bool {
        return Date().timeIntervalSince(cacheDate) > maxAge
    }
} 