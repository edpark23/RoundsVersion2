import SwiftUI

struct RoundActiveView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer? = nil
    @State private var roundStartTime: Date
    @State private var showingScoreVerification = false
    @State private var showingManualScoreEntry = false
    
    // Course and tee information
    let course: GolfCourseSelectorViewModel.GolfCourseDetails
    let tee: GolfCourseSelectorViewModel.TeeDetails
    let settings: RoundSettings
    
    // Sample players with the correct names for the test case (Ed vs Jay Lee)
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
    
    // For the test case, we're showing singles match between Ed and Jay
    var matchType: MatchType {
        return .singles
    }
    
    // The players are already correctly set up for the Ed vs Jay match
    var activePlayers: [UserProfile] {
        return matchPlayers
    }
    
    // For test purposes - in a real implementation, this would be passed from MatchView
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
            // Background
            Color(red: 0.95, green: 0.95, blue: 0.97).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Timer banner
                roundProgressBanner
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                
                // Course information
                courseInfoCard
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                
                // Player list
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(activePlayers, id: \.id) { player in
                            playerRow(player: player)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, 100) // Space for buttons
                }
                
                Spacer()
            }
            
            // Bottom buttons
            VStack {
                Spacer()
                
                VStack(spacing: 10) {
                    Button(action: {
                        showingManualScoreEntry = true
                    }) {
                        HStack {
                            Spacer()
                            Text("ENTER SCORE MANUALLY")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppColors.primaryNavy)
                            Spacer()
                        }
                        .frame(height: 48)
                        .background(Color.white)
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(AppColors.primaryNavy, lineWidth: 1.5)
                        )
                    }
                    
                    Button(action: {
                        // Show ScoreVerificationView for OCR scanning
                        showingScoreVerification = true
                    }) {
                        HStack {
                            Image(systemName: "camera")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(.trailing, 6)
                            
                            Text("SUBMIT ROUND WITH PHOTO")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(red: 0.3, green: 0.5, blue: 0.7))
                        .cornerRadius(24)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("ROUNDS")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // Profile action
                } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
            }
        }
        .navigationBarBackground(backgroundColor: AppColors.primaryNavy)
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
            }
        }
        .fullScreenCover(isPresented: $showingManualScoreEntry) {
            NavigationStack {
                EnterManualScoreView(
                    matchId: matchId,
                    selectedCourse: course
                )
            }
        }
    }
    
    // Green progress banner with round time
    private var roundProgressBanner: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.8, green: 0.9, blue: 0.8))
                .frame(height: 56)
            
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                
                Text("\(formatTimeInterval(elapsedTime)) - Round in Progress")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
            }
        }
    }
    
    // Course information card
    private var courseInfoCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(course.clubName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("View Round Settings")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
            }
            
            Text("\(tee.teeName) - \(tee.totalYards) yards")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)
            
            Text("Rating: \(String(format: "%.2f", tee.courseRating))")
                .font(.system(size: 12))
                .foregroundColor(.gray)
            
            Text("Slope: \(tee.slopeRating)")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
    }
    
    // Player row with updated status logic for Ed and Jay
    private func playerRow(player: UserProfile) -> some View {
        HStack(spacing: 10) {
            // Profile image
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                // Use the initials property from UserProfile
                Text(player.initials)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(AppColors.primaryNavy)
                    .clipShape(Circle())
                
                // Pro badge
                ZStack {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 18, height: 18)
                    
                    Text("P")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 13, y: 13)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(player.fullName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                // Round status - both players in progress for Ed vs Jay
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    
                    Text("Round in progress")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            // Only show 'View' button for the opponent (Jay Lee)
            if player.fullName == "Jay Lee" {
                Text("View")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
    }
    
    // Timer functions
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.elapsedTime = Date().timeIntervalSince(self.roundStartTime)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
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