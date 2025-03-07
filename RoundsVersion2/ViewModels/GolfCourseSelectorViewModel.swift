import Foundation
import FirebaseFirestore

@MainActor
class GolfCourseSelectorViewModel: ObservableObject {
    @Published var courses: [GolfCourseDetails] = []
    @Published var selectedCourse: GolfCourseDetails?
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    
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
        isLoading = true
        error = nil
        
        do {
            let snapshot = try await db.collection("courses").getDocuments()
            courses = snapshot.documents.compactMap { document in
                let data = document.data()
                
                guard let clubName = data["club_name"] as? String,
                      let courseName = data["course_name"] as? String,
                      let location = data["location"] as? [String: Any],
                      let city = location["city"] as? String,
                      let state = location["state"] as? String,
                      let tees = data["tees"] as? [String: [[String: Any]]]
                else { 
                    print("Failed to parse basic course data for document: \(document.documentID)")
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
            }
            
            print("Loaded \(courses.count) courses")
        } catch {
            self.error = "Failed to load courses: \(error.localizedDescription)"
            print("Error loading courses: \(error)")
        }
        
        isLoading = false
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
    
    func selectCourse(_ course: GolfCourseDetails) {
        selectedCourse = course
    }
} 