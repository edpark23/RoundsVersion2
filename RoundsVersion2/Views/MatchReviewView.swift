import SwiftUI

struct MatchReviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Model for match results
    struct PlayerResult {
        let id: String
        let name: String
        let initials: String
        let isPro: Bool
        let scores: [Int?]
        let totalScore: Int
        var isWinner: Bool = false
    }
    
    let matchId: String
    let course: GolfCourseSelectorViewModel.GolfCourseDetails
    let playerResults: [PlayerResult]
    
    // To track if we should navigate back to home
    @State private var navigateToHome = false
    
    init(matchId: String, course: GolfCourseSelectorViewModel.GolfCourseDetails, scores: [Int?]) {
        self.matchId = matchId
        self.course = course
        
        // For demo, create two player results with the actual scores and a dummy opponent
        let player1Scores = scores
        let player1Total = player1Scores.compactMap { $0 }.reduce(0, +)
        
        // Generate opponent scores that are slightly worse
        let player2Scores = player1Scores.map { score -> Int? in
            guard let score = score else { return nil }
            // Random chance to be same, worse, or better
            let variation = Int.random(in: -1...2)
            return max(1, score + variation)
        }
        let player2Total = player2Scores.compactMap { $0 }.reduce(0, +)
        
        // Determine winner
        let player1IsWinner = player1Total <= player2Total
        
        self.playerResults = [
            PlayerResult(
                id: "current_user",
                name: "Ed Park",
                initials: "EP",
                isPro: true,
                scores: player1Scores,
                totalScore: player1Total,
                isWinner: player1IsWinner
            ),
            PlayerResult(
                id: "opponent",
                name: "Jay Lee",
                initials: "JL",
                isPro: false,
                scores: player2Scores,
                totalScore: player2Total,
                isWinner: !player1IsWinner
            )
        ]
    }
    
    var body: some View {
        ZStack {
            // Background
            VStack(spacing: 0) {
                AppColors.primaryNavy
                    .frame(height: 160)
                AppColors.backgroundWhite
            }
            .ignoresSafeArea()
            
            // Content
            VStack(spacing: 0) {
                // Navigation bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("MATCH RESULTS")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(0.5)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 60)
                
                // Course name
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(course.clubName)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)
                        
                        if !course.courseName.isEmpty {
                            Text(course.courseName)
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Winner announcement
                if let winner = playerResults.first(where: { $0.isWinner }) {
                    winnerBanner(for: winner)
                        .padding(.top, 16)
                }
                
                // Player scorecards
                ScrollView {
                    VStack(spacing: 24) {
                        ForEach(playerResults, id: \.id) { player in
                            playerScorecard(player: player)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 100) // Space for the button
                }
                
                Spacer()
                
                // Return to home button
                Button(action: {
                    navigateToHome = true
                }) {
                    Text("BACK TO HOME")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppColors.highlightBlue)
                        .cornerRadius(28)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $navigateToHome) {
            // Navigate to the HomeView - this might need to be adjusted based on your app's structure
            HomeView()
        }
    }
    
    // MARK: - Components
    
    private func winnerBanner(for player: PlayerResult) -> some View {
        VStack(spacing: 12) {
            Text("CONGRATULATIONS!")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.highlightBlue)
            
            HStack(spacing: 12) {
                // Player avatar
                ZStack {
                    Circle()
                        .fill(AppColors.primaryNavy)
                        .frame(width: 52, height: 52)
                    
                    Text(player.initials)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    if player.isPro {
                        ZStack {
                            Circle()
                                .fill(Color.purple)
                                .frame(width: 20, height: 20)
                            
                            Text("P")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: 16, y: 16)
                    }
                }
                
                Text(player.name)
                    .font(.system(size: 18, weight: .bold))
                
                // Trophy icon
                Image(systemName: "trophy.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color.yellow)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow, lineWidth: 2)
                            .padding(1)
                    )
            )
        }
    }
    
    private func playerScorecard(player: PlayerResult) -> some View {
        VStack(spacing: 10) {
            // Player info and total score
            HStack {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Text(player.initials)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(AppColors.primaryNavy)
                        .clipShape(Circle())
                    
                    if player.isPro {
                        ZStack {
                            Circle()
                                .fill(Color.purple)
                                .frame(width: 18, height: 18)
                            
                            Text("P")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: 14, y: 14)
                    }
                }
                
                Text(player.name)
                    .font(.system(size: 17, weight: .bold))
                
                Spacer()
                
                // Total score
                Text("\(player.totalScore)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(player.isWinner ? Color.green : .black)
                    .padding(.trailing, 10)
            }
            
            // Score table
            VStack(spacing: 0) {
                scoreCardRows(player: player)
            }
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(player.isWinner ? Color.yellow : Color.gray.opacity(0.3), 
                           lineWidth: player.isWinner ? 2 : 1)
            )
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
    
    private func scoreCardRows(player: PlayerResult) -> some View {
        Group {
            // Title row
            HStack(spacing: 0) {
                Text("Hole")
                    .frame(width: 40, height: 30)
                    .background(AppColors.primaryNavy)
                    .foregroundColor(.white)
                
                // Front nine - Use integer literals for range
                ForEach(0..<9, id: \.self) { index in
                    Text("\(index + 1)")
                        .frame(width: 30, height: 30)
                        .background(AppColors.primaryNavy)
                        .foregroundColor(.white)
                }
            }
            .font(.system(.caption, design: .rounded))
            .fontWeight(.bold)
            
            // Par row
            if let tee = course.tees.first {
                HStack(spacing: 0) {
                    Text("Par")
                        .frame(width: 40, height: 30)
                        .background(Color.gray.opacity(0.1))
                    
                    // Front nine
                    ForEach(0..<min(9, tee.holes.count), id: \.self) { index in
                        Text("\(tee.holes[index].par)")
                            .frame(width: 30, height: 30)
                            .background(Color.gray.opacity(0.1))
                    }
                }
                .font(.system(.caption, design: .rounded))
            }
            
            // Score row
            HStack(spacing: 0) {
                Text("Score")
                    .frame(width: 40, height: 30)
                    .background(Color.white)
                
                // Front nine
                ForEach(0..<9, id: \.self) { index in
                    if let score = player.scores[index] {
                        Text("\(score)")
                            .frame(width: 30, height: 30)
                            .background(getScoreBackground(score: score, index: index))
                            .foregroundColor(.white)
                    } else {
                        Text("-")
                            .frame(width: 30, height: 30)
                            .background(Color.clear)
                            .foregroundColor(.gray)
                    }
                }
            }
            .font(.system(.caption, design: .rounded))
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
            // Back nine title row
            HStack(spacing: 0) {
                Text("Hole")
                    .frame(width: 40, height: 30)
                    .background(AppColors.primaryNavy)
                    .foregroundColor(.white)
                
                // Back nine - Use integer literals for range
                ForEach(9..<18, id: \.self) { index in
                    Text("\(index + 1)")
                        .frame(width: 30, height: 30)
                        .background(AppColors.primaryNavy)
                        .foregroundColor(.white)
                }
            }
            .font(.system(.caption, design: .rounded))
            .fontWeight(.bold)
            
            // Back nine par row
            if let tee = course.tees.first {
                HStack(spacing: 0) {
                    Text("Par")
                        .frame(width: 40, height: 30)
                        .background(Color.gray.opacity(0.1))
                    
                    // Back nine
                    ForEach(9..<min(18, tee.holes.count), id: \.self) { index in
                        Text("\(tee.holes[index].par)")
                            .frame(width: 30, height: 30)
                            .background(Color.gray.opacity(0.1))
                    }
                }
                .font(.system(.caption, design: .rounded))
            }
            
            // Back nine score row
            HStack(spacing: 0) {
                Text("Score")
                    .frame(width: 40, height: 30)
                    .background(Color.white)
                
                // Back nine
                ForEach(9..<18, id: \.self) { index in
                    if let score = player.scores[index] {
                        Text("\(score)")
                            .frame(width: 30, height: 30)
                            .background(getScoreBackground(score: score, index: index))
                            .foregroundColor(.white)
                    } else {
                        Text("-")
                            .frame(width: 30, height: 30)
                            .background(Color.clear)
                            .foregroundColor(.gray)
                    }
                }
            }
            .font(.system(.caption, design: .rounded))
        }
    }
    
    private func getScoreBackground(score: Int, index: Int) -> Color {
        guard course.tees.first?.holes.indices.contains(index) == true,
              let par = course.tees.first?.holes[index].par else {
            return .clear
        }
        
        switch score - par {
        case ..<0: // Birdie or better
            return .green
        case 0: // Par
            return AppColors.primaryNavy
        case 1: // Bogey
            return .orange
        default: // Double bogey or worse
            return .red
        }
    }
}

#Preview {
    // Create dummy scores for preview
    let scores: [Int?] = [4, 3, 5, 4, 3, 4, 5, 4, 3, 4, 5, 3, 4, 5, 4, 3, 4, 5]
    
    return MatchReviewView(
        matchId: "preview_match",
        course: GolfCourseSelectorViewModel.GolfCourseDetails(
            id: "preview",
            clubName: "Augusta National",
            courseName: "Championship Course",
            city: "Augusta",
            state: "GA",
            tees: [
                GolfCourseSelectorViewModel.TeeDetails(
                    type: "male",
                    teeName: "Blue",
                    courseRating: 72.5,
                    slopeRating: 132,
                    totalYards: 6832,
                    parTotal: 72,
                    holes: (0..<18).map { i in
                        let par = [4, 5, 4, 3, 4, 3, 4, 5, 4, 4, 5, 3, 4, 5, 3, 4, 4, 4][i]
                        return GolfCourseSelectorViewModel.HoleDetails(
                            number: i + 1,
                            par: par,
                            yardage: par == 3 ? 170 + (i * 5) : par == 5 ? 520 + (i * 7) : 380 + (i * 6),
                            handicap: i + 1
                        )
                    }
                )
            ]
        ),
        scores: scores
    )
} 