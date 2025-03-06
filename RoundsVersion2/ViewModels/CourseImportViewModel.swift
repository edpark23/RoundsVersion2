import Foundation

@MainActor
class CourseImportViewModel: ObservableObject {
    private let apiService = GolfCourseAPIService()
    
    @Published var isImporting = false
    @Published var totalCourses = 0
    @Published var processedCourses = 0
    @Published var errorMessage: String?
    @Published var shouldShowRetry = false
    
    var progress: Double {
        guard totalCourses > 0 else { return 0 }
        return Double(processedCourses) / Double(totalCourses)
    }
    
    func startImport() {
        guard !isImporting else { return }
        
        isImporting = true
        processedCourses = 0
        totalCourses = 0
        errorMessage = nil
        shouldShowRetry = false
        
        Task {
            do {
                try await apiService.fetchAndStoreAllCourses { processed, total in
                    Task { @MainActor in
                        self.processedCourses = processed
                        self.totalCourses = total
                    }
                }
                isImporting = false
            } catch let apiError as GolfCourseAPIService.APIError {
                errorMessage = apiError.localizedDescription
                shouldShowRetry = true
                isImporting = false
            } catch {
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                shouldShowRetry = true
                isImporting = false
            }
        }
    }
    
    func retry() {
        startImport()
    }
} 