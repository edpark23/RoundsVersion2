import Foundation
import FirebaseFirestore

@MainActor
class HomeViewModel: ObservableObject {
    @Published var recentMatches: [Match] = []
    @Published var errorMessage: String?
    
    init() {
        fetchRecentMatches()
    }
    
    func fetchRecentMatches() {
        // TODO: Implement fetching matches from Firestore
        // For now, using sample data
        recentMatches = [
            Match(id: "1", opponentName: "John Doe", date: Date(), result: "Won", eloChange: 15),
            Match(id: "2", opponentName: "Jane Smith", date: Date().addingTimeInterval(-86400), result: "Lost", eloChange: -10)
        ]
    }
    
    func startNewMatch() {
        // TODO: Implement starting a new match
    }
} 