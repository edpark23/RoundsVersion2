import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class LiveMatchScoreViewModel: ObservableObject {
    @Published var playerScores: [Int?] = Array(repeating: nil, count: 18)
    @Published var opponentScores: [Int?] = Array(repeating: nil, count: 18)
    @Published var currentUserId: String = ""
    @Published var isConnected: Bool = false
    
    private let db = Firestore.firestore()
    private var scoreListener: ListenerRegistration?
    private let matchId: String
    
    init(matchId: String) {
        self.matchId = matchId
        self.currentUserId = Auth.auth().currentUser?.uid ?? ""
        resetScores() // Reset scores for new match
        
        // Defer real-time sync to prevent Firebase cascade
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s delay
            await MainActor.run {
                setupRealtimeScoreSync()
            }
        }
    }
    
    deinit {
        scoreListener?.remove()
    }
    
    // MARK: - Score Reset
    func resetScores() {
        playerScores = Array(repeating: nil, count: 18)
        opponentScores = Array(repeating: nil, count: 18)
        
        // Defer Firebase clearing to prevent cascade during initialization
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2s delay
            await clearFirebaseScores()
        }
    }
    
    private func clearFirebaseScores() async {
        // Clear current user's scores
        do {
            try await db.collection("matches").document(matchId)
                .collection("scores").document(currentUserId)
                .delete()
        } catch {
            print("Error clearing user scores: \(error)")
        }
        
        // Note: We don't clear opponent's scores as they should manage their own
    }
    
    // MARK: - Real-time Score Syncing
    private func setupRealtimeScoreSync() {
        scoreListener = db.collection("matches").document(matchId)
            .collection("scores")
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self,
                      let documents = querySnapshot?.documents else {
                    print("Error fetching scores: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                Task { @MainActor in
                    self.isConnected = true
                    
                    for document in documents {
                        let data = document.data()
                        guard let playerId = data["playerId"] as? String,
                              let scores = data["scores"] as? [Int?],
                              scores.count == 18 else { continue }
                        
                        if playerId == self.currentUserId {
                            self.playerScores = scores
                        } else {
                            self.opponentScores = scores
                        }
                    }
                }
            }
    }
    
    // MARK: - Score Management
    func updateScore(hole: Int, score: Int, isCurrentUser: Bool = true) {
        guard hole > 0 && hole <= 18 else { return }
        
        let holeIndex = hole - 1
        
        if isCurrentUser {
            playerScores[holeIndex] = score
            syncScoreToFirebase(isCurrentUser: true)
        } else {
            // Only allow current user to update their own scores
            print("Cannot update opponent's score")
        }
    }
    
    func clearScore(hole: Int, isCurrentUser: Bool = true) {
        guard hole > 0 && hole <= 18 else { return }
        
        let holeIndex = hole - 1
        
        if isCurrentUser {
            playerScores[holeIndex] = nil
            syncScoreToFirebase(isCurrentUser: true)
        }
    }
    
    private func syncScoreToFirebase(isCurrentUser: Bool) {
        let scores = isCurrentUser ? playerScores : opponentScores
        let playerId = currentUserId // Only sync current user's scores
        
        let scoreData: [String: Any] = [
            "playerId": playerId,
            "scores": scores,
            "lastUpdated": FieldValue.serverTimestamp()
        ]
        
        db.collection("matches").document(matchId)
            .collection("scores").document(playerId)
            .setData(scoreData) { error in
                if let error = error {
                    print("Error syncing score: \(error)")
                }
            }
    }
    
    // MARK: - Score Calculations
    func getTotalScore(isCurrentUser: Bool) -> Int {
        let scores = isCurrentUser ? playerScores : opponentScores
        return scores.compactMap { $0 }.reduce(0, +)
    }
    
    func getTotalPar(isCurrentUser: Bool, getHolePar: (Int) -> Int) -> Int {
        let scores = isCurrentUser ? playerScores : opponentScores
        var totalPar = 0
        
        for (index, score) in scores.enumerated() {
            if score != nil {
                totalPar += getHolePar(index + 1)
            }
        }
        
        return totalPar
    }
    
    func getScoreToPar(isCurrentUser: Bool, getHolePar: (Int) -> Int) -> Int {
        let totalScore = getTotalScore(isCurrentUser: isCurrentUser)
        let totalPar = getTotalPar(isCurrentUser: isCurrentUser, getHolePar: getHolePar)
        return totalScore - totalPar
    }
} 