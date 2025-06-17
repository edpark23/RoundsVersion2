import SwiftUI
import FirebaseAuth

struct MatchHistoryView: View {
    @StateObject private var historyService = MatchHistoryService()
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var showingMatchDetail = false
    @State private var selectedMatch: CompletedMatch?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Selector
                tabSelector
                
                // Content
                TabView(selection: $selectedTab) {
                    // Recent Matches Tab
                    recentMatchesView
                        .tag(0)
                    
                    // Statistics Tab
                    statisticsView
                        .tag(1)
                    
                    // Search Tab
                    searchView
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(AppColors.backgroundPrimary)
            .navigationBarHidden(true)
        }
        .task {
            await loadData()
        }
        .sheet(isPresented: $showingMatchDetail) {
            if let match = selectedMatch {
                MatchDetailView(match: match)
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 0) {
            // Status bar spacer
            Rectangle()
                .fill(AppColors.primaryBlue)
                .frame(height: UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0)
                .ignoresSafeArea(.all, edges: .top)
            
            // Header content
            HStack {
                Button(action: {
                    // Navigate back
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("MATCH HISTORY")
                    .font(AppTypography.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Placeholder for symmetry
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .opacity(0)
            }
            .padding(.horizontal, AppSpacing.large)
            .padding(.vertical, AppSpacing.medium)
            .background(AppColors.primaryBlue)
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabButton(title: "Recent", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            TabButton(title: "Stats", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            
            TabButton(title: "Search", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
        }
        .padding(.horizontal, AppSpacing.large)
        .padding(.top, AppSpacing.medium)
    }
    
    // MARK: - Recent Matches View
    private var recentMatchesView: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.medium) {
                if historyService.isLoading {
                    ProgressView("Loading matches...")
                        .padding()
                } else if historyService.recentMatches.isEmpty {
                                            MatchHistoryEmptyStateView(
                        icon: "clock",
                        title: "No Recent Matches",
                        subtitle: "Your completed matches will appear here"
                    )
                    .padding()
                } else {
                    ForEach(historyService.recentMatches) { match in
                        MatchHistoryCard(match: match) {
                            selectedMatch = match
                            showingMatchDetail = true
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.large)
            .padding(.top, AppSpacing.medium)
        }
    }
    
    // MARK: - Statistics View
    private var statisticsView: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                if let stats = historyService.playerStats {
                    PlayerStatsCard(stats: stats)
                    
                    // Additional stats sections
                    VStack(spacing: AppSpacing.medium) {
                        StatsSection(title: "Scoring") {
                            MatchHistoryStatRow(label: "Eagles", value: "\(stats.eagles)")
                            MatchHistoryStatRow(label: "Birdies", value: "\(stats.birdies)")
                            MatchHistoryStatRow(label: "Pars", value: "\(stats.pars)")
                            MatchHistoryStatRow(label: "Bogeys", value: "\(stats.bogeys)")
                            MatchHistoryStatRow(label: "Double Bogeys+", value: "\(stats.doubleBogeys)")
                        }
                        
                        StatsSection(title: "Performance") {
                            MatchHistoryStatRow(label: "Best Score", value: stats.bestScore == 999 ? "N/A" : "\(stats.bestScore)")
                            MatchHistoryStatRow(label: "Average Score", value: String(format: "%.1f", stats.averageScorePerRound))
                            MatchHistoryStatRow(label: "Win Rate", value: String(format: "%.1f%%", stats.winPercentage))
                        }
                    }
                } else {
                    ProgressView("Loading statistics...")
                        .padding()
                }
            }
            .padding(.horizontal, AppSpacing.large)
            .padding(.top, AppSpacing.medium)
        }
    }
    
    // MARK: - Search View
    private var searchView: some View {
        VStack {
            // Search bar
            SearchBar(text: $searchText, placeholder: "Search matches...")
                .padding(.horizontal, AppSpacing.large)
                .padding(.top, AppSpacing.medium)
            
            // Search results would go here
            ScrollView {
                VStack {
                    Text("Search functionality coming soon")
                        .foregroundColor(AppColors.textSecondary)
                        .padding()
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func loadData() async {
        await historyService.fetchRecentMatches()
        await historyService.fetchPlayerStatistics()
    }
}

// MARK: - Supporting Views
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(AppTypography.bodyMedium)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? AppColors.primaryBlue : AppColors.textSecondary)
                
                Rectangle()
                    .fill(isSelected ? AppColors.primaryBlue : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct MatchHistoryCard: View {
    let match: CompletedMatch
    let onTap: () -> Void
    
    private var currentUserId: String {
        return Auth.auth().currentUser?.uid ?? ""
    }
    
    private var currentUserScore: Int {
        return match.finalScores[currentUserId] ?? 0
    }
    
    private var opponentScore: Int {
        let opponentId = match.players.first { $0.id != currentUserId }?.id ?? ""
        return match.finalScores[opponentId] ?? 0
    }
    
    private var opponentName: String {
        return match.players.first { $0.id != currentUserId }?.name ?? "Unknown"
    }
    
    private var didWin: Bool {
        return match.winnerId == currentUserId
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(match.course.name)
                            .font(AppTypography.titleSmall)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("\(match.course.city), \(match.course.state)")
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(didWin ? "W" : "L")
                            .font(AppTypography.titleSmall)
                            .fontWeight(.bold)
                            .foregroundColor(didWin ? AppColors.success : AppColors.error)
                        
                        Text(formatDate(match.completedAt))
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You")
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                        Text("\(currentUserScore)")
                            .font(AppTypography.titleMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    Text("vs")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(opponentName)
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                        Text("\(opponentScore)")
                            .font(AppTypography.titleMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            .padding(AppSpacing.medium)
            .background(AppColors.surfacePrimary)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct PlayerStatsCard: View {
    let stats: PlayerStatistics
    
    var body: some View {
        VStack(spacing: AppSpacing.medium) {
            HStack {
                Text("Overall Statistics")
                    .font(AppTypography.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            HStack(spacing: AppSpacing.large) {
                MatchStatItem(title: "Matches", value: "\(stats.matchesPlayed)")
                MatchStatItem(title: "Wins", value: "\(stats.wins)")
                MatchStatItem(title: "Win %", value: String(format: "%.1f%%", stats.winPercentage))
            }
            
            if let lastPlayed = stats.lastPlayed {
                HStack {
                    Text("Last Played: \(formatDate(lastPlayed))")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                }
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surfacePrimary)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct MatchStatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppTypography.titleLarge)
                .fontWeight(.bold)
                .foregroundColor(AppColors.primaryBlue)
            
            Text(title)
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(title)
                .font(AppTypography.titleSmall)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 0) {
                content
            }
            .background(AppColors.surfacePrimary)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

struct MatchHistoryStatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(AppTypography.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.small)
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
            
            TextField(placeholder, text: $text)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surfacePrimary)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct MatchHistoryEmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppColors.textSecondary)
            
            VStack(spacing: AppSpacing.small) {
                Text(title)
                    .font(AppTypography.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(subtitle)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AppSpacing.large)
    }
}

// MARK: - Preview
struct MatchHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        MatchHistoryView()
    }
} 