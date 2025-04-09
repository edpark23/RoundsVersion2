import SwiftUI

// Keep the FullScreenCover enum for navigation flow
enum FullScreenCover: Identifiable {
    case roundSetupFlow(RoundSetupFlowCoordinator)
    
    var id: String {
        switch self {
        case .roundSetupFlow:
            return "roundSetupFlow"
        }
    }
}

struct FullScreenCoverModifier: ViewModifier {
    @Binding var item: FullScreenCover?
    
    func body(content: Content) -> some View {
        content
            .fullScreenCover(item: $item) { cover in
                switch cover {
                case .roundSetupFlow(let coordinator):
                    coordinator
                }
            }
    }
}

extension View {
    func fullScreenCover(item: Binding<FullScreenCover?>) -> some View {
        self.modifier(FullScreenCoverModifier(item: item))
    }
}

struct GolfCourseSelectorView: View {
    @ObservedObject var viewModel: GolfCourseSelectorViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedFilter = "Nearby"
    @State private var selectedCourse: GolfCourseSelectorViewModel.GolfCourseDetails?
    @State private var showingTeeSelection = false
    @State private var fullScreenCover: FullScreenCover?
    @State private var loadedTees: [GolfCourseSelectorViewModel.TeeDetails] = []
    var onCourseAndTeeSelected: ((GolfCourseSelectorViewModel.GolfCourseDetails, GolfCourseSelectorViewModel.TeeDetails, RoundSettings) -> Void)?
    
    // Keep existing initializers for compatibility
    init(completion: @escaping (GolfCourseSelectorViewModel.GolfCourseDetails, GolfCourseSelectorViewModel.TeeDetails) -> Void) {
        self.viewModel = GolfCourseSelectorViewModel()
        self.onCourseAndTeeSelected = { course, tee, settings in
            completion(course, tee)
        }
    }
    
    init(viewModel: GolfCourseSelectorViewModel, 
         onCourseAndTeeSelected: ((GolfCourseSelectorViewModel.GolfCourseDetails, GolfCourseSelectorViewModel.TeeDetails, RoundSettings) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onCourseAndTeeSelected = onCourseAndTeeSelected
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
                            
                            Text("SELECT COURSE")
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .bold))
                                .tracking(0.5)
                            
                            Spacer()
                            
                            Button(action: {
                                // Profile action
                            }) {
                                Image(systemName: "person.crop.circle")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                    }
                }
                .frame(height: 90)
                
                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray.opacity(0.6))
                        .font(.system(size: 16))
                        .padding(.leading, 14)
                    
                    TextField("Search course by name", text: $searchText)
                        .font(.system(size: 16))
                        .padding(.vertical, 12)
                    
                    Spacer()
                    
                    Image(systemName: "mic.fill")
                        .foregroundColor(.gray.opacity(0.6))
                        .font(.system(size: 16))
                        .padding(.trailing, 14)
                }
                .background(Color(UIColor.systemGray6))
                .cornerRadius(25)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Filter tabs
                ZStack {
                    // Background capsule
                    Capsule()
                        .fill(Color(UIColor.systemGray6))
                        .frame(height: 40)
                    
                    HStack(spacing: 0) {
                        ForEach(["Nearby", "Recently Played", "My Courses"], id: \.self) { filter in
                            Button(action: {
                                selectedFilter = filter
                            }) {
                                Text(filter)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(selectedFilter == filter ? .white : .black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(
                                        selectedFilter == filter ?
                                        Capsule().fill(Color(red: 0.3, green: 0.5, blue: 0.7)) :
                                        Capsule().fill(Color.clear)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 3)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // Course list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.courses, id: \.id) { course in
                            Button(action: {
                                selectedCourse = course
                                loadTees(for: course)
                            }) {
                                CourseCard(
                                    courseName: course.clubName,
                                    distance: mockDistance(),
                                    location: "\(course.city), \(course.state)",
                                    rating: mockRating(),
                                    isSelected: selectedCourse?.id == course.id
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 90) // Space for the continue button
                }
                
                Spacer()
            }
            
            // Continue button fixed at bottom
            VStack {
                Spacer()
                
                Button(action: {
                    if selectedCourse != nil {
                        showingTeeSelection = true
                    }
                }) {
                    Text("CONTINUE")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.0, green: 75/255, blue: 143/255))
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                }
                .disabled(selectedCourse == nil)
                .opacity(selectedCourse == nil ? 0.7 : 1.0)
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showingTeeSelection) {
            if let course = selectedCourse {
                TeeSelectionView(
                    course: course,
                    tees: loadedTees,
                    onTeeSelected: { selectedTee in
                        fullScreenCover = .roundSetupFlow(
                            RoundSetupFlowCoordinator(
                                course: course, 
                                tee: selectedTee,
                                onComplete: { course, tee, settings in
                                    onCourseAndTeeSelected?(course, tee, settings)
                                    fullScreenCover = nil
                                    dismiss()
                                },
                                onCancel: {
                                    fullScreenCover = nil
                                }
                            )
                        )
                    }
                )
            }
        }
        .fullScreenCover(item: $fullScreenCover)
        .onAppear {
            // Load some sample courses if empty
            if viewModel.courses.isEmpty {
                loadSampleCourses()
            }
        }
    }
    
    private func loadTees(for course: GolfCourseSelectorViewModel.GolfCourseDetails) {
        // Sample tees data
        loadedTees = [
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
    
    // Helper function to generate mock distance
    private func mockDistance() -> String {
        let distance = Double.random(in: 3.0...9.0)
        return String(format: "%.1f miles", distance)
    }
    
    // Helper function to generate mock rating
    private func mockRating() -> Double {
        return Double(Int.random(in: 38...48)) / 10.0 // Generates 3.8 to 4.8
    }
    
    // Load sample courses for preview/testing
    private func loadSampleCourses() {
        // This would normally fetch from a database
        if viewModel.courses.isEmpty {
            let sampleCourses = [
                GolfCourseSelectorViewModel.GolfCourseDetails(
                    id: "1",
                    clubName: "Gotham Golf Club",
                    courseName: "Gotham Course",
                    city: "Augusta City",
                    state: "NY",
                    tees: []
                ),
                GolfCourseSelectorViewModel.GolfCourseDetails(
                    id: "2",
                    clubName: "Augusta Links",
                    courseName: "Augusta Course",
                    city: "Augusta City",
                    state: "NY",
                    tees: []
                ),
                GolfCourseSelectorViewModel.GolfCourseDetails(
                    id: "3",
                    clubName: "National Port Club",
                    courseName: "National Course",
                    city: "Long Brook",
                    state: "NY",
                    tees: []
                ),
                GolfCourseSelectorViewModel.GolfCourseDetails(
                    id: "4",
                    clubName: "West Port Golf Course",
                    courseName: "West Port Course",
                    city: "Long Brook",
                    state: "NY",
                    tees: []
                ),
                GolfCourseSelectorViewModel.GolfCourseDetails(
                    id: "5",
                    clubName: "Van Houston Interlinks Golf Course",
                    courseName: "Van Houston Course",
                    city: "Long Brook",
                    state: "NY",
                    tees: []
                )
            ]
            
            // In a real implementation, this would be done through the ViewModel properly
            // For demo purposes only:
            viewModel.courses = sampleCourses
        }
    }
}

// Course card view that matches the design in the image
struct CourseCard: View {
    let courseName: String
    let distance: String
    let location: String
    let rating: Double
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Course name
                Text(courseName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                
                // Distance and location
                HStack(spacing: 4) {
                    Text(distance)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    
                    Text("|")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    
                    Text(location)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                // Rating
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                }
            }
            
            Spacer()
            
            // Selection circle
            ZStack {
                Circle()
                    .stroke(isSelected ? Color(red: 0.0, green: 75/255, blue: 143/255) : Color.gray.opacity(0.6), lineWidth: 1.5)
                    .frame(width: 26, height: 26)
                
                if isSelected {
                    Circle()
                        .fill(Color(red: 0.0, green: 75/255, blue: 143/255))
                        .frame(width: 18, height: 18)
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color(red: 0.0, green: 75/255, blue: 143/255) : Color.clear, lineWidth: isSelected ? 1.5 : 0)
        )
    }
} 