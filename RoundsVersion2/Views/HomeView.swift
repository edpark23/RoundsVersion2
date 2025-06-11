import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var mainViewModel: MainViewModel
    @State private var showingNewMatch = false
    @State private var showingMatchmaking = false
    @State private var selectedTab: Tab = .solo
    @State private var animateStats = false
    
    enum Tab {
        case solo, duos
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                AppColors.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: AppSpacing.large) {
                        // Modern header with welcome message
                        modernHeaderView
                        
                        // Quick stats dashboard
                        quickStatsView
                        
                        // Game mode selector (improved)
                        modernGameModeSelector
                        
                        // Action buttons section (moved up for better UX)
                        actionButtonsSection
                        
                        // Enhanced profile card
                        enhancedProfileCard
                        
                        // Active matches section (limited to last 3)
                        activeMatchesSection
                        
                        // Recent achievements or tips
                        recentAchievementsView
                    }
                    .padding(.horizontal, AppSpacing.medium)
                    .padding(.top, AppSpacing.small)
                }
                .refreshable {
                    await refreshData()
                }
            }
            .navigationBarHidden(true)
            .modernSheet(isPresented: $showingNewMatch) {
                NavigationStack {
                    GolfCourseSelectorView(
                        viewModel: GolfCourseSelectorViewModel(),
                        onCourseAndTeeSelected: { course, tee, settings in
                            viewModel.createMatch(course: course, tee: tee, settings: settings)
                            showingNewMatch = false
                        }
                    )
                    .interactiveNavigation()
                }
            }
            .fullScreenCover(isPresented: $showingMatchmaking) {
                NavigationStack {
                    MatchmakingView()
                        .interactiveNavigation()
                }
            }
            .swipeGestures(
                onSwipeLeft: {
                    // Quick action for swipe left - could go to profile
                    print("Swiped left - could navigate to profile")
                },
                onSwipeRight: {
                    // Quick action for swipe right - could open quick actions
                    print("Swiped right - could open quick actions")
                },
                onSwipeDown: {
                    // Refresh gesture
                    Task {
                        await refreshData()
                    }
                }
            )
            .onAppear {
                Task {
                    await refreshData()
                    withAnimation(AppAnimations.smoothSpring.delay(0.2)) {
                        animateStats = true
                    }
                }
            }
        }
    }
    
    // MARK: - Modern Header
    private var modernHeaderView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back,")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text(mainViewModel.userProfile?.fullName ?? "Golfer")
                        .font(AppTypography.titleLarge)
                        .foregroundColor(AppColors.primaryBlue)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                // Profile image with modern styling
                if let profileImage = mainViewModel.profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(AppColors.primaryBlue, lineWidth: 2)
                        )
                } else {
                    Circle()
                        .fill(AppColors.lightBlue)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(mainViewModel.userProfile?.initials ?? "")
                                .font(AppTypography.bodyMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.primaryBlue)
                        )
                }
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surfacePrimary)
        .modernCard()
    }
    
    // MARK: - Quick Stats Dashboard
    private var quickStatsView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: AppSpacing.medium) {
            QuickStatCard(
                title: "Handicap Index",
                value: String(format: "%.1f", Double(mainViewModel.userProfile?.elo ?? 0) / 100.0),
                icon: "chart.line.uptrend.xyaxis",
                color: AppColors.primaryBlue,
                animate: animateStats
            )
            
            QuickStatCard(
                title: "Win Rate",
                value: viewModel.playerStats.winPercentage,
                icon: "trophy.fill",
                color: AppColors.success,
                animate: animateStats
            )
        }
    }
    
    // MARK: - Modern Game Mode Selector
    private var modernGameModeSelector: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Game Mode")
                .font(AppTypography.titleMedium)
                .foregroundColor(AppColors.textPrimary)
                .fontWeight(.semibold)
            
            HStack(spacing: AppSpacing.small) {
                GameModeButton(
                    title: "Solo",
                    icon: "person.fill",
                    isSelected: selectedTab == .solo,
                    action: { selectedTab = .solo }
                )
                
                GameModeButton(
                    title: "Duos",
                    icon: "person.2.fill",
                    isSelected: selectedTab == .duos,
                    action: { selectedTab = .duos }
                )
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surfacePrimary)
        .modernCard()
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: AppSpacing.medium) {
            Button(action: { 
                showingMatchmaking = true 
            }) {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Play Round")
                            .font(AppTypography.bodyLarge)
                            .fontWeight(.semibold)
                        
                        Text("Find opponents and start playing")
                            .font(AppTypography.caption)
                            .opacity(0.8)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .opacity(0.6)
                }
                .foregroundColor(.white)
                .padding(AppSpacing.medium)
                .background(
                    LinearGradient(
                        colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .interactiveButton()
            .hapticFeedback(style: .medium)
            .longPressGesture(duration: 0.3) {
                // Quick start with last settings
                print("Long press detected - quick start with last settings")
            }
            
            HStack(spacing: AppSpacing.medium) {
                Button(action: { 
                    showingNewMatch = true 
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Quick Match")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                }
                .secondaryButton()
                .interactiveButton()
                .hapticFeedback(style: .light)
                
                Button(action: { 
                    // Practice mode
                    print("Practice mode selected")
                }) {
                    HStack {
                        Image(systemName: "target")
                        Text("Practice")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                }
                .tertiaryButton()
                .interactiveButton()
                .hapticFeedback(style: .light)
                .longPressGesture(duration: 0.5) {
                    // Advanced practice options
                    print("Long press practice - advanced options")
                }
            }
        }
    }
    
    // MARK: - Enhanced Profile Card
    private var enhancedProfileCard: some View {
        VStack(spacing: AppSpacing.medium) {
            // Header
            HStack {
                Text("Player Profile")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppColors.textPrimary)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { /* Share profile */ }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(AppColors.primaryBlue)
                        .font(AppTypography.bodyMedium)
                }
            }
            
            // QR Code section with modern styling
            VStack(spacing: AppSpacing.medium) {
                ZStack {
                    // Modern QR code background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.backgroundSecondary)
                        .frame(width: 160, height: 160)
                    
                    Image(systemName: "qrcode")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 140)
                        .foregroundColor(AppColors.textPrimary)
                    
                    // Profile image overlay
                    if let profileImage = mainViewModel.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(AppColors.surfacePrimary, lineWidth: 3)
                            )
                    } else {
                        Circle()
                            .fill(AppColors.primaryBlue)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(mainViewModel.userProfile?.initials ?? "")
                                    .font(AppTypography.bodyMedium)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                    }
                }
                
                // Player info
                VStack(spacing: 4) {
                    Text(mainViewModel.userProfile?.fullName.uppercased() ?? "PLAYER")
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(AppColors.accentNavy)
                            .font(.caption)
                        
                        Text("Verified Player")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            
            // Enhanced stats grid
            enhancedStatsGrid
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surfacePrimary)
        .featuredCard()
    }
    
    // MARK: - Enhanced Stats Grid
    private var enhancedStatsGrid: some View {
        VStack(spacing: AppSpacing.medium) {
            // Performance stats
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("Performance")
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textSecondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: AppSpacing.small) {
                    StatCell(title: "WINS", value: "\(viewModel.playerStats.wins)", color: AppColors.success)
                    StatCell(title: "LOSSES", value: "\(viewModel.playerStats.losses)", color: AppColors.error)
                    StatCell(title: "DRAWS", value: "0", color: AppColors.warning)
                    StatCell(title: "WIN %", value: viewModel.playerStats.winPercentage, color: AppColors.primaryBlue)
                }
            }
            
            Divider()
                .background(AppColors.borderLight)
            
            // Scoring stats
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("Scoring")
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textSecondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: AppSpacing.small) {
                    StatCell(title: "BIRDIES", value: "\(viewModel.playerStats.birdies)", color: AppColors.success)
                    StatCell(title: "PARS", value: "\(viewModel.playerStats.pars)", color: AppColors.primaryBlue)
                    StatCell(title: "BOGEYS", value: "\(viewModel.playerStats.bogeys)", color: AppColors.warning)
                    StatCell(title: "DOUBLES", value: "\(viewModel.playerStats.doubleBogeys)", color: AppColors.error)
                }
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(12)
    }
    
    // MARK: - Active Matches Section
    private var activeMatchesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack {
                Text("Active Matches")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppColors.textPrimary)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(min(viewModel.activeMatches.count, 3))")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.lightBlue)
                    .cornerRadius(8)
                
                if viewModel.activeMatches.count > 3 {
                    Text("+\(viewModel.activeMatches.count - 3)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColors.backgroundSecondary)
                        .cornerRadius(6)
                }
            }
            
            ForEach(Array(viewModel.activeMatches.prefix(3))) { match in
                MatchCard(match: match)
            }
            
            // Empty state when no matches
            if viewModel.activeMatches.isEmpty {
                VStack(spacing: AppSpacing.small) {
                    Image(systemName: "golf.tee")
                        .font(.title)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("No active matches")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .fontWeight(.medium)
                    
                    Text("Start a new round to see it here")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(AppSpacing.large)
                .frame(maxWidth: .infinity)
                .background(AppColors.backgroundSecondary.opacity(0.5))
                .cornerRadius(12)
            }
            
            if viewModel.activeMatches.count > 3 {
                Button(action: { /* Show all matches */ }) {
                    HStack {
                        Text("View All Matches")
                            .font(AppTypography.bodyMedium)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(AppColors.primaryBlue)
                    .padding(AppSpacing.medium)
                    .background(AppColors.lightBlue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surfacePrimary)
        .modernCard()
    }
    
    // MARK: - Recent Achievements
    private var recentAchievementsView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Recent Achievements")
                .font(AppTypography.titleMedium)
                .foregroundColor(AppColors.textPrimary)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.medium) {
                    AchievementCard(
                        title: "First Win",
                        description: "Won your first match",
                        icon: "trophy.fill",
                        color: AppColors.accentGold
                    )
                    
                    AchievementCard(
                        title: "Eagle Eye",
                        description: "Made an eagle",
                        icon: "eye.fill",
                        color: AppColors.success
                    )
                    
                    AchievementCard(
                        title: "Consistency",
                        description: "5 matches this week",
                        icon: "calendar.badge.clock",
                        color: AppColors.primaryBlue
                    )
                }
                .padding(.horizontal, AppSpacing.medium)
            }
        }
        .padding(.vertical, AppSpacing.medium)
    }
    
    // MARK: - Helper Functions
    private func refreshData() async {
        await viewModel.loadUserData()
        await viewModel.loadActiveMatches()
        await viewModel.loadPlayerStats()
    }
}

// MARK: - Supporting Views

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let animate: Bool
    
    var body: some View {
        VStack(spacing: AppSpacing.small) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(AppTypography.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                        .scaleEffect(animate ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animate)
                    
                    Text(title)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surfacePrimary)
        .modernCard()
    }
}

struct GameModeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: AppSpacing.small) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : AppColors.primaryBlue)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(AppAnimations.quickSpring, value: isSelected)
                
                Text(title)
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : AppColors.primaryBlue)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.medium)
            .padding(.horizontal, AppSpacing.medium)
            .background(
                ZStack {
                    if isSelected {
                        LinearGradient(
                            colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .cornerRadius(12)
                    } else {
                        AppColors.lightBlue.opacity(0.3)
                            .cornerRadius(12)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.clear : AppColors.primaryBlue.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(
                color: isSelected ? AppColors.primaryBlue.opacity(0.3) : Color.clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 2 : 0
            )
            .animation(AppAnimations.smoothSpring, value: isSelected)
        }
        .interactiveButton()
        .hapticFeedback(style: .light)
    }
}

struct StatCell: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppTypography.bodyMedium)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.small)
    }
}

struct MatchCard: View {
    let match: HomeViewModel.Match
    
    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            // Match status indicator
            Circle()
                .fill(AppColors.success)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(match.courseName)
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("vs \(match.opponent?.fullName ?? "Opponent")")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("In Progress")
                    .font(AppTypography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.success)
                
                Text(match.date, format: .dateTime.hour().minute())
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.lightBlue.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AchievementCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(description)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 120, height: 100)
        .padding(AppSpacing.medium)
        .background(AppColors.surfacePrimary)
        .modernCard()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(MainViewModel())
    }
} 