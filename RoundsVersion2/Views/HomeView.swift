import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingNewMatch = false
    @State private var showingMatchmaking = false
    
    var body: some View {
        let content = ScrollView {
            VStack(spacing: 24) {
                welcomeSection
                playerStatsSection
                matchesSection
            }
            .padding(.vertical)
        }
        
        NavigationView {
            ZStack {
                AppColors.backgroundWhite
                    .ignoresSafeArea()
                content
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingNewMatch) {
                GolfCourseSelectorView { selectedCourse in
                    Task {
                        try? await viewModel.createMatch(with: selectedCourse)
                    }
                }
            }
            .sheet(isPresented: $showingMatchmaking) {
                MatchmakingView()
            }
            .onAppear {
                Task {
                    await viewModel.loadUserData()
                    await viewModel.loadActiveMatches()
                    await viewModel.loadPlayerStats()
                }
            }
        }
    }
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let userName = viewModel.userName {
                Text("Welcome back,")
                    .font(.title2)
                    .foregroundColor(AppColors.subtleGray)
                
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(userName)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primaryNavy)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(Color.yellow)
                        
                        Text("ELO \(viewModel.userElo)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.highlightBlue)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.yellow.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardStyle()
    }
    
    private var playerStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Stats")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.primaryNavy)
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(spacing: 16) {
                    // Win/Loss Record
                    HStack(spacing: 20) {
                        StatBox(
                            title: "Wins",
                            value: "\(viewModel.playerStats.wins)",
                            icon: "trophy.fill",
                            color: .green
                        )
                        
                        StatBox(
                            title: "Losses",
                            value: "\(viewModel.playerStats.losses)",
                            icon: "xmark.circle.fill",
                            color: .red
                        )
                        
                        StatBox(
                            title: "Win %",
                            value: viewModel.playerStats.winPercentage,
                            icon: "percent",
                            color: AppColors.highlightBlue
                        )
                    }
                    
                    Divider()
                    
                    // Golf Stats
                    HStack(spacing: 12) {
                        StatBox(
                            title: "Birdies",
                            value: "\(viewModel.playerStats.birdies)",
                            icon: "arrow.down.circle.fill",
                            color: .red
                        )
                        
                        StatBox(
                            title: "Pars",
                            value: "\(viewModel.playerStats.pars)",
                            icon: "equal.circle.fill",
                            color: AppColors.primaryNavy
                        )
                        
                        StatBox(
                            title: "Bogeys",
                            value: "\(viewModel.playerStats.bogeys)",
                            icon: "arrow.up.circle.fill",
                            color: AppColors.highlightBlue
                        )
                        
                        StatBox(
                            title: "Avg",
                            value: viewModel.playerStats.averageScore,
                            icon: "number.circle.fill",
                            color: AppColors.subtleGray
                        )
                    }
                }
                .padding()
                .cardStyle()
            }
        }
        .padding(.horizontal)
    }
    
    private var matchesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Matches")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primaryNavy)
                
                Spacer()
                
                Button(action: { showingNewMatch = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppColors.highlightBlue)
                        .font(.title2)
                }
            }
            
            HStack {
                Button(action: { showingMatchmaking = true }) {
                    Label("Find Match", systemImage: "magnifyingglass")
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .navyButton()
            }
            
            matchesContent
            
            if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var matchesContent: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding()
        } else if viewModel.activeMatches.isEmpty {
            emptyMatchesView
        } else {
            LazyVStack(spacing: 16) {
                // Only show the last two matches
                ForEach(viewModel.activeMatches.prefix(2)) { match in
                    if let opponent = match.opponent {
                        NavigationLink(destination: MatchView(matchId: match.id, opponent: opponent)) {
                            MatchCard(match: match)
                        }
                    } else {
                        MatchCard(match: match)
                            .overlay(
                                Text("Waiting for opponent...")
                                    .font(.caption)
                                    .foregroundColor(AppColors.subtleGray)
                                    .padding(8)
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(8)
                            )
                    }
                }
                
                // Show "View All" button if there are more than 2 matches
                if viewModel.activeMatches.count > 2 {
                    NavigationLink(destination: AllMatchesView(matches: viewModel.activeMatches)) {
                        Text("View All Matches (\(viewModel.activeMatches.count))")
                            .font(.subheadline)
                            .foregroundColor(AppColors.highlightBlue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppColors.highlightBlue, lineWidth: 1)
                            )
                    }
                }
            }
        }
    }
    
    private var emptyMatchesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "flag.fill")
                .font(.system(size: 40))
                .foregroundColor(AppColors.subtleGray)
            Text("No active matches")
                .font(.headline)
                .foregroundColor(AppColors.subtleGray)
            
            VStack(spacing: 8) {
                Button(action: { showingNewMatch = true }) {
                    Text("Start a New Match")
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .navyButton()
                
                Button(action: { showingMatchmaking = true }) {
                    Label("Find Match", systemImage: "magnifyingglass")
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .navyButton()
            }
        }
        .padding()
        .cardStyle()
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(AppColors.primaryNavy)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.subtleGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct AllMatchesView: View {
    let matches: [HomeViewModel.Match]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(matches) { match in
                    if let opponent = match.opponent {
                        NavigationLink(destination: MatchView(matchId: match.id, opponent: opponent)) {
                            MatchCard(match: match)
                        }
                    } else {
                        MatchCard(match: match)
                            .overlay(
                                Text("Waiting for opponent...")
                                    .font(.caption)
                                    .foregroundColor(AppColors.subtleGray)
                                    .padding(8)
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(8)
                            )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("All Matches")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MatchCard: View {
    let match: HomeViewModel.Match
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(match.courseName)
                    .font(.headline)
                    .foregroundColor(AppColors.primaryNavy)
                Text(match.clubName)
                    .font(.subheadline)
                    .foregroundColor(AppColors.subtleGray)
            }
            
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(AppColors.highlightBlue)
                Text("\(match.players.count) Players")
                    .foregroundColor(AppColors.subtleGray)
                
                Spacer()
                
                Image(systemName: "clock.fill")
                    .foregroundColor(AppColors.highlightBlue)
                Text(match.date.formatted(date: .abbreviated, time: .shortened))
                    .foregroundColor(AppColors.subtleGray)
            }
            .font(.subheadline)
            
            if let scores = match.scores {
                HStack {
                    Image(systemName: "flag.fill")
                        .foregroundColor(AppColors.highlightBlue)
                    Text("Scores: \(scores.map(String.init).joined(separator: ", "))")
                        .foregroundColor(AppColors.subtleGray)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .cardStyle()
    }
}

#Preview {
    HomeView()
} 