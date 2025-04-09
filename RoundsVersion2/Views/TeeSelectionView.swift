import SwiftUI

struct TeeSelectionView: View {
    let course: GolfCourseSelectorViewModel.GolfCourseDetails
    let tees: [GolfCourseSelectorViewModel.TeeDetails]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTeeId: String? = nil
    @State private var selectedTee: GolfCourseSelectorViewModel.TeeDetails? = nil
    @State private var showingRoundSetup = false
    @State private var debugMessage = ""
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
        VStack {
            // Course name header
            Text(course.clubName.uppercased())
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.gray)
                .padding(.vertical, 16)
            
            // Debug message with visible display
            Text(debugMessage.isEmpty ? "Waiting for selection..." : debugMessage)
                .font(.system(size: 14))
                .foregroundColor(debugMessage.isEmpty ? .gray : .red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            
            // List of tees using native selection
            List(effectiveTees, id: \.teeName, selection: $selectedTeeId) { tee in
                TeeRow(tee: tee, isSelected: selectedTeeId == tee.teeName)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("🟡 Direct tap on tee row: \(tee.teeName)")
                        debugMessage = "Selected: \(tee.teeName)"
                        selectTee(tee)
                    }
            }
            .listStyle(PlainListStyle())
            
            // Continue button appears when a tee is selected
            if let selectedTee = selectedTee {
                Button(action: {
                    print("🚀 Continue button pressed with tee: \(selectedTee.teeName)")
                    debugMessage = "Showing Round Setup as full-screen sheet"
                    showingRoundSetup = true
                }) {
                    Text("Continue with \(selectedTee.teeName) Tees")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primaryNavy)
                        .cornerRadius(10)
                        .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    debugMessage = "Back button pressed"
                    print("🔵 NAVIGATION: Back button pressed")
                    dismiss()
                }
            }
        }
        .onChange(of: selectedTeeId) { _, newValue in
            if let teeId = newValue {
                print("🟡 selectedTeeId changed to: \(teeId)")
                if let tee = effectiveTees.first(where: { $0.teeName == teeId }) {
                    selectedTee = tee
                }
            }
        }
        .onChange(of: showingRoundSetup) { oldValue, newValue in
            print("🔵 showingRoundSetup changed from \(oldValue) to \(newValue)")
        }
        .onAppear {
            print("🟢 TeeSelectionView appeared with \(course.tees.count) real tees")
            print("🟢 Using effectiveTees with \(effectiveTees.count) tees")
            debugMessage = "Select a tee to continue"
        }
        // Present RoundSetupView as a full-screen sheet
        .fullScreenCover(isPresented: $showingRoundSetup) {
            if let tee = selectedTee {
                NavigationStack {
                    RoundSetupFlowCoordinator(
                        course: course, 
                        tee: tee,
                        onComplete: { course, tee, settings in
                            // Process final settings and call the original callback
                            print("🏁 Round setup flow completed with settings")
                            onTeeSelected(tee)
                            showingRoundSetup = false
                        },
                        onCancel: {
                            showingRoundSetup = false
                        }
                    )
                }
            } else {
                Text("Error: No tee selected")
                    .onAppear {
                        print("❌ ERROR: Attempted to show RoundSetupView but selectedTee is nil")
                        showingRoundSetup = false
                    }
            }
        }
    }
    
    private func selectTee(_ tee: GolfCourseSelectorViewModel.TeeDetails) {
        print("🟡 selectTee called with: \(tee.teeName)")
        selectedTeeId = tee.teeName
        selectedTee = tee
    }
    
    // Use either provided tees or course tees
    private var effectiveTees: [GolfCourseSelectorViewModel.TeeDetails] {
        if !tees.isEmpty {
            return tees
        } else if !course.tees.isEmpty {
            return course.tees
        } else {
            // Fallback to sample tees in case both are empty
            return [
                .init(
                    type: "male",
                    teeName: "Blue",
                    courseRating: 72.5,
                    slopeRating: 132,
                    totalYards: 6832,
                    parTotal: 72,
                    holes: []
                ),
                .init(
                    type: "male",
                    teeName: "White", 
                    courseRating: 71.2,
                    slopeRating: 128,
                    totalYards: 6435,
                    parTotal: 72,
                    holes: []
                ),
                .init(
                    type: "female",
                    teeName: "Red",
                    courseRating: 69.8, 
                    slopeRating: 120,
                    totalYards: 5790,
                    parTotal: 72,
                    holes: []
                )
            ]
        }
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

// Simple row for the list
struct TeeRow: View {
    let tee: GolfCourseSelectorViewModel.TeeDetails
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(tee.teeName) - \(tee.totalYards) yards")
                    .font(.headline)
                
                HStack {
                    Text("Rating: \(String(format: "%.1f", tee.courseRating))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("•")
                        .foregroundColor(.gray)
                    
                    Text("Slope: \(tee.slopeRating)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(AppColors.primaryNavy)
            }
        }
        .padding(.vertical, 8)
        .background(isSelected ? Color.gray.opacity(0.1) : Color.clear)
        .cornerRadius(8)
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
                    tees: [] // Empty tees array is valid, our view has logic to handle it
                ),
                tees: [],
                onTeeSelected: { _ in 
                    // Empty callback for preview
                }
            )
        }
    }
} 