import Foundation
import FirebaseFirestore

@MainActor
class GolfCourseSelectorViewModel: ObservableObject {
    @Published var courses: [GolfCourseDetails] = []
    @Published var selectedCourse: GolfCourseDetails?
    @Published var isLoading = false
    @Published var error: String?
    @Published var hasMoreCourses = true
    
    private let db = Firestore.firestore()
    private let pageSize = 5 // Smaller batch size to prevent message too large errors
    private var lastDocument: DocumentSnapshot?
    
    struct HoleDetails: Hashable {
        let number: Int
        let par: Int
        let yardage: Int
        let handicap: Int
    }
    
    struct TeeDetails: Hashable {
        let type: String // "male" or "female"
        let teeName: String
        let courseRating: Double
        let slopeRating: Int
        let totalYards: Int
        let parTotal: Int
        let holes: [HoleDetails]
    }
    
    struct GolfCourseDetails: Identifiable, Hashable {
        let id: String
        let clubName: String
        let courseName: String
        let city: String
        let state: String
        let tees: [TeeDetails]
        
        // Implement Hashable manually since we want to use id for uniqueness
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: GolfCourseDetails, rhs: GolfCourseDetails) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    func loadCourses() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        // Reset if this is a fresh load
        if lastDocument == nil {
            courses = []
        }
        
        do {
            var query = db.collection("courses").limit(to: pageSize)
            
            // If we have a last document, start after it for pagination
            if let lastDocument = lastDocument {
                query = query.start(afterDocument: lastDocument)
            }
            
            let snapshot = try await query.getDocuments()
            
            // Update the last document for pagination
            lastDocument = snapshot.documents.last
            
            // Check if we've reached the end
            hasMoreCourses = snapshot.documents.count == pageSize
            
            let newCourses = snapshot.documents.compactMap { (document: QueryDocumentSnapshot) -> GolfCourseDetails? in
                let data = document.data()
                
                guard let clubName = data["club_name"] as? String,
                      let courseName = data["course_name"] as? String,
                      let location = data["location"] as? [String: Any],
                      let city = location["city"] as? String,
                      let state = location["state"] as? String
                else { 
                    print("Failed to parse basic course data for document: \(document.documentID)")
                    return nil 
                }
                
                // Create a simplified version of the course with minimal data
                // We'll load the full details only when a course is selected
                return GolfCourseDetails(
                    id: document.documentID,
                    clubName: clubName,
                    courseName: courseName,
                    city: city,
                    state: state,
                    tees: [] // Empty tees array to reduce data size
                )
            }
            
            // Append new courses to existing ones
            courses.append(contentsOf: newCourses)
            print("Loaded \(newCourses.count) courses, total: \(courses.count)")
        } catch {
            self.error = "Failed to load courses: \(error.localizedDescription)"
            print("Error loading courses: \(error)")
        }
        
        isLoading = false
    }
    
    // New method to load full course details when needed
    func loadCourseDetails(for courseId: String) async -> GolfCourseDetails? {
        do {
            let document = try await db.collection("courses").document(courseId).getDocument()
            guard document.exists, let data = document.data() else {
                print("Course document not found: \(courseId)")
                return nil
            }
            
            guard let clubName = data["club_name"] as? String,
                  let courseName = data["course_name"] as? String,
                  let location = data["location"] as? [String: Any],
                  let city = location["city"] as? String,
                  let state = location["state"] as? String,
                  let tees = data["tees"] as? [String: [[String: Any]]]
            else { 
                print("Failed to parse course details for document: \(courseId)")
                return nil 
            }
            
            var teeDetails: [TeeDetails] = []
            
            // Process male tees
            if let maleTees = tees["male"] {
                let processedTees = processTees(maleTees, type: "male")
                teeDetails.append(contentsOf: processedTees)
            }
            
            // Process female tees
            if let femaleTees = tees["female"] {
                let processedTees = processTees(femaleTees, type: "female")
                teeDetails.append(contentsOf: processedTees)
            }
            
            return GolfCourseDetails(
                id: document.documentID,
                clubName: clubName,
                courseName: courseName,
                city: city,
                state: state,
                tees: teeDetails
            )
        } catch {
            print("Error loading course details: \(error)")
            return nil
        }
    }
    
    // Load more courses when scrolling
    func loadMoreCoursesIfNeeded() async {
        guard hasMoreCourses && !isLoading else { return }
        await loadCourses()
    }
    
    private func processTees(_ tees: [[String: Any]], type: String) -> [TeeDetails] {
        return tees.compactMap { teeData in
            guard let teeName = teeData["tee_name"] as? String,
                  let courseRating = teeData["course_rating"] as? Double,
                  let slopeRating = teeData["slope_rating"] as? Int,
                  let totalYards = teeData["total_yards"] as? Int,
                  let parTotal = teeData["par_total"] as? Int,
                  let holes = teeData["holes"] as? [[String: Any]]
            else { 
                print("Failed to parse tee data: \(teeData)")
                return nil 
            }
            
            let holeDetails = holes.enumerated().compactMap { index, holeData -> HoleDetails? in
                guard let par = holeData["par"] as? Int,
                      let yardage = holeData["yardage"] as? Int,
                      let handicap = holeData["handicap"] as? Int
                else { 
                    print("Failed to parse hole data: \(holeData)")
                    return nil 
                }
                
                return HoleDetails(
                    number: index + 1,
                    par: par,
                    yardage: yardage,
                    handicap: handicap
                )
            }
            
            // Accept both 9-hole and 18-hole courses
            guard holeDetails.count == 9 || holeDetails.count == 18 else {
                print("Invalid number of holes: \(holeDetails.count). Course must have 9 or 18 holes.")
                return nil
            }
            
            return TeeDetails(
                type: type,
                teeName: teeName,
                courseRating: courseRating,
                slopeRating: slopeRating,
                totalYards: totalYards,
                parTotal: parTotal,
                holes: holeDetails
            )
        }
    }
    
    func selectCourse(_ course: GolfCourseDetails) async {
        // If the course has no tees, load the full details
        if course.tees.isEmpty {
            if let fullCourse = await loadCourseDetails(for: course.id) {
                selectedCourse = fullCourse
                return
            }
        }
        
        selectedCourse = course
    }
} 