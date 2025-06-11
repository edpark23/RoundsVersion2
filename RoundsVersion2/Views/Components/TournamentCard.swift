import SwiftUI

struct TournamentCard: View {
    let tournament: Tournament
    let onJoin: () -> Void
    let onViewDetails: () -> Void
    
    @State private var isJoining = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            // Header with title and status
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text(tournament.title)
                        .font(AppTypography.titleMedium)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(2)
                    
                    HStack(spacing: AppSpacing.small) {
                        Text(tournament.type.displayName)
                            .font(AppTypography.bodySmall)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.primaryBlue)
                            .padding(.horizontal, AppSpacing.small)
                            .padding(.vertical, 2)
                            .background(AppColors.primaryBlue.opacity(0.1))
                            .cornerRadius(AppSpacing.small)
                        
                        if tournament.isSponsored, let sponsor = tournament.sponsorName {
                            Text("Sponsored by \(sponsor)")
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppColors.accentGold)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                Spacer()
                
                StatusIndicator(status: tournament.status, timeRemaining: tournament.timeRemaining)
            }
            
            // Tournament details
            VStack(spacing: AppSpacing.small) {
                HStack {
                    Label {
                        Text("\(tournament.currentParticipants)/\(tournament.maxParticipants) players")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                    } icon: {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(AppColors.primaryBlue)
                    }
                    
                    Spacer()
                    
                    Label {
                        Text("$\(tournament.entryFee, specifier: "%.0f") entry")
                            .font(AppTypography.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(tournament.entryFee == 0 ? AppColors.birdieGreen : AppColors.textPrimary)
                    } icon: {
                        Image(systemName: tournament.entryFee == 0 ? "gift.fill" : "dollarsign.circle.fill")
                            .foregroundColor(tournament.entryFee == 0 ? AppColors.birdieGreen : AppColors.accentGold)
                    }
                }
                
                HStack {
                    Label {
                        Text("$\(tournament.totalPrizePool, specifier: "%.0f") prize pool")
                            .font(AppTypography.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.accentGold)
                    } icon: {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(AppColors.accentGold)
                    }
                    
                    Spacer()
                    
                    if let topPrize = tournament.prizes.first {
                        Text("+\(topPrize.eloBonus) ELO for winner")
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.primaryBlue)
                            .fontWeight(.medium)
                    }
                }
            }
            
            // Progress bar for active tournaments
            if tournament.status == .active {
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    HStack {
                        Text("Tournament Progress")
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Spacer()
                        
                        Text(tournament.statusDisplayText)
                            .font(AppTypography.bodySmall)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.primaryBlue)
                    }
                    
                    ProgressView(value: tournament.progressPercentage)
                        .tint(AppColors.primaryBlue)
                        .scaleEffect(y: 0.8)
                }
            }
            
            // Action buttons
            HStack(spacing: AppSpacing.medium) {
                Button(action: onViewDetails) {
                    HStack(spacing: AppSpacing.small) {
                        Image(systemName: "info.circle")
                        Text("Details")
                    }
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.primaryBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .secondaryButton()
                
                Button(action: {
                    if !isJoining {
                        isJoining = true
                        onJoin()
                        
                        // Reset after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isJoining = false
                        }
                    }
                }) {
                    HStack(spacing: AppSpacing.small) {
                        if isJoining {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: tournament.canJoin ? "plus.circle.fill" : "checkmark.circle.fill")
                        }
                        Text(buttonText)
                    }
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .primaryButton()
                .disabled(!tournament.canJoin || isJoining)
            }
        }
        .padding(AppSpacing.large)
        .shadow(color: AppColors.borderMedium.opacity(0.1), radius: 8, x: 0, y: 4)
        .background(AppColors.cardBackground)
        .cornerRadius(12)
    }
    
    private var buttonText: String {
        if isJoining {
            return "Joining..."
        } else if tournament.canJoin {
            return "Join Tournament"
        } else {
            return "View Tournament"
        }
    }
}

struct StatusIndicator: View {
    let status: TournamentStatus
    let timeRemaining: TimeInterval
    
    var body: some View {
        HStack(spacing: AppSpacing.xSmall) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(AppTypography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, AppSpacing.small)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .cornerRadius(AppSpacing.small)
    }
    
    private var statusColor: Color {
        switch status {
        case .upcoming:
            return AppColors.info
        case .registration:
            return AppColors.success
        case .active:
            return AppColors.birdieGreen
        case .completed:
            return AppColors.textSecondary
        case .cancelled:
            return AppColors.error
        }
    }
    
    private var statusText: String {
        switch status {
        case .upcoming:
            return "Upcoming"
        case .registration:
            return "Open"
        case .active:
            if timeRemaining > 0 {
                let hours = Int(timeRemaining) / 3600
                let minutes = Int(timeRemaining.truncatingRemainder(dividingBy: 3600)) / 60
                
                if hours > 24 {
                    let days = hours / 24
                    return "\(days)d left"
                } else if hours > 0 {
                    return "\(hours)h left"
                } else {
                    return "\(minutes)m left"
                }
            } else {
                return "Ending"
            }
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        }
    }
}

// Preview
struct TournamentCard_Previews: PreviewProvider {
    static var previews: some View {
        let mockTournament = Tournament(
            id: "1",
            title: "Daily Eagle Challenge",
            description: "Join the most competitive daily tournament!",
            type: .daily,
            format: .strokePlay,
            status: .active,
            createdAt: Date(),
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date().addingTimeInterval(3600 * 5),
            registrationDeadline: Date().addingTimeInterval(-7200),
            entryFee: 5.0,
            maxParticipants: 200,
            minParticipants: 8,
            currentParticipants: 127,
            numberOfRounds: 1,
            holesPerRound: 18,
            allowedCourses: ["any"],
            handicapRequired: false,
            minimumElo: nil,
            maximumElo: nil,
            totalPrizePool: 500.0,
            prizes: [
                TournamentPrize(position: "1st", cashAmount: 200.0, eloBonus: 25, description: "Winner")
            ],
            hostId: "system",
            hostName: "Rounds",
            isSponsored: false,
            sponsorName: nil,
            entries: [],
            chatEnabled: true,
            liveLeaderboard: true,
            allowSpectators: true
        )
        
        VStack(spacing: AppSpacing.large) {
            TournamentCard(
                tournament: mockTournament,
                onJoin: {},
                onViewDetails: {}
            )
        }
        .padding()
        .background(AppColors.backgroundPrimary)
        .previewLayout(.sizeThatFits)
    }
} 