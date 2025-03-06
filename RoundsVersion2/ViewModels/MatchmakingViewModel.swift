import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class MatchmakingViewModel: ObservableObject {
    @Published var matchState: MatchState = .searching
    @Published var opponent: UserProfile?
    @Published var shouldNavigateToMatch = false
    @Published var errorMessage: String?
    
    private var matchListener: ListenerRegistration?
    private var searchListener: ListenerRegistration?
    private var currentUserId: String?
    private var matchId: String?
    
    // ELO matching range (starts small and expands)
    private var eloRangeExpansion = 50
    private let maxEloRange = 400
    private let expansionInterval: TimeInterval = 5
    private var expansionTimer: Timer?
    
    var minElo: Int {
        guard let userElo = UserDefaults.standard.value(forKey: "userElo") as? Int else { return 1150 }
        return max(userElo - eloRangeExpansion, 0)
    }
    
    var maxElo: Int {
        guard let userElo = UserDefaults.standard.value(forKey: "userElo") as? Int else { return 1250 }
        return userElo + eloRangeExpansion
    }
    
    enum MatchState {
        case searching
        case found
        case accepted
    }
    
    func startMatchmaking() {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "Not logged in"
            return
        }
        
        currentUserId = currentUser.uid
        createMatchmakingDocument()
        startSearching()
        startEloRangeExpansion()
    }
    
    private func createMatchmakingDocument() {
        guard let userId = currentUserId else { return }
        
        Task {
            do {
                let db = Firestore.firestore()
                let userElo = UserDefaults.standard.value(forKey: "userElo") as? Int ?? 1200
                
                try await db.collection("matchmaking").document(userId).setData([
                    "userId": userId,
                    "elo": userElo,
                    "status": "searching",
                    "timestamp": FieldValue.serverTimestamp(),
                    "minEloMatch": minElo,
                    "maxEloMatch": maxElo
                ])
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func startSearching() {
        guard let userId = currentUserId else { return }
        let db = Firestore.firestore()
        
        searchListener = db.collection("matchmaking")
            .whereField("status", isEqualTo: "searching")
            .whereField("userId", isNotEqualTo: userId)
            .whereField("elo", isGreaterThanOrEqualTo: minElo)
            .whereField("elo", isLessThanOrEqualTo: maxElo)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else {
                    self?.errorMessage = error?.localizedDescription
                    return
                }
                
                // Find the first available opponent
                if let opponentDoc = documents.first {
                    self.createMatch(withOpponent: opponentDoc.documentID)
                }
            }
    }
    
    private func createMatch(withOpponent opponentId: String) {
        guard let userId = currentUserId else { return }
        let db = Firestore.firestore()
        
        Task {
            do {
                let matchRef = db.collection("matches").document()
                self.matchId = matchRef.documentID
                
                try await matchRef.setData([
                    "players": [userId, opponentId],
                    "status": "pending",
                    "timestamp": FieldValue.serverTimestamp()
                ])
                
                // Update both players' matchmaking status
                try await db.collection("matchmaking").document(userId).updateData([
                    "status": "matched",
                    "matchId": matchRef.documentID
                ])
                
                try await db.collection("matchmaking").document(opponentId).updateData([
                    "status": "matched",
                    "matchId": matchRef.documentID
                ])
                
                // Fetch opponent profile
                let opponentDoc = try await db.collection("users").document(opponentId).getDocument()
                if let data = opponentDoc.data() {
                    self.opponent = UserProfile(
                        id: opponentId,
                        fullName: data["fullName"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        elo: data["elo"] as? Int ?? 1200,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                    self.matchState = .found
                }
                
                // Start listening for match updates
                self.listenToMatch()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func listenToMatch() {
        guard let matchId = matchId else { return }
        let db = Firestore.firestore()
        
        matchListener = db.collection("matches").document(matchId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let data = snapshot?.data() else {
                    self?.errorMessage = error?.localizedDescription
                    return
                }
                
                if data["status"] as? String == "active" {
                    self?.shouldNavigateToMatch = true
                }
            }
    }
    
    private func startEloRangeExpansion() {
        expansionTimer = Timer.scheduledTimer(withTimeInterval: expansionInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.eloRangeExpansion < self.maxEloRange {
                self.eloRangeExpansion += 50
                self.updateEloRange()
            }
        }
    }
    
    private func updateEloRange() {
        guard let userId = currentUserId else { return }
        let db = Firestore.firestore()
        
        Task {
            try? await db.collection("matchmaking").document(userId).updateData([
                "minEloMatch": minElo,
                "maxEloMatch": maxElo
            ])
        }
    }
    
    func acceptMatch() {
        guard let matchId = matchId else { return }
        let db = Firestore.firestore()
        
        Task {
            do {
                try await db.collection("matches").document(matchId).updateData([
                    "status": "active"
                ])
                matchState = .accepted
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func cancelMatchmaking() {
        guard let userId = currentUserId else { return }
        let db = Firestore.firestore()
        
        Task {
            do {
                try await db.collection("matchmaking").document(userId).delete()
                if let matchId = matchId {
                    try await db.collection("matches").document(matchId).updateData([
                        "status": "cancelled"
                    ])
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        
        cleanup()
    }
    
    private func cleanup() {
        searchListener?.remove()
        matchListener?.remove()
        expansionTimer?.invalidate()
        expansionTimer = nil
    }
    
    deinit {
        cleanup()
    }
} 