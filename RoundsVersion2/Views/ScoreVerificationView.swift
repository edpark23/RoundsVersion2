import SwiftUI
import Vision
import VisionKit

struct ScoreVerificationView: View {
    @StateObject private var viewModel = ScoreVerificationViewModel()
    @Environment(\.dismiss) private var dismiss
    let matchId: String
    let selectedCourse: GolfCourseSelectorViewModel.GolfCourseDetails
    
    @State private var showingImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingDebugInfo = false
    @State private var showingShareSheet = false
    
    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundWhite
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Text("Score Verification")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.primaryNavy)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Image Card
                    VStack(spacing: 16) {
                        if let image = viewModel.processedImage ?? viewModel.capturedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .cardStyle()
                        } else {
                            uploadPlaceholder
                        }
                        
                        Button(action: { showingImagePicker = true }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text(viewModel.capturedImage == nil ? "Upload Scorecard" : "Retake Photo")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                        }
                        .navyButton()
                    }
                    .padding(.horizontal)
                    
                    // Results Section
                    if !viewModel.scores.isEmpty {
                        resultsCard
                    }
                    
                    // Debug Info
                    if !viewModel.debugInfo.isEmpty {
                        debugCard
                    }
                }
                .padding(.vertical)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            if sourceType == .camera && !isCameraAvailable {
                Text("Camera is not available on this device")
                    .padding()
            } else {
                ImagePicker(image: $viewModel.capturedImage, sourceType: sourceType)
                    .onDisappear {
                        if viewModel.capturedImage != nil {
                            Task {
                                await viewModel.processImage()
                            }
                        }
                    }
                    .interactiveDismissDisabled()
            }
        }
        .onChange(of: viewModel.capturedImage) { oldValue, newValue in
            if newValue != nil {
                Task {
                    await viewModel.processImage()
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
        .sheet(isPresented: $showingShareSheet) {
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
            let text = """
            Score Verification Debug Log
            Generated: \(timestamp)
            ----------------------------------------
            
            \(viewModel.debugInfo)
            """
            ShareSheet(items: [text])
        }
    }
    
    private var uploadPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(AppColors.secondaryNavy)
            
            Text("Take a photo of your scorecard")
                .font(.headline)
                .foregroundColor(AppColors.primaryNavy)
            
            Text("Make sure the scores are clearly visible")
                .font(.subheadline)
                .foregroundColor(AppColors.subtleGray)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
        .cardStyle()
        .padding(.horizontal)
    }
    
    private var resultsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detected Scores")
                .font(.headline)
                .foregroundColor(AppColors.primaryNavy)
            
            if let playerName = viewModel.foundPlayerName {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(AppColors.highlightBlue)
                    Text("Player: \(playerName)")
                        .foregroundColor(AppColors.primaryNavy)
                }
            }
            
            // Compact golf scorecard layout
            VStack(alignment: .leading, spacing: 4) {
                Text("Swipe to see all holes →")
                    .font(.caption)
                    .foregroundColor(AppColors.subtleGray)
                    .padding(.bottom, 4)
                
                ScrollView(.horizontal, showsIndicators: true) {
                    VStack(spacing: 0) {
                        // Header row with hole numbers
                        HStack(spacing: 0) {
                            Text("Hole")
                                .frame(width: 40, height: 30)
                                .background(AppColors.primaryNavy)
                                .foregroundColor(.white)
                            
                            ForEach(0..<viewModel.scores.count, id: \.self) { index in
                                Text("\(index + 1)")
                                    .frame(width: 30, height: 30)
                                    .background(AppColors.primaryNavy)
                                    .foregroundColor(.white)
                            }
                            
                            // Total column
                            Text("Tot")
                                .frame(width: 40, height: 30)
                                .background(AppColors.primaryNavy)
                                .foregroundColor(.white)
                        }
                        .font(.system(.caption2, design: .rounded))
                        .fontWeight(.bold)
                        
                        // Par row (if available)
                        if let selectedTee = selectedCourse.tees.first {
                            HStack(spacing: 0) {
                                Text("Par")
                                    .frame(width: 40, height: 30)
                                    .background(Color.gray.opacity(0.1))
                                
                                ForEach(selectedTee.holes.prefix(viewModel.scores.count), id: \.number) { hole in
                                    Text("\(hole.par)")
                                        .frame(width: 30, height: 30)
                                        .background(Color.gray.opacity(0.1))
                                }
                                
                                // Total par
                                let totalPar = selectedTee.holes.prefix(viewModel.scores.count).reduce(0) { $0 + $1.par }
                                Text("\(totalPar)")
                                    .frame(width: 40, height: 30)
                                    .background(Color.gray.opacity(0.1))
                                    .fontWeight(.bold)
                            }
                            .font(.system(.caption, design: .rounded))
                        }
                        
                        // Score row
                        HStack(spacing: 0) {
                            Text("Score")
                                .frame(width: 40, height: 30)
                                .background(AppColors.backgroundWhite)
                            
                            ForEach(viewModel.scores.indices, id: \.self) { index in
                                Text("\(viewModel.scores[index])")
                                    .frame(width: 30, height: 30)
                                    .background(
                                        getScoreBackgroundColor(
                                            score: viewModel.scores[index],
                                            par: selectedCourse.tees.first?.holes.count ?? 0 > index ? 
                                                selectedCourse.tees.first?.holes[index].par ?? 0 : 0
                                        )
                                    )
                                    .foregroundColor(.white)
                            }
                            
                            // Total score
                            let totalScore = viewModel.scores.reduce(0, +)
                            Text("\(totalScore)")
                                .frame(width: 40, height: 30)
                                .background(AppColors.highlightBlue)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                        .font(.system(.caption, design: .rounded))
                    }
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.subtleGray.opacity(0.3), lineWidth: 1)
                    )
                    // Make sure the content is wide enough to scroll
                    .frame(minWidth: UIScreen.main.bounds.width - 60)
                }
                .padding(.vertical, 4)
            }
            .padding(.horizontal, 4)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            Button(action: {
                Task {
                    await viewModel.submitScores(matchId: matchId)
                    dismiss()
                }
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Submit Scores")
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .navyButton()
        }
        .padding()
        .cardStyle()
        .padding(.horizontal)
    }
    
    // Helper function to get background color based on score relative to par
    private func getScoreBackgroundColor(score: Int, par: Int) -> Color {
        if par == 0 { return AppColors.subtleGray }
        
        switch score - par {
        case ..<0:  // Under par (birdie or better)
            return Color.red
        case 0:     // Par
            return AppColors.primaryNavy
        case 1:     // Bogey
            return AppColors.highlightBlue
        default:    // Double bogey or worse
            return AppColors.subtleGray
        }
    }
    
    private var debugCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Debug Information")
                    .font(.headline)
                    .foregroundColor(AppColors.primaryNavy)
                
                Spacer()
                
                Button(action: { viewModel.exportDebugInfo() }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(AppColors.highlightBlue)
                }
            }
            
            ScrollView {
                Text(viewModel.debugInfo)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundColor(AppColors.subtleGray)
            }
            .frame(maxHeight: 200)
        }
        .padding()
        .cardStyle()
        .padding(.horizontal)
    }
}

struct ScoreCardView: View {
    let scores: [Int]
    let holes: [GolfCourseSelectorViewModel.HoleDetails]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 0) {
                // Header row
                HStack(spacing: 0) {
                    Text("Hole")
                        .frame(width: 50)
                    ForEach(0..<scores.count, id: \.self) { index in
                        Text("\(index + 1)")
                            .frame(width: 40)
                    }
                }
                .font(.caption)
                .bold()
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                
                // Par row
                HStack(spacing: 0) {
                    Text("Par")
                        .frame(width: 50)
                    ForEach(holes, id: \.number) { hole in
                        Text("\(hole.par)")
                            .frame(width: 40)
                    }
                }
                .font(.caption)
                .padding(.vertical, 4)
                
                // Score row
                HStack(spacing: 0) {
                    Text("Score")
                        .frame(width: 50)
                    ForEach(scores.indices, id: \.self) { index in
                        Text("\(scores[index])")
                            .frame(width: 40)
                            .foregroundColor(scoreColor(score: scores[index], par: holes[index].par))
                    }
                }
                .font(.caption)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .padding()
        }
    }
    
    private func scoreColor(score: Int, par: Int) -> Color {
        if score < par { return .green }
        if score > par { return .red }
        return .primary
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        
        // Check if the requested source type is available
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            picker.sourceType = sourceType
            
            // Add additional configuration for camera
            if sourceType == .camera {
                picker.cameraCaptureMode = .photo
                picker.cameraDevice = .rear
                picker.showsCameraControls = true
            }
        } else {
            // Fallback to photo library if requested source is not available
            picker.sourceType = .photoLibrary
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // Fix iPad presentation
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIView() // Required for iPad
            popover.permittedArrowDirections = []
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 