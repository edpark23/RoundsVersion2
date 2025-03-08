import SwiftUI

struct GolfCourseSelectorView: View {
    @StateObject private var viewModel = GolfCourseSelectorViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCourseId: String?
    @State private var isSelectingCourse = false
    @State private var searchText = ""
    var onCourseSelected: ((GolfCourseSelectorViewModel.GolfCourseDetails) -> Void)?
    
    var filteredCourses: [GolfCourseSelectorViewModel.GolfCourseDetails] {
        if searchText.isEmpty {
            return viewModel.courses
        } else {
            return viewModel.courses.filter { course in
                course.clubName.localizedCaseInsensitiveContains(searchText) ||
                course.courseName.localizedCaseInsensitiveContains(searchText) ||
                course.city.localizedCaseInsensitiveContains(searchText) ||
                course.state.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.subtleGray)
                    
                    TextField("Search courses...", text: $searchText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppColors.subtleGray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)
                
                // Content area
                ZStack {
                    AppColors.backgroundWhite
                        .ignoresSafeArea()
                    
                    if viewModel.isLoading && viewModel.courses.isEmpty {
                        // Initial loading state
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Loading courses...")
                                .foregroundColor(AppColors.subtleGray)
                                .padding(.top)
                        }
                    } else if viewModel.courses.isEmpty {
                        // No courses available
                        VStack {
                            Image(systemName: "flag.fill")
                                .font(.system(size: 50))
                                .foregroundColor(AppColors.subtleGray)
                            Text("No courses available")
                                .font(.headline)
                                .foregroundColor(AppColors.subtleGray)
                                .padding(.top)
                            
                            if let error = viewModel.error {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding()
                            }
                        }
                    } else if filteredCourses.isEmpty {
                        // No search results
                        VStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(AppColors.subtleGray)
                            Text("No courses match your search")
                                .font(.headline)
                                .foregroundColor(AppColors.subtleGray)
                                .padding(.top)
                        }
                    } else {
                        // Course list
                        List {
                            ForEach(filteredCourses) { course in
                                Button(action: {
                                    selectedCourseId = course.id
                                    isSelectingCourse = true
                                    
                                    Task {
                                        await viewModel.selectCourse(course)
                                        if let selectedCourse = viewModel.selectedCourse {
                                            onCourseSelected?(selectedCourse)
                                            dismiss()
                                        }
                                    }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(course.clubName)
                                                .font(.headline)
                                                .foregroundColor(AppColors.primaryNavy)
                                            Text(course.courseName)
                                                .font(.subheadline)
                                                .foregroundColor(AppColors.subtleGray)
                                            Text("\(course.city), \(course.state)")
                                                .font(.caption)
                                                .foregroundColor(AppColors.subtleGray)
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedCourseId == course.id && isSelectingCourse {
                                            ProgressView()
                                                .scaleEffect(1.2)
                                        } else {
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(AppColors.subtleGray)
                                        }
                                    }
                                }
                                .listRowBackground(Color.white)
                            }
                            
                            // Load more indicator
                            if viewModel.hasMoreCourses {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                                .onAppear {
                                    Task {
                                        await viewModel.loadMoreCoursesIfNeeded()
                                    }
                                }
                                .listRowBackground(Color.white)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("Select Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primaryNavy)
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadCourses()
                }
            }
        }
    }
} 