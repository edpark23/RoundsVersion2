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
    
    struct APITournament: Codable {
        let tournamentID: Int
        let name: String
        let venue: String
        let location: String?
        let par: Int
        let yards: Int
        let city: String?
        let state: String?
        
        enum CodingKeys: String, CodingKey {
            case tournamentID = "TournamentID"
            case name = "Name"
            case venue = "Venue"
            case location = "Location"
            case par = "Par"
            case yards = "Yards"
            case city = "City"
            case state = "State"
        }
    }
    
    func fetchAndStoreCourses() async throws -> [GolfCourse] {
        // First, fetch courses from API
        let endpoint = "\(baseURL)/Tournaments?key=\(apiKey)"
        guard let url = URL(string: endpoint) else {
            throw GolfCourseError.invalidURL
        }
        
        print("Fetching tournaments from endpoint: \(endpoint)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GolfCourseError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("API Error Response: \(errorJson)")
                }
                throw GolfCourseError.apiError("API returned status code: \(httpResponse.statusCode)")
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw API Response: \(jsonString)")
            }
            
            do {
                let tournaments = try JSONDecoder().decode([APITournament].self, from: data)
                return try await processTournaments(tournaments)
            } catch let decodingError {
                print("Failed to decode tournaments: \(decodingError)")
                throw GolfCourseError.decodingError(decodingError)
            }
        } catch {
            print("API Error: \(error)")
            if let decodingError = error as? DecodingError {
                print("Decoding Error Details: \(decodingError)")
            }
            throw GolfCourseError.networkError(error)
        }
    }
    
    private func processTournaments(_ tournaments: [APITournament]) async throws -> [GolfCourse] {
        var courses: [GolfCourse] = []
        
        for tournament in tournaments {
            // Extract location components
            var city: String?
            var state: String?
            
            if let location = tournament.location {
                let components = location.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                if components.count >= 2 {
                    city = String(components[0])
                    state = String(components[1])
                } else if components.count == 1 {
                    city = String(components[0])
                }
            }
            
            // Create a basic hole structure (since we don't have detailed hole information)
            let holes = (1...18).map { number in
                GolfCourse.Hole(
                    number: number,
                    par: tournament.par / 18, // Approximate par per hole
                    handicap: number // Default handicap
                )
            }
            
            // Create a single tee set with the tournament yardage
            let tees = [
                GolfCourse.TeeSet(
                    name: "Tournament",
                    rating: 72.0, // Default rating
                    slope: 113, // Default slope
                    yardages: Array(repeating: tournament.yards / 18, count: 18) // Approximate yards per hole
                )
            ]
            
            let course = GolfCourse(
                id: String(tournament.tournamentID),
                name: tournament.venue,
                city: city ?? tournament.city ?? "",
                state: state ?? tournament.state ?? "",
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