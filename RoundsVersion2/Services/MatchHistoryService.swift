import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class MatchHistoryService: ObservableObject {
    private let db = Firestore.firestore()
    
    @Published var recentMatches: [CompletedMatch] = []
    @Published var playerStats: PlayerStatistics?
    @Published var isLoading = false
    
    // MARK: - Fetch Recent Matches
    func fetchRecentMatches(limit: Int = 10) async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let snapshot = try await db.collection("completedMatches")
                .whereField("players", arrayContains: ["id": currentUserId])
                .order(by: "completedAt", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            let matches = snapshot.documents.compactMap { document -> CompletedMatch? in
                return try? document.data(as: CompletedMatch.self)
            }
            
            await MainActor.run {
                self.recentMatches = matches
                self.isLoading = false
            }
            
        } catch {
            print("Error fetching recent matches: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Fetch Specific Match
    func fetchMatch(matchId: String) async -> CompletedMatch? {
        do {
            let document = try await db.collection("completedMatches").document(matchId).getDocument()
            return try document.data(as: CompletedMatch.self)
        } catch {
            print("Error fetching match \(matchId): \(error)")
            return nil
        }
    }
    
    // MARK: - Fetch Player Statistics
    func fetchPlayerStatistics() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let document = try await db.collection("users").document(currentUserId).getDocument()
            if let data = document.data(),
               let statsData = data["statistics"] as? [String: Any] {
                
                let stats = PlayerStatistics(
                    matchesPlayed: statsData["matchesPlayed"] as? Int ?? 0,
                    wins: statsData["wins"] as? Int ?? 0,
                    losses: statsData["losses"] as? Int ?? 0,
                    totalStrokes: statsData["totalStrokes"] as? Int ?? 0,
                    eagles: statsData["eagles"] as? Int ?? 0,
                    birdies: statsData["birdies"] as? Int ?? 0,
                    pars: statsData["pars"] as? Int ?? 0,
                    bogeys: statsData["bogeys"] as? Int ?? 0,
                    doubleBogeys: statsData["doubleBogeys"] as? Int ?? 0,
                    bestScore: statsData["bestScore"] as? Int ?? 999,
                    averageScore: statsData["averageScore"] as? Double ?? 0.0,
                    lastPlayed: (statsData["lastPlayed"] as? Timestamp)?.dateValue()
                )
                
                await MainActor.run {
                    self.playerStats = stats
                }
            }
        } catch {
            print("Error fetching player statistics: \(error)")
        }
    }
    
    // MARK: - Fetch Match History for Profile
    func fetchMatchHistory(playerId: String? = nil, limit: Int = 20) async -> [MatchHistoryItem] {
        let userId = playerId ?? Auth.auth().currentUser?.uid ?? ""
        
        do {
            let snapshot = try await db.collection("users").document(userId)
                .collection("matchHistory")
                .order(by: "date", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            return snapshot.documents.compactMap { document -> MatchHistoryItem? in
                let data = document.data()
                return MatchHistoryItem(
                    matchId: data["matchId"] as? String ?? "",
                    date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                    won: data["won"] as? Bool ?? false,
                    score: data["score"] as? Int ?? 0,
                    scoreToPar: data["scoreToPar"] as? Int ?? 0,
                    courseName: data["courseName"] as? String ?? "",
                    opponentId: data["opponentId"] as? String ?? "",
                    opponentName: data["opponentName"] as? String ?? ""
                )
            }
        } catch {
            print("Error fetching match history: \(error)")
            return []
        }
    }
    
    // MARK: - Search Matches
    func searchMatches(courseName: String? = nil, opponentName: String? = nil, dateRange: DateInterval? = nil) async -> [CompletedMatch] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return [] }
        
        var query: Query = db.collection("completedMatches")
            .whereField("players", arrayContains: ["id": currentUserId])
        
        if let courseName = courseName, !courseName.isEmpty {
            query = query.whereField("course.name", isEqualTo: courseName)
        }
        
        if let dateRange = dateRange {
            query = query
                .whereField("completedAt", isGreaterThanOrEqualTo: Timestamp(date: dateRange.start))
                .whereField("completedAt", isLessThanOrEqualTo: Timestamp(date: dateRange.end))
        }
        
        do {
            let snapshot = try await query
                .order(by: "completedAt", descending: true)
                .getDocuments()
            
            let matches = snapshot.documents.compactMap { document -> CompletedMatch? in
                return try? document.data(as: CompletedMatch.self)
            }
            
            // Filter by opponent name if specified (since Firestore doesn't support complex queries)
            if let opponentName = opponentName, !opponentName.isEmpty {
                return matches.filter { match in
                    match.players.contains { player in
                        player.id != currentUserId && player.name.localizedCaseInsensitiveContains(opponentName)
                    }
                }
            }
            
            return matches
            
        } catch {
            print("Error searching matches: \(error)")
            return []
        }
    }
}

// MARK: - Data Models
struct CompletedMatch: Codable, Identifiable {
    var id: String { matchId }
    let matchId: String
    let status: String
    let completedAt: Date
    let startedAt: Date
    let duration: TimeInterval
    
    let course: CourseInfo
    let tee: TeeInfo
    let players: [PlayerInfo]
    let scores: MatchScores
    let finalScores: [String: Int]
    let scoresToPar: [String: Int]
    
    let winnerId: String
    let winnerName: String
    let strokeDifference: Int
    let wasPlayoff: Bool
    
    let statistics: [String: PlayerMatchStats]
    let settings: RoundSettingsData
    
    let version: String
    let platform: String
    
    enum CodingKeys: String, CodingKey {
        case matchId = "matchId"
        case status, completedAt, startedAt, duration
        case course, tee, players, scores, finalScores, scoresToPar
        case winnerId, winnerName, strokeDifference, wasPlayoff
        case statistics, settings, version, platform
    }
}

struct CourseInfo: Codable {
    let id: String
    let name: String
    let city: String
    let state: String
}

struct TeeInfo: Codable {
    let name: String
    let yardage: Int
    let rating: Double
    let slope: Int
    let par: Int
}

struct PlayerInfo: Codable {
    let id: String
    let name: String
    let email: String
    let elo: Int
}

struct MatchScores: Codable {
    let player: [Int?]
    let opponent: [Int?]
}

struct PlayerMatchStats: Codable {
    let holesPlayed: Int
    let totalStrokes: Int
    let eagles: Int
    let birdies: Int
    let pars: Int
    let bogeys: Int
    let doubleBogeys: Int
    let tripleBogeyPlus: Int
    let averageScore: Double
}

struct RoundSettingsData: Codable {
    let concedePutt: Bool
    let puttingAssist: Bool
    let greenSpeed: String
    let windStrength: String
    let mulligans: Int
    let caddyAssist: Bool
    let startingHole: Int
}

struct PlayerStatistics {
    let matchesPlayed: Int
    let wins: Int
    let losses: Int
    let totalStrokes: Int
    let eagles: Int
    let birdies: Int
    let pars: Int
    let bogeys: Int
    let doubleBogeys: Int
    let bestScore: Int
    let averageScore: Double
    let lastPlayed: Date?
    
    var winPercentage: Double {
        guard matchesPlayed > 0 else { return 0.0 }
        return Double(wins) / Double(matchesPlayed) * 100.0
    }
    
    var averageScorePerRound: Double {
        guard matchesPlayed > 0 else { return 0.0 }
        return Double(totalStrokes) / Double(matchesPlayed)
    }
}

struct MatchHistoryItem {
    let matchId: String
    let date: Date
    let won: Bool
    let score: Int
    let scoreToPar: Int
    let courseName: String
    let opponentId: String
    let opponentName: String
    
    var scoreToParString: String {
        if scoreToPar == 0 { return "E" }
        return scoreToPar > 0 ? "+\(scoreToPar)" : "\(scoreToPar)"
    }
    
    var resultText: String {
        return won ? "W" : "L"
    }
    
    var resultColor: Color {
        return won ? .green : .red
    }
} 