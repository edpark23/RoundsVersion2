import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class MatchViewModel: ObservableObject {
    let matchId: String
    let opponent: UserProfile
    
    @Published var messages: [ChatMessage] = []
    @Published var messageText = ""
    @Published var errorMessage: String?
    @Published var currentUserProfile: UserProfile?
    @Published var matchStatus: MatchStatus = .inProgress
    
    private var messagesListener: ListenerRegistration?
    
    enum MatchStatus {
        case inProgress
        case completed(winner: String, loser: String)
        case cancelled
    }
    
    init(matchId: String, opponent: UserProfile) {
        self.matchId = matchId
        self.opponent = opponent
        setupMessagesListener()
        fetchCurrentUserProfile()
    }
    
    private func fetchCurrentUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        Task {
            do {
                let doc = try await db.collection("users").document(userId).getDocument()
                if let data = doc.data() {
                    self.currentUserProfile = UserProfile(
                        id: userId,
                        fullName: data["fullName"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        elo: data["elo"] as? Int ?? EloCalculator.initialElo,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func setupMessagesListener() {
        let db = Firestore.firestore()
        
        messagesListener = db.collection("matches")
            .document(matchId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    self?.errorMessage = error?.localizedDescription
                    return
                }
                
                self?.messages = documents.compactMap { ChatMessage(document: $0) }
            }
    }
    
    func sendMessage() {
        guard !messageText.isEmpty,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let messageRef = db.collection("matches")
            .document(matchId)
            .collection("messages")
            .document()
        
        Task {
            do {
                try await messageRef.setData([
                    "senderId": userId,
                    "text": messageText,
                    "timestamp": FieldValue.serverTimestamp()
                ])
                
                messageText = ""
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func completeMatch(currentPlayerWon: Bool) async {
        guard let currentUser = currentUserProfile else {
            errorMessage = "Current user profile not loaded"
            return
        }
        
        let db = Firestore.firestore()
        
        do {
            // Calculate new ELO ratings
            let (winnerNewElo, loserNewElo) = EloCalculator.updateRatings(
                player1Rating: currentUser.elo,
                player2Rating: opponent.elo,
                player1Result: currentPlayerWon ? .win : .loss
            )
            
            // Determine winner and loser
            let (winnerId, loserId) = currentPlayerWon ? 
                (currentUser.id, opponent.id) : 
                (opponent.id, currentUser.id)
            
            // Create immutable dictionaries for Firestore updates
            let matchUpdateData: [String: Any] = [
                "status": "completed",
                "winner": winnerId,
                "loser": loserId,
                "completedAt": FieldValue.serverTimestamp(),
                "winnerEloChange": currentPlayerWon ? (winnerNewElo - currentUser.elo) : (winnerNewElo - opponent.elo),
                "loserEloChange": currentPlayerWon ? (loserNewElo - opponent.elo) : (loserNewElo - currentUser.elo)
            ]
            
            let winnerUpdateData: [String: Any] = [
                "elo": winnerNewElo
            ]
            
            let loserUpdateData: [String: Any] = [
                "elo": loserNewElo
            ]
            
            // Update match document with results
            try await db.collection("matches").document(matchId).updateData(matchUpdateData)
            
            // Update winner's ELO
            try await db.collection("users").document(winnerId).updateData(winnerUpdateData)
            
            // Update loser's ELO
            try await db.collection("users").document(loserId).updateData(loserUpdateData)
            
            // Update local state
            matchStatus = .completed(winner: winnerId, loser: loserId)
            
        } catch {
            errorMessage = "Failed to complete match: \(error.localizedDescription)"
        }
    }
    
    func cancelMatch() async {
        let db = Firestore.firestore()
        
        do {
            let cancelUpdateData: [String: Any] = [
                "status": "cancelled",
                "cancelledAt": FieldValue.serverTimestamp()
            ]
            
            try await db.collection("matches").document(matchId).updateData(cancelUpdateData)
            
            matchStatus = .cancelled
            
        } catch {
            errorMessage = "Failed to cancel match: \(error.localizedDescription)"
        }
    }
    
    deinit {
        messagesListener?.remove()
    }
} 