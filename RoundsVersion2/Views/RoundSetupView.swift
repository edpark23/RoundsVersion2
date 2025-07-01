import SwiftUI

struct RoundSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedConcedePutt = "5 ft / 4.6 m"
    @State private var selectedPuttingAssist = "Off"
    @State private var selectedGreenSpeed = "Fast"
    @State private var selectedWindStrength = "Low"
    @State private var selectedMulligans = "None"
    @State private var selectedCaddyAssist = "Off"
    
    let onSetupComplete: (RoundSettings) -> Void
    let onCancel: () -> Void
    
    // Options for each setting - updated to match the design
    let concedePuttOptions = ["None", "2 ft / 0.6 m", "3 ft / 0.9 m", "4 ft / 1.2 m", "5 ft / 4.6 m", "6 ft / 1.8 m"]
    let puttingAssistOptions = ["Off", "On"]
    let greenSpeedOptions = ["Slow", "Medium", "Fast"]
    let windStrengthOptions = ["None", "Low", "Medium", "High"]
    let mulligansOptions = ["None", "1 per 9", "2 per 9", "Unlimited"]
    let caddyAssistOptions = ["Off", "On"]
    
    var body: some View {
        ZStack {
            // Main background
            Color(red: 0.95, green: 0.95, blue: 0.97).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navy blue header - copying exact structure from GolfCourseSelectorView
                ZStack {
                    Color(red: 0.0, green: 75/255, blue: 143/255).ignoresSafeArea(edges: .top)
                    
                    VStack(spacing: 0) {
                        // Status bar space
                        Color.clear.frame(height: 44)
                        
                        // Navigation bar
                        HStack {
                            Button(action: {
                                onCancel()
                            }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20, weight: .semibold))
                            }
                            
                            Spacer()
                            
                            Text("SETUP ROUND")
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .bold))
                                .tracking(0.5)
                            
                            Spacer()
                            
                            Button(action: {
                                // Menu action
                            }) {
                                Image(systemName: "line.horizontal.3")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                    }
                }
                .frame(height: 90)
                
                // Scrollable settings content
                ScrollView {
                    VStack(spacing: 24) {
                        // Game settings
                        settingSection(title: "CONCEDE PUTT", selection: $selectedConcedePutt, options: concedePuttOptions)
                        settingSection(title: "PUTTING ASSIST", selection: $selectedPuttingAssist, options: puttingAssistOptions)
                        settingSection(title: "GREEN SPEED", selection: $selectedGreenSpeed, options: greenSpeedOptions)
                        settingSection(title: "WIND STRENGTH", selection: $selectedWindStrength, options: windStrengthOptions)
                        settingSection(title: "MULLIGANS", selection: $selectedMulligans, options: mulligansOptions)
                        settingSection(title: "CADDY ASSIST", selection: $selectedCaddyAssist, options: caddyAssistOptions)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 100) // Space for continue button
                }
                
                Spacer()
            }
            
            // Continue button fixed at bottom
            VStack {
                Spacer()
                
                Button(action: {
                    let settings = RoundSettings(
                        concedePutt: selectedConcedePutt,
                        puttingAssist: selectedPuttingAssist,
                        greenSpeed: selectedGreenSpeed,
                        windStrength: selectedWindStrength,
                        mulligans: selectedMulligans,
                        caddyAssist: selectedCaddyAssist,
                        startingHole: 1 // Default to hole 1, will be updated in confirm view
                    )
                    onSetupComplete(settings)
                }) {
                    Text("Continue")
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
    }
    
    private func settingSection(title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection.wrappedValue = option
                    }
                }
            } label: {
                HStack {
                    Text(selection.wrappedValue)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
            .padding(.horizontal, 16)
        }
    }
}

struct RoundSetupView_Previews: PreviewProvider {
    static var previews: some View {
        RoundSetupView(
            onSetupComplete: { _ in },
            onCancel: { }
        )
    }
} 