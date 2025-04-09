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
        VStack(spacing: 16) {
            // Date display
            Text(dateFormatter.string(from: Date()))
                .font(.system(size: 18))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)
                .padding(.top, 20)
            
            // Course Information
            infoCard(
                content: {
                    HStack {
                        Text(course.clubName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Edit")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                    }
                }
            )
            
            // Tee Information
            infoCard(
                content: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Tees:")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                            
                            Text("\(tee.teeName) - \(tee.totalYards) yards")
                                .font(.system(size: 18))
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            Text("Edit")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                        }
                        
                        Text("Rating: \(String(format: "%.2f", tee.courseRating))")
                            .font(.system(size: 17))
                            .foregroundColor(.gray)
                        
                        Text("Slope: \(tee.slopeRating)")
                            .font(.system(size: 17))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            )
            
            // Game Settings
            infoCard(
                content: {
                    VStack(spacing: 20) {
                        HStack {
                            Spacer()
                            Text("Edit")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                        }
                        
                        // Row 1
                        HStack(alignment: .top) {
                            settingItem(title: "CONCEDE PUTT", value: settings.concedePutt)
                            Spacer()
                            settingItem(title: "PUTTING ASSIST", value: settings.puttingAssist)
                        }
                        
                        // Row 2
                        HStack(alignment: .top) {
                            settingItem(title: "GREEN SPEED", value: settings.greenSpeed)
                            Spacer()
                            settingItem(title: "WIND STRENGTH", value: settings.windStrength)
                        }
                        
                        // Row 3
                        HStack(alignment: .top) {
                            settingItem(title: "MULLIGANS", value: settings.mulligans)
                            Spacer()
                            settingItem(title: "CADDY ASSIST", value: settings.caddyAssist)
                        }
                    }
                }
            )
            
            // Starting Hole selection
            infoCard(
                content: {
                    VStack(alignment: .leading) {
                        Text("Starting Hole:")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.bottom, 10)
                        
                        HStack(spacing: 30) {
                            startingHoleButton(holeNumber: 1)
                            startingHoleButton(holeNumber: 10)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            )
            
            Spacer()
            
            // Start Round button
            Button(action: {
                // Update settings with selected starting hole
                settings.startingHole = selectedStartingHole
                // Present the RoundActiveView with full screen cover
                showRoundActive = true
                // Note: we're not calling onConfirm() here anymore
            }) {
                Text("START ROUND")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(AppColors.primaryNavy)
                    )
                    .padding(.horizontal, 30)
            }
            .padding(.bottom, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("CONFIRM")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // Profile action
                } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
        }
        .navigationBarBackground(backgroundColor: AppColors.primaryNavy)
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
    
    private func infoCard<Content: View>(content: @escaping () -> Content) -> some View {
        content()
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .background(Color.white)
            )
            .padding(.horizontal, 30)
    }
    
    private func settingItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }
    
    private func startingHoleButton(holeNumber: Int) -> some View {
        Button(action: {
            selectedStartingHole = holeNumber
        }) {
            ZStack {
                Circle()
                    .stroke(AppColors.primaryNavy, lineWidth: 2)
                    .frame(width: 40, height: 40)
                
                if selectedStartingHole == holeNumber {
                    Circle()
                        .fill(AppColors.primaryNavy)
                        .frame(width: 32, height: 32)
                }
                
                Text("\(holeNumber)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(selectedStartingHole == holeNumber ? .white : AppColors.primaryNavy)
            }
        }
    }
}

// Extension to customize the Navigation Bar background
extension View {
    func navigationBarBackground(backgroundColor: Color) -> some View {
        self.modifier(NavigationBarModifier(backgroundColor: backgroundColor))
    }
}

struct NavigationBarModifier: ViewModifier {
    var backgroundColor: Color
    
    func body(content: Content) -> some View {
        content
            .toolbarBackground(backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// Preview
struct RoundConfirmView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
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
} 