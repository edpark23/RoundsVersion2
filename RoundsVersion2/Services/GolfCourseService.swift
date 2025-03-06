import Foundation
import FirebaseFirestore

actor GolfCourseService {
    private let apiKey = "888466edaff84b5ea86a236fcaf4792e"
    private let baseURL = "https://api.sportsdata.io/golf/v2/json"
    private let db = Firestore.firestore()
    
    enum GolfCourseError: Error {
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case decodingError(Error)
        case apiError(String)
    }
    
    struct APIResponse: Codable {
        let courses: [APICourse]
    }
    
    struct APICourse: Codable {
        let courseID: Int
        let name: String
        let city: String
        let state: String
        let holes: [APIHole]
        let tees: [APITee]
        
        struct APIHole: Codable {
            let number: Int
            let par: Int
            let handicap: Int
        }
        
        struct APITee: Codable {
            let teeType: String
            let par: Int
            let rating: Double
            let slope: Int
            let yardages: [Int]
        }
    }
    
    func fetchAndStoreCourses() async throws -> [GolfCourse] {
        // First, fetch courses from API
        let endpoint = "\(baseURL)/courses?key=\(apiKey)"
        guard let url = URL(string: endpoint) else {
            throw GolfCourseError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GolfCourseError.invalidResponse
        }
        
        do {
            let apiResponse = try JSONDecoder().decode([APICourse].self, from: data)
            let courses = try await processCourses(apiResponse)
            return courses
        } catch {
            print("Decoding error: \(error)")
            throw GolfCourseError.decodingError(error)
        }
    }
    
    private func processCourses(_ apiCourses: [APICourse]) async throws -> [GolfCourse] {
        var courses: [GolfCourse] = []
        
        for apiCourse in apiCourses {
            let tees = apiCourse.tees.map { tee in
                GolfCourse.TeeSet(
                    name: tee.teeType,
                    rating: tee.rating,
                    slope: tee.slope,
                    yardages: tee.yardages
                )
            }
            
            let holes = apiCourse.holes.map { hole in
                GolfCourse.Hole(
                    number: hole.number,
                    par: hole.par,
                    handicap: hole.handicap
                )
            }
            
            let course = GolfCourse(
                id: String(apiCourse.courseID),
                name: apiCourse.name,
                city: apiCourse.city,
                state: apiCourse.state,
                tees: tees,
                holes: holes,
                lastUpdated: Date()
            )
            
            // Store in Firebase
            try await storeCourse(course)
            courses.append(course)
        }
        
        return courses
    }
    
    private func storeCourse(_ course: GolfCourse) async throws {
        try await db.collection("courses")
            .document(course.id)
            .setData(course.asDictionary, merge: true)
    }
    
    func fetchStoredCourses() async throws -> [GolfCourse] {
        let snapshot = try await db.collection("courses").getDocuments()
        return snapshot.documents.compactMap { GolfCourse.from($0) }
    }
} 