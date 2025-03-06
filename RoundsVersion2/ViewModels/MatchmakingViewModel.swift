import Foundation
import FirebaseFirestore
import FirebaseAuth

// Add ListenerManager class at the top of the file after imports
final class ListenerManager {
    private(set) var searchListener: ListenerRegistration?
    private(set) var matchListener: ListenerRegistration?
    private(set) var expansionTimer: Timer?
    
    func setSearchListener(_ listener: ListenerRegistration?) {
        searchListener = listener
    }
    
    func setMatchListener(_ listener: ListenerRegistration?) {
        matchListener = listener
    }
    
    func setExpansionTimer(_ timer: Timer?) {
        expansionTimer = timer
    }
    
    func cleanup() {
        searchListener?.remove()
        matchListener?.remove()
        expansionTimer?.invalidate()
        
        searchListener = nil
        matchListener = nil
        expansionTimer = nil
    }
}

@MainActor
class MatchmakingViewModel: ObservableObject {
    @Published var matchState: MatchState = .searching
    @Published var opponent: UserProfile?
    @Published var shouldNavigateToMatch = false
    @Published var errorMessage: String?
    @Published var matchId: String?
    
    private let listeners = ListenerManager()
    private var currentUserId: String?
    
    // ELO matching range (starts small and expands)
    private var eloRangeExpansion = 50
    private let maxEloRange = 400
    private let expansionInterval: TimeInterval = 5
    
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
            print("Cannot start matchmaking - User not logged in")
            return
        }
        
        print("Starting matchmaking process")
        currentUserId = currentUser.uid
        
        // Start searching immediately
        startSearching()
        startEloRangeExpansion()
    }
    
    private func createMatch(withOpponent opponentId: String) {
        guard let userId = currentUserId else { return }
        let db = Firestore.firestore()
        
        // Stop searching and expanding ELO range once we find a match
        listeners.searchListener?.remove()
        listeners.expansionTimer?.invalidate()
        
        Task {
            do {
                let matchRef = db.collection("matches").document()
                self.matchId = matchRef.documentID
                
                let matchData = MatchData(
                    players: [userId, opponentId],
                    status: "pending",
                    timestamp: FieldValue.serverTimestamp()
                )
                
                try await matchRef.setData(matchData.asDictionary)
                
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
    
    private func startSearching() {
        guard let userId = currentUserId else { return }
        let db = Firestore.firestore()
        
        print("Starting matchmaking search - User ID: \(userId)")
        print("Initial ELO Range: \(minElo) to \(maxElo)")
        
        // First, get all documents to see what's in the collection
        Task {
            do {
                let allDocs = try await db.collection("users").getDocuments()
                print("\n=== All users in database ===")
                allDocs.documents.forEach { doc in
                    let data = doc.data()
                    print("""
                        \nUser:
                        - User ID: \(doc.documentID)
                        - ELO: \(data["elo"] ?? "unknown")
                        """)
                }
            } catch {
                print("Error fetching all users: \(error.localizedDescription)")
            }
        }
        
        // Query with ELO range at database level from users collection
        let listener = db.collection("users")
            .whereField("elo", isGreaterThanOrEqualTo: minElo)
            .whereField("elo", isLessThanOrEqualTo: maxElo)
            .order(by: "elo")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    // Check if the error is about missing index
                    if error.localizedDescription.contains("requires an index") {
                        self.errorMessage = """
                            Users collection needs a composite index. Please create the index with:
                            Collection: users
                            Fields indexed:
                            1. elo (Ascending)
                            2. createdAt (Descending)
                            """
                        print("Waiting for index to be built: \(error.localizedDescription)")
                    } else {
                        self.errorMessage = error.localizedDescription
                        print("Search error: \(error.localizedDescription)")
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No users found in ELO range")
                    return
                }
                
                print("\n=== Found \(documents.count) total users in ELO range ===")
                
                // Show all potential matches
                print("\nAll users in range:")
                documents.forEach { doc in
                    let data = doc.data()
                    print("""
                        \nUser:
                        - User ID: \(doc.documentID) \(doc.documentID == userId ? "(Current User)" : "")
                        - ELO: \(data["elo"] ?? "unknown")
                        - Name: \(data["fullName"] ?? "unknown")
                        """)
                }
                
                // Filter out current user
                let matchingDocs = documents.filter { doc in
                    let docId = doc.documentID
                    return docId != userId
                }
                
                print("\n=== After filtering out current user: \(matchingDocs.count) potential matches ===")
                
                if let opponentDoc = matchingDocs.first {
                    print("\nSelected match with user: \(opponentDoc.documentID)")
                    self.createMatch(withOpponent: opponentDoc.documentID)
                } else {
                    print("\nNo suitable users found in ELO range \(self.minElo) to \(self.maxElo)")
                }
            }
        
        listeners.setSearchListener(listener)
    }
    
    private func listenToMatch() {
        guard let matchId = matchId else { return }
        let db = Firestore.firestore()
        
        print("Starting to listen for match updates on ID: \(matchId)")
        
        let listener = db.collection("matches").document(matchId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else {
                    print("Self is nil in match listener")
                    return
                }
                
                if let error = error {
                    print("Match listener error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = snapshot?.data() else {
                    print("No data in match snapshot")
                    self.errorMessage = "Match data not found"
                    return
                }
                
                print("Received match update: \(data)")
                
                if let status = data["status"] as? String {
                    print("Match status updated to: \(status)")
                    switch status {
                    case "active":
                        print("Match is now active, updating UI state")
                        self.matchState = .accepted
                        self.shouldNavigateToMatch = true
                        print("Navigation flag set to true")
                    case "cancelled":
                        print("Match was cancelled, resetting state")
                        self.cleanup()
                        self.matchState = .searching
                    default:
                        print("Unhandled match status: \(status)")
                        break
                    }
                }
            }
        
        listeners.setMatchListener(listener)
    }
    
    private func startEloRangeExpansion() {
        let timer = Timer.scheduledTimer(withTimeInterval: expansionInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                
                if self.eloRangeExpansion < self.maxEloRange {
                    self.eloRangeExpansion += 50
                    await self.updateEloRange()
                }
            }
        }
        
        listeners.setExpansionTimer(timer)
    }
    
    private func updateEloRange() async {
        print("Expanding ELO range - New range: \(minElo) to \(maxElo)")
        // No need to update any documents, just let the listener query with new range
    }
    
    func acceptMatch() {
        guard let matchId = matchId else {
            print("Error: No match ID available")
            errorMessage = "No match ID available"
            return
        }
        
        print("Accepting match with ID: \(matchId)")
        let db = Firestore.firestore()
        let statusData = StatusData(status: "active", matchId: matchId)
        
        Task { @MainActor in
            do {
                print("Updating match status to active...")
                try await db.collection("matches").document(matchId).updateData(statusData.asDictionary)
                print("Successfully updated match status to active")
                
                // Verify the match data after update
                let matchDoc = try await db.collection("matches").document(matchId).getDocument()
                if let data = matchDoc.data() {
                    print("Current match data: \(data)")
                }
                
                print("Setting matchState to .accepted")
                matchState = .accepted
                
                print("Setting shouldNavigateToMatch to true")
                shouldNavigateToMatch = true
                
                print("Match accepted successfully - Ready for navigation")
            } catch {
                print("Error accepting match: \(error.localizedDescription)")
                errorMessage = "Failed to accept match: \(error.localizedDescription)"
            }
        }
    }
    
    func cancelMatchmaking() {
        guard let matchId = matchId else { return }
        let db = Firestore.firestore()
        
        Task {
            do {
                let statusData = StatusData(status: "cancelled", matchId: matchId)
                try await db.collection("matches").document(matchId).updateData(statusData.asDictionary)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        
        Task { @MainActor in
            cleanup()
        }
    }
    
    private func cleanup() {
        listeners.cleanup()
    }
    
    deinit {
        listeners.cleanup()
    }
}

// Make all data types Sendable
struct MatchmakingData: Sendable {
    let minEloMatch: Int
    let maxEloMatch: Int
    let status: String
    let timestamp: FieldValue
    let userId: String
    let elo: Int
    
    var asDictionary: [String: Any] {
        [
            "minEloMatch": minEloMatch,
            "maxEloMatch": maxEloMatch,
            "status": status,
            "timestamp": timestamp,
            "userId": userId,
            "elo": elo
        ]
    }
}

struct MatchData: Sendable {
    let players: [String]
    let status: String
    let timestamp: FieldValue
    
    var asDictionary: [String: Any] {
        [
            "players": players,
            "status": status,
            "timestamp": timestamp
        ]
    }
}

struct StatusData: Sendable {
    let status: String
    let matchId: String
    
    var asDictionary: [String: Any] {
        [
            "status": status,
            "matchId": matchId
        ]
    }
}

// Add new Sendable type for ELO range updates
struct EloRangeData: Sendable {
    let minEloMatch: Int
    let maxEloMatch: Int
    
    var asDictionary: [String: Any] {
        [
            "minEloMatch": minEloMatch,
            "maxEloMatch": maxEloMatch
        ]
    }
} 