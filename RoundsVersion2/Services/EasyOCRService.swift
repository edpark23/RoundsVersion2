import Foundation
import UIKit

// MARK: - EasyOCR Service
@MainActor
class EasyOCRService: ObservableObject {
    
    static let shared = EasyOCRService()
    
    // Configuration
    private let baseURL = "http://localhost:5001" // Change to your server URL (using 5001 to avoid AirPlay conflict)
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Response Models (nested types as expected by the view model)
    struct EasyOCRResponse: Codable {
        let success: Bool
        let scores: [Int]?
        let allText: [TextDetection]?
        let processingTime: Double?
        let error: String?
    }
    
    struct TextDetection: Codable {
        let boundingBox: [[Double]]
        let text: String
        let confidence: Double
    }
    
    struct OCRResult: Codable {
        let image: String
    }
    
    struct HealthResponse: Codable {
        let status: String
        let message: String
    }
    
    // MARK: - Error Types
    enum EasyOCRError: Error, LocalizedError {
        case imageConversionFailed
        case invalidURL
        case networkError(String)
        case serverError(String)
        case decodingError(String)
        
        var errorDescription: String? {
            switch self {
            case .imageConversionFailed:
                return "Failed to convert image to data"
            case .invalidURL:
                return "Invalid server URL"
            case .networkError(let message):
                return "Network error: \(message)"
            case .serverError(let message):
                return "Server error: \(message)"
            case .decodingError(let message):
                return "Failed to decode response: \(message)"
            }
        }
    }
    
    // MARK: - Main OCR Method
    func performOCR(on image: UIImage) async throws -> EasyOCRResponse {
        // Check server health first
        let isHealthy = await checkServerHealth()
        guard isHealthy else {
            throw EasyOCRError.serverError("Server is not healthy")
        }
        
        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw EasyOCRError.imageConversionFailed
        }
        
        // Create base64 string
        let base64String = imageData.base64EncodedString()
        
        // Create request
        guard let url = URL(string: "\(baseURL)/ocr") else {
            throw EasyOCRError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = OCRResult(image: base64String)
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw EasyOCRError.networkError("Failed to encode request body")
        }
        
        // Make request
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw EasyOCRError.networkError("Invalid response type")
            }
            
            guard httpResponse.statusCode == 200 else {
                throw EasyOCRError.serverError("HTTP \(httpResponse.statusCode)")
            }
            
            let ocrResponse = try JSONDecoder().decode(EasyOCRResponse.self, from: data)
            return ocrResponse
            
        } catch let error as EasyOCRError {
            throw error
        } catch {
            throw EasyOCRError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Health Check
    func checkServerHealth() async -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else {
            return false
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }
            
            let healthResponse = try JSONDecoder().decode(HealthResponse.self, from: data)
            return healthResponse.status == "healthy"
            
        } catch {
            return false
        }
    }
    
    // MARK: - Server Status
    func checkServerStatus() async -> Bool {
        return await checkServerHealth()
    }
    
    // MARK: - Golf-specific score extraction
    func extractGolfScores(from results: [TextDetection]) -> [String] {
        // Extract potential golf scores (1-10, par values, etc.)
        let scores = results.compactMap { result -> String? in
            let text = result.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            // Check if it's a valid golf score
            if let score = Int(text), score >= 1 && score <= 10 {
                return text
            }
            
            // Check for par values
            if text.lowercased().contains("par") {
                return text
            }
            
            return nil
        }
        
        return scores
    }
}

// MARK: - Server Response Models (for communication with Python server)
private struct OCRResponse: Codable {
    let success: Bool
    let detections: [Detection]
    let error: String?
    let processingTime: Double?
    
    struct Detection: Codable {
        let text: String
        let confidence: Double
        let bbox: [Double]
        let imageSize: [Int]
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
} 