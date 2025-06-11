import Foundation
import SwiftUI

// MARK: - Service Container for Dependency Injection
class ServiceContainer {
    
    // Make shared nonisolated to avoid MainActor issues
    nonisolated(unsafe) static let shared = ServiceContainer()
    
    // MARK: - Private Initializer
    private init() {}
    
    // MARK: - Service Access Methods
    @MainActor
    func socialService() -> any SocialServiceProtocol {
        if FeatureFlags.useNewSocialService {
            return SocialServiceAdapter()
        } else {
            return SocialServiceWrapper(service: SocialService())
        }
    }
    
    // MARK: - Phase 4: Advanced Services
    @MainActor
    func advancedImageCache() -> AdvancedImageCache {
        return AdvancedImageCache.shared
    }
    
    @MainActor
    func smartDataSync() -> SmartDataSync {
        return SmartDataSync.shared
    }
    
    @MainActor
    func networkOptimizer() -> NetworkOptimizer {
        return NetworkOptimizer.shared
    }
    
    @MainActor
    func authService() -> any AuthServiceProtocol {
        if FeatureFlags.useNewAuthService {
            return AuthServiceAdapter()
        } else {
            return AuthServiceWrapper(service: SocialService())
        }
    }
    
    func imageCache() -> ImageCacheProtocol {
        if FeatureFlags.useNewImageCache {
            return ImageCacheAdapter()
        } else {
            return ImageCacheStub()
        }
    }
    
    func golfCourseService() -> GolfCourseServiceProtocol {
        if FeatureFlags.useNewGolfCourseService {
            return GolfCourseServiceAdapter()
        } else {
            return GolfCourseServiceStub()
        }
    }
    
    func scoreVerificationService() -> ScoreVerificationServiceProtocol {
        if FeatureFlags.useNewScoreVerification {
            return ScoreVerificationServiceAdapter()
        } else {
            return ScoreVerificationServiceStub()
        }
    }
    
    @MainActor
    func tournamentService() -> any TournamentServiceProtocol {
        if FeatureFlags.useNewTournamentService {
            return TournamentServiceAdapter()
        } else {
            return TournamentServiceStub()
        }
    }
    
    // MARK: - Reset for Testing
    func reset() {
        // Services are created on-demand now, no need to reset lazy properties
        // This method is kept for API compatibility but does nothing
    }
}

// MARK: - Stub Implementations for Fallback
class ImageCacheStub: ImageCacheProtocol {
    func cacheImage(_ image: UIImage, for url: String) async {
        // No-op stub
    }
    
    func cachedImage(for url: String) async -> UIImage? {
        return nil
    }
    
    func clearCache() async {
        // No-op stub
    }
}

class GolfCourseServiceStub: GolfCourseServiceProtocol {
    func searchCourses(query: String) async -> [GolfCourse] {
        return []
    }
    
    func getCourseDetails(courseId: String) async -> GolfCourse? {
        return nil
    }
    
    func getNearbyGolfCourses(latitude: Double, longitude: Double, radius: Double) async -> [GolfCourse] {
        return []
    }
}

class ScoreVerificationServiceStub: ScoreVerificationServiceProtocol {
    func verifyScore(image: UIImage) async -> String? {
        return nil
    }
    
    func processScorecard(image: UIImage) async -> [Int] {
        return []
    }
}

@MainActor
class TournamentServiceStub: TournamentServiceProtocol, ObservableObject {
    @Published var tournaments: [Tournament] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    func loadTournaments() async {
        // No-op stub
    }
    
    func createTournament(_ tournament: Tournament) async {
        // No-op stub
    }
    
    func joinTournament(_ tournamentId: String) async {
        // No-op stub
    }
    
    func leaveTournament(_ tournamentId: String) async {
        // No-op stub
    }
}

// MARK: - SwiftUI Environment Key
struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue = ServiceContainer.shared
}

extension EnvironmentValues {
    var serviceContainer: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
} 