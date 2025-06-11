import Foundation
import Network
import os

// MARK: - Network Optimization Service
// Intelligent request deduplication, batching, and retry mechanisms

@MainActor
class NetworkOptimizer: ObservableObject {
    static let shared = NetworkOptimizer()
    
    // MARK: - Configuration
    private let maxRetries = 3
    private let baseRetryDelay: TimeInterval = 1.0
    private let requestTimeout: TimeInterval = 30.0
    
    // MARK: - Dependencies
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.rounds", category: "NetworkOptimizer")
    
    // MARK: - Network State
    @Published var networkStatus: NetworkStatus = .connected
    @Published var bandwidthQuality: BandwidthQuality = .good
    @Published var optimizationStats = OptimizationStatistics()
    
    enum NetworkStatus {
        case connected
        case constrained
        case expensive
        case disconnected
        case unknown
    }
    
    enum BandwidthQuality {
        case excellent
        case good
        case fair
        case poor
    }
    
    struct OptimizationStatistics {
        var requestsSaved: Int = 0
        var batchesSent: Int = 0
        var retryAttempts: Int = 0
        var networkErrors: Int = 0
        var averageResponseTime: TimeInterval = 0
        
        var efficiency: Double {
            let totalRequests = requestsSaved + batchesSent
            guard totalRequests > 0 else { return 0 }
            return Double(requestsSaved) / Double(totalRequests)
        }
    }
    
    // MARK: - Initialization
    private init() {
        // Simplified initialization
    }
    
    // MARK: - Optimized Request Interface
    func performRequest(
        url: URL,
        method: String = "GET",
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> Data {
        if FeatureFlags.useNetworkOptimization {
            return try await optimizedRequest(url: url, method: method, headers: headers, body: body)
        } else {
            return try await standardRequest(url: url, method: method, headers: headers, body: body)
        }
    }
    
    private func optimizedRequest(
        url: URL,
        method: String,
        headers: [String: String],
        body: Data?
    ) async throws -> Data {
        // Execute with retry logic
        return try await executeWithRetry(url: url, method: method, headers: headers, body: body)
    }
    
    private func standardRequest(
        url: URL,
        method: String,
        headers: [String: String],
        body: Data?
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = requestTimeout
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
    
    // MARK: - Retry Logic
    private func executeWithRetry(
        url: URL,
        method: String,
        headers: [String: String],
        body: Data?
    ) async throws -> Data {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                let data = try await performNetworkRequest(
                    url: url,
                    method: method,
                    headers: headers,
                    body: body
                )
                
                return data
                
            } catch {
                lastError = error
                await incrementRetryAttempts()
                
                // Don't retry on certain errors
                if !shouldRetry(error: error) {
                    break
                }
                
                // Exponential backoff with jitter
                if attempt < maxRetries - 1 {
                    let delay = baseRetryDelay * pow(2.0, Double(attempt)) + Double.random(in: 0...1)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        await incrementNetworkErrors()
        throw lastError ?? NSError(domain: "NetworkOptimizer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown network error"])
    }
    
    private func performNetworkRequest(
        url: URL,
        method: String,
        headers: [String: String],
        body: Data?
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = requestTimeout
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Validate response
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode >= 400 {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        return data
    }
    
    private func shouldRetry(error: Error) -> Bool {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .httpError(let code):
                // Don't retry client errors (4xx)
                return code >= 500
            case .timeout, .connectionFailed:
                return true
            }
        }
        
        // Retry on network connectivity issues
        if (error as NSError).domain == NSURLErrorDomain {
            let code = (error as NSError).code
            return [
                NSURLErrorTimedOut,
                NSURLErrorCannotFindHost,
                NSURLErrorCannotConnectToHost,
                NSURLErrorNetworkConnectionLost
            ].contains(code)
        }
        
        return false
    }
    
    // MARK: - Statistics & Monitoring
    private func incrementRetryAttempts() async {
        optimizationStats.retryAttempts += 1
    }
    
    private func incrementNetworkErrors() async {
        optimizationStats.networkErrors += 1
    }
    
    // MARK: - Public Interface
    func clearMetrics() {
        optimizationStats = OptimizationStatistics()
    }
    
    func getNetworkReport() -> String {
        return """
        📊 Network Optimization Report:
        - Status: \(networkStatus)
        - Quality: \(bandwidthQuality)
        - Retry Attempts: \(optimizationStats.retryAttempts)
        - Network Errors: \(optimizationStats.networkErrors)
        """
    }
}

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case httpError(Int)
    case timeout
    case connectionFailed
    
    var errorDescription: String? {
        switch self {
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .timeout:
            return "Request timed out"
        case .connectionFailed:
            return "Connection failed"
        }
    }
} 