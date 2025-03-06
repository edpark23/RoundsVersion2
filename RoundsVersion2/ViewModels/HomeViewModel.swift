import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class HomeViewModel: ObservableObject {
    @Published var recentMatches: [Match] = []
    @Published var errorMessage: String?
    
    init() {
        fetchRecentMatches()
    }
    
    func fetchRecentMatches() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        Task {
            do {
                let matchesQuery = db.collection("matches")
                    .whereField("players", arrayContains: userId)
                    .whereField("status", isEqualTo: "completed")
                    .order(by: "completedAt", descending: true)
                    .limit(to: 10)
                
                let snapshot = try await matchesQuery.getDocuments()
                
                var matches: [Match] = []
                for document in snapshot.documents {
                    let data = document.data()
                    
                    // Get opponent's profile
                    let players = data["players"] as? [String] ?? []
                    let opponentId = players.first { $0 != userId } ?? ""
                    
                    let opponentDoc = try await db.collection("users").document(opponentId).getDocument()
                    let opponentData = opponentDoc.data() ?? [:]
                    let opponentName = opponentData["fullName"] as? String ?? "Unknown"
                    
                    // Determine if current user won and their ELO change
                    let winnerId = data["winner"] as? String ?? ""
                    let result = winnerId == userId ? "Won" : "Lost"
                    let eloChange = winnerId == userId ? 
                        (data["winnerEloChange"] as? Int ?? 0) : 
                        (data["loserEloChange"] as? Int ?? 0)
                    
                    let match = Match(
                        id: document.documentID,
                        opponentName: opponentName,
                        date: (data["completedAt"] as? Timestamp)?.dateValue() ?? Date(),
                        result: result,
                        eloChange: eloChange
                    )
                    matches.append(match)
                }
                
                self.recentMatches = matches
                
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func startNewMatch() {
        // TODO: Implement starting a new match
    }
} 