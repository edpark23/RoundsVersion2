import SwiftUI
import FirebaseFirestore

struct LiveMatchView: View {
    let matchId: String
    let opponent: UserProfile
    let course: GolfCourseSelectorViewModel.GolfCourseDetails
    let tee: GolfCourseSelectorViewModel.TeeDetails
    
    @StateObject private var viewModel: LiveMatchViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentHole: Int = 1
    @State private var showingScoreEntry = false
    @State private var showingCamera = false
    @State private var animateHoleTransition = false
    @State private var showingLeaderboard = false
    @State private var showingChatView = false
    @Namespace private var holeTransition
    
    init(matchId: String, opponent: UserProfile, course: GolfCourseSelectorViewModel.GolfCourseDetails, tee: GolfCourseSelectorViewModel.TeeDetails) {
        self.matchId = matchId
        self.opponent = opponent
        self.course = course
        self.tee = tee
        _viewModel = StateObject(wrappedValue: LiveMatchViewModel(matchId: matchId))
    }
    
    var body: some View {
        Text("Live Match View - Phase 4")
            .font(.title)
    }
    
    // MARK: - Modern Header
    private var modernHeader: some View {
        VStack(spacing: 0) {
            // Status bar area
            AppColors.primaryBlue
                .frame(height: 50)
                .ignoresSafeArea(edges: .top)
            
            // Header content
            HStack {
                // Back button with haptic feedback
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .interactiveButton()
                
                Spacer()
                
                // Live match indicator
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppColors.success)
                            .frame(width: 8, height: 8)
                            .animation(AppAnimations.quickSpring.repeatForever(), value: viewModel.isLiveUpdateActive)
                        
                        Text("LIVE MATCH")
                            .font(AppTypography.captionLarge)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Text(viewModel.formattedMatchTime)
                        .font(AppTypography.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Settings menu
                Button(action: {
                    // Show settings
                }) {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .interactiveButton()
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
            .background(AppColors.primaryBlue)
        }
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Live Scorecard
    private var liveScorecard: some View {
        VStack(spacing: AppSpacing.medium) {
            // Players header
            HStack(spacing: AppSpacing.medium) {
                // Current user
                VStack(spacing: AppSpacing.small) {
                    ZStack {
                        Circle()
                            .fill(AppColors.primaryBlue)
                            .frame(width: 60, height: 60)
                        
                        Text(viewModel.currentUser?.initials ?? "")
                            .font(AppTypography.titleMedium)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Text("You")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("\(viewModel.getCurrentUserTotal())")
                        .font(AppTypography.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.isCurrentUserLeading() ? AppColors.success : AppColors.textPrimary)
                }
                .scaleEffect(viewModel.isCurrentUserLeading() ? 1.05 : 1.0)
                .animation(AppAnimations.quickSpring, value: viewModel.isCurrentUserLeading())
                
                Spacer()
                
                // VS indicator
                Text("VS")
                    .font(AppTypography.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                // Opponent
                VStack(spacing: AppSpacing.small) {
                    ZStack {
                        Circle()
                            .fill(AppColors.secondaryBlue)
                            .frame(width: 60, height: 60)
                        
                        Text(opponent.initials)
                            .font(AppTypography.titleMedium)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Text(opponent.fullName.components(separatedBy: " ").first ?? "Opponent")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("\(viewModel.getOpponentTotal())")
                        .font(AppTypography.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(!viewModel.isCurrentUserLeading() ? AppColors.success : AppColors.textPrimary)
                }
                .scaleEffect(!viewModel.isCurrentUserLeading() ? 1.05 : 1.0)
                .animation(AppAnimations.quickSpring, value: viewModel.isCurrentUserLeading())
            }
            .padding(AppSpacing.medium)
            .background(AppColors.surfacePrimary)
            .modernCard()
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.top, AppSpacing.small)
    }
    
    // MARK: - Current Hole Card
    private var currentHoleCard: some View {
        VStack(spacing: AppSpacing.medium) {
            // Hole navigation
            HStack {
                Button(action: {
                    if currentHole > 1 {
                        withAnimation(AppAnimations.quickSpring) {
                            currentHole -= 1
                        }
                    }
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundColor(currentHole > 1 ? AppColors.primaryBlue : AppColors.textTertiary)
                }
                .disabled(currentHole <= 1)
                .interactiveButton()
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("HOLE \(currentHole)")
                        .font(AppTypography.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                        .matchedGeometryEffect(id: "hole-\(currentHole)", in: holeTransition)
                    
                    Text("Par \(getCurrentHolePar())")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    if currentHole < 18 {
                        withAnimation(AppAnimations.quickSpring) {
                            currentHole += 1
                        }
                    }
                }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(currentHole < 18 ? AppColors.primaryBlue : AppColors.textTertiary)
                }
                .disabled(currentHole >= 18)
                .interactiveButton()
            }
            
            // Hole details
            HStack(spacing: AppSpacing.large) {
                VStack(spacing: AppSpacing.small) {
                    Text("YARDAGE")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("\(getCurrentHoleYardage()) yds")
                        .font(AppTypography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(spacing: AppSpacing.small) {
                    Text("HANDICAP")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("\(getCurrentHoleHandicap())")
                        .font(AppTypography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(spacing: AppSpacing.small) {
                    Text("YOUR SCORE")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text(viewModel.getCurrentHoleScore(hole: currentHole) ?? "-")
                        .font(AppTypography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primaryBlue)
                }
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surfacePrimary)
        .modernCard()
        .padding(.horizontal, AppSpacing.medium)
    }
    
    // MARK: - Modern Action Buttons
    private var modernActionButtons: some View {
        VStack(spacing: AppSpacing.medium) {
            // Primary action - Enter Score
            Button(action: {
                showingScoreEntry = true
            }) {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    
                    Text("Enter Score for Hole \(currentHole)")
                        .font(AppTypography.bodyLarge)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            }
            .primaryButton()
            .interactiveButton()
            
            // Secondary actions
            HStack(spacing: AppSpacing.medium) {
                Button(action: {
                    showingCamera = true
                }) {
                    HStack(spacing: AppSpacing.small) {
                        Image(systemName: "camera.fill")
                        Text("Scan Card")
                    }
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.primaryBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                }
                .secondaryButton()
                .interactiveButton()
                
                Button(action: {
                    showingLeaderboard = true
                }) {
                    HStack(spacing: AppSpacing.small) {
                        Image(systemName: "chart.bar.fill")
                        Text("Leaderboard")
                    }
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.primaryBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                }
                .secondaryButton()
                .interactiveButton()
                
                Button(action: {
                    showingChatView = true
                }) {
                    HStack(spacing: AppSpacing.small) {
                        Image(systemName: "message.fill")
                        Text("Chat")
                    }
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.primaryBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                }
                .secondaryButton()
                .interactiveButton()
            }
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.bottom, AppSpacing.large)
    }
    
    // MARK: - Helper Functions
    private func getCurrentHolePar() -> Int {
        guard currentHole <= tee.holes.count else { return 4 }
        return tee.holes[currentHole - 1].par
    }
    
    private func getCurrentHoleYardage() -> Int {
        guard currentHole <= tee.holes.count else { return 400 }
        return tee.holes[currentHole - 1].yardage
    }
    
    private func getCurrentHoleHandicap() -> Int {
        guard currentHole <= tee.holes.count else { return 1 }
        return tee.holes[currentHole - 1].handicap
    }
    
    private func advanceToNextHole() {
        if currentHole < 18 {
            withAnimation(AppAnimations.quickSpring) {
                currentHole += 1
            }
        }
    }
}

// MARK: - Supporting Views

struct ModernScoreEntryView: View {
    let hole: Int
    let par: Int
    let onScoreEntered: (Int) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedScore: Int = 4
    @State private var animateSelection = false
    
    var body: some View {
        VStack(spacing: AppSpacing.large) {
            // Header
            VStack(spacing: AppSpacing.small) {
                Text("Hole \(hole)")
                    .font(AppTypography.displaySmall)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Par \(par)")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Score picker with enhanced animations
            VStack(spacing: AppSpacing.medium) {
                Text("Select Your Score")
                    .font(AppTypography.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: AppSpacing.medium) {
                    ForEach(1...12, id: \.self) { score in
                        Button(action: {
                            selectedScore = score
                            withAnimation(AppAnimations.quickSpring) {
                                animateSelection.toggle()
                            }
                        }) {
                            VStack(spacing: 4) {
                                Text("\(score)")
                                    .font(AppTypography.titleLarge)
                                    .fontWeight(.bold)
                                    .foregroundColor(selectedScore == score ? .white : getScoreColor(score: score, par: par))
                                
                                Text(getScoreLabel(score: score, par: par))
                                    .font(AppTypography.caption)
                                    .foregroundColor(selectedScore == score ? .white.opacity(0.8) : AppColors.textSecondary)
                            }
                            .frame(width: 70, height: 70)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedScore == score ? getScoreColor(score: score, par: par) : AppColors.backgroundSecondary)
                            )
                            .scaleEffect(selectedScore == score ? 1.1 : 1.0)
                            .animation(AppAnimations.quickSpring, value: selectedScore)
                        }
                        .interactiveButton()
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: AppSpacing.medium) {
                Button(action: {
                    onScoreEntered(selectedScore)
                }) {
                    Text("Confirm Score")
                        .font(AppTypography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .primaryButton()
                .interactiveButton()
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                }
                .interactiveButton()
            }
        }
        .padding(AppSpacing.large)
        .background(AppColors.backgroundPrimary)
        .navigationBarHidden(true)
    }
    
    private func getScoreColor(score: Int, par: Int) -> Color {
        switch score - par {
        case ..<(-1): return AppColors.success // Eagle or better
        case -1: return AppColors.birdieGreen // Birdie
        case 0: return AppColors.primaryBlue // Par
        case 1: return AppColors.warning // Bogey
        default: return AppColors.error // Double bogey or worse
        }
    }
    
    private func getScoreLabel(score: Int, par: Int) -> String {
        switch score - par {
        case ..<(-2): return "Eagle+"
        case -2: return "Eagle"
        case -1: return "Birdie"
        case 0: return "Par"
        case 1: return "Bogey"
        case 2: return "Double"
        default: return "Triple+"
        }
    }
}

struct ModernCameraView: View {
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            // Placeholder for camera functionality
            VStack(spacing: AppSpacing.large) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.primaryBlue)
                
                Text("Camera View")
                    .font(AppTypography.titleLarge)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Camera integration coming soon")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                
                Button("Close") {
                    dismiss()
                }
                .primaryButton()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundPrimary)
        .navigationBarHidden(true)
    }
}

struct ModernLeaderboardView: View {
    let matchId: String
    let players: [UserProfile?]
    let scores: [String: [Int?]]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            Text("Leaderboard")
                .font(AppTypography.displaySmall)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            // Leaderboard content placeholder
            VStack(spacing: AppSpacing.medium) {
                Text("Live leaderboard updates")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                
                Text("Real-time scoring coming soon")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(AppSpacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(AppColors.backgroundPrimary)
        .navigationBarHidden(true)
    }
}

struct ModernChatView: View {
    let matchId: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            Text("Match Chat")
                .font(AppTypography.displaySmall)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            // Chat content placeholder
            VStack(spacing: AppSpacing.medium) {
                Text("Real-time chat with your opponent")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                
                Text("Chat functionality coming soon")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(AppSpacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(AppColors.backgroundPrimary)
        .navigationBarHidden(true)
    }
} 