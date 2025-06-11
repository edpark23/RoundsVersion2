import Foundation

// MARK: - Feature Flags for Safe Migration
struct FeatureFlags {
    
    // MARK: - Service Layer Flags
    static var useNewImageCache = true
    static var useNewSocialService = true
    static var useNewAuthService = true
    static var useNewGolfCourseService = true
    static var useNewScoreVerification = true
    static var useNewTournamentService = true
    
    // MARK: - Architecture Flags
    static var useDependencyInjection = true
    static var useNewStateManagement = true
    static var useComponentViews = true
    static var useOptimizedViewModels = true
    
    // MARK: - Performance Flags
    static var enableImageCaching = true
    static var enableQueryOptimization = true
    static var enableIncrementalLoading = true
    static var enableBackgroundProcessing = true
    
    // MARK: - UI Optimization Flags
    static var useOptimizedHomeView = true
    static var useOptimizedSocialView = true
    static var useOptimizedScoreView = true
    static var useOptimizedLiveMatchView = true
    
    // MARK: - Phase 3: Advanced View Optimizations
    static var useViewRecycling = true
    static var enableViewPerformanceOptimizations = true
    
    // MARK: - Phase 4: Image & Data Caching
    static var useAdvancedImageCache = true
    static var enableDiskCaching = true
    static var useSmartDataSync = true
    static var enableBackgroundPrefetch = true
    static var useNetworkOptimization = true
    static var enableOfflineMode = true
    
    // MARK: - Phase 6: Modular Architecture & Scalability
    static var useModularArchitecture = true
    static var enableFeatureModules = true
    static var useAdvancedMonitoring = true
    static var enablePluginSystem = true
    static var usePerformanceDashboard = true
    static var enableHotSwapping = true
    static var enableABTesting = true
    static var useAnalyticsPipeline = true
    
    // MARK: - Debug & Monitoring Flags
    static var enablePerformanceMonitoring = true
    static var enableDebugLogging = true
    static var enableCrashProtection = true
    
    // MARK: - Batch Operations
    static func enableCoreOptimizations() {
        useNewImageCache = true
        useDependencyInjection = true
        enableImageCaching = true
        enablePerformanceMonitoring = true
    }
    
    static func enableServiceOptimizations() {
        useNewSocialService = true
        useNewAuthService = true
        enableQueryOptimization = true
        enableIncrementalLoading = true
    }
    
    static func enableUIOptimizations() {
        useComponentViews = true
        useOptimizedViewModels = true
        useOptimizedHomeView = true
        useOptimizedSocialView = true
    }
    
    static func enableAllOptimizations() {
        enableCoreOptimizations()
        enableServiceOptimizations()
        enableUIOptimizations()
    }
    
    static func disableAllOptimizations() {
        // Service Layer
        useNewImageCache = false
        useNewSocialService = false
        useNewAuthService = false
        useNewGolfCourseService = false
        useNewScoreVerification = false
        useNewTournamentService = false
        
        // Architecture
        useDependencyInjection = false
        useNewStateManagement = false
        useComponentViews = false
        useOptimizedViewModels = false
        
        // Performance
        enableImageCaching = false
        enableQueryOptimization = false
        enableIncrementalLoading = false
        enableBackgroundProcessing = false
        
        // UI
        useOptimizedHomeView = false
        useOptimizedSocialView = false
        useOptimizedScoreView = false
        useOptimizedLiveMatchView = false
    }
    
    // MARK: - Emergency Rollback
    static func emergencyRollback() {
        print("🚨 EMERGENCY ROLLBACK: Disabling all optimizations")
        disableAllOptimizations()
        enablePerformanceMonitoring = true // Keep monitoring on
        enableDebugLogging = true // Enable debug for investigation
    }
} 