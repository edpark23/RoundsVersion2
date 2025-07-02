import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class MatchStateManager: ObservableObject {
    // MARK: - Published Properties
    @Published var matchStatus: MatchStatus = .pending
    @Published var players: [UserProfile] = []
    @Published var currentUserId: String = ""
    @Published var opponentId: String = ""
    @Published var matchStartTime: Date?
    @Published var isMatchComplete: Bool = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    // MARK: - Private Properties
    private let matchId: String
    private let db = Firestore.firestore()
    private var matchListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(matchId: String) {
        self.matchId = matchId
        self.currentUserId = Auth.auth().currentUser?.uid ?? ""
        initializeMatch()
    }
    
    deinit {
        Task { @MainActor in
            cleanup()
        }
    }
    
    // MARK: - Public Interface
    
    /// Initialize match and load player data
    func initializeMatch() {
        Task {
            await loadMatchMetadata()
            await loadPlayerProfiles()
            setupMatchListener()
        }
    }
    
    /// Start the match (updates status to active)
    func startMatch() async {
        do {
            try await db.collection("matches").document(matchId).updateData([
                "status": MatchStatus.active.rawValue,
                "startTime": FieldValue.serverTimestamp()
            ])
        } catch {
            print("Error starting match: \(error)")
        }
    }
    
    /// Complete the match with final results
    func completeMatch(playerFinalScore: Int, opponentFinalScore: Int) async {
        let winnerId = playerFinalScore <= opponentFinalScore ? currentUserId : opponentId
        
        do {
            try await db.collection("matches").document(matchId).updateData([
                "status": MatchStatus.completed.rawValue,
                "completedAt": FieldValue.serverTimestamp(),
                "finalScores": [
                    currentUserId: playerFinalScore,
                    opponentId: opponentFinalScore
                ],
                "winnerId": winnerId
            ])
            
            isMatchComplete = true
        } catch {
            print("Error completing match: \(error)")
        }
    }
    
    /// Get current player profile
    func getCurrentPlayer() -> UserProfile? {
        return players.first { $0.id == currentUserId }
    }
    
    /// Get opponent profile
    func getOpponent() -> UserProfile? {
        return players.first { $0.id == opponentId }
    }
    
    // MARK: - Private Implementation
    
    private func loadMatchMetadata() async {
        do {
            let snapshot = try await db.collection("matches").document(matchId).getDocument()
            guard let data = snapshot.data() else { return }
            
            // Extract match status
            if let statusString = data["status"] as? String,
               let status = MatchStatus(rawValue: statusString) {
                matchStatus = status
            }
            
            // Extract start time
            if let startTimestamp = data["startTime"] as? Timestamp {
                matchStartTime = startTimestamp.dateValue()
            }
            
            // Extract player IDs
            if let playerIds = data["players"] as? [String] {
                opponentId = playerIds.first { $0 != currentUserId } ?? ""
            }
            
            connectionStatus = .connected
            
        } catch {
            print("Error loading match metadata: \(error)")
            connectionStatus = .error
        }
    }
    
    private func loadPlayerProfiles() async {
        var loadedPlayers: [UserProfile] = []
        
        // Load current user
        if let currentUser = await loadUserProfile(userId: currentUserId) {
            loadedPlayers.append(currentUser)
        }
        
        // Load opponent
        if !opponentId.isEmpty,
           let opponent = await loadUserProfile(userId: opponentId) {
            loadedPlayers.append(opponent)
        }
        
        players = loadedPlayers
    }
    
    private func loadUserProfile(userId: String) async -> UserProfile? {
        do {
            let snapshot = try await db.collection("users").document(userId).getDocument()
            guard let data = snapshot.data() else { return nil }
            
            return UserProfile(
                id: userId,
                fullName: data["fullName"] as? String ?? "",
                email: data["email"] as? String ?? "",
                elo: data["elo"] as? Int ?? 1200,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                isAdmin: data["isAdmin"] as? Bool ?? false,
                profilePictureURL: data["profilePictureURL"] as? String
            )
        } catch {
            print("Error loading user profile for \(userId): \(error)")
            return nil
        }
    }
    
    private func setupMatchListener() {
        matchListener = db.collection("matches").document(matchId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Match listener error: \(error)")
                    self.connectionStatus = .error
                    return
                }
                
                guard let data = snapshot?.data() else { return }
                
                Task { @MainActor in
                    self.processMatchUpdate(data)
                }
            }
    }
    
    private func processMatchUpdate(_ data: [String: Any]) {
        // Update match status
        if let statusString = data["status"] as? String,
           let status = MatchStatus(rawValue: statusString) {
            matchStatus = status
            
            if status == .completed {
                isMatchComplete = true
            }
        }
        
        // Update start time if available
        if let startTimestamp = data["startTime"] as? Timestamp {
            matchStartTime = startTimestamp.dateValue()
        }
        
        connectionStatus = .connected
    }
    
    private func cleanup() {
        matchListener?.remove()
        cancellables.removeAll()
    }
}

// MARK: - Supporting Types
enum MatchStatus: String, CaseIterable {
    case pending = "pending"
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"
}

enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
    case error
} 