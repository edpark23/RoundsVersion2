import Foundation
import FirebaseFirestore

@MainActor
final class AdminViewModel: ObservableObject {
    @Published var courses: [StoredCourse] = []
    @Published var error: String?
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    
    struct StoredCourse: Identifiable {
        let id: String
        let clubName: String
        let courseName: String
        let city: String
        let state: String
        let lastUpdated: Date
    }
    
    func loadStoredCourses() async {
        isLoading = true
        do {
            let snapshot = try await db.collection("courses").getDocuments()
            courses = snapshot.documents.compactMap { document in
                let data = document.data()
                guard let clubName = data["club_name"] as? String,
                      let location = data["location"] as? [String: Any],
                      let city = location["city"] as? String,
                      let state = location["state"] as? String,
                      let timestamp = data["last_updated"] as? Timestamp
                else {
                    print("Failed to parse course data for document: \(document.documentID)")
                    print("Data: \(data)")
                    return nil
                }
                
                return StoredCourse(
                    id: document.documentID,
                    clubName: clubName,
                    courseName: data["course_name"] as? String ?? "",
                    city: city,
                    state: state,
                    lastUpdated: timestamp.dateValue()
                )
            }
            
            print("Loaded \(courses.count) courses from Firebase")
            error = nil
        } catch {
            self.error = "Failed to load stored courses: \(error.localizedDescription)"
            print("Error loading courses: \(error)")
        }
        isLoading = false
    }
} 