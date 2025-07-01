import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var mainViewModel: MainViewModel
    @State private var showingNewMatch = false
    @State private var showingMatchmaking = false
    @State private var animateStats = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                AppColors.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: AppSpacing.large) {
                        // Simple header with welcome message
                        headerView
                        
                        // Basic stats
                        statsView
                        
                        // Single main action button
                        mainActionButton
                        
                        // Active matches section
                        if !viewModel.activeMatches.isEmpty {
                            activeMatchesSection
                        }
                    }
                    .padding(.horizontal, AppSpacing.medium)
                    .padding(.top, AppSpacing.small)
                }
                .refreshable {
                    await refreshData()
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showingMatchmaking) {
                NavigationStack {
                    MatchmakingView()
                        .interactiveNavigation()
                }
            }
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
    
    // MARK: - Simple Header
    private var headerView: some View {
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
                
                // Simple profile image
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
    
    // MARK: - Basic Stats
    private var statsView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: AppSpacing.medium) {
            StatCard(
                title: "ELO Rating",
                value: "\(mainViewModel.userProfile?.elo ?? 1200)",
                icon: "chart.line.uptrend.xyaxis",
                color: AppColors.primaryBlue,
                animate: animateStats
            )
            
            StatCard(
                title: "Win Rate",
                value: viewModel.playerStats.winPercentage,
                icon: "trophy.fill",
                color: AppColors.success,
                animate: animateStats
            )
        }
    }
    
    // MARK: - Single Main Action Button
    private var mainActionButton: some View {
        Button(action: { 
            showingMatchmaking = true 
        }) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Start Match")
                        .font(AppTypography.bodyLarge)
                        .fontWeight(.semibold)
                    
                    Text("Find opponents and play")
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
    }
    
    // MARK: - Simple Active Matches Section
    private var activeMatchesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Active Matches")
                .font(AppTypography.titleMedium)
                .foregroundColor(AppColors.textPrimary)
                .fontWeight(.semibold)
            
            ForEach(viewModel.activeMatches.prefix(3), id: \.id) { match in
                SimpleMatchCard(match: match)
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surfacePrimary)
        .modernCard()
    }
    
    // MARK: - Helper Functions
    private func refreshData() async {
        // Defer Firebase operations to prevent initialization cascade
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s delay
            viewModel.fetchRecentMatches()
            viewModel.loadPlayerProfile()
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
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

struct SimpleMatchCard: View {
    let match: HomeViewModel.Match
    
    var body: some View {
        HStack(spacing: AppSpacing.medium) {
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
            
            Text("Active")
                .font(AppTypography.caption)
                .fontWeight(.medium)
                .foregroundColor(AppColors.success)
        }
        .padding(AppSpacing.medium)
        .background(AppColors.lightBlue.opacity(0.1))
        .cornerRadius(12)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(MainViewModel())
    }
} 