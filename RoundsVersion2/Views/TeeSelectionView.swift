import SwiftUI

struct TeeSelectionView: View {
    let course: GolfCourseSelectorViewModel.GolfCourseDetails
    let tees: [GolfCourseSelectorViewModel.TeeDetails]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTee: GolfCourseSelectorViewModel.TeeDetails? = nil
    @State private var showingRoundSetup = false
    let onTeeSelected: (GolfCourseSelectorViewModel.TeeDetails) -> Void
    
    // Initialize with a required callback and tees
    init(
        course: GolfCourseSelectorViewModel.GolfCourseDetails,
        tees: [GolfCourseSelectorViewModel.TeeDetails],
        onTeeSelected: @escaping (GolfCourseSelectorViewModel.TeeDetails) -> Void
    ) {
        self.course = course
        self.tees = tees
        self.onTeeSelected = onTeeSelected
        print("🔍 TeeSelectionView initialized with course: \(course.clubName)")
    }
    
    var body: some View {
        ZStack {
            // Main background
            Color(red: 0.95, green: 0.95, blue: 0.97).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navy blue header
                ZStack {
                    Color(red: 0.0, green: 75/255, blue: 143/255).ignoresSafeArea(edges: .top)
                    
                    VStack(spacing: 0) {
                        // Status bar space
                        Color.clear.frame(height: 44)
                        
                        // Navigation bar
                        HStack {
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20, weight: .semibold))
                            }
                            
                            Spacer()
                            
                            Text("SELECT TEES")
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .bold))
                                .tracking(0.5)
                            
                            Spacer()
                            
                            Button(action: {
                                // Menu action
                            }) {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                    }
                }
                .frame(height: 90)
                
                // Course name
                VStack(spacing: 0) {
                    Text(course.clubName.uppercased())
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.top, 24)
                        .padding(.bottom, 20)
                }
                
                // Tee selection list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(effectiveTees, id: \.teeName) { tee in
                            TeeCard(
                                tee: tee,
                                isSelected: selectedTee?.teeName == tee.teeName,
                                onTap: {
                                    selectedTee = tee
                                }
                            )
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 100) // Space for continue button
                }
                
                Spacer()
            }
            
            // Continue button fixed at bottom
            VStack {
                Spacer()
                
                Button(action: {
                    if selectedTee != nil {
                        showingRoundSetup = true
                    }
                }) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color(red: 0.0, green: 75/255, blue: 143/255))
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 34)
                }
                .disabled(selectedTee == nil)
                .opacity(selectedTee == nil ? 0.6 : 1.0)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingRoundSetup) {
            if let tee = selectedTee {
                NavigationStack {
                    RoundSetupFlowCoordinator(
                        course: course, 
                        tee: tee,
                        onComplete: { course, tee, settings in
                            onTeeSelected(tee)
                            showingRoundSetup = false
                        },
                        onCancel: {
                            showingRoundSetup = false
                        }
                    )
                }
            }
        }
    }
    
    // Use either provided tees or course tees
    private var effectiveTees: [GolfCourseSelectorViewModel.TeeDetails] {
        if !tees.isEmpty {
            return tees
        } else if !course.tees.isEmpty {
            return course.tees
        } else {
            // Fallback to sample tees matching the design
            return [
                .init(
                    type: "male",
                    teeName: "Black",
                    courseRating: 76.10,
                    slopeRating: 141,
                    totalYards: 7206,
                    parTotal: 72,
                    holes: []
                ),
                .init(
                    type: "male",
                    teeName: "Gold",
                    courseRating: 73.80,
                    slopeRating: 137,
                    totalYards: 6914,
                    parTotal: 72,
                    holes: []
                ),
                .init(
                    type: "male",
                    teeName: "White",
                    courseRating: 71.70,
                    slopeRating: 131,
                    totalYards: 6675,
                    parTotal: 72,
                    holes: []
                ),
                .init(
                    type: "male",
                    teeName: "Green",
                    courseRating: 69.83,
                    slopeRating: 125,
                    totalYards: 6432,
                    parTotal: 72,
                    holes: []
                ),
                .init(
                    type: "female",
                    teeName: "Red",
                    courseRating: 67.48,
                    slopeRating: 120,
                    totalYards: 5865,
                    parTotal: 72,
                    holes: []
                )
            ]
        }
    }
}

// Modern tee card component matching the design
struct TeeCard: View {
    let tee: GolfCourseSelectorViewModel.TeeDetails
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    // Tee name and yardage
                    Text("\(tee.teeName) - \(tee.totalYards) yards")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                    
                    // Rating and slope
                    HStack(spacing: 16) {
                        Text("Rating: \(String(format: "%.2f", tee.courseRating))")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text("Slope: \(tee.slopeRating)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Radio button
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color(red: 0.0, green: 75/255, blue: 143/255) : Color.gray.opacity(0.4), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color(red: 0.0, green: 75/255, blue: 143/255))
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(red: 0.0, green: 75/255, blue: 143/255) : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// RoundSetupFlowCoordinator to manage the flow between RoundSetupView and RoundConfirmView
struct RoundSetupFlowCoordinator: View {
    let course: GolfCourseSelectorViewModel.GolfCourseDetails
    let tee: GolfCourseSelectorViewModel.TeeDetails
    let onComplete: (GolfCourseSelectorViewModel.GolfCourseDetails, GolfCourseSelectorViewModel.TeeDetails, RoundSettings) -> Void
    let onCancel: () -> Void
    
    @State private var showingRoundSetup = true
    @State private var showingRoundConfirm = false
    @State private var roundSettings = RoundSettings(
        concedePutt: "2 Feet",
        puttingAssist: "On",
        greenSpeed: "Medium",
        windStrength: "Medium",
        mulligans: "1 per 9",
        caddyAssist: "On",
        startingHole: 1
    )
    
    var body: some View {
        ZStack {
            // This is the base layer that will dismiss the entire flow if tapped
            Color.black.opacity(0.001)
                .onTapGesture {
                    onCancel()
                }
            
            // Setup View
            if showingRoundSetup {
                RoundSetupView(onSetupComplete: { settings in
                    print("DEBUG: RoundSetup completed with settings")
                    roundSettings = settings
                    showingRoundSetup = false
                    showingRoundConfirm = true
                }, onCancel: {
                    print("DEBUG: RoundSetup cancelled")
                    onCancel()
                })
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
            
            // Confirm View
            if showingRoundConfirm {
                RoundConfirmView(
                    course: course,
                    tee: tee,
                    settings: roundSettings,
                    onConfirm: {
                        print("DEBUG: RoundConfirm completed")
                        // The updated settings with starting hole will be passed back
                        onComplete(course, tee, roundSettings)
                    }
                )
                .transition(.move(edge: .bottom))
                .zIndex(2)
            }
        }
        .ignoresSafeArea()
    }
}

struct TeeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TeeSelectionView(
                course: GolfCourseSelectorViewModel.GolfCourseDetails(
                    id: "sample_course",
                    clubName: "Gotham Golf Club",
                    courseName: "Main Course",
                    city: "Gotham",
                    state: "NY",
                    tees: []
                ),
                tees: [],
                onTeeSelected: { _ in 
                    // Empty callback for preview
                }
            )
        }
    }
} 