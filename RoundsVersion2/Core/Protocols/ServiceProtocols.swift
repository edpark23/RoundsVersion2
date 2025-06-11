import Foundation
import FirebaseFirestore
import FirebaseAuth
import UIKit
import Combine

// MARK: - Social Service Protocol
@MainActor
protocol SocialServiceProtocol: ObservableObject {
    var friends: [FriendUser] { get }
    var pendingRequests: [Friendship] { get }
    var sentRequests: [Friendship] { get }
    var chatRooms: [ChatRoom] { get }
    var isLoading: Bool { get }
    var error: String? { get }
    
    func searchUsers(query: String) async -> [FriendUser]
    func sendFriendRequest(to userId: String) async
    func acceptFriendRequest(from userId: String) async
    func getFriendsList() async -> [FriendUser]
    func getIncomingFriendRequests() async -> [FriendRequest]
    func getOutgoingFriendRequests() async -> [FriendRequest]
    func declineFriendRequest(friendshipId: String) async throws
    func blockUser(friendshipId: String) async throws
    func createDirectChat(with friendId: String) async throws -> ChatRoom
    func createGroupChat(name: String, participantIds: [String]) async throws -> ChatRoom
    func sendMessage(to chatRoomId: String, text: String) async throws
    func getMessages(for chatRoomId: String) -> AnyPublisher<[SocialChatMessage], Error>
}

// MARK: - Authentication Service Protocol
@MainActor
protocol AuthServiceProtocol: ObservableObject {
    var currentUser: User? { get }
    var userProfile: UserProfile? { get }
    var isLoadingProfile: Bool { get }
    var errorMessage: String? { get }
    
    func signOut()
    func uploadProfilePicture(_ image: UIImage) async
    func updateProfile(_ profile: UserProfile) async
}

// MARK: - Image Cache Protocol
protocol ImageCacheProtocol {
    func cacheImage(_ image: UIImage, for url: String) async
    func cachedImage(for url: String) async -> UIImage?
    func clearCache() async
}

// MARK: - Golf Course Service Protocol
protocol GolfCourseServiceProtocol {
    func searchCourses(query: String) async -> [GolfCourse]
    func getCourseDetails(courseId: String) async -> GolfCourse?
    func getNearbyGolfCourses(latitude: Double, longitude: Double, radius: Double) async -> [GolfCourse]
}

// MARK: - Score Verification Protocol
protocol ScoreVerificationProtocol: ObservableObject {
    var capturedImage: UIImage? { get set }
    var processedImage: UIImage? { get set }
    var isProcessing: Bool { get }
    var scores: [Int] { get }
    var error: String? { get }
    
    func processImage() async
}

// MARK: - Score Verification Service Protocol
protocol ScoreVerificationServiceProtocol {
    func verifyScore(image: UIImage) async -> String?
    func processScorecard(image: UIImage) async -> [Int]
}

// MARK: - Tournament Service Protocol
@MainActor
protocol TournamentServiceProtocol: ObservableObject {
    var tournaments: [Tournament] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    
    func loadTournaments() async
    func createTournament(_ tournament: Tournament) async
    func joinTournament(_ tournamentId: String) async
    func leaveTournament(_ tournamentId: String) async
} 