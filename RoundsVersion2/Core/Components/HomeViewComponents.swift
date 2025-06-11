import SwiftUI
import FirebaseAuth

// MARK: - Home View Component Architecture
// Breaking down the large HomeView into optimized components

// MARK: - Optimized Welcome Header
struct WelcomeHeader: View {
    let userName: String?
    let userElo: Int
    @State private var animateWelcome = false
    
    var body: some View {
        if FeatureFlags.useComponentViews {
            OptimizedCard(style: .featured) {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text(welcomeMessage)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                                .scaleEffect(animateWelcome ? 1.0 : 0.8)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateWelcome)
                            
                            Text("Ready for your next round?")
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        EloDisplayBadge(elo: userElo)
                    }
                }
            }
            .onAppear { animateWelcome = true }
        } else {
            // Fallback to standard implementation
            standardWelcomeHeader
        }
    }
    
    private var welcomeMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting = hour < 12 ? "Good Morning" : hour < 17 ? "Good Afternoon" : "Good Evening"
        return "\(greeting), \(userName ?? "Golfer")!"
    }
    
    private var standardWelcomeHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(welcomeMessage)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Ready for your next round?")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .modernCard()
    }
}

// MARK: - Elo Display Badge
struct EloDisplayBadge: View {
    let elo: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(elo)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text("ELO")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
}

// MARK: - Quick Stats Dashboard
struct QuickStatsDashboard: View {
    let stats: [StatsGrid.StatItem]
    @State private var animateStats = false
    
    var body: some View {
        if FeatureFlags.useComponentViews {
            OptimizedCard(style: .standard) {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    Text("Quick Stats")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    StatsGrid(stats: stats, columns: 2)
                        .scaleEffect(animateStats ? 1.0 : 0.8)
                        .opacity(animateStats ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateStats)
                }
            }
            .onAppear { animateStats = true }
        } else {
            // Fallback to standard grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(stats) { stat in
                    VStack {
                        Text(stat.value)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(stat.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .modernCard()
                }
            }
        }
    }
}

// MARK: - Game Mode Selector
struct GameModeSelector: View {
    @Binding var selectedTab: GameTab
    @State private var animateSelection = false
    
    enum GameTab: CaseIterable {
        case solo, duos
        
        var title: String {
            switch self {
            case .solo: return "Solo Round"
            case .duos: return "Match Play"
            }
        }
        
        var icon: String {
            switch self {
            case .solo: return "figure.golf"
            case .duos: return "person.2.fill"
            }
        }
    }
    
    var body: some View {
        if FeatureFlags.useComponentViews {
            OptimizedCard(style: .standard) {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    Text("Game Mode")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: AppSpacing.medium) {
                        ForEach(GameTab.allCases, id: \.self) { tab in
                            OptimizedGameModeButton(
                                tab: tab,
                                isSelected: selectedTab == tab,
                                action: { 
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedTab = tab
                                    }
                                }
                            )
                        }
                    }
                }
            }
        } else {
            // Standard implementation
            VStack {
                HStack {
                    ForEach(GameTab.allCases, id: \.self) { tab in
                        Button(action: { selectedTab = tab }) {
                            Text(tab.title)
                                .foregroundColor(selectedTab == tab ? .white : .blue)
                        }
                        .primaryButton()
                    }
                }
            }
            .modernCard()
        }
    }
}

// MARK: - Game Mode Button Component
struct OptimizedGameModeButton: View {
    let tab: GameModeSelector.GameTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.small) {
                Image(systemName: tab.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : AppColors.primaryBlue)
                
                Text(tab.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : AppColors.primaryBlue)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        AppColors.lightBlue.opacity(0.2)
                    }
                }
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : AppColors.primaryBlue.opacity(0.3), lineWidth: 1)
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .shadow(color: isSelected ? AppColors.primaryBlue.opacity(0.3) : .clear, radius: isSelected ? 6 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Action Buttons Section
struct ActionButtonsSection: View {
    let onNewMatch: () -> Void
    let onMatchmaking: () -> Void
    let selectedTab: GameModeSelector.GameTab
    
    var body: some View {
        if FeatureFlags.useComponentViews {
            VStack(spacing: AppSpacing.medium) {
                PerformanceButton(
                    title: selectedTab == .solo ? "Start Solo Round" : "Find Match",
                    style: .primary
                ) {
                    if selectedTab == .solo {
                        onNewMatch()
                    } else {
                        onMatchmaking()
                    }
                }
                
                PerformanceButton(
                    title: "Quick Practice",
                    style: .secondary
                ) {
                    // Handle quick practice
                }
            }
        } else {
            VStack(spacing: 16) {
                Button(action: onNewMatch) {
                    Text("Start New Round")
                }
                .primaryButton()
                
                Button(action: onMatchmaking) {
                    Text("Find Match")
                }
                .secondaryButton()
            }
        }
    }
}

// MARK: - Active Matches Preview
struct ActiveMatchesPreview: View {
    let matches: [ActiveMatch]
    let onMatchTap: (ActiveMatch) -> Void
    
    struct ActiveMatch: Identifiable {
        let id = UUID()
        let opponentName: String
        let course: String
        let currentHole: Int
        let status: String
        let lastActivity: Date
    }
    
    var body: some View {
        if FeatureFlags.useComponentViews && !matches.isEmpty {
            OptimizedCard(style: .standard) {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    HStack {
                        Text("Active Matches")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        Text("\(matches.count)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.primaryBlue)
                            .cornerRadius(10)
                    }
                    
                    LazyVStack(spacing: AppSpacing.small) {
                        ForEach(matches.prefix(3)) { match in
                            ActiveMatchRow(match: match, onTap: { onMatchTap(match) })
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Active Match Row Component
struct ActiveMatchRow: View {
    let match: ActiveMatchesPreview.ActiveMatch
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.medium) {
                SmartImageView(
                    url: nil,
                    placeholder: "person.circle.fill",
                    size: CGSize(width: 40, height: 40)
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(match.opponentName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("\(match.course) • Hole \(match.currentHole)")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(match.status)
                        .font(.caption)
                        .foregroundColor(AppColors.success)
                    
                    Text(timeAgo(match.lastActivity))
                        .font(.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, AppSpacing.small)
            .background(AppColors.backgroundSecondary.opacity(0.5))
            .cornerRadius(8)
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Profile Card Component
struct HomeProfileCard: View {
    let userName: String?
    let userElo: Int
    let profileImageURL: String?
    
    var body: some View {
        if FeatureFlags.useComponentViews {
            OptimizedCard(style: .compact) {
                HStack(spacing: AppSpacing.medium) {
                    SmartImageView(
                        url: profileImageURL,
                        placeholder: "person.circle.fill",
                        size: CGSize(width: 50, height: 50)
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(userName ?? "Guest Player")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("ELO Rating: \(userElo)")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "person.circle")
                            .font(.title2)
                            .foregroundColor(AppColors.primaryBlue)
                    }
                }
            }
        } else {
            HStack {
                AsyncImage(url: URL(string: profileImageURL ?? "")) { image in
                    image.resizable()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(userName ?? "Guest")
                        .font(.headline)
                    Text("ELO: \(userElo)")
                        .font(.caption)
                }
                
                Spacer()
            }
            .modernCard()
        }
    }
} 