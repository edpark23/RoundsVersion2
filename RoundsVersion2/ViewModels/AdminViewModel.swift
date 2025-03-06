import Foundation

@MainActor
final class AdminViewModel: ObservableObject {
    @Published var courses: [GolfCourse] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let golfCourseService = GolfCourseService()
    
    func fetchGolfCourses() async {
        isLoading = true
        error = nil
        
        do {
            courses = try await golfCourseService.fetchAndStoreCourses()
        } catch {
            self.error = "Failed to fetch courses: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadStoredCourses() async {
        do {
            courses = try await golfCourseService.fetchStoredCourses()
        } catch {
            self.error = "Failed to load stored courses: \(error.localizedDescription)"
        }
    }
} 