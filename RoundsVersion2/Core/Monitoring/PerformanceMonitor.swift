import Foundation
import os.log

// MARK: - Performance Monitor for Optimization Tracking
class PerformanceMonitor {
    
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "RoundsVersion2", category: "Performance")
    
    // MARK: - Metrics Storage
    private static var metrics: [String: PerformanceMetric] = [:]
    private static let queue = DispatchQueue(label: "performance-monitor", qos: .utility)
    
    // MARK: - Performance Measurement
    static func measure<T>(_ operationName: String, operation: () async throws -> T) async rethrows -> T {
        guard FeatureFlags.enablePerformanceMonitoring else {
            return try await operation()
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = getCurrentMemoryUsage()
        
        let result = try await operation()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let endMemory = getCurrentMemoryUsage()
        let duration = endTime - startTime
        let memoryDelta = endMemory - startMemory
        
        await recordMetric(
            operation: operationName,
            duration: duration,
            memoryDelta: memoryDelta
        )
        
        return result
    }
    
    static func measureSync<T>(_ operationName: String, operation: () throws -> T) rethrows -> T {
        guard FeatureFlags.enablePerformanceMonitoring else {
            return try operation()
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = getCurrentMemoryUsage()
        
        let result = try operation()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let endMemory = getCurrentMemoryUsage()
        let duration = endTime - startTime
        let memoryDelta = endMemory - startMemory
        
        Task {
            await recordMetric(
                operation: operationName,
                duration: duration,
                memoryDelta: memoryDelta
            )
        }
        
        return result
    }
    
    // MARK: - Crash Protection
    static func safely<T>(_ operationName: String, 
                         operation: () async throws -> T, 
                         fallback: () async -> T) async -> T {
        guard FeatureFlags.enableCrashProtection else {
            do {
                return try await operation()
            } catch {
                logger.error("Operation failed: \(operationName) - \(error.localizedDescription)")
                return await fallback()
            }
        }
        
        do {
            return try await measure(operationName, operation: operation)
        } catch {
            logger.error("🚨 New implementation failed for \(operationName): \(error.localizedDescription)")
            await recordFailure(operation: operationName, error: error)
            return await fallback()
        }
    }
    
    // MARK: - Memory Tracking
    private static func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // MB
        } else {
            return 0
        }
    }
    
    // MARK: - Metric Recording
    @MainActor
    private static func recordMetric(operation: String, duration: Double, memoryDelta: Double) {
        queue.async {
            let metric = PerformanceMetric(
                operation: operation,
                duration: duration,
                memoryDelta: memoryDelta,
                timestamp: Date()
            )
            
            metrics[operation] = metric
            
            if FeatureFlags.enableDebugLogging {
                logger.info("📊 \(operation): \(String(format: "%.3f", duration))s, Memory: \(String(format: "%.1f", memoryDelta))MB")
            }
        }
    }
    
    @MainActor
    private static func recordFailure(operation: String, error: Error) {
        queue.async {
            logger.error("❌ \(operation) failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Metrics Retrieval
    static func getMetrics() -> [String: PerformanceMetric] {
        return queue.sync { metrics }
    }
    
    static func clearMetrics() {
        queue.async { metrics.removeAll() }
    }
    
    // MARK: - Performance Report
    static func generateReport() -> String {
        let currentMetrics = getMetrics()
        
        guard !currentMetrics.isEmpty else {
            return "No performance metrics available"
        }
        
        var report = "📊 Performance Report\n"
        report += "===================\n\n"
        
        for (operation, metric) in currentMetrics.sorted(by: { $0.value.duration > $1.value.duration }) {
            report += "🔄 \(operation):\n"
            report += "   Duration: \(String(format: "%.3f", metric.duration))s\n"
            report += "   Memory: \(String(format: "%.1f", metric.memoryDelta))MB\n"
            report += "   Time: \(metric.timestamp)\n\n"
        }
        
        return report
    }
}

// MARK: - Performance Metric Model
struct PerformanceMetric {
    let operation: String
    let duration: Double
    let memoryDelta: Double
    let timestamp: Date
} 