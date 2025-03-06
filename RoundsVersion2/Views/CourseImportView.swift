import SwiftUI

struct CourseImportView: View {
    @StateObject private var viewModel = CourseImportViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Golf Course Import")
                .font(.title)
                .fontWeight(.bold)
            
            if viewModel.isImporting {
                VStack(spacing: 16) {
                    ProgressView(value: viewModel.progress) {
                        Text("Importing Courses...")
                            .font(.headline)
                    } currentValueLabel: {
                        Text("\(viewModel.processedCourses) of \(viewModel.totalCourses)")
                            .font(.subheadline)
                    }
                    .progressViewStyle(.linear)
                    .padding(.horizontal)
                    
                    if viewModel.totalCourses > 0 {
                        Text("Processing \(viewModel.processedCourses) of \(viewModel.totalCourses) courses")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("Error")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    
                    if viewModel.shouldShowRetry {
                        Button(action: {
                            viewModel.retry()
                        }) {
                            Label("Retry Import", systemImage: "arrow.clockwise")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            } else {
                VStack(spacing: 16) {
                    Text("Ready to Import")
                        .font(.headline)
                    
                    Text("This will download and store golf course data from the API. The process may take several minutes.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        viewModel.startImport()
                    }) {
                        Text("Start Import")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
} 