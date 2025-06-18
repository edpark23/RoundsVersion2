import SwiftUI

struct RoundConfirmView: View {
    @Environment(\.dismiss) private var dismiss
    let course: GolfCourseSelectorViewModel.GolfCourseDetails
    let tee: GolfCourseSelectorViewModel.TeeDetails
    @State var settings: RoundSettings
    @State private var selectedStartingHole: Int = 1
    let onConfirm: () -> Void
    @State private var showRoundActive = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()
    
    var body: some View {
        ZStack {
            // Main background
            Color(red: 0.95, green: 0.95, blue: 0.97).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Uniform header
                UniformHeader(
                    title: "CONFIRM",
                    onBackTapped: { dismiss() },
                    onMenuTapped: { /* Menu action */ }
                )
                
                // Scrollable content
                ScrollView {
                    VStack(spacing: 16) {
                        // Date display
                        HStack {
                            Text(dateFormatter.string(from: Date()))
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        
                        // Course Information Card
                        VStack(spacing: 0) {
                            HStack {
                                Text("Gotham Golf Club")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                Button("Edit") {
                                    // Edit course action
                                }
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        
                        // Tees Information Card
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                HStack(spacing: 4) {
                                    Text("Tees:")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.black)
                                    
                                    Text("White - 6675 yards")
                                        .font(.system(size: 16))
                                        .foregroundColor(.black)
                                }
                                
                                Spacer()
                                
                                Button("Edit") {
                                    // Edit tees action
                                }
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                            }
                            
                            Text("Rating: 71.70")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            Text("Slope: 131")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        
                        // Game Settings Card
                        VStack(spacing: 16) {
                            HStack {
                                Spacer()
                                Button("Edit") {
                                    // Edit settings action
                                }
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                            }
                            
                            // Settings in 2-column layout
                            VStack(spacing: 16) {
                                // Row 1
                                HStack(alignment: .top) {
                                    settingItem(title: "CONCEDE PUTT", value: "5 yds / 4.6 m")
                                    Spacer()
                                    settingItem(title: "PUTTING ASSIST", value: "Off")
                                }
                                
                                // Row 2
                                HStack(alignment: .top) {
                                    settingItem(title: "GREEN SPEED", value: "Fast")
                                    Spacer()
                                    settingItem(title: "WIND STRENGTH", value: "Low")
                                }
                                
                                // Row 3
                                HStack(alignment: .top) {
                                    settingItem(title: "MULLIGANS", value: "None")
                                    Spacer()
                                    settingItem(title: "CADDY ASSIST", value: "None")
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        
                        // Starting Hole Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Starting Hole:")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                            
                            HStack(spacing: 40) {
                                startingHoleButton(holeNumber: 1)
                                startingHoleButton(holeNumber: 10)
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        
                        // Bottom spacing for button
                        Color.clear.frame(height: 100)
                    }
                }
            }
            
            // Start Round button fixed at bottom
            VStack {
                Spacer()
                
                Button(action: {
                    // Update settings with selected starting hole
                    settings.startingHole = selectedStartingHole
                    // Present the RoundActiveView with full screen cover
                    showRoundActive = true
                }) {
                    Text("Start Round")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color(red: 0.0, green: 75/255, blue: 143/255))
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 34)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Initialize the starting hole selector with the current value
            selectedStartingHole = settings.startingHole
        }
        .fullScreenCover(isPresented: $showRoundActive) {
            // When RoundActiveView is dismissed, call onConfirm to complete the flow
            onConfirm()
        } content: {
            NavigationStack {
                RoundActiveView(
                    course: course,
                    tee: tee,
                    settings: settings
                )
            }
        }
    }
    
    private func settingItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
                .tracking(0.5)
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func startingHoleButton(holeNumber: Int) -> some View {
        Button(action: {
            selectedStartingHole = holeNumber
        }) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(selectedStartingHole == holeNumber ? Color(red: 0.0, green: 75/255, blue: 143/255) : Color.gray.opacity(0.4), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if selectedStartingHole == holeNumber {
                        Circle()
                            .fill(Color(red: 0.0, green: 75/255, blue: 143/255))
                            .frame(width: 14, height: 14)
                    }
                }
                
                Text("\(holeNumber)")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black)
            }
        }
    }
}

// Preview
struct RoundConfirmView_Previews: PreviewProvider {
    static var previews: some View {
        RoundConfirmView(
            course: GolfCourseSelectorViewModel.GolfCourseDetails(
                id: "sample_course",
                clubName: "Gotham Golf Club",
                courseName: "Main Course",
                city: "Gotham",
                state: "NY",
                tees: []
            ),
            tee: GolfCourseSelectorViewModel.TeeDetails(
                type: "male",
                teeName: "White",
                courseRating: 71.70,
                slopeRating: 131,
                totalYards: 6675,
                parTotal: 72,
                holes: []
            ),
            settings: RoundSettings(
                concedePutt: "5 yds / 4.6 m",
                puttingAssist: "Off",
                greenSpeed: "Fast",
                windStrength: "Low",
                mulligans: "None",
                caddyAssist: "None"
            ),
            onConfirm: {}
        )
    }
} 