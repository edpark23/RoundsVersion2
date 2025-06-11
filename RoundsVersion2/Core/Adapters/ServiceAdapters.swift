import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import UIKit

// MARK: - Adapter to make existing SocialService conform to protocol
@MainActor
class SocialServiceWrapper: SocialServiceProtocol, ObservableObject {
    private let service: SocialService
    
    @Published var friends: [FriendUser] = []
    @Published var pendingRequests: [Friendship] = []
    @Published var sentRequests: [Friendship] = []
    @Published var chatRooms: [ChatRoom] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    
    init(service: SocialService) {
        self.service = service
    }
    
    func searchUsers(query: String) async -> [FriendUser] {
        // Bridge existing service
        return []
    }
    
    func sendFriendRequest(to userId: String) async {
        // Bridge existing service
    }
    
    func acceptFriendRequest(from userId: String) async {
        // Bridge existing service
    }
    
    func getFriendsList() async -> [FriendUser] {
        return []
    }
    
    func getIncomingFriendRequests() async -> [FriendRequest] {
        return []
    }
    
    func getOutgoingFriendRequests() async -> [FriendRequest] {
        return []
    }
    
    func declineFriendRequest(friendshipId: String) async throws {
        // Bridge existing service
    }
    
    func blockUser(friendshipId: String) async throws {
        // Bridge existing service
    }
    
    func createDirectChat(with friendId: String) async throws -> ChatRoom {
        // Mock implementation
        return ChatRoom(type: .direct, participantIds: [friendId], createdBy: "")
    }
    
    func createGroupChat(name: String, participantIds: [String]) async throws -> ChatRoom {
        // Mock implementation
        return ChatRoom(type: .group, name: name, participantIds: participantIds, createdBy: "")
    }
    
    func sendMessage(to chatRoomId: String, text: String) async throws {
        // Bridge existing service
    }
    
    func getMessages(for chatRoomId: String) -> AnyPublisher<[SocialChatMessage], Error> {
        // Mock implementation
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

// MARK: - Adapter to make existing AuthService conform to protocol  
@MainActor
class AuthServiceWrapper: AuthServiceProtocol, ObservableObject {
    
    @Published var currentUser: User? = nil
    @Published var userProfile: UserProfile? = nil
    @Published var isLoadingProfile: Bool = false
    @Published var errorMessage: String? = nil
    
    init(service: SocialService) {
        // Stub implementation - no actual AuthService exists
    }
    
    func uploadProfilePicture(_ image: UIImage) async {
        isLoadingProfile = true
        // Simulate upload
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2s
        isLoadingProfile = false
    }
    
    func updateProfile(_ profile: UserProfile) async {
        isLoadingProfile = true
        // Simulate update
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
        userProfile = profile
        isLoadingProfile = false
    }
    
    func signOut() {
        currentUser = nil
        userProfile = nil
        errorMessage = nil
    }
}

// MARK: - MainViewModel Adapter for AuthServiceProtocol
@MainActor
class MainViewModelAdapter: ObservableObject, AuthServiceProtocol {
    @Published var currentUser: User?
    @Published var userProfile: UserProfile?
    @Published var isLoadingProfile: Bool = false
    @Published var errorMessage: String?
    
    private let mainViewModel = MainViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Bridge published properties
        mainViewModel.$currentUser
            .assign(to: &$currentUser)
        
        mainViewModel.$userProfile
            .assign(to: &$userProfile)
        
        mainViewModel.$isLoadingProfile
            .assign(to: &$isLoadingProfile)
        
        mainViewModel.$errorMessage
            .assign(to: &$errorMessage)
    }
    
    func uploadProfilePicture(_ image: UIImage) async {
        await mainViewModel.uploadProfilePicture(image: image)
    }
    
    func updateProfile(_ profile: UserProfile) async {
        // MainViewModel doesn't have updateProfile method, so simulate it
        isLoadingProfile = true
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s simulation
        userProfile = profile
        isLoadingProfile = false
    }
    
    func signOut() {
        mainViewModel.signOut()
    }
}

// MARK: - No-Op Image Cache (for when feature flag is off)
class NoOpImageCache: ImageCacheProtocol {
    func cachedImage(for url: String) async -> UIImage? {
        // Passthrough - use existing image loading logic
        return nil
    }
    
    func cacheImage(_ image: UIImage, for url: String) async {
        // No-op when feature flag is disabled
    }
    
    func clearCache() {
        // No-op
    }
}

// MARK: - Image Cache Service (Optimized Implementation)
class ImageCacheService: ImageCacheProtocol {
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCacheURL: URL
    private let queue = DispatchQueue(label: "image-cache", qos: .utility)
    
    init() {
        // Setup disk cache
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = cacheDir.appendingPathComponent("ImageCache")
        
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        
        // Configure memory cache
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    func cachedImage(for url: String) async -> UIImage? {
        let key = NSString(string: url)
        
        // Check memory cache first
        if let image = memoryCache.object(forKey: key) {
            return image
        }
        
        // Check disk cache
        let fileName = url.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        let fileURL = diskCacheURL.appendingPathComponent(fileName)
        
        if let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            // Store in memory cache
            memoryCache.setObject(image, forKey: key)
            return image
        }
        
        // Download and cache
        return await downloadAndCache(url: url)
    }
    
    func cacheImage(_ image: UIImage, for url: String) async {
        let key = NSString(string: url)
        
        // Store in memory
        memoryCache.setObject(image, forKey: key)
        
        // Store on disk
        if let data = image.jpegData(compressionQuality: 0.8) {
            let fileName = url.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
            let fileURL = diskCacheURL.appendingPathComponent(fileName)
            
            try? data.write(to: fileURL)
        }
    }
    
    func clearCache() {
        memoryCache.removeAllObjects()
        
        try? FileManager.default.removeItem(at: diskCacheURL)
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }
    
    private func downloadAndCache(url: String) async -> UIImage? {
        guard let imageURL = URL(string: url) else { return nil }
        
        do {
            let request = URLRequest(url: imageURL, cachePolicy: .returnCacheDataElseLoad)
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let image = UIImage(data: data) {
                await cacheImage(image, for: url)
                return image
            }
        } catch {
            print("Failed to download image: \(error)")
        }
        
        return nil
    }
}

// MARK: - Service Adapters with proper MainActor isolation

@MainActor
class AuthServiceAdapter: AuthServiceProtocol, ObservableObject {
    
    @Published var currentUser: User? = nil
    @Published var userProfile: UserProfile? = nil
    @Published var isLoadingProfile: Bool = false
    @Published var errorMessage: String? = nil
    
    func uploadProfilePicture(_ image: UIImage) async {
        isLoadingProfile = true
        // Simulate upload
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2s
        isLoadingProfile = false
    }
    
    func updateProfile(_ profile: UserProfile) async {
        isLoadingProfile = true
        // Simulate update
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
        userProfile = profile
        isLoadingProfile = false
    }
    
    func signOut() {
        currentUser = nil
        userProfile = nil
        errorMessage = nil
    }
}

// MARK: - Social Service Adapter
@MainActor
class SocialServiceAdapter: SocialServiceProtocol, ObservableObject {
    
    @Published var friends: [FriendUser] = []
    @Published var pendingRequests: [Friendship] = []
    @Published var sentRequests: [Friendship] = []
    @Published var chatRooms: [ChatRoom] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    
    func searchUsers(query: String) async -> [FriendUser] {
        // Simulate API call
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        return []
    }
    
    func sendFriendRequest(to userId: String) async {
        // Simulate API call
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
    }
    
    func acceptFriendRequest(from userId: String) async {
        // Simulate API call
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
    }
    
    func getFriendsList() async -> [FriendUser] {
        // Simulate API call
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        return []
    }
    
    func getIncomingFriendRequests() async -> [FriendRequest] {
        // Simulate API call
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        return []
    }
    
    func getOutgoingFriendRequests() async -> [FriendRequest] {
        // Simulate API call
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        return []
    }
    
    func declineFriendRequest(friendshipId: String) async throws {
        // Simulate API call
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
    }
    
    func blockUser(friendshipId: String) async throws {
        // Simulate API call
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
    }
    
    func createDirectChat(with friendId: String) async throws -> ChatRoom {
        // Mock implementation
        return ChatRoom(type: .direct, participantIds: [friendId], createdBy: "")
    }
    
    func createGroupChat(name: String, participantIds: [String]) async throws -> ChatRoom {
        // Mock implementation
        return ChatRoom(type: .group, name: name, participantIds: participantIds, createdBy: "")
    }
    
    func sendMessage(to chatRoomId: String, text: String) async throws {
        // Simulate API call
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    func getMessages(for chatRoomId: String) -> AnyPublisher<[SocialChatMessage], Error> {
        // Mock implementation
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

// MARK: - Image Cache Adapter
class ImageCacheAdapter: ImageCacheProtocol {
    private var cache: [String: UIImage] = [:]
    
    func cacheImage(_ image: UIImage, for url: String) async {
        cache[url] = image
    }
    
    func cachedImage(for url: String) async -> UIImage? {
        return cache[url]
    }
    
    func clearCache() async {
        cache.removeAll()
    }
}

// MARK: - Golf Course Service Adapter
class GolfCourseServiceAdapter: GolfCourseServiceProtocol {
    
    func searchCourses(query: String) async -> [GolfCourse] {
        // Simulate API call
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        return []
    }
    
    func getCourseDetails(courseId: String) async -> GolfCourse? {
        // Simulate API call
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        return nil
    }
    
    func getNearbyGolfCourses(latitude: Double, longitude: Double, radius: Double) async -> [GolfCourse] {
        // Simulate API call
        try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        return []
    }
}

// MARK: - Score Verification Service Adapter
class ScoreVerificationServiceAdapter: ScoreVerificationServiceProtocol {
    
    func verifyScore(image: UIImage) async -> String? {
        // Simulate OCR processing
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        return "4" // Simulated score
    }
    
    func processScorecard(image: UIImage) async -> [Int] {
        // Simulate scorecard processing
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        return Array(1...18).map { _ in Int.random(in: 3...7) } // Random scores
    }
}

// MARK: - Tournament Service Adapter
@MainActor
class TournamentServiceAdapter: TournamentServiceProtocol, ObservableObject {
    
    @Published var tournaments: [Tournament] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    func loadTournaments() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
        tournaments = [] // Mock tournaments
        isLoading = false
    }
    
    func createTournament(_ tournament: Tournament) async {
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        tournaments.append(tournament)
    }
    
    func joinTournament(_ tournamentId: String) async {
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
    }
    
    func leaveTournament(_ tournamentId: String) async {
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
    }
} 