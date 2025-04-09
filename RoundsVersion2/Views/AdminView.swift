import SwiftUI

struct AdminView: View {
    @StateObject private var viewModel = AdminViewModel()
    @EnvironmentObject private var mainViewModel: MainViewModel
    
    var body: some View {
        NavigationStack {
            Group {
                if mainViewModel.userProfile?.isAdmin == true {
                    adminContent
                } else {
                    noAccessContent
                }
            }
            .navigationTitle("Admin")
            .task {
                await viewModel.loadStoredCourses()
            }
        }
    }
    
    // MARK: - Component Views
    
    private var adminContent: some View {
        VStack {
            coursesList
            
            if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }
        }
    }
    
    private var coursesList: some View {
        List {
            coursesDataSection
            storedCoursesSection
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var coursesDataSection: some View {
        Section("Golf Course Data") {
            NavigationLink(destination: CourseImportView()) {
                Label("Import Golf Courses", systemImage: "arrow.down.doc")
            }
            
            if !viewModel.courses.isEmpty {
                Text("\(viewModel.courses.count) courses stored")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var storedCoursesSection: some View {
        Section("Stored Courses") {
            ForEach(viewModel.courses, id: \.id) { course in
                courseRow(course: course)
            }
        }
    }
    
    private func courseRow(course: AdminViewModel.StoredCourse) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(course.clubName)
                .font(.headline)
            if !course.courseName.isEmpty {
                Text(course.courseName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Text("\(course.city), \(course.state)")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text("Last updated: \(course.lastUpdated.formatted())")
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
    
    private var noAccessContent: some View {
        ContentUnavailableView(
            "Admin Access Required",
            systemImage: "lock.fill",
            description: Text("You need admin privileges to access this section.")
        )
    }
} 