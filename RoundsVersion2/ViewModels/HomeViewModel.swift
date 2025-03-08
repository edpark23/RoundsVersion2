import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    struct Match: Identifiable, Hashable {
        let id: String
        let courseName: String
        let clubName: String
        let date: Date
        let players: [String]
        let status: String
        let scores: [Int]?
        var opponent: UserProfile?
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: Match, rhs: Match) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    struct PlayerStats {
        var wins: Int = 0
        var losses: Int = 0
        var birdies: Int = 0
        var pars: Int = 0
        var bogeys: Int = 0
        var doubleBogeys: Int = 0
        var totalHolesPlayed: Int = 0
        var totalScore: Int = 0
        
        var winPercentage: String {
            let total = wins + losses
            if total == 0 { return "0%" }
            let percentage = Double(wins) / Double(total) * 100
            return String(format: "%.0f%%", percentage)
        }
        
        var averageScore: String {
            if totalHolesPlayed == 0 { return "N/A" }
            let average = Double(totalScore) / Double(totalHolesPlayed)
            return String(format: "%.1f", average)
        }
    }
    
    @Published var userName: String?
    @Published var activeMatches: [Match] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var playerStats = PlayerStats()
    @Published var userElo: Int = 1200 // Default ELO
    
    private let db = Firestore.firestore()
    
    init() {
        fetchRecentMatches()
    }
    
    func fetchRecentMatches() {
        // TODO: Implement fetching matches from Firestore
        // For now, using sample data
        activeMatches = [
            Match(
                id: "1",
                courseName: "Pine Valley",
                clubName: "Pine Valley Golf Club",
                date: Date(),
                players: ["user1"],
                status: "active",
                scores: nil,
                opponent: UserProfile(
                    id: "opponent1",
                    fullName: "John Doe",
                    email: "john@example.com",
                    elo: 1200,
                    createdAt: Date(),
                    isAdmin: false
                )
            ),
            Match(
                id: "2",
                courseName: "Augusta National",
                clubName: "Augusta National Golf Club",
                date: Date().addingTimeInterval(-86400),
                players: ["user1"],
                status: "active",
                scores: nil,
                opponent: UserProfile(
                    id: "opponent2",
                    fullName: "Jane Smith",
                    email: "jane@example.com",
                    elo: 1300,
                    createdAt: Date(),
                    isAdmin: false
                )
            )
        ]
    }
    
    func startNewMatch() {
        // TODO: Implement starting a new match
    }
    
    func loadUserData() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let userDoc = try await db.collection("users").document(userId).getDocument()
            if let data = userDoc.data() {
                self.userName = data["fullName"] as? String
                self.userElo = data["elo"] as? Int ?? 1200
            }
        } catch {
            self.error = "Failed to load user data: \(error.localizedDescription)"
        }
    }
    
    func loadActiveMatches() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        self.isLoading = true
        
        do {
            // Remove the order by clause to avoid requiring the composite index
            let matchesSnapshot = try await db.collection("matches")
                .whereField("players", arrayContains: userId)
                .whereField("status", isEqualTo: "active")
                .getDocuments()
            
            var matches: [Match] = []
            
            for document in matchesSnapshot.documents {
                if let match = try? await createMatchFromDocument(document) {
                    matches.append(match)
                }
            }
            
            // Sort matches by date in memory instead
            self.activeMatches = matches.sorted(by: { $0.date > $1.date })
            self.isLoading = false
        } catch {
            self.error = "Failed to load matches: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    func loadPlayerStats() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        self.isLoading = true
        
        do {
            // Get all completed matches for this user
            let matchesSnapshot = try await db.collection("matches")
                .whereField("players", arrayContains: userId)
                .whereField("status", isEqualTo: "completed")
                .getDocuments()
            
            var stats = PlayerStats()
            
            for document in matchesSnapshot.documents {
                let data = document.data()
                
                // Count wins and losses
                if let winnerId = data["winnerId"] as? String {
                    if winnerId == userId {
                        stats.wins += 1
                    } else {
                        stats.losses += 1
                    }
                }
                
                // Process scores if available
                if let scores = data["scores"] as? [Int], 
                   let courseId = data["courseId"] as? String {
                    
                    // Get course details to calculate par scores
                    let courseDoc = try await db.collection("courses").document(courseId).getDocument()
                    if let courseData = courseDoc.data(),
                       let tees = courseData["tees"] as? [String: [[String: Any]]],
                       let maleTees = tees["male"],
                       let firstTee = maleTees.first,
                       let holes = firstTee["holes"] as? [[String: Any]] {
                        
                        // Process each hole's score
                        for (index, score) in scores.enumerated() {
                            if index < holes.count {
                                if let par = holes[index]["par"] as? Int {
                                    let relativeToPar = score - par
                                    
                                    switch relativeToPar {
                                    case ..<0: // Birdie or better
                                        stats.birdies += 1
                                    case 0: // Par
                                        stats.pars += 1
                                    case 1: // Bogey
                                        stats.bogeys += 1
                                    default: // Double bogey or worse
                                        stats.doubleBogeys += 1
                                    }
                                    
                                    stats.totalScore += score
                                    stats.totalHolesPlayed += 1
                                }
                            }
                        }
                    }
                }
            }
            
            self.playerStats = stats
            self.isLoading = false
        } catch {
            self.error = "Failed to load player stats: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    private func createMatchFromDocument(_ document: QueryDocumentSnapshot) async throws -> Match {
        let data = document.data()
        let scores: [Int]? = data["scores"] as? [Int]
        let opponent: UserProfile? = nil  // We'll implement opponent fetching later
        
        return Match(
            id: document.documentID,
            courseName: data["courseName"] as? String ?? "",
            clubName: data["clubName"] as? String ?? "",
            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
            players: data["players"] as? [String] ?? [],
            status: data["status"] as? String ?? "active",
            scores: scores,
            opponent: opponent
        )
    }
    
    func createMatch(with course: GolfCourseSelectorViewModel.GolfCourseDetails) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.error = "User not authenticated"
            return
        }
        
        self.isLoading = true
        
        let matchData: [String: Any] = [
            "courseName": course.courseName,
            "clubName": course.clubName,
            "courseId": course.id,
            "date": Timestamp(date: Date()),
            "players": [userId],
            "status": "active",
            "createdBy": userId,
            "createdAt": FieldValue.serverTimestamp(),
            "scores": NSNull()
        ]
        
        do {
            let docRef = try await db.collection("matches").addDocument(data: matchData)
            let scores: [Int]? = nil
            let opponent: UserProfile? = nil
            
            let newMatch = Match(
                id: docRef.documentID,
                courseName: course.courseName,
                clubName: course.clubName,
                date: Date(),
                players: [userId],
                status: "active",
                scores: scores,
                opponent: opponent
            )
            
            self.activeMatches.append(newMatch)
            self.isLoading = false
        } catch {
            self.error = "Failed to create match: \(error.localizedDescription)"
            self.isLoading = false
            throw error
        }
    }
} 