import Foundation
import SwiftUI

// MARK: - Centralized Tournament State
@Observable
class TournamentState {
    
    // MARK: - Properties
    var tournaments: [Tournament] = []
    var myTournaments: [Tournament] = []
    var selectedTournament: Tournament?
    var leaderboards: [String: [LeaderboardEntry]] = [:]
    
    // MARK: - Loading States
    var isLoading = false
    var isLoadingLeaderboard = false
    var isJoining = false
    var isCreating = false
    
    // MARK: - UI State
    var filterType: TournamentFilterType = .all
    var searchQuery = ""
    var errorMessage: String?
    var isInitialized = false
    
    // MARK: - Private Properties
    private let serviceContainer = ServiceContainer.shared
    
    // MARK: - Initialization
    func initialize() {
        guard !isInitialized else { return }
        
        Task { @MainActor in
            await loadTournaments()
            isInitialized = true
        }
    }
    
    func reset() {
        tournaments.removeAll()
        myTournaments.removeAll()
        selectedTournament = nil
        leaderboards.removeAll()
        filterType = .all
        searchQuery = ""
        errorMessage = nil
        isInitialized = false
    }
    
    // MARK: - Data Loading
    @MainActor
    func loadTournaments() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            if FeatureFlags.useNewTournamentService {
                await PerformanceMonitor.measure("TournamentState.loadTournaments") {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s optimized
                }
            } else {
                try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2s existing
            }
            
            await MainActor.run {
                // Mock tournaments for now
                tournaments = generateMockTournaments()
                isLoading = false
            }
        }
    }
    
    @MainActor
    func loadLeaderboard(for tournamentId: String) async {
        guard !isLoadingLeaderboard else { return }
        isLoadingLeaderboard = true
        
        // Simulate loading leaderboard
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        // Mock leaderboard data
        leaderboards[tournamentId] = [
            LeaderboardEntry(
                userId: "user1",
                userName: "Pro Golfer",
                userElo: 1600,
                currentPosition: 1,
                totalScore: -5,
                roundScores: [68, 70, 67],
                isCurrentUser: false,
                avatar: nil
            )
        ]
        
        isLoadingLeaderboard = false
    }
    
    // MARK: - Actions
    @MainActor
    func joinTournament(_ tournament: Tournament) async {
        guard !isJoining else { return }
        isJoining = true
        
        let tournamentService = serviceContainer.tournamentService()
        
        if FeatureFlags.useNewTournamentService {
            await PerformanceMonitor.measure("TournamentState.joinTournament") {
                await tournamentService.joinTournament(tournament.id)
            }
        } else {
            await tournamentService.joinTournament(tournament.id)
        }
        
        // Update local state
        await loadTournaments()
        
        isJoining = false
    }
    
    @MainActor
    func createTournament(_ tournament: Tournament) async {
        guard !isCreating else { return }
        isCreating = true
        
        let tournamentService = serviceContainer.tournamentService()
        
        if FeatureFlags.useNewTournamentService {
            await PerformanceMonitor.measure("TournamentState.createTournament") {
                await tournamentService.createTournament(tournament)
            }
        } else {
            await tournamentService.createTournament(tournament)
        }
        
        // Update local state
        await loadTournaments()
        
        isCreating = false
    }
    
    @MainActor
    func selectTournament(_ tournament: Tournament) {
        selectedTournament = tournament
        Task {
            await loadLeaderboard(for: tournament.id)
        }
    }
    
    @MainActor
    func setFilter(_ filter: TournamentFilterType) {
        filterType = filter
        updateFilteredTournaments()
    }
    
    @MainActor
    func searchTournaments(_ query: String) {
        searchQuery = query
        updateFilteredTournaments()
    }
    
    @MainActor
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Private Helpers
    private func updateMyTournaments() {
        // Filter tournaments where current user is participating
        myTournaments = tournaments.filter { tournament in
            // Mock logic - in real implementation, check if current user is in tournament entries
            return tournament.currentParticipants > 0
        }
    }
    
    private func updateFilteredTournaments() {
        // Apply filters and search - update filtered tournaments
        // Implementation would filter the tournaments array based on filterType and searchQuery
    }
    
    private func generateMockTournaments() -> [Tournament] {
        return [
            Tournament(
                id: "1",
                title: "Weekend Championship",
                description: "Competitive weekend tournament",
                type: .weekly,
                format: .strokePlay,
                status: .registration,
                createdAt: Date(),
                startDate: Date().addingTimeInterval(86400), // Tomorrow
                endDate: Date().addingTimeInterval(172800), // Day after tomorrow
                registrationDeadline: Date().addingTimeInterval(43200), // 12 hours
                entryFee: 25.0,
                maxParticipants: 100,
                minParticipants: 10,
                currentParticipants: 45,
                numberOfRounds: 2,
                holesPerRound: 18,
                allowedCourses: ["any"],
                handicapRequired: false,
                minimumElo: nil,
                maximumElo: nil,
                totalPrizePool: 1000.0,
                prizes: [],
                hostId: "host1",
                hostName: "Tournament Host",
                isSponsored: false,
                sponsorName: nil,
                entries: [],
                chatEnabled: true,
                liveLeaderboard: true,
                allowSpectators: true
            )
        ]
    }
    
    // MARK: - Computed Properties
    var activeTournaments: [Tournament] {
        return tournaments.filter { $0.status == .active }
    }
    
    var upcomingTournaments: [Tournament] {
        return tournaments.filter { $0.status == .upcoming || $0.status == .registration }
    }
    
    var myActiveTournaments: [Tournament] {
        return myTournaments.filter { $0.status == .active }
    }
}

// MARK: - Tournament Filter Types
enum TournamentFilterType: String, CaseIterable {
    case all = "All"
    case upcoming = "Upcoming"
    case active = "Active"
    case completed = "Completed"
    case myTournaments = "My Tournaments"
} 