import Foundation
import FirebaseFirestore
import SwiftUI

@MainActor
class TournamentViewModel: ObservableObject {
    @Published var tournaments: [Tournament] = []
    @Published var activeTournaments: [Tournament] = []
    @Published var upcomingTournaments: [Tournament] = []
    @Published var myTournaments: [Tournament] = []
    @Published var featuredTournaments: [Tournament] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingCreateTournament = false
    @Published var showingTournamentDetail = false
    @Published var selectedTournament: Tournament?
    
    // Filters
    @Published var selectedType: TournamentType?
    @Published var selectedEntryFee: Double?
    @Published var showOnlyJoinable = false
    
    private var db: Firestore?
    private let currentUserId: String
    private var hasInitializedFirebase = false
    
    // Mock data for safe initialization
    private let mockTournaments: [Tournament] = [
        Tournament(
            id: "1",
            title: "Daily Eagle Challenge",
            description: "Score under par to win!",
            type: .daily,
            format: .strokePlay,
            status: .active,
            createdAt: Date(),
            startDate: Date(),
            endDate: Date().addingTimeInterval(24 * 60 * 60),
            registrationDeadline: Date().addingTimeInterval(-60 * 60),
            entryFee: 5.0,
            maxParticipants: 50,
            minParticipants: 2,
            currentParticipants: 25,
            numberOfRounds: 1,
            holesPerRound: 18,
            allowedCourses: ["any"],
            handicapRequired: false,
            minimumElo: nil,
            maximumElo: nil,
            totalPrizePool: 250.0,
            prizes: [],
            hostId: "demo_user",
            hostName: "Demo Host",
            isSponsored: false,
            sponsorName: nil,
            entries: [],
            chatEnabled: true,
            liveLeaderboard: true,
            allowSpectators: true
        ),
        Tournament(
            id: "2", 
            title: "Weekly Championship",
            description: "Best score wins the weekly crown",
            type: .weekly,
            format: .strokePlay,
            status: .registration,
            createdAt: Date(),
            startDate: Date().addingTimeInterval(60 * 60),
            endDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            registrationDeadline: Date().addingTimeInterval(30 * 60),
            entryFee: 10.0,
            maxParticipants: 100,
            minParticipants: 8,
            currentParticipants: 45,
            numberOfRounds: 2,
            holesPerRound: 18,
            allowedCourses: ["any"],
            handicapRequired: false,
            minimumElo: nil,
            maximumElo: nil,
            totalPrizePool: 1000.0,
            prizes: [],
            hostId: "demo_user",
            hostName: "Demo Host",
            isSponsored: false,
            sponsorName: nil,
            entries: [],
            chatEnabled: true,
            liveLeaderboard: true,
            allowSpectators: true
        ),
        Tournament(
            id: "3",
            title: "Monthly Masters",
            description: "Elite tournament for top players",
            type: .monthly,
            format: .strokePlay,
            status: .upcoming,
            createdAt: Date(),
            startDate: Date().addingTimeInterval(24 * 60 * 60),
            endDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
            registrationDeadline: Date().addingTimeInterval(12 * 60 * 60),
            entryFee: 25.0,
            maxParticipants: 25,
            minParticipants: 8,
            currentParticipants: 12,
            numberOfRounds: 4,
            holesPerRound: 18,
            allowedCourses: ["premium"],
            handicapRequired: true,
            minimumElo: 1800,
            maximumElo: nil,
            totalPrizePool: 625.0,
            prizes: [],
            hostId: "demo_user",
            hostName: "Demo Host",
            isSponsored: true,
            sponsorName: "Golf Pro Shop",
            entries: [],
            chatEnabled: true,
            liveLeaderboard: true,
            allowSpectators: true
        )
    ]
    
    init(currentUserId: String = "demo_user") {
        self.currentUserId = currentUserId
        // Safe initialization - no Firebase calls
        loadMockData()
    }
    
    // Lazy Firebase initialization
    private func initializeFirebaseIfNeeded() {
        guard !hasInitializedFirebase else { return }
        
        db = Firestore.firestore()
        hasInitializedFirebase = true
    }
    
    // MARK: - Public Methods
    
    func loadMockData() {
        tournaments = mockTournaments
    }
    
    func loadTournaments() {
        // Safe loading - using mock data for now
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            self?.tournaments = self?.mockTournaments ?? []
        }
    }
    
    func joinTournament(_ tournament: Tournament) {
        // Mock join functionality
        errorMessage = nil
        
        guard tournament.canJoin else {
            errorMessage = "Cannot join this tournament"
            return
        }
        
        // Simulate joining
        if tournaments.firstIndex(where: { $0.id == tournament.id }) != nil {
            // In a real implementation, we would update tournament.entries
            // For now, just show success
            errorMessage = "Successfully joined tournament!"
        }
    }
    
    func createTournament(title: String, description: String, type: TournamentType, entryFee: Double) {
        // Mock create functionality
        let newTournament = Tournament(
            id: UUID().uuidString,
            title: title,
            description: description,
            type: type,
            format: .strokePlay,
            status: .registration,
            createdAt: Date(),
            startDate: Date().addingTimeInterval(60 * 60),
            endDate: Date().addingTimeInterval(type.duration),
            registrationDeadline: Date().addingTimeInterval(-3600),
            entryFee: entryFee,
            maxParticipants: 50,
            minParticipants: 8,
            currentParticipants: 25,
            numberOfRounds: type == .daily ? 1 : (type == .weekly ? 2 : 4),
            holesPerRound: 18,
            allowedCourses: ["any"],
            handicapRequired: false,
            minimumElo: nil,
            maximumElo: nil,
            totalPrizePool: entryFee * Double(25) * 0.8, // 80% goes to prizes
            prizes: [
                TournamentPrize(position: "1st", cashAmount: entryFee * Double(25) * 0.4, eloBonus: 25, description: "Winner"),
                TournamentPrize(position: "2nd", cashAmount: entryFee * Double(25) * 0.2, eloBonus: 15, description: "Runner-up"),
                TournamentPrize(position: "3rd", cashAmount: entryFee * Double(25) * 0.1, eloBonus: 10, description: "Third Place")
            ],
            hostId: "demo_user",
            hostName: "Demo Host",
            isSponsored: type == .major,
            sponsorName: type == .major ? "TaylorMade" : nil,
            entries: [],
            chatEnabled: true,
            liveLeaderboard: true,
            allowSpectators: true
        )
        
        tournaments.insert(newTournament, at: 0)
        showingCreateTournament = false
    }
    
    func leaveTournament(_ tournament: Tournament) async -> Bool {
        // Implementation for leaving a tournament
        return true
    }
    
    func getLeaderboard(for tournament: Tournament) -> [LeaderboardEntry] {
        return tournament.entries.enumerated().map { index, entry in
            LeaderboardEntry(
                userId: entry.userId,
                userName: entry.userName,
                userElo: entry.userElo,
                currentPosition: index + 1,
                totalScore: entry.totalScore,
                roundScores: entry.scores,
                isCurrentUser: entry.userId == currentUserId,
                avatar: nil
            )
        }.sorted { $0.totalScore < $1.totalScore }
    }
    
    // MARK: - Private Methods
    
    private func organizeTournaments() {
        let now = Date()
        
        activeTournaments = tournaments.filter { tournament in
            tournament.status == .active || (tournament.status == .registration && tournament.startDate <= now)
        }
        
        upcomingTournaments = tournaments.filter { tournament in
            tournament.status == .upcoming || (tournament.status == .registration && tournament.startDate > now)
        }
        
        myTournaments = tournaments.filter { tournament in
            tournament.entries.contains { $0.userId == currentUserId } || tournament.hostId == currentUserId
        }
        
        featuredTournaments = tournaments.filter { tournament in
            tournament.isSponsored || tournament.type == .major || tournament.totalPrizePool > 500
        }.prefix(3).map { $0 }
        
        applyFilters()
    }
    
    private func applyFilters() {
        var filtered = tournaments
        
        if let selectedType = selectedType {
            filtered = filtered.filter { $0.type == selectedType }
        }
        
        if let selectedEntryFee = selectedEntryFee {
            filtered = filtered.filter { $0.entryFee <= selectedEntryFee }
        }
        
        if showOnlyJoinable {
            filtered = filtered.filter { $0.canJoin }
        }
        
        // Update filtered arrays based on filters
        tournaments = filtered
        organizeTournaments()
    }
    
    private func calculateTotalPrizePool(from prizes: [TournamentPrize]) -> Double {
        return prizes.reduce(0) { $0 + $1.cashAmount }
    }
    
    // MARK: - Mock Data (Remove in production)
    
    private func setupMockData() {
        let mockTournaments = [
            createMockTournament(
                title: "Daily Eagle Challenge",
                type: .daily,
                entryFee: 5.0,
                participants: 127,
                maxParticipants: 200,
                status: .active,
                timeOffset: -3600 // Started 1 hour ago
            ),
            createMockTournament(
                title: "Weekend Masters",
                type: .weekly,
                entryFee: 25.0,
                participants: 45,
                maxParticipants: 100,
                status: .registration,
                timeOffset: 86400 // Starts tomorrow
            ),
            createMockTournament(
                title: "Monthly Championship",
                type: .monthly,
                entryFee: 50.0,
                participants: 234,
                maxParticipants: 500,
                status: .upcoming,
                timeOffset: 86400 * 7 // Starts in a week
            )
        ]
        
        tournaments = mockTournaments
        organizeTournaments()
    }
    
    private func createMockTournament(
        title: String,
        type: TournamentType,
        entryFee: Double,
        participants: Int,
        maxParticipants: Int,
        status: TournamentStatus,
        timeOffset: TimeInterval
    ) -> Tournament {
        let startDate = Date().addingTimeInterval(timeOffset)
        let endDate = startDate.addingTimeInterval(type.duration)
        
        return Tournament(
            id: UUID().uuidString,
            title: title,
            description: "Join the most competitive golf tournament of the \(type.displayName.lowercased())!",
            type: type,
            format: .strokePlay,
            status: status,
            createdAt: Date(),
            startDate: startDate,
            endDate: endDate,
            registrationDeadline: startDate.addingTimeInterval(-3600),
            entryFee: entryFee,
            maxParticipants: maxParticipants,
            minParticipants: 8,
            currentParticipants: participants,
            numberOfRounds: type == .daily ? 1 : (type == .weekly ? 2 : 4),
            holesPerRound: 18,
            allowedCourses: ["any"],
            handicapRequired: false,
            minimumElo: nil,
            maximumElo: nil,
            totalPrizePool: entryFee * Double(participants) * 0.8, // 80% goes to prizes
            prizes: [
                TournamentPrize(position: "1st", cashAmount: entryFee * Double(participants) * 0.4, eloBonus: 25, description: "Winner"),
                TournamentPrize(position: "2nd", cashAmount: entryFee * Double(participants) * 0.2, eloBonus: 15, description: "Runner-up"),
                TournamentPrize(position: "3rd", cashAmount: entryFee * Double(participants) * 0.1, eloBonus: 10, description: "Third Place")
            ],
            hostId: "system",
            hostName: "Rounds",
            isSponsored: type == .major,
            sponsorName: type == .major ? "TaylorMade" : nil,
            entries: [],
            chatEnabled: true,
            liveLeaderboard: true,
            allowSpectators: true
        )
    }
} 