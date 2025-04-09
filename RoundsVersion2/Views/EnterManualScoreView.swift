import SwiftUI

struct EnterManualScoreView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ScoreVerificationViewModel()
    let matchId: String
    let selectedCourse: GolfCourseSelectorViewModel.GolfCourseDetails
    
    @State private var currentHole = 1
    @State private var scores: [Int?] = Array(repeating: nil, count: 18)
    @State private var isEnteringScore = false
    @State private var tempScore: String = ""
    // Create a state to hold the processed course with complete hole data
    @State private var processedCourse: GolfCourseSelectorViewModel.GolfCourseDetails
    @State private var isShowingMatchReview = false
    
    // Initialize with proper course data
    init(matchId: String, selectedCourse: GolfCourseSelectorViewModel.GolfCourseDetails) {
        self.matchId = matchId
        self.selectedCourse = selectedCourse
        
        // Process the course to ensure it has complete hole data
        var processedCourse = selectedCourse
        
        // If the course has no tees or the tees have no holes, create sample data
        if processedCourse.tees.isEmpty || processedCourse.tees.first?.holes.isEmpty == true {
            var tees = processedCourse.tees
            
            // If tees array is empty, add a default tee
            if tees.isEmpty {
                tees = [GolfCourseSelectorViewModel.TeeDetails(
                    type: "male",
                    teeName: "White",
                    courseRating: 72.0,
                    slopeRating: 130,
                    totalYards: 6500,
                    parTotal: 72,
                    holes: []
                )]
            }
            
            // Update holes for each tee if they don't have any
            tees = tees.map { tee in
                var updatedTee = tee
                
                // If holes array is empty, create sample holes
                if updatedTee.holes.isEmpty {
                    var sampleHoles = [GolfCourseSelectorViewModel.HoleDetails]()
                    
                    // Create 18 sample holes with reasonable data
                    for i in 1...18 {
                        let par = [3, 4, 4, 5, 4, 3, 4, 5, 4, 4, 3, 4, 5, 4, 3, 4, 4, 5][i-1] // Common par distribution
                        let yardage = par == 3 ? 170 + (i * 5) : par == 5 ? 520 + (i * 7) : 380 + (i * 6)
                        let handicap = [13, 7, 3, 1, 15, 11, 9, 5, 17, 14, 8, 2, 4, 16, 12, 10, 6, 18][i-1] // Common handicap distribution
                        
                        sampleHoles.append(GolfCourseSelectorViewModel.HoleDetails(
                            number: i,
                            par: par,
                            yardage: yardage,
                            handicap: handicap
                        ))
                    }
                    
                    updatedTee = GolfCourseSelectorViewModel.TeeDetails(
                        type: tee.type,
                        teeName: tee.teeName,
                        courseRating: tee.courseRating,
                        slopeRating: tee.slopeRating,
                        totalYards: tee.totalYards,
                        parTotal: tee.parTotal,
                        holes: sampleHoles
                    )
                }
                
                return updatedTee
            }
            
            // Create the updated course with complete hole data
            processedCourse = GolfCourseSelectorViewModel.GolfCourseDetails(
                id: processedCourse.id,
                clubName: processedCourse.clubName,
                courseName: processedCourse.courseName,
                city: processedCourse.city,
                state: processedCourse.state,
                tees: tees
            )
        }
        
        // Use _processedCourse to initialize the @State property
        _processedCourse = State(initialValue: processedCourse)
    }
    
    // Log the course structure when view appears
    private func logCourseStructure() {
        print("=== COURSE STRUCTURE ===")
        print("Course club name: \(processedCourse.clubName)")
        print("Course name: \(processedCourse.courseName)")
        print("Number of tees: \(processedCourse.tees.count)")
        
        if let firstTee = processedCourse.tees.first {
            print("First tee name: \(firstTee.teeName)")
            print("Number of holes: \(firstTee.holes.count)")
            
            for (index, hole) in firstTee.holes.enumerated() {
                print("Hole \(index+1): Par \(hole.par), Yards \(hole.yardage), Handicap \(hole.handicap)")
            }
        } else {
            print("No tees available in the course")
        }
    }
    
    var body: some View {
        ZStack {
            backgroundLayer
            
            VStack(spacing: 0) {
                navigationBar
                courseNameSection
                scorecardSummary
                holeInfoCard
                playerSection
                
                Spacer()
                
                if !scores.contains(nil) {
                    submitButton
                }
            }
            
            // Use an overlay instead of sheet to avoid dismissal issues
            if isEnteringScore {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Optional: Allow tapping outside to dismiss
                        // isEnteringScore = false
                    }
                
                NumberPadView(
                    currentHole: currentHole,
                    tempScore: $tempScore,
                    isEnteringScore: $isEnteringScore,
                    onScoreSubmit: { score in
                        // Update score for current hole
                        scores[currentHole - 1] = score
                        
                        // Explicitly refresh the UI by creating a new array
                        let updatedScores = scores
                        scores = updatedScores
                        
                        // Move to next hole if available
                        if currentHole < 18 {
                            currentHole += 1
                        }
                    }
                )
                .transition(.move(edge: .bottom))
                .background(Color.white)
                .cornerRadius(16)
                .shadow(radius: 10)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, maxHeight: 400)
                .position(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height - 200)
            }
        }
        .navigationBarHidden(true)
        .animation(.easeInOut, value: isEnteringScore)
        .onAppear {
            logCourseStructure()
        }
        .fullScreenCover(isPresented: $isShowingMatchReview) {
            MatchReviewView(
                matchId: matchId,
                course: processedCourse,
                scores: scores
            )
        }
    }
    
    // MARK: - View Components
    
    private var backgroundLayer: some View {
        VStack(spacing: 0) {
            AppColors.primaryNavy
                .frame(height: 160)
            AppColors.backgroundWhite
        }
        .ignoresSafeArea()
    }
    
    private var navigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("SCORECARD")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .tracking(0.5)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
        .padding(.top, 60)
    }
    
    private var courseNameSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(processedCourse.clubName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                
                if !processedCourse.courseName.isEmpty {
                    Text(processedCourse.courseName)
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var scorecardSummary: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 0) {
                scoreCardHeaderRow
                scoreCardParRow
                scoreCardScoreRow
            }
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .id("scorecard-\(scores.compactMap{$0}.count)") // Force refresh when score count changes
    }
    
    private var scoreCardHeaderRow: some View {
        HStack(spacing: 0) {
            Text("Hole")
                .frame(width: 40, height: 30)
                .background(AppColors.primaryNavy)
                .foregroundColor(.white)
            
            ForEach(0..<18, id: \.self) { index in
                Text("\(index + 1)")
                    .frame(width: 30, height: 30)
                    .background(index + 1 == currentHole ? AppColors.highlightBlue : AppColors.primaryNavy)
                    .foregroundColor(.white)
            }
        }
        .font(.system(.caption, design: .rounded))
        .fontWeight(.bold)
    }
    
    private var scoreCardParRow: some View {
        Group {
            if let tee = processedCourse.tees.first {
                HStack(spacing: 0) {
                    Text("Par")
                        .frame(width: 40, height: 30)
                        .background(Color.gray.opacity(0.1))
                    
                    ForEach(0..<min(tee.holes.count, 18), id: \.self) { index in
                        Text("\(tee.holes[index].par)")
                            .frame(width: 30, height: 30)
                            .background(Color.gray.opacity(0.1))
                    }
                }
                .font(.system(.caption, design: .rounded))
            }
        }
    }
    
    private var scoreCardScoreRow: some View {
        HStack(spacing: 0) {
            Text("Score")
                .frame(width: 40, height: 30)
                .background(AppColors.backgroundWhite)
            
            ForEach(0..<18, id: \.self) { index in
                if let score = scores[index] {
                    Text("\(score)")
                        .frame(width: 30, height: 30)
                        .background(getScoreBackground(for: index))
                        .foregroundColor(.white)
                } else {
                    Text("-")
                        .frame(width: 30, height: 30)
                        .background(.clear)
                        .foregroundColor(.gray)
                }
            }
        }
        .font(.system(.caption, design: .rounded))
    }
    
    private var holeInfoCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("\(currentHole)")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 120, alignment: .leading)
                
                ForEach(0..<3, id: \.self) { index in
                    if index > 0 {
                        Divider()
                            .frame(height: 40)
                            .background(Color.gray.opacity(0.3))
                    }
                    
                    holeDetailItem(index: index)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .id(currentHole) // Force refresh when current hole changes
    }
    
    private func holeDetailItem(index: Int) -> some View {
        // Get the current hole data from the processed course
        let holeIndex = currentHole - 1
        let tee = processedCourse.tees.first
        let hole = tee?.holes.indices.contains(holeIndex) == true ? tee?.holes[holeIndex] : nil
        
        let text: String
        switch index {
        case 0: text = "Par \(hole?.par ?? 0)"
        case 1: text = "\(hole?.yardage ?? 0) yards"
        case 2: text = "HI: \(hole?.handicap ?? 0)"
        default: text = ""
        }
        
        return Text(text)
            .font(.system(size: 17))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
    }
    
    private var playerSection: some View {
        HStack(spacing: 12) {
            playerProfile
            
            Text("TIGAWOODSYAW")
                .font(.system(size: 16, weight: .bold))
            
            // Calculate and show current score vs par
            calculateScoreVsPar()
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.gray)
            
            Spacer()
            
            scoreEntryButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }
    
    private func calculateScoreVsPar() -> some View {
        // Calculate running score vs par using correct golf scoring logic
        var runningScore = 0
        
        // For each hole with a score, calculate (score - par) and add to running total
        for index in 0..<scores.count {
            if let score = scores[index],
               processedCourse.tees.first?.holes.indices.contains(index) == true,
               let par = processedCourse.tees.first?.holes[index].par {
                // For golf scoring: positive is above par (bad), negative is below par (good)
                runningScore += (score - par)
            }
        }
        
        // Format the score text
        let scoreText: String
        if scores.compactMap({ $0 }).isEmpty {
            scoreText = "E" // Even par when no scores
        } else if runningScore == 0 {
            scoreText = "E" // Even par
        } else if runningScore > 0 {
            scoreText = "+\(runningScore)" // Over par (bad)
        } else {
            scoreText = "\(runningScore)" // Under par (good)
        }
        
        return Text(scoreText)
    }
    
    private var playerProfile: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 40)
            
            Text("EP")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(AppColors.primaryNavy)
                .clipShape(Circle())
            
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
    }
    
    private var scoreEntryButton: some View {
        Button(action: {
            tempScore = ""
            isEnteringScore = true
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(width: 120, height: 80)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                
                if let score = scores[currentHole - 1] {
                    Text("\(score)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                } else {
                    VStack(spacing: 4) {
                        Text("Enter")
                            .font(.system(size: 17))
                        Text("Score")
                            .font(.system(size: 17))
                    }
                    .foregroundColor(Color.gray.opacity(0.5))
                }
            }
        }
    }
    
    private var submitButton: some View {
        Button(action: {
            submitScores()
        }) {
            Text("SUBMIT ROUND")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(AppColors.highlightBlue)
                .cornerRadius(28)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
    }
    
    private func getScoreBackground(for index: Int) -> Color {
        guard let score = scores[index],
              processedCourse.tees.first?.holes.indices.contains(index) == true,
              let par = processedCourse.tees.first?.holes[index].par else {
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
    
    private func submitScores() {
        let finalScores = scores.compactMap { $0 }
        viewModel.setManualScores(finalScores.map(String.init).joined(separator: ","))
        
        // Instead of dismissing, navigate to the Match Review view
        // Only show the review if we have scores
        if !scores.contains(nil) {
            Task {
                await viewModel.submitScores(matchId: matchId)
                
                // Present the match review view
                isShowingMatchReview = true
            }
        }
    }
}

// MARK: - Number Pad View
struct NumberPadView: View {
    let currentHole: Int
    @Binding var tempScore: String
    @Binding var isEnteringScore: Bool
    let onScoreSubmit: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Score for Hole \(currentHole)")
                .font(.headline)
                .padding(.top)
            
            if !tempScore.isEmpty {
                Text(tempScore)
                    .font(.system(size: 36, weight: .bold))
            }
            
            VStack(spacing: 15) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 15) {
                        ForEach(1...3, id: \.self) { col in
                            numberButton(number: row * 3 + col)
                        }
                    }
                }
                
                HStack(spacing: 15) {
                    deleteButton
                    numberButton(number: 0)
                    submitButton
                }
            }
            .padding()
            
            // Add a clear confirmation button
            Button(action: {
                if let score = Int(tempScore), !tempScore.isEmpty {
                    onScoreSubmit(score)
                    tempScore = ""
                    isEnteringScore = false
                }
            }) {
                Text("CONFIRM SCORE")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(tempScore.isEmpty ? Color.gray : AppColors.highlightBlue)
                    .cornerRadius(25)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
            }
            .disabled(tempScore.isEmpty)
        }
    }
    
    private func numberButton(number: Int) -> some View {
        Button(action: {
            if tempScore.count < 2 {
                tempScore += "\(number)"
            }
        }) {
            Text("\(number)")
                .font(.system(size: 24, weight: .medium))
                .frame(width: 70, height: 70)
                .background(Color.white)
                .cornerRadius(35)
        }
    }
    
    private var deleteButton: some View {
        Button(action: {
            if !tempScore.isEmpty {
                tempScore.removeLast()
            }
        }) {
            Image(systemName: "delete.left")
                .font(.system(size: 24, weight: .medium))
                .frame(width: 70, height: 70)
                .background(Color.white)
                .cornerRadius(35)
        }
    }
    
    private var submitButton: some View {
        Button(action: {
            if let score = Int(tempScore) {
                onScoreSubmit(score)
                tempScore = ""
                isEnteringScore = false
            }
        }) {
            Image(systemName: "checkmark")
                .font(.system(size: 24, weight: .medium))
                .frame(width: 70, height: 70)
                .background(AppColors.primaryNavy)
                .foregroundColor(.white)
                .cornerRadius(35)
        }
        .disabled(tempScore.isEmpty)
    }
}

#Preview {
    NavigationView {
        EnterManualScoreView(
            matchId: "test_match",
            selectedCourse: GolfCourseSelectorViewModel.GolfCourseDetails(
                id: "test",
                clubName: "Gotham Golf Club",
                courseName: "Main Course",
                city: "Gotham",
                state: "NY",
                tees: [
                    GolfCourseSelectorViewModel.TeeDetails(
                        type: "male",
                        teeName: "Blue",
                        courseRating: 72.5,
                        slopeRating: 132,
                        totalYards: 6832,
                        parTotal: 72,
                        holes: Array(repeating: GolfCourseSelectorViewModel.HoleDetails(
                            number: 1,
                            par: 4,
                            yardage: 412,
                            handicap: 13
                        ), count: 18)
                    )
                ]
            )
        )
    }
} 