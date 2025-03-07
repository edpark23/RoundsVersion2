import SwiftUI

struct GolfCourseSelectorView: View {
    @StateObject private var viewModel = GolfCourseSelectorViewModel()
    @Environment(\.dismiss) private var dismiss
    var onCourseSelected: (GolfCourseSelectorViewModel.GolfCourseDetails) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView("Loading courses...")
                } else {
                    // Course Picker Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select a Golf Course")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Menu {
                            ForEach(viewModel.courses) { course in
                                Button {
                                    viewModel.selectCourse(course)
                                } label: {
                                    Text("\(course.clubName) - \(course.city), \(course.state)")
                                }
                            }
                        } label: {
                            HStack {
                                Text(viewModel.selectedCourse?.clubName ?? "Choose a course")
                                    .foregroundColor(viewModel.selectedCourse == nil ? .gray : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                }
                
                if let selectedCourse = viewModel.selectedCourse {
                    ScrollView {
                        VStack(spacing: 16) {
                            Text("Scorecard Preview")
                                .font(.headline)
                                .padding(.top)
                            
                            ForEach(selectedCourse.tees, id: \.teeName) { tee in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("\(tee.type.capitalized) - \(tee.teeName)")
                                            .font(.subheadline)
                                            .bold()
                                        Spacer()
                                        Text("Rating: \(String(format: "%.1f", tee.courseRating)) / \(tee.slopeRating)")
                                            .font(.caption)
                                    }
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        VStack(spacing: 0) {
                                            // Header row
                                            HStack(spacing: 0) {
                                                Text("Hole")
                                                    .frame(width: 50)
                                                ForEach(tee.holes, id: \.number) { hole in
                                                    Text("\(hole.number)")
                                                        .frame(width: 40)
                                                }
                                                if tee.holes.count == 9 {
                                                    Text("Total")
                                                        .frame(width: 50)
                                                }
                                            }
                                            .font(.caption)
                                            .bold()
                                            .padding(.vertical, 4)
                                            .background(Color.gray.opacity(0.1))
                                            
                                            // Par row
                                            HStack(spacing: 0) {
                                                Text("Par")
                                                    .frame(width: 50)
                                                ForEach(tee.holes, id: \.number) { hole in
                                                    Text("\(hole.par)")
                                                        .frame(width: 40)
                                                }
                                                if tee.holes.count == 9 {
                                                    Text("\(tee.holes.reduce(0) { $0 + $1.par })")
                                                        .frame(width: 50)
                                                        .bold()
                                                }
                                            }
                                            .font(.caption)
                                            .padding(.vertical, 4)
                                            
                                            // Yardage row
                                            HStack(spacing: 0) {
                                                Text("Yards")
                                                    .frame(width: 50)
                                                ForEach(tee.holes, id: \.number) { hole in
                                                    Text("\(hole.yardage)")
                                                        .frame(width: 40)
                                                }
                                                if tee.holes.count == 9 {
                                                    Text("\(tee.holes.reduce(0) { $0 + $1.yardage })")
                                                        .frame(width: 50)
                                                        .bold()
                                                }
                                            }
                                            .font(.caption)
                                            .padding(.vertical, 4)
                                            .background(Color.gray.opacity(0.1))
                                            
                                            // Handicap row
                                            HStack(spacing: 0) {
                                                Text("HCP")
                                                    .frame(width: 50)
                                                ForEach(tee.holes, id: \.number) { hole in
                                                    Text("\(hole.handicap)")
                                                        .frame(width: 40)
                                                }
                                                if tee.holes.count == 9 {
                                                    Text("-")
                                                        .frame(width: 50)
                                                }
                                            }
                                            .font(.caption)
                                            .padding(.vertical, 4)
                                        }
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .padding(.horizontal)
                            }
                            
                            Button(action: {
                                if let course = viewModel.selectedCourse {
                                    onCourseSelected(course)
                                    dismiss()
                                }
                            }) {
                                Text("Confirm Golf Course")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            .padding()
                        }
                    }
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("Select Golf Course")
            .task {
                await viewModel.loadCourses()
            }
        }
    }
} 