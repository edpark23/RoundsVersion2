import SwiftUI

struct RankingView: View {
    @StateObject private var viewModel = RankingViewModel()
    @State private var selectedOpponentElo: Double = 1200
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Player Rank Card
                    currentRankCard
                    
                    // Tier Progress
                    tierProgressCard
                    
                    // Match Preview Calculator
                    matchPreviewCard
                    
                    // Recent ELO History
                    eloHistoryCard
                    
                    // All Tiers Overview
                    allTiersCard
                }
                .padding()
            }
            .navigationTitle("Rankings")
            .onAppear {
                viewModel.loadPlayerRanking()
            }
        }
    }
    
    // MARK: - Current Rank Card
    private var currentRankCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Rank")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.playerRank.currentTier.icon)
                            .foregroundColor(Color(hex: viewModel.playerRank.currentTier.color))
                            .font(.title2)
                        
                        Text(viewModel.playerRank.currentTier.rawValue)
                            .font(AppTypography.titleLarge)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("ELO Rating")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("\(viewModel.playerRank.currentElo)")
                        .font(AppTypography.displaySmall)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primaryBlue)
                }
            }
            
            // Win/Loss Record
            HStack(spacing: 20) {
                StatItem(title: "Matches", value: "\(viewModel.playerRank.matchesPlayed)")
                StatItem(title: "Wins", value: "\(viewModel.playerRank.wins)")
                StatItem(title: "Win Rate", value: "\(Int(viewModel.playerRank.winPercentage * 100))%")
                StatItem(title: "Peak ELO", value: "\(viewModel.playerRank.highestElo)")
            }
        }
        .liveMatchCard()
    }
    
    // MARK: - Tier Progress Card
    private var tierProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tier Progress")
                .font(AppTypography.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            let currentTier = viewModel.playerRank.currentTier
            let progress = viewModel.getTierProgress()
            let nextTierElo = viewModel.getNextTierRequirement()
            
            if let nextTierElo = nextTierElo {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Next: \(viewModel.getNextTier()?.rawValue ?? "Master")")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Spacer()
                        
                        Text("\(nextTierElo - viewModel.playerRank.currentElo) ELO to go")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.primaryBlue)
                    }
                    
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primaryBlue))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                    
                    HStack {
                        Text("\(currentTier.eloRange.lowerBound)")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                        
                        Spacer()
                        
                        Text("\(nextTierElo)")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            } else {
                Text("🏆 You've reached the highest tier!")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.success)
            }
        }
        .liveMatchCard()
    }
    
    // MARK: - Match Preview Card
    private var matchPreviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Match Preview")
                .font(AppTypography.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Opponent ELO")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(Int(selectedOpponentElo))")
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primaryBlue)
                }
                
                Slider(value: $selectedOpponentElo, in: 800...3000, step: 50)
                    .accentColor(AppColors.primaryBlue)
                
                let preview = ELOCalculator.previewEloChanges(
                    playerElo: viewModel.playerRank.currentElo,
                    opponentElo: Int(selectedOpponentElo)
                )
                
                HStack(spacing: 16) {
                    EloChangePreview(
                        title: "Win",
                        change: preview.winGain,
                        color: AppColors.success
                    )
                    
                    EloChangePreview(
                        title: "Draw",
                        change: preview.drawChange,
                        color: AppColors.warning
                    )
                    
                    EloChangePreview(
                        title: "Loss",
                        change: preview.lossChange,
                        color: AppColors.error
                    )
                }
            }
        }
        .liveMatchCard()
    }
    
    // MARK: - ELO History Card
    private var eloHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Matches")
                .font(AppTypography.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            if viewModel.playerRank.eloHistory.isEmpty {
                Text("No matches played yet")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(viewModel.playerRank.eloHistory.suffix(5).enumerated()), id: \.offset) { index, entry in
                        EloHistoryRow(entry: entry)
                    }
                }
            }
        }
        .liveMatchCard()
    }
    
    // MARK: - All Tiers Card
    private var allTiersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Tiers")
                .font(AppTypography.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            LazyVStack(spacing: 8) {
                ForEach(RankTier.allCases, id: \.self) { tier in
                    TierRow(
                        tier: tier,
                        isCurrentTier: tier == viewModel.playerRank.currentTier
                    )
                }
            }
        }
        .liveMatchCard()
    }
}

// MARK: - Supporting Views
struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            
            Text(value)
                .font(AppTypography.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

struct EloChangePreview: View {
    let title: String
    let change: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            
            Text("\(change >= 0 ? "+" : "")\(change)")
                .font(AppTypography.bodyMedium)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct EloHistoryRow: View {
    let entry: EloHistoryEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Result icon
            Image(systemName: entry.matchResult == .win ? "checkmark.circle.fill" : 
                            entry.matchResult == .loss ? "xmark.circle.fill" : "minus.circle.fill")
                .foregroundColor(entry.matchResult == .win ? AppColors.success : 
                               entry.matchResult == .loss ? AppColors.error : AppColors.warning)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("vs \(entry.opponentElo) ELO")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(entry.date, style: .relative)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.eloChange >= 0 ? "+" : "")\(entry.eloChange)")
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(entry.eloChange >= 0 ? AppColors.success : AppColors.error)
                
                Text("\(entry.newElo)")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TierRow: View {
    let tier: RankTier
    let isCurrentTier: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tier.icon)
                .foregroundColor(Color(hex: tier.color))
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(tier.rawValue)
                    .font(AppTypography.bodyMedium)
                    .fontWeight(isCurrentTier ? .bold : .medium)
                    .foregroundColor(isCurrentTier ? AppColors.primaryBlue : AppColors.textPrimary)
                
                Text("\(tier.eloRange.lowerBound) - \(tier.eloRange.upperBound == 9999 ? "∞" : "\(tier.eloRange.upperBound)") ELO")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            if isCurrentTier {
                Text("CURRENT")
                    .font(AppTypography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primaryBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.primaryBlue.opacity(0.1))
                    )
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCurrentTier ? AppColors.primaryBlue.opacity(0.05) : Color.clear)
        )
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 