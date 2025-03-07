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
        NavigationView {
            VStack(spacing: 20) {
                if viewModel.isProcessing {
                    if let image = viewModel.capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(10)
                            .overlay {
                                ProgressView("Processing scorecard...")
                                    .padding()
                                    .background(Color(.systemBackground).opacity(0.8))
                                    .cornerRadius(10)
                            }
                    }
                } else if let processedImage = viewModel.processedImage {
                    Image(uiImage: processedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(10)
                } else if let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(10)
                }
                
                if !viewModel.scores.isEmpty {
                    ScoreCardView(
                        scores: viewModel.scores,
                        holes: selectedCourse.tees.first?.holes ?? []
                    )
                    
                    if let playerName = viewModel.foundPlayerName {
                        Text("Scores found for: \(playerName)")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    } else {
                        Text("Using scores from first row")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    
                    Button {
                        Task {
                            await viewModel.submitScores(matchId: matchId)
                            dismiss()
                        }
                    } label: {
                        Text("Submit Scores")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                } else if !viewModel.isProcessing {
                    VStack(spacing: 16) {
                        Button {
                            sourceType = .photoLibrary
                            showingImagePicker = true
                        } label: {
                            Label("Choose Photo", systemImage: "photo.on.rectangle")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        
                        if isCameraAvailable {
                            Button {
                                sourceType = .camera
                                showingImagePicker = true
                            } label: {
                                Label("Take Photo", systemImage: "camera")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Button {
                    showingDebugInfo.toggle()
                } label: {
                    Label("Debug Info", systemImage: "info.circle")
                        .font(.caption)
                }
                .sheet(isPresented: $showingDebugInfo) {
                    NavigationView {
                        ScrollView {
                            VStack(spacing: 20) {
                                Text(viewModel.debugInfo)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack(spacing: 16) {
                                    Button {
                                        UIPasteboard.general.string = viewModel.debugInfo
                                    } label: {
                                        Label("Copy to Clipboard", systemImage: "doc.on.doc")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue)
                                            .cornerRadius(10)
                                    }
                                    
                                    Button {
                                        showingShareSheet = true
                                    } label: {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue)
                                            .cornerRadius(10)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .navigationTitle("Debug Information")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingDebugInfo = false
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Score Verification")
            .navigationBarTitleDisplayMode(.inline)
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