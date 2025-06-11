import SwiftUI

struct RoundActiveView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer? = nil
    @State private var roundStartTime: Date
    @State private var showingScoreVerification = false
    @State private var showingManualScoreEntry = false
    @State private var currentHole: Int = 1
    @State private var animateTimer = false
    
    // Course and tee information
    let course: GolfCourseSelectorViewModel.GolfCourseDetails
    let tee: GolfCourseSelectorViewModel.TeeDetails
    let settings: RoundSettings
    
    // Enhanced players with Phase 4 UI integration
    @State var matchPlayers: [UserProfile] = [
        UserProfile(
            id: "current_user",
            fullName: "Ed Park",
            email: "ed@example.com",
            elo: 1850,
            createdAt: Date(),
            isAdmin: false,
            profilePictureURL: nil
        ),
        UserProfile(
            id: "opponent",
            fullName: "Jay Lee",
            email: "jay@example.com",
            elo: 1750,
            createdAt: Date(),
            isAdmin: false,
            profilePictureURL: nil
        )
    ]
    
    // Match type determines how many players to display
    enum MatchType {
        case singles // 2 players
        case doubles // 4 players
    }
    
    var matchType: MatchType {
        return .singles
    }
    
    var activePlayers: [UserProfile] {
        return matchPlayers
    }
    
    var matchId: String {
        return "test_match_123"
    }
    
    init(course: GolfCourseSelectorViewModel.GolfCourseDetails, tee: GolfCourseSelectorViewModel.TeeDetails, settings: RoundSettings) {
        self.course = course
        self.tee = tee
        self.settings = settings
        self._roundStartTime = State(initialValue: Date())
    }
    
    var body: some View {
        ZStack {
            // Modern Phase 4 background
            AppColors.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Enhanced header with Phase 4 styling
                modernHeader
                
                // Live round progress with Phase 4 enhancements
                liveProgressBanner
                
                // Enhanced course information
                modernCourseCard
                
                // Live player scorecard
                livePlayerScorecard
                
                Spacer()
                
                // Phase 4 action buttons
                modernActionButtons
            }
        }
        .navigationBarHidden(true)
        .swipeGestures(
            onSwipeLeft: {
                // Quick hole navigation
                if currentHole < 18 {
                    withAnimation(AppAnimations.holeChange) {
                        currentHole += 1
                    }
                }
            },
            onSwipeRight: {
                // Previous hole navigation
                if currentHole > 1 {
                    withAnimation(AppAnimations.holeChange) {
                        currentHole -= 1
                    }
                }
            },
            onSwipeUp: {
                // Quick score entry
                showingManualScoreEntry = true
            },
            onSwipeDown: {
                // Refresh round data
                withAnimation(AppAnimations.liveUpdate) {
                    // Refresh logic here
                }
            }
        )
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .fullScreenCover(isPresented: $showingScoreVerification) {
            NavigationStack {
                ScoreVerificationView(
                    matchId: matchId,
                    selectedCourse: course
                )
                .interactiveNavigation()
            }
        }
        .fullScreenCover(isPresented: $showingManualScoreEntry) {
            NavigationStack {
                EnterManualScoreView(
                    matchId: matchId,
                    selectedCourse: course
                )
                .interactiveNavigation()
            }
        }
    }
    
    // MARK: - Modern Header
    private var modernHeader: some View {
        VStack(spacing: 0) {
            // Status bar background
            AppColors.primaryBlue
                .frame(height: 50)
                .ignoresSafeArea(edges: .top)
            
            // Header content with Phase 4 enhancements
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .interactiveButton()
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("LIVE ROUND")
                        .font(AppTypography.captionLarge)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .liveIndicator()
                    
                    Text(course.clubName)
                        .font(AppTypography.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Button(action: {
                    // Profile or settings action
                }) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                .interactiveButton()
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.bottom, AppSpacing.small)
            .background(AppColors.primaryBlue)
        }
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Live Progress Banner
    private var liveProgressBanner: some View {
        HStack {
            // Timer with enhanced animation
            HStack(spacing: AppSpacing.small) {
                Circle()
                    .fill(AppColors.liveGreen)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animateTimer ? 1.2 : 1.0)
                    .animation(AppAnimations.liveUpdate.repeatForever(), value: animateTimer)
                
                Text(formattedTime(elapsedTime))
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .pulseOnUpdate(elapsedTime)
            }
            
            Spacer()
            
            // Current hole indicator
            Text("Hole \(currentHole) of 18")
                .font(AppTypography.bodySmall)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(AppSpacing.medium)
        .background(AppColors.success)
        .cornerRadius(12)
        .padding(.horizontal, AppSpacing.medium)
        .padding(.top, AppSpacing.small)
        .onAppear {
            animateTimer = true
        }
    }
    
    // MARK: - Modern Course Card
    private var modernCourseCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Text(course.clubName)
                    .font(AppTypography.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text("\(course.city), \(course.state)")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Course details with Phase 4 styling
            HStack(spacing: AppSpacing.large) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TEE")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text(tee.teeName)
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primaryBlue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("PAR")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("\(tee.parTotal)")
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primaryBlue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("YARDAGE")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("\(tee.totalYards)")
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primaryBlue)
                }
                
                Spacer()
            }
        }
        .liveMatchCard()
        .padding(.horizontal, AppSpacing.medium)
        .padding(.top, AppSpacing.small)
    }
    
    // MARK: - Live Player Scorecard
    private var livePlayerScorecard: some View {
        VStack(spacing: AppSpacing.medium) {
            Text("PLAYERS")
                .font(AppTypography.captionLarge)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(activePlayers, id: \.id) { player in
                modernPlayerRow(player: player)
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surfacePrimary)
        .modernCard()
        .padding(.horizontal, AppSpacing.medium)
        .padding(.top, AppSpacing.small)
    }
    
    // MARK: - Modern Player Row
    private func modernPlayerRow(player: UserProfile) -> some View {
        HStack(spacing: AppSpacing.medium) {
            // Enhanced player avatar
            ZStack {
                Circle()
                    .fill(player.id == "current_user" ? AppColors.primaryBlue : AppColors.secondaryBlue)
                    .frame(width: 50, height: 50)
                
                Text(player.initials)
                    .font(AppTypography.bodyLarge)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if player.id == "current_user" {
                    Circle()
                        .stroke(AppColors.accentGold, lineWidth: 2)
                        .frame(width: 54, height: 54)
                }
            }
            
            // Player info with enhanced typography
            VStack(alignment: .leading, spacing: 2) {
                Text(player.fullName)
                    .font(AppTypography.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(AppColors.accentGold)
                    
                    Text("ELO: \(player.elo)")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            // Live score indicator
            VStack(spacing: 4) {
                Text("TOTAL")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                Text("E")
                    .font(AppTypography.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.success)
                    .pulseOnUpdate(player.id)
            }
        }
        .padding(AppSpacing.small)
        .background(AppColors.backgroundSecondary.opacity(0.5))
        .cornerRadius(12)
    }
    
    // MARK: - Modern Action Buttons
    private var modernActionButtons: some View {
        VStack(spacing: AppSpacing.medium) {
            // Primary action - Manual score entry
            Button(action: {
                showingManualScoreEntry = true
            }) {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                    
                    Text("ENTER SCORE MANUALLY")
                        .font(AppTypography.bodyLarge)
                        .fontWeight(.bold)
                }
                .foregroundColor(AppColors.primaryBlue)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(AppColors.backgroundWhite)
                .cornerRadius(28)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(AppColors.primaryBlue, lineWidth: 2)
                )
            }
            .interactiveButton()
            
            // Secondary action - Camera scan
            Button(action: {
                showingScoreVerification = true
            }) {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                    
                    Text("SUBMIT ROUND WITH PHOTO")
                        .font(AppTypography.bodyLarge)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            }
            .primaryButton()
            .interactiveButton()
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.bottom, AppSpacing.large)
    }
    
    // MARK: - Helper Functions
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime = Date().timeIntervalSince(roundStartTime)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formattedTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct RoundActiveView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RoundActiveView(
                course: GolfCourseSelectorViewModel.GolfCourseDetails(
                    id: "1", 
                    clubName: "Gotham Golf Club", 
                    courseName: "Gotham Course", 
                    city: "Augusta City", 
                    state: "NY", 
                    tees: []
                ),
                tee: GolfCourseSelectorViewModel.TeeDetails(
                    type: "male",
                    teeName: "White", 
                    courseRating: 71.70, 
                    slopeRating: 131, 
                    totalYards: 6675, 
                    parTotal: 72, 
                    holes: []
                ),
                settings: RoundSettings.defaultSettings
            )
        }
    }
} 