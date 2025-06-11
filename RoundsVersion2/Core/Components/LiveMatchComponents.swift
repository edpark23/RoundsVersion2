import SwiftUI
import FirebaseAuth

// MARK: - Live Match Component Architecture
// Breaking down the large LiveMatchView into optimized components

// MARK: - Match Header Component
struct LiveMatchHeader: View {
    let matchTime: String
    let courseName: String
    let currentHole: Int
    @State private var pulseAnimation = false
    
    var body: some View {
        if FeatureFlags.useComponentViews {
            OptimizedCard(style: .compact) {
                VStack(spacing: AppSpacing.small) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("LIVE MATCH")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.success)
                                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                            
                            Text(courseName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("⏱ \(matchTime)")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text("Hole \(currentHole)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.primaryBlue)
                        }
                    }
                }
            }
            .onAppear { pulseAnimation = true }
        } else {
            standardMatchHeader
        }
    }
    
    private var standardMatchHeader: some View {
        VStack {
            Text("LIVE MATCH - \(courseName)")
                .font(.headline)
            Text("Hole \(currentHole) • \(matchTime)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .modernCard()
    }
}

// MARK: - Live Scorecard Component
struct LiveScorecard: View {
    let scores: [String: [Int?]]
    let currentHole: Int
    let playerNames: [String]
    
    var body: some View {
        if FeatureFlags.useComponentViews {
            OptimizedCard(style: .standard) {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    Text("Live Scorecard")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(spacing: 0) {
                            ScorecardHeaderRow(currentHole: currentHole)
                            
                            ForEach(playerNames, id: \.self) { playerName in
                                ScorecardPlayerRow(
                                    playerName: playerName,
                                    scores: scores[playerName] ?? Array(repeating: nil, count: 18),
                                    currentHole: currentHole
                                )
                            }
                        }
                        .background(AppColors.surfacePrimary)
                        .cornerRadius(8)
                    }
                }
            }
        } else {
            standardScorecard
        }
    }
    
    private var standardScorecard: some View {
        VStack {
            Text("Scorecard")
                .font(.headline)
            
            // Simplified scorecard view
            ForEach(playerNames, id: \.self) { player in
                HStack {
                    Text(player)
                    Spacer()
                    Text("Total: \(calculateTotal(for: player))")
                }
            }
        }
        .modernCard()
    }
    
    private func calculateTotal(for player: String) -> Int {
        return scores[player]?.compactMap { $0 }.reduce(0, +) ?? 0
    }
}

// MARK: - Scorecard Header Row
struct ScorecardHeaderRow: View {
    let currentHole: Int
    
    var body: some View {
        HStack(spacing: 0) {
            Text("Player")
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 80, height: 30)
                .background(AppColors.primaryNavy)
                .foregroundColor(.white)
            
            ForEach(1...18, id: \.self) { hole in
                Text("\(hole)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 30, height: 30)
                    .background(hole == currentHole ? AppColors.highlightBlue : AppColors.primaryNavy)
                    .foregroundColor(.white)
            }
            
            Text("Total")
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 50, height: 30)
                .background(AppColors.primaryNavy)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Scorecard Player Row
struct ScorecardPlayerRow: View {
    let playerName: String
    let scores: [Int?]
    let currentHole: Int
    
    var body: some View {
        HStack(spacing: 0) {
            Text(playerName)
                .font(.caption)
                .frame(width: 80, height: 30)
                .background(AppColors.backgroundSecondary)
                .foregroundColor(AppColors.textPrimary)
            
            ForEach(0..<18, id: \.self) { index in
                Text(scores[index].map(String.init) ?? "-")
                    .font(.caption)
                    .frame(width: 30, height: 30)
                    .background(
                        index + 1 == currentHole ? 
                            AppColors.highlightBlue.opacity(0.3) : 
                            AppColors.backgroundSecondary
                    )
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Text("\(scores.compactMap { $0 }.reduce(0, +))")
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 50, height: 30)
                .background(AppColors.backgroundSecondary)
                .foregroundColor(AppColors.textPrimary)
        }
    }
} 