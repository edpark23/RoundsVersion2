import SwiftUI

struct RoundSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedConcedePutt = "2 Feet"
    @State private var selectedPuttingAssist = "On"
    @State private var selectedGreenSpeed = "Medium"
    @State private var selectedWindStrength = "Medium"
    @State private var selectedMulligans = "1 per 9"
    @State private var selectedCaddyAssist = "On"
    
    let onSetupComplete: (RoundSettings) -> Void
    let onCancel: () -> Void
    
    // Options for each setting
    let concedePuttOptions = ["None", "2 Feet", "3 Feet", "4 Feet", "5 Feet", "6 Feet"]
    let puttingAssistOptions = ["Off", "On"]
    let greenSpeedOptions = ["Slow", "Medium", "Fast"]
    let windStrengthOptions = ["None", "Light", "Medium", "Strong"]
    let mulligansOptions = ["None", "1 per 9", "2 per 9", "Unlimited"]
    let caddyAssistOptions = ["Off", "On"]
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Button(action: {
                    onCancel()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Text("ROUND SETTINGS")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
                
                // Empty spacer to balance the X button
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            ScrollView {
                VStack(spacing: 25) {
                    // Game settings
                    settingSection(title: "CONCEDE PUTT", selection: $selectedConcedePutt, options: concedePuttOptions)
                    settingSection(title: "PUTTING ASSIST", selection: $selectedPuttingAssist, options: puttingAssistOptions)
                    settingSection(title: "GREEN SPEED", selection: $selectedGreenSpeed, options: greenSpeedOptions)
                    settingSection(title: "WIND STRENGTH", selection: $selectedWindStrength, options: windStrengthOptions)
                    settingSection(title: "MULLIGANS", selection: $selectedMulligans, options: mulligansOptions)
                    settingSection(title: "CADDY ASSIST", selection: $selectedCaddyAssist, options: caddyAssistOptions)
                    
                    Spacer(minLength: 30)
                    
                    // Continue button
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
                        Text("CONTINUE")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(AppColors.primaryNavy)
                            )
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 30)
                }
                .padding(.top, 20)
            }
        }
        .background(Color.white)
        .cornerRadius(20, corners: [.topLeft, .topRight])
    }
    
    private func settingSection(title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .padding(.horizontal, 20)
            
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
                        .padding(.leading, 20)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                        .padding(.trailing, 20)
                }
                .frame(height: 55)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 20)
            }
        }
    }
}

struct RoundSetupView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            
            VStack {
                Spacer()
                
                RoundSetupView(
                    onSetupComplete: { _ in },
                    onCancel: { }
                )
            }
        }
    }
} 