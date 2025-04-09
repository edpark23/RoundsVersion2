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
    @Published var copyableDebugText: String = ""
    @Published var manualScoreInput: String = ""
    @Published var showingManualScoreEntry: Bool = false
    
    private let db = Firestore.firestore()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.rounds", category: "ScoreVerification")
    
    private var shouldLog = false
    private var userNameRow: String?
    
    private func logDebug(_ message: String, force: Bool = false) {
        debugInfo += message + "\n"
        copyableDebugText += message + "\n"
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
        copyableDebugText = ""
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
                error = "Could not detect scores. Please ensure the scorecard is clearly visible or enter scores manually."
                showingManualScoreEntry = true
            } else if extractedScores.count < 18 {
                // If we found some scores but not all 18, show a warning
                logDebug("⚠️ Only found \(extractedScores.count) scores, expected 18. Consider entering scores manually.", force: true)
                scores = extractedScores
                foundPlayerName = playerName
                showingManualScoreEntry = true
            } else {
                scores = extractedScores
                foundPlayerName = playerName
            }
        } catch {
            self.error = "Failed to process image: \(error.localizedDescription)"
            logDebug("❌ Error: \(error.localizedDescription)", force: true)
            showingManualScoreEntry = true
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
        // First try the grid-based approach
        if let result = try await processGridBasedScorecard(from: observations) {
            let (playerName, gridScores, observation) = result
            if !gridScores.isEmpty && gridScores.count >= 8 {
                logDebug("✅ Grid-based approach found \(gridScores.count) scores: \(gridScores)", force: true)
                return (playerName, gridScores, observation)
            }
        }
        
        // Try the column-based approach if grid-based doesn't find enough scores
        if let result = try await processColumnBasedScorecard(from: observations) {
            let (playerName, columnScores, observation) = result
            if !columnScores.isEmpty && columnScores.count > 8 {
                logDebug("✅ Column-based approach found \(columnScores.count) scores: \(columnScores)", force: true)
                return (playerName, columnScores, observation)
            }
        }
        
        // Try the clustering approach if other approaches don't find enough scores
        if let result = try await processClusterBasedScorecard(from: observations) {
            let (playerName, clusterScores, observation) = result
            if !clusterScores.isEmpty && clusterScores.count > 8 {
                logDebug("✅ Cluster-based approach found \(clusterScores.count) scores: \(clusterScores)", force: true)
                return (playerName, clusterScores, observation)
            }
        }
        
        // Fall back to the row-based approach if other approaches fail
        var rows: [(observation: VNRecognizedTextObservation, yPosition: CGFloat, text: String, xPosition: CGFloat)] = []
        
        // Extract text and position information
        for observation in observations {
            if let recognizedText = observation.topCandidates(1).first {
                let text = recognizedText.string
                let yPosition = observation.boundingBox.origin.y
                let xPosition = observation.boundingBox.origin.x
                rows.append((observation, yPosition, text, xPosition))
                // Log all text for debugging
                logDebug("Raw text found: '\(text)' at x: \(String(format: "%.2f", xPosition)), y: \(String(format: "%.2f", yPosition))", force: true)
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
        var userNameRow: (observation: VNRecognizedTextObservation, yPosition: CGFloat)?
        
        // First, find the exact row containing the username
        for row in sortedRows {
            if row.text.lowercased().contains(userName.lowercased()) {
                logDebug("📍 Found name '\(userName)' in text: '\(row.text)' at position (x: \(String(format: "%.2f", row.xPosition)), y: \(String(format: "%.2f", row.yPosition)))", force: true)
                userNameRow = (row.observation, row.yPosition)
                break
            }
        }
        
        // If we didn't find the username, return early
        guard let userNameRow = userNameRow else {
            logDebug("❌ Could not find username '\(userName)' in any text", force: true)
            return (nil, [], nil)
        }
        
        // Use an extremely strict threshold for the same row (0.005 instead of 0.01)
        let sameRowThreshold: CGFloat = 0.005
        logDebug("🔍 Using strict row threshold: \(sameRowThreshold) for y-position: \(String(format: "%.5f", userNameRow.yPosition))", force: true)
        
        // Find all text elements that are EXACTLY on the same row (very similar y-position)
        let sameRowTexts = sortedRows.filter { row in
            let yDiff = abs(row.yPosition - userNameRow.yPosition)
            let isInSameRow = yDiff < sameRowThreshold
            logDebug("Checking text: '\(row.text)' at y: \(String(format: "%.5f", row.yPosition)), diff: \(String(format: "%.5f", yDiff)), same row: \(isInSameRow)", force: true)
            return isInSameRow
        }.sorted { $0.xPosition < $1.xPosition }
        
        // Log individual text elements in the row
        logDebug("=== Text elements in the EXACT same row as username ===", force: true)
        for text in sameRowTexts {
            logDebug("Text segment at x: \(String(format: "%.4f", text.xPosition)), y: \(String(format: "%.4f", text.yPosition)): '\(text.text)'", force: true)
        }
        
        // Find the index of the username in the sorted row texts
        var usernameIndex = -1
        for (index, text) in sameRowTexts.enumerated() {
            if text.text.lowercased().contains(userName.lowercased()) {
                usernameIndex = index
                break
            }
        }
        
        // Only consider text elements to the right of the username
        // This ensures we're only getting scores that come after the player name
        var relevantTexts = sameRowTexts
        if usernameIndex >= 0 {
            relevantTexts = Array(sameRowTexts.dropFirst(usernameIndex + 1))
            logDebug("Found username at position \(usernameIndex), only considering \(relevantTexts.count) text elements to the right", force: true)
        }
        
        let fullRowText = relevantTexts.map { $0.text }.joined(separator: " ")
        logDebug("📝 Complete row text after username: '\(fullRowText)'", force: true)
        
        // ONLY look for scores in the same row as the username
        let scoresInRow = extractScores(from: fullRowText)
        
        if !scoresInRow.isEmpty {
            let limitedScores = Array(scoresInRow.prefix(18)) // Ensure we don't exceed 18 scores
            logDebug("✅ Found \(limitedScores.count) scores in the EXACT same row as the username: \(limitedScores)", force: true)
            return (userName, limitedScores, userNameRow.observation)
        } else {
            logDebug("❌ No scores found in the EXACT same row as the username", force: true)
            return (userName, [], userNameRow.observation)
        }
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
                    // CHANGED: Allow duplicate scores to preserve order
                    scores.append(number)
                    logDebug("✅ Valid score found: \(number) (from '\(component)')", force: true)
                } else {
                    logDebug("❌ Score out of range: \(number) (from '\(component)')", force: true)
                }
            } else {
                logDebug("❌ Invalid number format: '\(component)')", force: true)
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
    
    // New function to handle manual score entry
    func setManualScores(_ scoreString: String) {
        let components = scoreString.components(separatedBy: CharacterSet(charactersIn: ", "))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var newScores: [Int] = []
        var hasError = false
        
        for component in components {
            if let score = Int(component), score >= 1 && score <= 20 {
                newScores.append(score)
            } else {
                hasError = true
                break
            }
        }
        
        if hasError || newScores.isEmpty {
            error = "Invalid score format. Please enter scores as numbers separated by commas."
        } else {
            scores = newScores
            error = nil
            logDebug("✅ Manually entered scores: \(scores)", force: true)
        }
    }
    
    private func processGridBasedScorecard(from observations: [VNRecognizedTextObservation]) async throws -> (playerName: String?, scores: [Int], selectedObservation: VNRecognizedTextObservation?)? {
        logDebug("🔍 Trying grid-based scorecard processing approach", force: true)
        
        var textElements: [(observation: VNRecognizedTextObservation, text: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat)] = []
        
        // Extract all text elements with their positions and dimensions
        for observation in observations {
            if let recognizedText = observation.topCandidates(1).first {
                let text = recognizedText.string
                let x = observation.boundingBox.origin.x
                let y = observation.boundingBox.origin.y
                let width = observation.boundingBox.width
                let height = observation.boundingBox.height
                
                textElements.append((observation, text, x, y, width, height))
                logDebug("Grid text: '\(text)' at x: \(String(format: "%.3f", x)), y: \(String(format: "%.3f", y)), w: \(String(format: "%.3f", width)), h: \(String(format: "%.3f", height))", force: true)
            }
        }
        
        // Get current user's name
        guard let userName = try? await getCurrentUserName() else {
            logDebug("❌ Could not get current user name", force: true)
            return nil
        }
        
        // Find the player name in the text elements
        var playerNameElement: (observation: VNRecognizedTextObservation, text: String, x: CGFloat, y: CGFloat)? = nil
        for element in textElements {
            if element.text.lowercased().contains(userName.lowercased()) {
                playerNameElement = (element.observation, element.text, element.x, element.y)
                logDebug("📍 Grid approach found name '\(userName)' in text: '\(element.text)' at position (x: \(String(format: "%.3f", element.x)), y: \(String(format: "%.3f", element.y)))", force: true)
                break
            }
        }
        
        guard let playerNameElement = playerNameElement else {
            logDebug("❌ Grid approach could not find username in any text", force: true)
            return nil
        }
        
        // STEP 1: Find all hole numbers (1-18) to establish the scorecard structure
        var holeElements: [(number: Int, x: CGFloat, y: CGFloat)] = []
        
        for element in textElements {
            if let number = Int(element.text), number >= 1 && number <= 18 {
                // Check if this is likely a hole number (typically at the top of the scorecard)
                if element.y > 0.5 && element.y < 0.6 { // More precise range for hole numbers
                    holeElements.append((number, element.x, element.y))
                    logDebug("🔢 Found hole number \(number) at x: \(String(format: "%.3f", element.x)), y: \(String(format: "%.3f", element.y))", force: true)
                }
            }
        }
        
        // Filter out duplicate hole numbers by keeping only the ones with the most consistent y-coordinate
        let averageHoleY = holeElements.map { $0.y }.reduce(0, +) / CGFloat(holeElements.count)
        let filteredHoleElements = holeElements.filter { abs($0.y - averageHoleY) < 0.02 }
        
        // Sort hole elements by hole number to ensure correct order
        let sortedHoleElements = filteredHoleElements.sorted { $0.number < $1.number }
        
        logDebug("📊 Found \(sortedHoleElements.count) unique hole numbers", force: true)
        for hole in sortedHoleElements {
            logDebug("  - Hole \(hole.number) at x: \(String(format: "%.3f", hole.x))", force: true)
        }
        
        // STEP 2: Find all potential scores in the player's row with a relaxed threshold
        let playerY = playerNameElement.y
        let rowThreshold: CGFloat = 0.04 // Relaxed threshold for the entire row
        
        var potentialScores: [(score: Int, x: CGFloat, y: CGFloat)] = []
        
        for element in textElements {
            if let score = Int(element.text), score >= 1 && score <= 20 {
                let yDiff = abs(element.y - playerY)
                
                // Check if it's in the player's row and to the right of the player name
                if yDiff < rowThreshold && element.x > playerNameElement.x {
                    potentialScores.append((score, element.x, element.y))
                    logDebug("  - Potential score: \(score) at x: \(String(format: "%.3f", element.x)), y: \(String(format: "%.3f", element.y)), y-diff: \(String(format: "%.4f", yDiff))", force: true)
                }
            }
        }
        
        // STEP 3: Match scores to holes based on x-coordinate alignment
        var holeToScoreMap: [Int: (score: Int, x: CGFloat, distance: CGFloat)] = [:]
        
        // For each hole, find the closest score by x-coordinate
        for hole in sortedHoleElements {
            var bestMatch: (score: Int, x: CGFloat, distance: CGFloat)? = nil
            
            for score in potentialScores {
                let xDistance = abs(score.x - hole.x)
                
                // Only consider scores that are reasonably close to the hole's x-coordinate
                if xDistance < 0.03 {
                    if bestMatch == nil || xDistance < bestMatch!.distance {
                        bestMatch = (score.score, score.x, xDistance)
                    }
                }
            }
            
            if let match = bestMatch {
                holeToScoreMap[hole.number] = match
                logDebug("✅ Matched hole \(hole.number) with score \(match.score) (distance: \(String(format: "%.4f", match.distance)))", force: true)
            }
        }
        
        // STEP 4: For holes without a direct match, try to infer scores based on position
        if holeToScoreMap.count < 18 {
            logDebug("⚠️ Only matched \(holeToScoreMap.count) holes directly, trying to infer remaining scores", force: true)
            
            // Sort potential scores by x-coordinate
            let sortedScores = potentialScores.sorted { $0.x < $1.x }
            
            // For each unmatched hole, find the closest unused score
            for holeNumber in 1...18 {
                if holeToScoreMap[holeNumber] == nil {
                    // Find the hole's x-coordinate
                    if let holeX = sortedHoleElements.first(where: { $0.number == holeNumber })?.x {
                        // Find the closest unused score
                        var closestScore: (score: Int, x: CGFloat, distance: CGFloat)? = nil
                        
                        for score in sortedScores {
                            // Skip scores that are already matched
                            if !holeToScoreMap.values.contains(where: { $0.score == score.score && $0.x == score.x }) {
                                let distance = abs(score.x - holeX)
                                if closestScore == nil || distance < closestScore!.distance {
                                    closestScore = (score.score, score.x, distance)
                                }
                            }
                        }
                        
                        if let match = closestScore {
                            holeToScoreMap[holeNumber] = match
                            logDebug("✅ Inferred hole \(holeNumber) with score \(match.score) (distance: \(String(format: "%.4f", match.distance)))", force: true)
                        }
                    }
                }
            }
        }
        
        // STEP 5: As a last resort, use any remaining scores in order
        if holeToScoreMap.count < 18 {
            logDebug("⚠️ Still only have \(holeToScoreMap.count) holes matched, using remaining scores in order", force: true)
            
            // Get unused scores
            let usedScorePositions = holeToScoreMap.values.map { ($0.score, $0.x) }
            let unusedScores = potentialScores.filter { score in
                !usedScorePositions.contains(where: { $0.0 == score.score && $0.1 == score.x })
            }.sorted { $0.x < $1.x }
            
            // Get unmatched holes
            let unmatchedHoles = (1...18).filter { holeToScoreMap[$0] == nil }.sorted()
            
            // Assign unused scores to unmatched holes
            for (index, holeNumber) in unmatchedHoles.enumerated() {
                if index < unusedScores.count {
                    let score = unusedScores[index]
                    holeToScoreMap[holeNumber] = (score.score, score.x, 999) // Use a large distance to indicate it's a fallback
                    logDebug("✅ Assigned remaining score \(score.score) to hole \(holeNumber)", force: true)
                }
            }
        }
        
        // STEP 6: Build the final scores array
        var finalScores: [Int] = []
        var scoreDetails: [(hole: Int, score: Int, x: CGFloat, confidence: String)] = []
        
        for holeNumber in 1...18 {
            if let scoreInfo = holeToScoreMap[holeNumber] {
                finalScores.append(scoreInfo.score)
                
                // Determine confidence level based on distance
                let confidence: String
                if scoreInfo.distance < 0.01 {
                    confidence = "High"
                } else if scoreInfo.distance < 0.02 {
                    confidence = "Medium"
                } else {
                    confidence = "Low"
                }
                
                scoreDetails.append((holeNumber, scoreInfo.score, scoreInfo.x, confidence))
            } else {
                // If we still don't have a score for this hole, use a placeholder
                finalScores.append(0) // Use 0 as a placeholder
                scoreDetails.append((holeNumber, 0, 0, "None"))
                logDebug("⚠️ No score found for hole \(holeNumber), using placeholder", force: true)
            }
        }
        
        // Remove placeholder scores if we don't have enough real scores
        let realScores = finalScores.filter { $0 > 0 }
        if realScores.count < 8 {
            logDebug("❌ Not enough real scores found (\(realScores.count)), giving up", force: true)
            return nil
        }
        
        // Log the final scores with confidence levels
        logDebug("✅ Grid approach final scores:", force: true)
        for detail in scoreDetails {
            let scoreStatus = detail.score > 0 ? "✓" : "❌"
            logDebug("  - Hole \(detail.hole): \(detail.score) \(scoreStatus) (x: \(String(format: "%.3f", detail.x)), confidence: \(detail.confidence))", force: true)
        }
        
        // Generate a pre-filled manual entry string for easy correction
        let manualEntryString = finalScores.map { String($0) }.joined(separator: ", ")
        logDebug("📝 Pre-filled manual entry: \(manualEntryString)", force: true)
        
        return (userName, finalScores, playerNameElement.observation)
    }
    
    private func processColumnBasedScorecard(from observations: [VNRecognizedTextObservation]) async throws -> (playerName: String?, scores: [Int], selectedObservation: VNRecognizedTextObservation?)? {
        logDebug("🔍 Trying column-based scorecard processing approach", force: true)
        
        var textElements: [(observation: VNRecognizedTextObservation, text: String, x: CGFloat, y: CGFloat)] = []
        
        // Extract all text elements with their positions
        for observation in observations {
            if let recognizedText = observation.topCandidates(1).first {
                let text = recognizedText.string
                let x = observation.boundingBox.origin.x
                let y = observation.boundingBox.origin.y
                
                textElements.append((observation, text, x, y))
            }
        }
        
        // Get current user's name
        guard let userName = try? await getCurrentUserName() else {
            logDebug("❌ Could not get current user name", force: true)
            return nil
        }
        
        // Find the player name in the text elements
        var playerNameElement: (observation: VNRecognizedTextObservation, text: String, x: CGFloat, y: CGFloat)? = nil
        for element in textElements {
            if element.text.lowercased().contains(userName.lowercased()) {
                playerNameElement = (element.observation, element.text, element.x, element.y)
                logDebug("📍 Column approach found name '\(userName)' in text: '\(element.text)' at position (x: \(String(format: "%.3f", element.x)), y: \(String(format: "%.3f", element.y)))", force: true)
                break
            }
        }
        
        guard let playerNameElement = playerNameElement else {
            logDebug("❌ Column approach could not find username in any text", force: true)
            return nil
        }
        
        // Find hole numbers (1-18) to identify column positions
        var holeColumns: [(holeNumber: Int, x: CGFloat)] = []
        for element in textElements {
            if let number = Int(element.text), number >= 1 && number <= 18 {
                // Check if this is likely a hole number (typically at the top of the scorecard)
                if element.y > 0.5 { // Assuming scorecard is in the upper half of the image
                    holeColumns.append((number, element.x))
                    logDebug("🔢 Found potential hole number \(number) at x: \(String(format: "%.3f", element.x)), y: \(String(format: "%.3f", element.y))", force: true)
                }
            }
        }
        
        // Sort hole columns by hole number
        holeColumns.sort { $0.holeNumber < $1.holeNumber }
        
        if holeColumns.isEmpty {
            logDebug("❌ Column approach could not find any hole numbers", force: true)
            return nil
        }
        
        // Find scores that align with hole columns and are near the player's row
        var scores: [Int?] = Array(repeating: nil, count: 18)
        let rowThreshold: CGFloat = 0.05 // More relaxed vertical threshold
        let columnThreshold: CGFloat = 0.02 // Horizontal alignment threshold
        
        for element in textElements {
            // Check if it's a potential score
            if let score = Int(element.text), score >= 1 && score <= 20 {
                // Check if it's near the player's row
                let yDiff = abs(element.y - playerNameElement.y)
                let isNearPlayerRow = yDiff < rowThreshold
                
                if isNearPlayerRow {
                    // Find which hole column this score aligns with
                    for (_, holeColumn) in holeColumns.enumerated() {
                        let xDiff = abs(element.x - holeColumn.x)
                        if xDiff < columnThreshold {
                            let holeIndex = holeColumn.holeNumber - 1
                            if holeIndex >= 0 && holeIndex < 18 {
                                scores[holeIndex] = score
                                logDebug("✅ Column approach matched score \(score) with hole \(holeColumn.holeNumber) at x: \(String(format: "%.3f", element.x))", force: true)
                            }
                        }
                    }
                }
            }
        }
        
        // Convert to non-optional array, removing any nil values
        let finalScores = scores.compactMap { $0 }
        
        if !finalScores.isEmpty {
            logDebug("✅ Column approach found \(finalScores.count) scores: \(finalScores)", force: true)
            return (userName, finalScores, playerNameElement.observation)
        } else {
            logDebug("❌ Column approach found no valid scores", force: true)
            return nil
        }
    }
    
    private func processClusterBasedScorecard(from observations: [VNRecognizedTextObservation]) async throws -> (playerName: String?, scores: [Int], selectedObservation: VNRecognizedTextObservation?)? {
        logDebug("🔍 Trying cluster-based scorecard processing approach", force: true)
        
        var textElements: [(observation: VNRecognizedTextObservation, text: String, x: CGFloat, y: CGFloat)] = []
        
        // Extract all text elements with their positions
        for observation in observations {
            if let recognizedText = observation.topCandidates(1).first {
                let text = recognizedText.string
                let x = observation.boundingBox.origin.x
                let y = observation.boundingBox.origin.y
                
                textElements.append((observation, text, x, y))
            }
        }
        
        // Get current user's name
        guard let userName = try? await getCurrentUserName() else {
            logDebug("❌ Could not get current user name", force: true)
            return nil
        }
        
        // Find the player name in the text elements
        var playerNameElement: (observation: VNRecognizedTextObservation, text: String, x: CGFloat, y: CGFloat)? = nil
        for element in textElements {
            if element.text.lowercased().contains(userName.lowercased()) {
                playerNameElement = (element.observation, element.text, element.x, element.y)
                logDebug("📍 Cluster approach found name '\(userName)' in text: '\(element.text)' at position (x: \(String(format: "%.3f", element.x)), y: \(String(format: "%.3f", element.y)))", force: true)
                break
            }
        }
        
        guard let playerNameElement = playerNameElement else {
            logDebug("❌ Cluster approach could not find username in any text", force: true)
            return nil
        }
        
        // Cluster text elements into rows based on their y-coordinates
        let clusterThreshold: CGFloat = 0.01 // Threshold for clustering
        var rowClusters: [[CGFloat]] = []
        
        for element in textElements {
            let y = element.y
            
            // Check if this y-coordinate fits into an existing cluster
            var foundCluster = false
            for i in 0..<rowClusters.count {
                let clusterY = rowClusters[i].reduce(0, +) / CGFloat(rowClusters[i].count)
                if abs(y - clusterY) < clusterThreshold {
                    rowClusters[i].append(y)
                    foundCluster = true
                    break
                }
            }
            
            // If no matching cluster, create a new one
            if !foundCluster {
                rowClusters.append([y])
            }
        }
        
        // Calculate the average y-coordinate for each cluster
        let clusterAverages = rowClusters.map { $0.reduce(0, +) / CGFloat($0.count) }
        
        // Find which cluster the player name belongs to
        let playerNameY = playerNameElement.y
        var playerClusterIndex = -1
        var minDiff: CGFloat = 1.0
        
        for (index, clusterY) in clusterAverages.enumerated() {
            let diff = abs(playerNameY - clusterY)
            if diff < minDiff {
                minDiff = diff
                playerClusterIndex = index
            }
        }
        
        if playerClusterIndex == -1 {
            logDebug("❌ Cluster approach could not find which cluster the player name belongs to", force: true)
            return nil
        }
        
        let playerClusterY = clusterAverages[playerClusterIndex]
        logDebug("📊 Cluster approach found player name in cluster with average y: \(String(format: "%.3f", playerClusterY))", force: true)
        
        // Find all potential scores in the player's cluster
        var potentialScores: [(score: Int, x: CGFloat)] = []
        
        for element in textElements {
            // Check if it's in the player's cluster
            if abs(element.y - playerClusterY) < clusterThreshold {
                // Check if it's a potential score
                if let score = Int(element.text), score >= 1 && score <= 20 {
                    // Check if it's to the right of the player name
                    if element.x > playerNameElement.x {
                        potentialScores.append((score, element.x))
                        logDebug("🔢 Cluster approach found potential score \(score) at x: \(String(format: "%.3f", element.x))", force: true)
                    }
                }
            }
        }
        
        // Sort potential scores by x-position (left to right)
        potentialScores.sort { $0.x < $1.x }
        
        // Extract the scores
        let scores = potentialScores.map { $0.score }
        
        if !scores.isEmpty {
            let limitedScores = Array(scores.prefix(18)) // Ensure we don't exceed 18 scores
            logDebug("✅ Cluster approach found \(limitedScores.count) scores: \(limitedScores)", force: true)
            return (userName, limitedScores, playerNameElement.observation)
        } else {
            logDebug("❌ Cluster approach found no valid scores", force: true)
            return nil
        }
    }
    
    // Enhanced manual score entry function with pre-filled values
    func prepareManualScoreEntry() {
        if !scores.isEmpty {
            manualScoreInput = scores.map { String($0) }.joined(separator: ", ")
        }
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
} 