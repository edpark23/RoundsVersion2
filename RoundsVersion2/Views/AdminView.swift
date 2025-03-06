import SwiftUI

struct AdminView: View {
    @StateObject private var viewModel = AdminViewModel()
    @EnvironmentObject private var mainViewModel: MainViewModel
    
    var body: some View {
        NavigationStack {
            VStack {
                if mainViewModel.userProfile?.isAdmin == true {
                    List {
                        Section("Golf Course Data") {
                            NavigationLink(destination: CourseImportView()) {
                                Label("Import Golf Courses", systemImage: "arrow.down.doc")
                            }
                            
                            if viewModel.isLoading {
                                HStack {
                                    Text("Loading courses...")
                                    Spacer()
                                    ProgressView()
                                }
                            } else if !viewModel.courses.isEmpty {
                                Text("\(viewModel.courses.count) courses stored")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if !viewModel.courses.isEmpty {
                            Section("Stored Courses") {
                                ForEach(viewModel.courses) { course in
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
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .refreshable {
                        await viewModel.loadStoredCourses()
                    }
                    
                    if let error = viewModel.error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                    }
                } else {
                    ContentUnavailableView(
                        "Admin Access Required",
                        systemImage: "lock.fill",
                        description: Text("You need admin privileges to access this section.")
                    )
                }
            }
            .navigationTitle("Admin")
            .task {
                await viewModel.loadStoredCourses()
            }
        }
    }
} 