import Foundation
import SwiftUI
import Combine
import os

// MARK: - Plugin System Architecture
// Extensible plugin system for dynamic feature loading and A/B testing

// MARK: - Plugin Protocols
protocol Plugin: AnyObject {
    var pluginId: String { get }
    var version: String { get }
    var name: String { get }
    var description: String { get }
    var isEnabled: Bool { get set }
    
    func load() async throws
    func unload() async
    func configure(with settings: [String: Any]) async
}

protocol UIPlugin: Plugin {
    associatedtype ContentView: View
    
    func createView() -> ContentView
    func updateView(_ view: ContentView, with data: [String: Any]) -> ContentView
}

protocol ServicePlugin: Plugin {
    associatedtype Service
    
    func createService() -> Service
    func configureService(_ service: Service) async
}

protocol AnalyticsPlugin: Plugin {
    func trackEvent(_ event: String, parameters: [String: Any])
    func trackUserProperty(_ property: String, value: Any)
}

// MARK: - Plugin Manager
@MainActor
class PluginManager: ObservableObject {
    static let shared = PluginManager()
    
    @Published var loadedPlugins: [String: Plugin] = [:]
    @Published var availablePlugins: [PluginManifest] = []
    @Published var pluginStats: [String: PluginStatistics] = [:]
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.rounds", category: "PluginManager")
    private var abTestingEngine: ABTestingEngine?
    
    struct PluginManifest {
        let id: String
        let name: String
        let version: String
        let description: String
        let type: PluginType
        let dependencies: [String]
        let minimumAppVersion: String
        
        enum PluginType {
            case ui, service, analytics, experimental
        }
    }
    
    struct PluginStatistics {
        var loadTime: TimeInterval = 0
        var memoryUsage: Int = 0
        var errorCount: Int = 0
        var lastUsed: Date?
        var usageCount: Int = 0
    }
    
    private init() {
        if FeatureFlags.enablePluginSystem {
            setupPluginSystem()
        }
        
        if FeatureFlags.enableABTesting {
            abTestingEngine = ABTestingEngine()
        }
    }
    
    // MARK: - Plugin Management
    func loadPlugin<T: Plugin>(_ plugin: T) async throws {
        guard FeatureFlags.enablePluginSystem else { return }
        
        logger.info("🔌 Loading plugin: \(plugin.name) v\(plugin.version)")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            try await plugin.load()
            
            loadedPlugins[plugin.pluginId] = plugin
            
            // Record statistics
            let loadTime = CFAbsoluteTimeGetCurrent() - startTime
            pluginStats[plugin.pluginId] = PluginStatistics(
                loadTime: loadTime,
                lastUsed: Date(),
                usageCount: 1
            )
            
            logger.info("✅ Plugin \(plugin.name) loaded successfully in \(String(format: "%.3f", loadTime))s")
            
        } catch {
            logger.error("❌ Failed to load plugin \(plugin.name): \(error.localizedDescription)")
            throw PluginError.loadFailed(plugin.pluginId, error)
        }
    }
    
    func unloadPlugin(_ pluginId: String) async {
        guard let plugin = loadedPlugins[pluginId] else { return }
        
        logger.info("🔌 Unloading plugin: \(plugin.name)")
        
        await plugin.unload()
        loadedPlugins.removeValue(forKey: pluginId)
        
        logger.info("✅ Plugin \(plugin.name) unloaded")
    }
    
    func reloadPlugin(_ pluginId: String) async throws {
        guard FeatureFlags.enableHotSwapping,
              let plugin = loadedPlugins[pluginId] else { return }
        
        logger.info("🔄 Reloading plugin: \(plugin.name)")
        
        await unloadPlugin(pluginId)
        try await loadPlugin(plugin)
    }
    
    // MARK: - Plugin Discovery
    func getPlugin<T: Plugin>(_ type: T.Type) -> T? {
        return loadedPlugins.values.compactMap { $0 as? T }.first
    }
    
    func getPlugins<T: Plugin>(ofType type: T.Type) -> [T] {
        return loadedPlugins.values.compactMap { $0 as? T }
    }
    
    func isPluginLoaded(_ pluginId: String) -> Bool {
        return loadedPlugins[pluginId] != nil
    }
    
    // MARK: - Configuration
    func configurePlugin(_ pluginId: String, settings: [String: Any]) async {
        guard let plugin = loadedPlugins[pluginId] else { return }
        
        logger.info("⚙️ Configuring plugin: \(plugin.name)")
        await plugin.configure(with: settings)
        
        // Update usage statistics
        pluginStats[pluginId]?.usageCount += 1
        pluginStats[pluginId]?.lastUsed = Date()
    }
    
    // MARK: - System Setup
    private func setupPluginSystem() {
        // Load core plugins
        Task {
            await loadCorePlugins()
        }
        
        // Setup plugin discovery
        discoverAvailablePlugins()
    }
    
    private func loadCorePlugins() async {
        // Load essential plugins here
        logger.info("Loading core plugins...")
        
        // Example: Analytics plugin
        if FeatureFlags.useAnalyticsPipeline {
            await loadAnalyticsPlugin()
        }
    }
    
    private func loadAnalyticsPlugin() async {
        let analyticsPlugin = CoreAnalyticsPlugin()
        do {
            try await loadPlugin(analyticsPlugin)
        } catch {
            logger.error("Failed to load analytics plugin: \(error.localizedDescription)")
        }
    }
    
    private func discoverAvailablePlugins() {
        // Discover available plugins from bundle or remote source
        availablePlugins = [
            PluginManifest(
                id: "com.rounds.analytics",
                name: "Core Analytics",
                version: "1.0.0",
                description: "Core analytics and event tracking",
                type: .analytics,
                dependencies: [],
                minimumAppVersion: "1.0.0"
            )
        ]
    }
    
    // MARK: - A/B Testing Integration
    func createABTest(_ testId: String, variants: [String], allocation: [String: Double]) {
        abTestingEngine?.createTest(testId, variants: variants, allocation: allocation)
    }
    
    func getABTestVariant(_ testId: String, userId: String) -> String? {
        return abTestingEngine?.getVariant(testId, userId: userId)
    }
    
    func trackABTestConversion(_ testId: String, userId: String, conversionEvent: String) {
        abTestingEngine?.trackConversion(testId, userId: userId, event: conversionEvent)
    }
    
    // MARK: - Performance Monitoring
    func getPluginPerformanceReport() -> String {
        var report = "🔌 Plugin Performance Report:\n\n"
        
        for (id, stats) in pluginStats {
            if let plugin = loadedPlugins[id] {
                report += """
                📱 \(plugin.name) (v\(plugin.version))
                • Load Time: \(String(format: "%.3f", stats.loadTime))s
                • Memory: \(stats.memoryUsage / 1024)KB
                • Usage Count: \(stats.usageCount)
                • Last Used: \(stats.lastUsed?.formatted(.dateTime.hour().minute()) ?? "Never")
                • Errors: \(stats.errorCount)
                
                """
            }
        }
        
        return report
    }
}

// MARK: - A/B Testing Engine
class ABTestingEngine {
    private var activeTests: [String: ABTest] = [:]
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.rounds", category: "ABTesting")
    
    struct ABTest {
        let id: String
        let variants: [String]
        let allocation: [String: Double]
        var participants: [String: String] = [:] // userId -> variant
        var conversions: [String: [String]] = [:] // variant -> [events]
    }
    
    func createTest(_ testId: String, variants: [String], allocation: [String: Double]) {
        let test = ABTest(
            id: testId,
            variants: variants,
            allocation: allocation
        )
        
        activeTests[testId] = test
        logger.info("🧪 Created A/B test: \(testId) with variants: \(variants)")
    }
    
    func getVariant(_ testId: String, userId: String) -> String? {
        guard var test = activeTests[testId] else { return nil }
        
        // Check if user already assigned
        if let existingVariant = test.participants[userId] {
            return existingVariant
        }
        
        // Assign variant based on allocation
        let variant = assignVariant(test.allocation, userId: userId)
        test.participants[userId] = variant
        activeTests[testId] = test
        
        logger.info("🧪 Assigned user \(userId) to variant \(variant) for test \(testId)")
        return variant
    }
    
    func trackConversion(_ testId: String, userId: String, event: String) {
        guard var test = activeTests[testId],
              let variant = test.participants[userId] else { return }
        
        if test.conversions[variant] == nil {
            test.conversions[variant] = []
        }
        test.conversions[variant]?.append(event)
        activeTests[testId] = test
        
        logger.info("🧪 Tracked conversion for user \(userId) in variant \(variant): \(event)")
    }
    
    private func assignVariant(_ allocation: [String: Double], userId: String) -> String {
        // Simple hash-based assignment for consistency
        let hash = abs(userId.hashValue)
        let normalized = Double(hash % 100) / 100.0
        
        var cumulative = 0.0
        for (variant, probability) in allocation {
            cumulative += probability
            if normalized <= cumulative {
                return variant
            }
        }
        
        return allocation.keys.first ?? "control"
    }
}

// MARK: - Core Analytics Plugin
class CoreAnalyticsPlugin: AnalyticsPlugin {
    let pluginId = "com.rounds.analytics"
    let version = "1.0.0"
    let name = "Core Analytics"
    let description = "Core analytics and event tracking functionality"
    var isEnabled = true
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.rounds", category: "Analytics")
    
    func load() async throws {
        logger.info("Loading Core Analytics Plugin")
        // Initialize analytics systems
    }
    
    func unload() async {
        logger.info("Unloading Core Analytics Plugin")
        // Cleanup analytics systems
    }
    
    func configure(with settings: [String: Any]) async {
        logger.info("Configuring analytics with settings: \(settings)")
        // Apply configuration
    }
    
    func trackEvent(_ event: String, parameters: [String: Any]) {
        guard isEnabled else { return }
        
        logger.info("📊 Event: \(event) - \(parameters)")
        // Send to analytics service
    }
    
    func trackUserProperty(_ property: String, value: Any) {
        guard isEnabled else { return }
        
        logger.info("👤 User Property: \(property) = \(String(describing: value))")
        // Update user properties
    }
}

// MARK: - Plugin Errors
enum PluginError: LocalizedError {
    case loadFailed(String, Error)
    case configurationInvalid(String)
    case dependencyNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .loadFailed(let id, let error):
            return "Failed to load plugin \(id): \(error.localizedDescription)"
        case .configurationInvalid(let id):
            return "Invalid configuration for plugin \(id)"
        case .dependencyNotFound(let dependency):
            return "Required dependency not found: \(dependency)"
        }
    }
} 