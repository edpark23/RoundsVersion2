import Foundation
import FirebaseFirestore
import Network

struct GolfCourseAPIService {
    private let apiKey = "KDEQD36LY7YAYBIP3Z252NL6FE"
    private let baseURL = "https://api.golfcourseapi.com/v1"
    private let db = Firestore.firestore()
    
    enum APIError: Error {
        case invalidURL
        case networkError(Error)
        case noInternetConnection
        case invalidResponse
        case serverError(Int)
        
        var localizedDescription: String {
            switch self {
            case .invalidURL:
                return "Invalid API URL"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .noInternetConnection:
                return "No internet connection. Please check your connection and try again."
            case .invalidResponse:
                return "Invalid response from server"
            case .serverError(let code):
                return "Server error (Code: \(code))"
            }
        }
    }
    
    // Models to match the API response
    struct CourseResponse: Codable {
        let courses: [Course]
        let metadata: Metadata
        
        struct Metadata: Codable {
            let currentPage: Int
            let pageSize: Int
            let firstPage: Int
            let lastPage: Int
            let totalRecords: Int
            
            enum CodingKeys: String, CodingKey {
                case currentPage = "current_page"
                case pageSize = "page_size"
                case firstPage = "first_page"
                case lastPage = "last_page"
                case totalRecords = "total_records"
            }
        }
    }
    
    struct Course: Codable {
        let id: Int
        let clubName: String
        let courseName: String?
        let location: Location
        let tees: Tees?
        
        enum CodingKeys: String, CodingKey {
            case id
            case clubName = "club_name"
            case courseName = "course_name"
            case location
            case tees
        }
    }
    
    struct Location: Codable {
        let address: String?
        let city: String?
        let state: String?
        let country: String?
        let latitude: Double?
        let longitude: Double?
    }
    
    struct Tees: Codable {
        let female: [TeeSet]?
        let male: [TeeSet]?
    }
    
    struct TeeSet: Codable {
        let teeName: String
        let courseRating: Double?
        let slopeRating: Int?
        let bogeyRating: Double?
        let totalYards: Int?
        let totalMeters: Int?
        let numberOfHoles: Int?
        let parTotal: Int?
        let holes: [Hole]?
        
        enum CodingKeys: String, CodingKey {
            case teeName = "tee_name"
            case courseRating = "course_rating"
            case slopeRating = "slope_rating"
            case bogeyRating = "bogey_rating"
            case totalYards = "total_yards"
            case totalMeters = "total_meters"
            case numberOfHoles = "number_of_holes"
            case parTotal = "par_total"
            case holes
        }
    }
    
    struct Hole: Codable {
        let par: Int?
        let yardage: Int?
        let handicap: Int?
    }
    
    private func createRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData
        return request
    }
    
    private func checkNetworkConnection() async throws {
        let monitor = NWPathMonitor()
        return try await withCheckedThrowingContinuation { continuation in
            monitor.pathUpdateHandler = { path in
                monitor.cancel()
                if path.status == .satisfied {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: APIError.noInternetConnection)
                }
            }
            monitor.start(queue: DispatchQueue.global())
        }
    }
    
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Always print response data for debugging
            print("API Response for \(request.url?.absoluteString ?? "")")
            if let json = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                print("Response JSON:\n\(prettyString)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoder = JSONDecoder()
                    return try decoder.decode(T.self, from: data)
                } catch {
                    print("Decoding error: \(error)")
                    // Print coding path for better debugging
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("Missing key '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue })")
                        case .typeMismatch(let type, let context):
                            print("Type mismatch: expected \(type) at path: \(context.codingPath.map { $0.stringValue })")
                        default:
                            print("Other decoding error: \(decodingError)")
                        }
                    }
                    throw APIError.invalidResponse
                }
            case 401:
                throw APIError.serverError(401)
            case 429:
                // Rate limit hit - wait and retry
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
                return try await performRequest(request)
            default:
                throw APIError.serverError(httpResponse.statusCode)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    func fetchAndStoreAllCourses(progressCallback: @escaping (Int, Int) -> Void) async throws {
        // Check network connection first
        try await checkNetworkConnection()
        
        var currentPage = 1
        var totalPages = 1
        var processedCourses = 0
        var totalCourses = 0
        
        // First, get the total number of courses
        guard let initialUrl = URL(string: "\(baseURL)/courses?page=1") else {
            throw APIError.invalidURL
        }
        
        let initialRequest = createRequest(url: initialUrl)
        let initialResponse: CourseResponse = try await performRequest(initialRequest)
        
        totalCourses = initialResponse.metadata.totalRecords
        totalPages = initialResponse.metadata.lastPage
        
        progressCallback(0, totalCourses)
        
        repeat {
            guard let pageUrl = URL(string: "\(baseURL)/courses?page=\(currentPage)") else {
                throw APIError.invalidURL
            }
            
            let pageRequest = createRequest(url: pageUrl)
            let response: CourseResponse = try await performRequest(pageRequest)
            
            // Store courses in Firebase
            for course in response.courses {
                do {
                    try await storeCourse(course)
                    processedCourses += 1
                    progressCallback(processedCourses, totalCourses)
                } catch {
                    print("Error storing course \(course.id): \(error)")
                    // Continue with next course even if one fails
                    continue
                }
            }
            
            currentPage += 1
            
            // Add a small delay to avoid hitting rate limits
            if currentPage <= totalPages {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            }
            
        } while currentPage <= totalPages
    }
    
    private func storeCourse(_ course: Course) async throws {
        let courseRef = db.collection("courses").document(String(course.id))
        
        var courseData: [String: Any] = [
            "club_name": course.clubName,
            "course_name": course.courseName ?? "",
            "location": [
                "address": course.location.address ?? "",
                "city": course.location.city ?? "",
                "state": course.location.state ?? "",
                "country": course.location.country ?? "",
                "latitude": course.location.latitude ?? 0.0,
                "longitude": course.location.longitude ?? 0.0
            ],
            "last_updated": FieldValue.serverTimestamp()
        ]
        
        if let tees = course.tees {
            var teesData: [String: [[String: Any]]] = [:]
            
            if let maleTees = tees.male {
                teesData["male"] = maleTees.map { convertTeeSetToDict($0) }
            }
            
            if let femaleTees = tees.female {
                teesData["female"] = femaleTees.map { convertTeeSetToDict($0) }
            }
            
            courseData["tees"] = teesData
        }
        
        try await courseRef.setData(courseData, merge: true)
    }
    
    private func convertTeeSetToDict(_ teeSet: TeeSet) -> [String: Any] {
        var dict: [String: Any] = [
            "tee_name": teeSet.teeName,
            "course_rating": teeSet.courseRating ?? 0.0,
            "slope_rating": teeSet.slopeRating ?? 0,
            "bogey_rating": teeSet.bogeyRating ?? 0.0,
            "total_yards": teeSet.totalYards ?? 0,
            "total_meters": teeSet.totalMeters ?? 0,
            "number_of_holes": teeSet.numberOfHoles ?? 0,
            "par_total": teeSet.parTotal ?? 0
        ]
        
        if let holes = teeSet.holes {
            dict["holes"] = holes.map { hole in
                [
                    "par": hole.par ?? 0,
                    "yardage": hole.yardage ?? 0,
                    "handicap": hole.handicap ?? 0
                ]
            }
        }
        
        return dict
    }
} 