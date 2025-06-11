import Foundation
import FirebaseFirestore

// MARK: - Tournament Types
enum TournamentType: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case major = "major"
    case privateTournament = "private"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily Challenge"
        case .weekly: return "Weekly Tournament"
        case .monthly: return "Monthly Championship"
        case .major: return "Major Tournament"
        case .privateTournament: return "Private Event"
        }
    }
    
    var duration: TimeInterval {
        switch self {
        case .daily: return 24 * 60 * 60 // 1 day
        case .weekly: return 7 * 24 * 60 * 60 // 7 days
        case .monthly: return 30 * 24 * 60 * 60 // 30 days
        case .major: return 14 * 24 * 60 * 60 // 14 days
        case .privateTournament: return 7 * 24 * 60 * 60 // 7 days default
        }
    }
    
    var maxParticipants: Int {
        switch self {
        case .daily: return 50
        case .weekly: return 100
        case .monthly: return 200
        case .major: return 500
        case .privateTournament: return 20
        }
    }
}

enum TournamentStatus: String, Codable {
    case upcoming = "upcoming"
    case registration = "registration"
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"
}

enum TournamentFormat: String, CaseIterable, Codable {
    case strokePlay = "stroke_play"
    case matchPlay = "match_play"
    case stableford = "stableford"
    case bestBall = "best_ball"
    case scramble = "scramble"
    
    var displayName: String {
        switch self {
        case .strokePlay: return "Stroke Play"
        case .matchPlay: return "Match Play"
        case .stableford: return "Stableford"
        case .bestBall: return "Best Ball"
        case .scramble: return "Scramble"
        }
    }
}

// MARK: - Tournament Prize Structure
struct TournamentPrize: Codable {
    let position: String // "1st", "2nd", "Top 10%", etc.
    let cashAmount: Double
    let eloBonus: Int
    let description: String
}

// MARK: - Tournament Entry
struct TournamentEntry: Codable {
    let userId: String
    let userName: String
    let userElo: Int
    let entryTime: Date
    let scores: [Int] // Scores for each round
    let totalScore: Int
    let position: Int?
    let prizesWon: [TournamentPrize]
}

// MARK: - Main Tournament Model
struct Tournament: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let type: TournamentType
    let format: TournamentFormat
    let status: TournamentStatus
    
    // Timing
    let createdAt: Date
    let startDate: Date
    let endDate: Date
    let registrationDeadline: Date
    
    // Entry Details
    let entryFee: Double
    let maxParticipants: Int
    let minParticipants: Int
    let currentParticipants: Int
    
    // Tournament Configuration
    let numberOfRounds: Int
    let holesPerRound: Int
    let allowedCourses: [String] // Course IDs or "any"
    let handicapRequired: Bool
    let minimumElo: Int?
    let maximumElo: Int?
    
    // Prizes
    let totalPrizePool: Double
    let prizes: [TournamentPrize]
    
    // Host Information
    let hostId: String
    let hostName: String
    let isSponsored: Bool
    let sponsorName: String?
    
    // Participants
    let entries: [TournamentEntry]
    
    // Social Features
    let chatEnabled: Bool
    let liveLeaderboard: Bool
    let allowSpectators: Bool
    
    // Computed Properties
    var timeRemaining: TimeInterval {
        return endDate.timeIntervalSinceNow
    }
    
    var isRegistrationOpen: Bool {
        return status == .registration && Date() < registrationDeadline
    }
    
    var canJoin: Bool {
        return isRegistrationOpen && currentParticipants < maxParticipants
    }
    
    var progressPercentage: Double {
        let totalDuration = endDate.timeIntervalSince(startDate)
        let elapsed = Date().timeIntervalSince(startDate)
        return min(max(elapsed / totalDuration, 0), 1)
    }
    
    var statusDisplayText: String {
        switch status {
        case .upcoming:
            let formatter = RelativeDateTimeFormatter()
            return "Starts \(formatter.localizedString(for: startDate, relativeTo: Date()))"
        case .registration:
            return "Registration Open"
        case .active:
            if timeRemaining > 0 {
                return formatTimeRemaining(timeRemaining)
            } else {
                return "Tournament Ending"
            }
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        }
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let timeRemaining = endDate.timeIntervalSince(Date())
        guard timeRemaining > 0 else { return "Ended" }
        
        let days = Int(timeRemaining) / (24 * 3600)
        let hours = Int(timeRemaining.truncatingRemainder(dividingBy: 24 * 3600)) / 3600
        let minutes = Int(timeRemaining.truncatingRemainder(dividingBy: 3600)) / 60
        
        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Tournament Creation Request
struct CreateTournamentRequest: Codable {
    let title: String
    let description: String
    let type: TournamentType
    let format: TournamentFormat
    let startDate: Date
    let entryFee: Double
    let maxParticipants: Int
    let numberOfRounds: Int
    let holesPerRound: Int
    let prizes: [TournamentPrize]
    let chatEnabled: Bool
    let isPrivate: Bool
    let inviteList: [String] // User IDs for private tournaments
}

// MARK: - Tournament Leaderboard Entry
struct LeaderboardEntry: Codable, Identifiable {
    let id = UUID()
    let userId: String
    let userName: String
    let userElo: Int
    let currentPosition: Int
    let totalScore: Int
    let roundScores: [Int]
    let isCurrentUser: Bool
    let avatar: String?
    
    var scoreDisplay: String {
        if totalScore > 0 {
            return "+\(totalScore)"
        } else if totalScore < 0 {
            return "\(totalScore)"
        } else {
            return "E"
        }
    }
}

// MARK: - Tournament Participant
struct TournamentParticipant: Codable, Identifiable {
    var id = UUID()
    let userId: String
    let username: String
    let currentELO: Int
    var scores: [Int] = []
    var totalScore: Int = 0
    var position: Int = 0
    let joinedAt: Date
    
    private enum CodingKeys: String, CodingKey {
        case userId, username, currentELO, scores, totalScore, position, joinedAt
    }
} 