import Foundation
import Vision
import UIKit
import FirebaseFirestore
import FirebaseAuth
import os

@MainActor
class ScoreVerificationViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var processedImage: UIImage?
    @Published var isProcessing = false
    @Published var scores: [Int] = []
    @Published var error: String?
    @Published var foundPlayerName: String?
    @Published var debugInfo: String = ""
    @Published var showingShareSheet = false
    @Published var shareItems: [Any] = []
    
    private let db = Firestore.firestore()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.rounds", category: "ScoreVerification")
    
    private var shouldLog = false
    private var userNameRow: String?
    
    private func logDebug(_ message: String, force: Bool = false) {
        debugInfo += message + "\n"
        if shouldLog || force {
            // Only print if it's about the username row or forced
            if message.contains(userNameRow ?? "") || force {
                print("🎯 Score Verification: \(message)")
                logger.debug("\(message)")
            }
        }
    }
    
    func processImage() async {
        guard let image = capturedImage else {
            error = "No image selected"
            return
        }
        
        isProcessing = true
        error = nil
        debugInfo = ""
        shouldLog = false
        userNameRow = nil
        
        do {
            let textObservations = try await performOCR(on: image)
            
            // Create visualization
            let visualizedImage = await visualizeObservations(textObservations, on: image)
            processedImage = visualizedImage
            
            let (playerName, extractedScores, selectedObservation) = try await processScorecard(from: textObservations)
            
            // Highlight the selected row
            if let selectedObservation = selectedObservation {
                processedImage = await highlightSelectedRow(selectedObservation, on: visualizedImage)
            }
            
            if let playerName = playerName {
                logDebug("✅ Found player '\(playerName)' with scores: \(extractedScores)", force: true)
            }
            
            if extractedScores.isEmpty {
                error = "Could not detect scores. Please ensure the scorecard is clearly visible."
            } else {
                scores = extractedScores
                foundPlayerName = playerName
            }
        } catch {
            self.error = "Failed to process image: \(error.localizedDescription)"
            logDebug("❌ Error: \(error.localizedDescription)", force: true)
        }
        
        isProcessing = false
    }
    
    private func visualizeObservations(_ observations: [VNRecognizedTextObservation], on image: UIImage) async -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        return renderer.image { context in
            // Draw original image
            image.draw(in: CGRect(origin: .zero, size: image.size))
            
            // Setup drawing attributes
            let attributes: [NSAttributedString.Key: Any] = [
                .strokeColor: UIColor.blue,
                .strokeWidth: 1.0
            ]
            
            // Transform Vision coordinates to image coordinates
            let transform = CGAffineTransform.identity
                .scaledBy(x: image.size.width, y: -image.size.height)
                .translatedBy(x: 0, y: -1)
            
            // Draw boxes around all text
            for observation in observations {
                let rect = observation.boundingBox.applying(transform)
                UIColor.blue.setStroke()
                context.cgContext.setLineWidth(1.0)
                context.cgContext.stroke(rect)
                
                if let text = observation.topCandidates(1).first?.string {
                    (text as NSString).draw(at: CGPoint(x: rect.minX, y: rect.minY - 15),
                                         withAttributes: attributes)
                }
            }
        }
    }
    
    private func highlightSelectedRow(_ observation: VNRecognizedTextObservation, on image: UIImage) async -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        return renderer.image { context in
            // Draw the image with existing boxes
            image.draw(in: CGRect(origin: .zero, size: image.size))
            
            // Transform Vision coordinates to image coordinates
            let transform = CGAffineTransform.identity
                .scaledBy(x: image.size.width, y: -image.size.height)
                .translatedBy(x: 0, y: -1)
            
            // Draw highlighted box around selected row
            let rect = observation.boundingBox.applying(transform)
            UIColor.green.setStroke()
            context.cgContext.setLineWidth(2.0)
            context.cgContext.stroke(rect)
            
            // Add "Selected Row" label
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.green,
                .font: UIFont.boldSystemFont(ofSize: 14)
            ]
            ("Selected Row" as NSString).draw(
                at: CGPoint(x: rect.minX, y: rect.minY - 20),
                withAttributes: attributes
            )
        }
    }
    
    private func performOCR(on image: UIImage) async throws -> [VNRecognizedTextObservation] {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "ScoreVerification", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get CGImage"])
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.minimumTextHeight = 0.01 // Adjust this value if needed
        
        try requestHandler.perform([request])
        
        guard let observations = request.results else {
            throw NSError(domain: "ScoreVerification", code: 2, userInfo: [NSLocalizedDescriptionKey: "No text found"])
        }
        
        return observations
    }
    
    private func processScorecard(from observations: [VNRecognizedTextObservation]) async throws -> (playerName: String?, scores: [Int], selectedObservation: VNRecognizedTextObservation?) {
        var rows: [(observation: VNRecognizedTextObservation, yPosition: CGFloat, text: String, xPosition: CGFloat)] = []
        
        // Extract text and position information
        for observation in observations {
            if let recognizedText = observation.topCandidates(1).first {
                let text = recognizedText.string
                let yPosition = observation.boundingBox.origin.y
                let xPosition = observation.boundingBox.origin.x
                rows.append((observation, yPosition, text, xPosition))
                // Log all text for debugging
                logDebug("Raw text found: '\(text)' at x: \(String(format: "%.2f", xPosition))", force: true)
            }
        }
        
        // Sort rows by y-position (top to bottom)
        let sortedRows = rows.sorted { $0.yPosition > $1.yPosition }
        
        // Get current user's name
        guard let userName = try? await getCurrentUserName() else {
            logDebug("❌ Could not get current user name", force: true)
            return (nil, [], nil)
        }
        
        // Try to find the row with the player's name
        var targetRow: (observation: VNRecognizedTextObservation, text: String)?
        var playerName: String?
        
        // Find all text elements on the same y-position (same row)
        for (index, row) in sortedRows.enumerated() {
            let matches = row.text.lowercased().contains(userName.lowercased())
            
            if matches {
                // Find all text on the same horizontal line (similar y-position)
                let sameRowTexts = sortedRows.filter { otherRow in
                    abs(otherRow.yPosition - row.yPosition) < 0.02 // Adjust this threshold if needed
                }.sorted { $0.xPosition < $1.xPosition }
                
                // Log individual text elements in the row
                for text in sameRowTexts {
                    logDebug("Text segment at x: \(String(format: "%.2f", text.xPosition)): '\(text.text)'", force: true)
                }
                
                let fullRowText = sameRowTexts.map { $0.text }.joined(separator: " ")
                logDebug("📍 Found name at position (x: \(String(format: "%.2f", row.xPosition)), y: \(String(format: "%.2f", row.yPosition)))", force: true)
                logDebug("📝 Complete row text: '\(fullRowText)'", force: true)
                
                // Look for scores in the complete row text and to the right
                var allScores: [Int] = []
                
                // First, try to find scores in the current row
                let scoresInRow = extractScores(from: fullRowText)
                if !scoresInRow.isEmpty {
                    allScores = Array(scoresInRow.prefix(18)) // Ensure we don't exceed 18 scores
                }
                
                // If we don't have all 18 scores, look for more text to the right
                if allScores.count < 18 {
                    let textsToRight = sortedRows.filter { otherRow in
                        abs(otherRow.yPosition - row.yPosition) < 0.02 && // Same row
                        otherRow.xPosition > row.xPosition + 0.1 // Significantly to the right
                    }.sorted { $0.xPosition < $1.xPosition }
                    
                    for rightText in textsToRight {
                        if allScores.count >= 18 { break } // Stop if we have enough scores
                        logDebug("Looking at text to right: '\(rightText.text)'", force: true)
                        let additionalScores = extractScores(from: rightText.text)
                        let remainingCount = 18 - allScores.count
                        let newScores = Array(additionalScores.prefix(remainingCount))
                        allScores.append(contentsOf: newScores)
                    }
                }
                
                if !allScores.isEmpty {
                    targetRow = (row.observation, fullRowText)
                    playerName = userName
                    logDebug("✅ Total scores found: \(allScores.count)", force: true)
                    return (playerName, allScores, row.observation)
                }
                
                // If still no scores, check adjacent rows
                if allScores.isEmpty {
                    if index > 0 && index < sortedRows.count {
                        let aboveIndex = index - 1
                        let aboveRowTexts = sortedRows.filter { otherRow in
                            if let aboveYPosition = sortedRows[safe: aboveIndex]?.yPosition {
                                return abs(otherRow.yPosition - aboveYPosition) < 0.02
                            }
                            return false
                        }.sorted { $0.xPosition < $1.xPosition }
                        let aboveFullText = aboveRowTexts.map { $0.text }.joined(separator: " ")
                        let aboveScores = extractScores(from: aboveFullText)
                        if !aboveScores.isEmpty {
                            let limitedScores = Array(aboveScores.prefix(18))
                            logDebug("⬆️ Found scores in row above: \(limitedScores)", force: true)
                            return (userName, limitedScores, aboveRowTexts.first?.observation)
                        }
                    }
                    
                    if index + 1 < sortedRows.count {
                        let belowIndex = index + 1
                        let belowRowTexts = sortedRows.filter { otherRow in
                            if let belowYPosition = sortedRows[safe: belowIndex]?.yPosition {
                                return abs(otherRow.yPosition - belowYPosition) < 0.02
                            }
                            return false
                        }.sorted { $0.xPosition < $1.xPosition }
                        let belowFullText = belowRowTexts.map { $0.text }.joined(separator: " ")
                        let belowScores = extractScores(from: belowFullText)
                        if !belowScores.isEmpty {
                            let limitedScores = Array(belowScores.prefix(18))
                            logDebug("⬇️ Found scores in row below: \(limitedScores)", force: true)
                            return (userName, limitedScores, belowRowTexts.first?.observation)
                        }
                    }
                }
                
                targetRow = (row.observation, fullRowText)
                playerName = userName
            }
        }
        
        if targetRow != nil {
            logDebug("❌ Found name but no scores nearby", force: true)
        }
        return (playerName, [], targetRow?.observation)
    }
    
    private func getCurrentUserName() async throws -> String? {
        guard let userId = Auth.auth().currentUser?.uid else {
            logDebug("No authenticated user found")
            return nil
        }
        
        let userDoc = try await db.collection("users").document(userId).getDocument()
        let userName = userDoc.data()?["fullName"] as? String
        logDebug("Retrieved user name from Firebase: \(userName ?? "none")")
        return userName
    }
    
    private func extractScores(from text: String) -> [Int] {
        var scores: [Int] = []
        logDebug("=== Score Extraction ===")
        logDebug("Input text: '\(text)'")
        
        // Clean the text first
        var cleanedText = text
            .replacingOccurrences(of: "O", with: "0")
            .replacingOccurrences(of: "o", with: "0")
            .replacingOccurrences(of: "l", with: "1")
            .replacingOccurrences(of: "I", with: "1")
            .replacingOccurrences(of: "i", with: "1")
            .replacingOccurrences(of: "S", with: "5")  // Common OCR mistake
            .replacingOccurrences(of: "B", with: "8")  // Common OCR mistake
            .replacingOccurrences(of: "g", with: "9")  // Common OCR mistake
            .replacingOccurrences(of: "Z", with: "2")  // Common OCR mistake
        
        // Remove any text in parentheses and other non-score elements
        if let parenthesesRange = cleanedText.range(of: "\\([^)]+\\)", options: .regularExpression) {
            cleanedText.removeSubrange(parenthesesRange)
        }
        
        // Remove common non-score elements
        let nonScoreElements = ["NIA", "81", "Total", "Score", "Hole", "Out", "In"]
        for element in nonScoreElements {
            cleanedText = cleanedText.replacingOccurrences(of: element, with: " ")
        }
        
        // Replace all non-numeric characters with space, except decimal points
        cleanedText = cleanedText.replacingOccurrences(of: "[^0-9\\s,|/\\\\\\-_.]", with: " ", options: .regularExpression)
        
        logDebug("Cleaned text: '\(cleanedText)'")
        
        // Split by common separators and process each component
        let separators = CharacterSet(charactersIn: " ,|/\\-_\t")
        let components = cleanedText.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        logDebug("Split components: \(components)")
        
        // Process each component
        for component in components {
            logDebug("Processing component: '\(component)'")
            
            // Handle potential decimal numbers (e.g., "4.0" should be "4")
            let numberStr = component.split(separator: ".").first.map(String.init) ?? component
            
            if let number = Int(numberStr) {
                // Validate the score is within reasonable range for golf
                if number >= 1 && number <= 20 {
                    if !scores.contains(number) {
                        scores.append(number)
                        logDebug("✅ Valid score found: \(number) (from '\(component)')", force: true)
                    } else {
                        logDebug("⚠️ Duplicate score ignored: \(number) (from '\(component)')", force: true)
                    }
                } else {
                    logDebug("❌ Score out of range: \(number) (from '\(component)')", force: true)
                }
            } else {
                logDebug("❌ Invalid number format: '\(component)'", force: true)
            }
        }
        
        // Additional validation
        if scores.count > 18 {
            logDebug("⚠️ More than 18 scores found, truncating to first 18", force: true)
            scores = Array(scores.prefix(18))
        }
        
        logDebug("Final scores: \(scores)", force: true)
        return scores
    }
    
    func submitScores(matchId: String) async {
        guard !scores.isEmpty else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            error = "User not authenticated"
            return
        }
        
        do {
            let scoreData: [String: Any] = [
                "scores": scores,
                "submittedAt": FieldValue.serverTimestamp(),
                "submittedBy": userId,
                "verified": true,
                "playerNameFound": foundPlayerName ?? "Not found"
            ]
            
            try await db.collection("matches")
                .document(matchId)
                .collection("scores")
                .document(userId)
                .setData(scoreData)
            
        } catch let firestoreError {
            error = "Failed to submit scores: \(firestoreError.localizedDescription)"
        }
    }
    
    func exportDebugInfo() {
        // Create a temporary file
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
        let fileName = "scorecard_debug_\(timestamp).txt".replacingOccurrences(of: "/", with: "-")
        
        guard let tempDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            // Add a header with timestamp
            var fullDebugInfo = "Score Verification Debug Log\n"
            fullDebugInfo += "Generated: \(timestamp)\n"
            fullDebugInfo += "----------------------------------------\n\n"
            fullDebugInfo += debugInfo
            
            try fullDebugInfo.write(to: fileURL, atomically: true, encoding: .utf8)
            shareItems = [fileURL]
            showingShareSheet = true
        } catch {
            self.error = "Failed to export debug info: \(error.localizedDescription)"
        }
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
} 