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
    @State private var hasAttemptedInitialLoad = false
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
                        if viewModel.isLoading && viewModel.courses.isEmpty {
                            // Loading indicator
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(Color(red: 0.0, green: 75/255, blue: 143/255))
                                
                                Text("Loading golf courses...")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else if viewModel.courses.isEmpty && !viewModel.isLoading {
                            // Empty state
                            VStack(spacing: 16) {
                                Image(systemName: "golf.tee")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray.opacity(0.6))
                                
                                Text("No golf courses found")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                Text("Please check your connection and try again")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                
                                Button("Retry") {
                                    Task {
                                        await viewModel.resetAndReload()
                                    }
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 0.0, green: 75/255, blue: 143/255))
                                .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
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
                            
                            // Load more button if there are more courses
                            if viewModel.hasMoreCourses {
                                Button(action: {
                                    Task {
                                        await viewModel.loadMoreCoursesIfNeeded()
                                    }
                                }) {
                                    HStack {
                                        if viewModel.isLoading {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .tint(.white)
                                        }
                                        Text(viewModel.isLoading ? "Loading..." : "Load More Courses")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(Color(red: 0.0, green: 75/255, blue: 143/255).opacity(0.7))
                                    .cornerRadius(18)
                                }
                                .disabled(viewModel.isLoading)
                                .padding(.horizontal, 32)
                                .padding(.top, 16)
                                .padding(.bottom, 20)
                            }
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 120) // Increased space for the continue button
                }
                
                Spacer()
            }
            
            // Continue button fixed at bottom with enhanced visibility
            VStack {
                Spacer()
                
                // Background overlay to ensure button visibility
                VStack(spacing: 0) {
                    // Gradient fade overlay
                    LinearGradient(
                        colors: [Color.clear, Color(red: 0.95, green: 0.95, blue: 0.97).opacity(0.8), Color(red: 0.95, green: 0.95, blue: 0.97)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 30)
                    
                    // Solid background for button area
                    Color(red: 0.95, green: 0.95, blue: 0.97)
                        .frame(height: 80)
                }
                .overlay(
                    // Continue button
                    Button(action: {
                        if selectedCourse != nil {
                            showingTeeSelection = true
                        }
                    }) {
                        Text("CONTINUE")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                Capsule()
                                    .fill(Color(red: 0.0, green: 75/255, blue: 143/255))
                                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                            )
                            .padding(.horizontal, 16)
                    }
                    .disabled(selectedCourse == nil)
                    .opacity(selectedCourse == nil ? 0.7 : 1.0)
                    .scaleEffect(selectedCourse != nil ? 1.0 : 0.95)
                    .animation(.easeInOut(duration: 0.2), value: selectedCourse != nil)
                    .padding(.bottom, 20)
                )
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
            print("🎯 GolfCourseSelectorView appeared. Courses count: \(viewModel.courses.count), isLoading: \(viewModel.isLoading), hasAttemptedLoad: \(hasAttemptedInitialLoad)")
        }
        .task {
            // The ViewModel now handles loading via auth state listener
            // But we can still trigger a manual load if needed
            if !hasAttemptedInitialLoad {
                print("🎯 GolfCourseSelectorView: Checking if manual load needed...")
                hasAttemptedInitialLoad = true
                
                // Only load manually if auth listener hasn't triggered yet
                if viewModel.courses.isEmpty && !viewModel.isLoading {
                    print("🎯 GolfCourseSelectorView: Triggering manual load...")
                    await viewModel.loadCourses()
                }
                print("🎯 GolfCourseSelectorView: Initial setup completed")
            } else {
                print("🎯 GolfCourseSelectorView: Initial load already attempted, skipping")
            }
        }
        .alert("Error Loading Courses", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
            Button("Retry") {
                Task {
                    await viewModel.resetAndReload()
                }
            }
        } message: {
            Text(viewModel.error ?? "")
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