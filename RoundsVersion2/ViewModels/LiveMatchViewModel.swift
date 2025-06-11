import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class LiveMatchViewModel: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var scores: [String: [Int?]] = [:]
    @Published var isLiveUpdateActive = true
    @Published var matchStartTime = Date()
    @Published var formattedMatchTime = "00:00"
    @Published var isMatchCompleted = false
    
    private let matchId: String
    private let db = Firestore.firestore()
    private var matchTimer: Timer?
    @Published private var rankingViewModel = RankingViewModel()
    
    init(matchId: String) {
        self.matchId = matchId
    }
    
    func startLiveMatch() async {
        // Load current user
        await loadCurrentUser()
        
        // Start match timer
        startMatchTimer()
        
        // Set up real-time listeners
        setupRealTimeListeners()
    }
    
    func enterScore(hole: Int, score: Int) {
        // Update local scores
        guard let userId = currentUser?.id else { return }
        
        if scores[userId] == nil {
            scores[userId] = Array(repeating: nil, count: 18)
        }
        
        scores[userId]?[hole - 1] = score
        
        // Update Firebase
        Task {
            await updateScoreInFirebase(hole: hole, score: score)
        }
    }
    
    func processScorecard(image: UIImage) {
        // Placeholder for scorecard processing
        print("Processing scorecard image")
    }
    
    func refreshMatchData() async {
        // Refresh match data
        await loadMatchScores()
    }
    
    func getCurrentUserTotal() -> Int {
        guard let userId = currentUser?.id,
              let userScores = scores[userId] else { return 0 }
        
        return userScores.compactMap { $0 }.reduce(0, +)
    }
    
    func getOpponentTotal() -> Int {
        // Find opponent scores
        let opponentScores = scores.first { $0.key != currentUser?.id }?.value
        return opponentScores?.compactMap { $0 }.reduce(0, +) ?? 0
    }
    
    func isCurrentUserLeading() -> Bool {
        return getCurrentUserTotal() <= getOpponentTotal()
    }
    
    func getCurrentHoleScore(hole: Int) -> String? {
        guard let userId = currentUser?.id,
              let userScores = scores[userId],
              hole <= userScores.count,
              let score = userScores[hole - 1] else { return nil }
        
        return "\(score)"
    }
    
    private func loadCurrentUser() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if let data = document.data() {
                currentUser = UserProfile(
                    id: userId,
                    fullName: data["fullName"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    elo: data["elo"] as? Int ?? 1200,
                    createdAt: Date(),
                    isAdmin: data["isAdmin"] as? Bool ?? false,
                    profilePictureURL: data["profilePictureURL"] as? String
                )
            }
        } catch {
            print("Error loading current user: \(error)")
        }
    }
    
    private func loadMatchScores() async {
        // Load scores from Firebase
        do {
            let document = try await db.collection("matches").document(matchId).getDocument()
            if let data = document.data(),
               let scoresData = data["scores"] as? [String: [Int?]] {
                scores = scoresData
            }
        } catch {
            print("Error loading match scores: \(error)")
        }
    }
    
    private func updateScoreInFirebase(hole: Int, score: Int) async {
        guard let userId = currentUser?.id else { return }
        
        do {
            try await db.collection("matches").document(matchId).updateData([
                "scores.\(userId)": FieldValue.arrayUnion([score])
            ])
        } catch {
            print("Error updating score: \(error)")
        }
    }
    
    private func startMatchTimer() {
        matchTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                let elapsed = Date().timeIntervalSince(self.matchStartTime)
                let minutes = Int(elapsed) / 60
                let seconds = Int(elapsed) % 60
                
                self.formattedMatchTime = String(format: "%02d:%02d", minutes, seconds)
            }
        }
    }
    
    private func setupRealTimeListeners() {
        // Set up real-time listeners for live updates
        db.collection("matches").document(matchId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening to match updates: \(error)")
                    return
                }
                
                guard let document = documentSnapshot,
                      let data = document.data() else { return }
                
                DispatchQueue.main.async {
                    if let scoresData = data["scores"] as? [String: [Int?]] {
                        self.scores = scoresData
                    }
                }
            }
    }
    
    func completeMatch() async {
        guard let currentUserId = currentUser?.id,
              let currentUserScores = scores[currentUserId],
              let opponentEntry = scores.first(where: { $0.key != currentUserId }) else {
            print("Cannot complete match - missing data")
            return
        }
        
        let opponentScores = opponentEntry.value
        let currentUserTotal = currentUserScores.compactMap { $0 }.reduce(0, +)
        let opponentTotal = opponentScores.compactMap { $0 }.reduce(0, +)
        let opponentId = opponentEntry.key
        
        // Get opponent ELO from Firestore
        do {
            let opponentDoc = try await db.collection("users").document(opponentId).getDocument()
            let opponentElo = opponentDoc.data()?["elo"] as? Int ?? 1200
            
            // Process ELO ranking
            rankingViewModel.processMatchResult(
                opponentId: opponentId,
                opponentElo: opponentElo,
                playerScore: currentUserTotal,
                opponentScore: opponentTotal
            )
            
            // Update match status in Firestore
            try await db.collection("matches").document(matchId).updateData([
                "status": "completed",
                "completedAt": FieldValue.serverTimestamp(),
                "finalScores": [
                    currentUserId: currentUserTotal,
                    opponentId: opponentTotal
                ],
                "winnerId": currentUserTotal <= opponentTotal ? currentUserId : opponentId
            ])
            
            isMatchCompleted = true
            print("Match completed successfully with ELO processing")
            
        } catch {
            print("Error completing match: \(error)")
        }
    }
    
    func getMatchResult() -> (playerWon: Bool, strokeDifference: Int)? {
        guard let currentUserId = currentUser?.id,
              let currentUserScores = scores[currentUserId],
              let opponentEntry = scores.first(where: { $0.key != currentUserId }) else {
            return nil
        }
        
        let opponentScores = opponentEntry.value
        let currentUserTotal = currentUserScores.compactMap { $0 }.reduce(0, +)
        let opponentTotal = opponentScores.compactMap { $0 }.reduce(0, +)
        
        return (
            playerWon: currentUserTotal <= opponentTotal,
            strokeDifference: abs(currentUserTotal - opponentTotal)
        )
    }
    
    deinit {
        matchTimer?.invalidate()
    }
} 