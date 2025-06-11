import Foundation
import Vision
import UIKit
import os

// MARK: - Score Processing Components
// Decomposed from the massive ScoreVerificationViewModel

// MARK: - OCR Processing Service
@MainActor
class OCRProcessor: ObservableObject {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.rounds", category: "OCRProcessor")
    
    func performOCR(on image: UIImage) async throws -> [VNRecognizedTextObservation] {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.minimumTextHeight = 0.005
        request.automaticallyDetectsLanguage = true
        request.customWords = ["PAR", "HOLE", "TOTAL", "OUT", "IN", "HANDICAP", "YARDAGE"]
        
        try requestHandler.perform([request])
        
        guard let observations = request.results else {
            throw OCRError.noTextFound
        }
        
        return observations
    }
    
    enum OCRError: LocalizedError {
        case invalidImage
        case noTextFound
        
        var errorDescription: String? {
            switch self {
            case .invalidImage: return "Failed to process image"
            case .noTextFound: return "No text found in image"
            }
        }
    }
}

// MARK: - Score Extraction Engine
@MainActor
class ScoreExtractor: ObservableObject {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.rounds", category: "ScoreExtractor")
    
    func extractScores(from observations: [VNRecognizedTextObservation]) async -> ScoreExtractionResult {
        if FeatureFlags.useOptimizedViewModels {
            return await performOptimizedExtraction(observations)
        } else {
            return await performStandardExtraction(observations)
        }
    }
    
    private func performOptimizedExtraction(_ observations: [VNRecognizedTextObservation]) async -> ScoreExtractionResult {
        // Optimized algorithm - Process in parallel
        await withTaskGroup(of: [Int].self) { group in
            var allScores: [Int] = []
            var playerName: String?
            
            // Parallel processing for better performance
            group.addTask {
                await self.findScoresInRow(observations)
            }
            
            for await scores in group {
                allScores.append(contentsOf: scores)
            }
            
            // Find player name
            playerName = await findPlayerName(observations)
            
            return ScoreExtractionResult(
                playerName: playerName,
                scores: Array(allScores.prefix(18)), // Take first 18 scores
                confidence: allScores.count >= 9 ? 0.8 : 0.4
            )
        }
    }
    
    private func performStandardExtraction(_ observations: [VNRecognizedTextObservation]) async -> ScoreExtractionResult {
        let scores = await findScoresInRow(observations)
        let playerName = await findPlayerName(observations)
        
        return ScoreExtractionResult(
            playerName: playerName,
            scores: Array(scores.prefix(18)),
            confidence: scores.count >= 9 ? 0.6 : 0.3
        )
    }
    
    private func findScoresInRow(_ observations: [VNRecognizedTextObservation]) async -> [Int] {
        var scores: [Int] = []
        
        for observation in observations {
            if let text = observation.topCandidates(1).first?.string {
                let numbers = extractNumbersFromText(text)
                scores.append(contentsOf: numbers.filter { $0 > 0 && $0 <= 10 })
            }
        }
        
        return scores
    }
    
    private func findPlayerName(_ observations: [VNRecognizedTextObservation]) async -> String? {
        for observation in observations {
            if let text = observation.topCandidates(1).first?.string {
                if isLikelyPlayerName(text) {
                    return text.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return nil
    }
    
    private func extractNumbersFromText(_ text: String) -> [Int] {
        let pattern = "\\b([1-9]|10)\\b"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(text.startIndex..., in: text)
        
        var numbers: [Int] = []
        regex?.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            if let matchRange = match?.range,
               let range = Range(matchRange, in: text),
               let number = Int(text[range]) {
                numbers.append(number)
            }
        }
        
        return numbers
    }
    
    private func isLikelyPlayerName(_ text: String) -> Bool {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.count > 3 &&
               cleaned.count < 30 &&
               !cleaned.allSatisfy(\.isNumber) &&
               !["PAR", "TOTAL", "HOLE", "OUT", "IN"].contains(cleaned.uppercased())
    }
}

// MARK: - Image Processing Service
@MainActor
class ImageProcessor: ObservableObject {
    
    func visualizeObservations(_ observations: [VNRecognizedTextObservation], on image: UIImage) async -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: image.size))
            
            let transform = CGAffineTransform.identity
                .scaledBy(x: image.size.width, y: -image.size.height)
                .translatedBy(x: 0, y: -1)
            
            for observation in observations {
                let rect = observation.boundingBox.applying(transform)
                UIColor.blue.setStroke()
                context.cgContext.setLineWidth(1.0)
                context.cgContext.stroke(rect)
            }
        }
    }
    
    func highlightSelectedArea(_ observation: VNRecognizedTextObservation, on image: UIImage) async -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: image.size))
            
            let transform = CGAffineTransform.identity
                .scaledBy(x: image.size.width, y: -image.size.height)
                .translatedBy(x: 0, y: -1)
            
            let rect = observation.boundingBox.applying(transform)
            UIColor.green.setStroke()
            context.cgContext.setLineWidth(2.0)
            context.cgContext.stroke(rect)
        }
    }
}

// MARK: - Result Models
struct ScoreExtractionResult {
    let playerName: String?
    let scores: [Int]
    let confidence: Double
    
    var isValid: Bool {
        return scores.count >= 9 && confidence > 0.5
    }
    
    var isComplete: Bool {
        return scores.count == 18
    }
}

// MARK: - Optimized Score Verification Coordinator
@MainActor
class OptimizedScoreVerificationViewModel: ObservableObject {
    // Simplified, focused state management
    @Published var capturedImage: UIImage?
    @Published var processedImage: UIImage?
    @Published var isProcessing = false
    @Published var extractionResult: ScoreExtractionResult?
    @Published var error: String?
    @Published var debugInfo: String = ""
    
    // Specialized processors
    private let ocrProcessor = OCRProcessor()
    private let scoreExtractor = ScoreExtractor()
    private let imageProcessor = ImageProcessor()
    
    func processImage() async {
        guard let image = capturedImage else {
            error = "No image selected"
            return
        }
        
        isProcessing = true
        error = nil
        debugInfo = ""
        
        if FeatureFlags.useOptimizedViewModels {
            await performOptimizedProcessing(image)
        } else {
            await performStandardProcessing(image)
        }
        
        isProcessing = false
    }
    
    private func performOptimizedProcessing(_ image: UIImage) async {
        await PerformanceMonitor.measure("OptimizedScoreVerification.processImage") {
            do {
                let observations = try await ocrProcessor.performOCR(on: image)
                processedImage = await imageProcessor.visualizeObservations(observations, on: image)
                extractionResult = await scoreExtractor.extractScores(from: observations)
                
                if let result = extractionResult, !result.isValid {
                    error = "Could not extract sufficient scores. Found \(result.scores.count) scores."
                }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    private func performStandardProcessing(_ image: UIImage) async {
        // Fallback to standard processing
        do {
            let observations = try await ocrProcessor.performOCR(on: image)
            processedImage = await imageProcessor.visualizeObservations(observations, on: image)
            extractionResult = await scoreExtractor.extractScores(from: observations)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    // MARK: - Convenience Properties
    var scores: [Int] {
        return extractionResult?.scores ?? []
    }
    
    var foundPlayerName: String? {
        return extractionResult?.playerName
    }
    
    var processingConfidence: Double {
        return extractionResult?.confidence ?? 0.0
    }
} 