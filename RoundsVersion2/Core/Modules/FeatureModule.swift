import Foundation
import SwiftUI
import Combine
import os

// MARK: - Feature Module Architecture
// Enterprise-grade modular system for scalable feature development

// MARK: - Core Module Protocols
protocol FeatureModule: ObservableObject {
    associatedtype Configuration: ModuleConfiguration
    associatedtype Dependencies: ModuleDependencies
    
    var moduleId: String { get }
    var version: String { get }
    var isEnabled: Bool { get set }
    var configuration: Configuration { get set }
    var dependencies: Dependencies { get }
    
    func initialize() async throws
    func shutdown() async
    func healthCheck() async -> ModuleHealth
}

protocol ModuleConfiguration: Codable {
    var featureFlags: [String: Bool] { get set }
}

protocol ModuleDependencies {
    var serviceContainer: ServiceContainer { get }
    var logger: Logger { get }
}

// MARK: - Module Health & Status
struct ModuleHealth {
    let status: HealthStatus
    let metrics: HealthMetrics
    let lastCheck: Date
    let issues: [HealthIssue]
    
    enum HealthStatus {
        case healthy, warning, critical, unknown
    }
    
    struct HealthMetrics {
        let memoryUsage: Int // bytes
        let cpuUsage: Double // percentage
        let networkRequests: Int
        let errorRate: Double
        let responseTime: TimeInterval
    }
    
    struct HealthIssue {
        let severity: Severity
        let description: String
        let recommendation: String
        
        enum Severity {
            case low, medium, high, critical
        }
    }
}

// MARK: - Module Manager
@MainActor
class ModuleManager: ObservableObject {
    static let shared = ModuleManager()
    
    @Published var modules: [String: any FeatureModule] = [:]
    @Published var moduleHealth: [String: ModuleHealth] = [:]
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.rounds", category: "ModuleManager")
    private var healthCheckTimer: Timer?
    
    private init() {
        if FeatureFlags.useModularArchitecture {
            scheduleHealthChecks()
        }
    }
    
    // MARK: - Module Registration
    func register<T: FeatureModule>(_ module: T) async throws {
        guard FeatureFlags.enableFeatureModules else { return }
        
        logger.info("Registering module: \(module.moduleId) v\(module.version)")
        
        do {
            try await module.initialize()
            modules[module.moduleId] = module
            
            // Initial health check
            let health = await module.healthCheck()
            moduleHealth[module.moduleId] = health
            
            logger.info("✅ Module \(module.moduleId) registered successfully")
        } catch {
            logger.error("❌ Failed to register module \(module.moduleId): \(error.localizedDescription)")
            throw ModuleError.registrationFailed(module.moduleId, error)
        }
    }
    
    func unregister(_ moduleId: String) async {
        guard let module = modules[moduleId] else { return }
        
        logger.info("Unregistering module: \(moduleId)")
        
        await module.shutdown()
        modules.removeValue(forKey: moduleId)
        moduleHealth.removeValue(forKey: moduleId)
        
        logger.info("✅ Module \(moduleId) unregistered")
    }
    
    // MARK: - Module Access
    func getModule<T: FeatureModule>(_ type: T.Type) -> T? {
        return modules.values.compactMap { $0 as? T }.first
    }
    
    func getModule(id: String) -> (any FeatureModule)? {
        return modules[id]
    }
    
    // MARK: - Health Monitoring
    private func scheduleHealthChecks() {
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task {
                await self?.performHealthChecks()
            }
        }
    }
    
    private func performHealthChecks() async {
        guard FeatureFlags.useAdvancedMonitoring else { return }
        
        for (id, module) in modules {
            let health = await module.healthCheck()
            moduleHealth[id] = health
            
            // Alert on critical issues
            if health.status == .critical {
                logger.error("🚨 CRITICAL: Module \(id) health check failed")
                await handleCriticalModule(id, health: health)
            }
        }
    }
    
    private func handleCriticalModule(_ moduleId: String, health: ModuleHealth) async {
        // Auto-restart critical modules if enabled
        if FeatureFlags.enableHotSwapping {
            logger.info("🔄 Attempting to restart critical module: \(moduleId)")
            await restartModule(moduleId)
        }
    }
    
    // MARK: - Hot Swapping
    func restartModule(_ moduleId: String) async {
        guard FeatureFlags.enableHotSwapping,
              let module = modules[moduleId] else { return }
        
        logger.info("🔄 Restarting module: \(moduleId)")
        
        await module.shutdown()
        
        do {
            try await module.initialize()
            logger.info("✅ Module \(moduleId) restarted successfully")
        } catch {
            logger.error("❌ Failed to restart module \(moduleId): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Module Communication
    func sendMessage<T>(_ message: T, to moduleId: String) async -> Bool {
        guard modules[moduleId] != nil else { return false }
        
        // Inter-module communication would be implemented here
        logger.info("📨 Sending message to module: \(moduleId)")
        return true
    }
    
    // MARK: - Performance Metrics
    func getSystemHealth() -> SystemHealth {
        let moduleStatuses = moduleHealth.mapValues { $0.status }
        let overallStatus = determineOverallStatus(moduleStatuses.values)
        
        let totalMemory = moduleHealth.values.reduce(0) { $0 + $1.metrics.memoryUsage }
        let avgCpuUsage = moduleHealth.values.reduce(0.0) { $0 + $1.metrics.cpuUsage } / Double(max(moduleHealth.count, 1))
        
        return SystemHealth(
            overallStatus: overallStatus,
            moduleCount: modules.count,
            totalMemoryUsage: totalMemory,
            averageCpuUsage: avgCpuUsage,
            lastUpdate: Date()
        )
    }
    
    private func determineOverallStatus(_ statuses: Dictionary<String, ModuleHealth.HealthStatus>.Values) -> ModuleHealth.HealthStatus {
        if statuses.contains(.critical) { return .critical }
        if statuses.contains(.warning) { return .warning }
        if statuses.allSatisfy({ $0 == .healthy }) { return .healthy }
        return .unknown
    }
}

// MARK: - System Health
struct SystemHealth {
    let overallStatus: ModuleHealth.HealthStatus
    let moduleCount: Int
    let totalMemoryUsage: Int
    let averageCpuUsage: Double
    let lastUpdate: Date
}

// MARK: - Base Module Implementation
@MainActor
class BaseFeatureModule: ObservableObject, @preconcurrency FeatureModule {
    let moduleId: String
    let version: String
    @Published var isEnabled: Bool = true
    nonisolated(unsafe) var configuration: BaseModuleConfiguration
    nonisolated let dependencies: BaseDependencies
    
    init(moduleId: String, version: String = "1.0.0") {
        self.moduleId = moduleId
        self.version = version
        self.configuration = BaseModuleConfiguration()
        self.dependencies = BaseDependencies()
    }
    
    func initialize() async throws {
        // Base initialization - override in subclasses
        dependencies.logger.info("Initializing module: \(self.moduleId)")
    }
    
    func shutdown() async {
        // Base shutdown - override in subclasses
        dependencies.logger.info("Shutting down module: \(self.moduleId)")
    }
    
    func healthCheck() async -> ModuleHealth {
        // Basic health check - override for specific metrics
        return ModuleHealth(
            status: await self.isEnabled ? .healthy : .warning,
            metrics: ModuleHealth.HealthMetrics(
                memoryUsage: 1024 * 1024, // 1MB default
                cpuUsage: 5.0, // 5% default
                networkRequests: 0,
                errorRate: 0.0,
                responseTime: 0.1
            ),
            lastCheck: Date(),
            issues: []
        )
    }
}

// MARK: - Base Configuration & Dependencies
struct BaseModuleConfiguration: ModuleConfiguration {
    var featureFlags: [String: Bool] = [:]
    
    // Codable conformance is now automatic
}

struct BaseDependencies: ModuleDependencies {
    let serviceContainer = ServiceContainer.shared
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.rounds", category: "Module")
}

// MARK: - Module Errors
enum ModuleError: LocalizedError {
    case registrationFailed(String, Error)
    case initializationFailed(String)
    case configurationInvalid(String)
    
    var errorDescription: String? {
        switch self {
        case .registrationFailed(let id, let error):
            return "Failed to register module \(id): \(error.localizedDescription)"
        case .initializationFailed(let id):
            return "Failed to initialize module \(id)"
        case .configurationInvalid(let id):
            return "Invalid configuration for module \(id)"
        }
    }
} 