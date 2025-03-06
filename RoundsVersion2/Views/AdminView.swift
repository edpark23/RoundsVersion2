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
                            Button(action: {
                                Task {
                                    await viewModel.fetchGolfCourses()
                                }
                            }) {
                                HStack {
                                    Text("Fetch Golf Courses")
                                    Spacer()
                                    if viewModel.isLoading {
                                        ProgressView()
                                    }
                                }
                            }
                            .disabled(viewModel.isLoading)
                            
                            if !viewModel.courses.isEmpty {
                                Text("\(viewModel.courses.count) courses stored")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Section("Stored Courses") {
                            ForEach(viewModel.courses) { course in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(course.name)
                                        .font(.headline)
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
                    .listStyle(InsetGroupedListStyle())
                    
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