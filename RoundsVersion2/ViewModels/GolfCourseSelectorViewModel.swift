import Foundation
import FirebaseFirestore
import FirebaseAuth

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
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        // Initialize with clean state
        print("🏌️ GolfCourseSelectorViewModel initialized")
        setupAuthListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    private func setupAuthListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if user != nil {
                    print("🔐 Auth state changed - user authenticated, auto-loading courses")
                    // Only load if we don't have courses already
                    if self?.courses.isEmpty == true && self?.isLoading == false {
                        await self?.loadCourses()
                    }
                } else {
                    print("🔐 Auth state changed - user not authenticated")
                    self?.courses = []
                    self?.error = "Please sign in to view golf courses"
                }
            }
        }
    }
    
    func resetAndReload() async {
        print("🔄 Resetting ViewModel state and reloading...")
        lastDocument = nil
        courses = []
        error = nil
        hasMoreCourses = true
        await loadCourses()
    }
    
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
        guard !isLoading else { 
            print("⚠️ Already loading courses, skipping...")
            return 
        }
        
        // Check if user is authenticated
        guard Auth.auth().currentUser != nil else {
            print("❌ User not authenticated, cannot load courses")
            error = "Please sign in to view golf courses"
            return
        }
        
        print("🏌️ Starting to load courses from Firebase...")
        print("🔐 User authenticated: \(Auth.auth().currentUser?.uid ?? "unknown")")
        isLoading = true
        error = nil
        
        // Reset if this is a fresh load
        if lastDocument == nil {
            courses = []
            print("🔄 Fresh load - clearing existing courses")
        }
        
        do {
            var query = db.collection("courses").limit(to: pageSize)
            
            // If we have a last document, start after it for pagination
            if let lastDocument = lastDocument {
                query = query.start(afterDocument: lastDocument)
                print("📄 Continuing pagination from last document")
            }
            
            print("🔍 Executing Firebase query...")
            let snapshot = try await query.getDocuments()
            print("📊 Firebase query completed. Found \(snapshot.documents.count) documents")
            
            // Update the last document for pagination
            lastDocument = snapshot.documents.last
            
            // Check if we've reached the end
            hasMoreCourses = snapshot.documents.count == pageSize
            print("📈 Has more courses: \(hasMoreCourses)")
            
            // Debug: Print first few document IDs
            if !snapshot.documents.isEmpty {
                let documentIds = snapshot.documents.prefix(3).map { $0.documentID }
                print("📋 First few document IDs: \(documentIds)")
            }
            
            let newCourses = snapshot.documents.compactMap { (document: QueryDocumentSnapshot) -> GolfCourseDetails? in
                let data = document.data()
                print("🔍 Processing document \(document.documentID)")
                print("📄 Document data keys: \(Array(data.keys))")
                
                guard let clubName = data["club_name"] as? String,
                      let courseName = data["course_name"] as? String,
                      let location = data["location"] as? [String: Any],
                      let city = location["city"] as? String,
                      let state = location["state"] as? String
                else { 
                    print("❌ Failed to parse basic course data for document: \(document.documentID)")
                    print("📄 Available data: \(data)")
                    return nil 
                }
                
                print("✅ Successfully parsed course: \(clubName) in \(city), \(state)")
                
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
            print("✅ Successfully loaded \(newCourses.count) courses, total: \(courses.count)")
            
            // If no courses were found and this is the first load, provide helpful message
            if courses.isEmpty && lastDocument == nil {
                print("⚠️ No courses found in Firebase. Database might be empty.")
                error = "No golf courses found. Please check if course data has been imported."
            }
            
        } catch {
            self.error = "Failed to load courses: \(error.localizedDescription)"
            print("❌ Error loading courses: \(error)")
            print("🔍 Error details: \(error)")
        }
        
        isLoading = false
        print("🏁 Course loading completed. Final count: \(courses.count)")
    }
    
    // New method to load full course details when needed
    func loadCourseDetails(for courseId: String) async -> GolfCourseDetails? {
        print("Loading course details for ID: \(courseId)")
        do {
            let document = try await db.collection("courses").document(courseId).getDocument()
            guard document.exists, let data = document.data() else {
                print("⚠️ Course document not found: \(courseId)")
                return nil
            }
            
            guard let clubName = data["club_name"] as? String,
                  let courseName = data["course_name"] as? String,
                  let location = data["location"] as? [String: Any],
                  let city = location["city"] as? String,
                  let state = location["state"] as? String,
                  let tees = data["tees"] as? [String: [[String: Any]]]
            else { 
                print("⚠️ Failed to parse course details for document: \(courseId)")
                print("Data received: \(data)")
                return nil 
            }
            
            var teeDetails: [TeeDetails] = []
            
            // Process male tees
            if let maleTees = tees["male"] {
                print("Processing \(maleTees.count) male tees")
                let processedTees = processTees(maleTees, type: "male")
                teeDetails.append(contentsOf: processedTees)
            }
            
            // Process female tees
            if let femaleTees = tees["female"] {
                print("Processing \(femaleTees.count) female tees")
                let processedTees = processTees(femaleTees, type: "female")
                teeDetails.append(contentsOf: processedTees)
            }
            
            print("Finished processing tees, total: \(teeDetails.count)")
            
            return GolfCourseDetails(
                id: document.documentID,
                clubName: clubName,
                courseName: courseName,
                city: city,
                state: state,
                tees: teeDetails
            )
        } catch {
            print("⚠️ Error loading course details: \(error)")
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
            print("Course \(course.clubName) has no tees, loading details")
            if let fullCourse = await loadCourseDetails(for: course.id) {
                print("Loaded full course details: \(fullCourse.clubName) with \(fullCourse.tees.count) tees")
                selectedCourse = fullCourse
                return
            } else {
                print("⚠️ Failed to load course details for \(course.id)")
            }
        } else {
            print("Course \(course.clubName) already has \(course.tees.count) tees, using existing data")
        }
        
        selectedCourse = course
    }
    
    // Helper method to get sample tees when no real tees are available
    func getSampleTees() -> [TeeDetails] {
        print("Generating sample tees")
        return [
            TeeDetails(
                type: "male",
                teeName: "Black",
                courseRating: 76.10,
                slopeRating: 141,
                totalYards: 7206,
                parTotal: 72,
                holes: []
            ),
            TeeDetails(
                type: "male",
                teeName: "Gold",
                courseRating: 73.80,
                slopeRating: 137,
                totalYards: 6914,
                parTotal: 72,
                holes: []
            ),
            TeeDetails(
                type: "male",
                teeName: "White",
                courseRating: 71.70,
                slopeRating: 131,
                totalYards: 6675,
                parTotal: 72,
                holes: []
            ),
            TeeDetails(
                type: "male",
                teeName: "Green",
                courseRating: 69.83,
                slopeRating: 125,
                totalYards: 6432,
                parTotal: 72,
                holes: []
            ),
            TeeDetails(
                type: "male",
                teeName: "Red",
                courseRating: 67.48,
                slopeRating: 120,
                totalYards: 6168,
                parTotal: 72,
                holes: []
            )
        ]
    }
    
    func createMatch(course: GolfCourseDetails, tee: TeeDetails, settings: RoundSettings) {
        print("Creating match with:")
        print("Course: \(course.clubName) - \(course.courseName)")
        print("Tee: \(tee.teeName) (\(tee.totalYards) yards)")
        print("Settings: Concede putt: \(settings.concedePutt), Starting hole: \(settings.startingHole)")
        
        // Here we would typically integrate with Firebase
        // For demo purposes, we'll just log the details
    }
} 