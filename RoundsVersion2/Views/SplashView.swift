import SwiftUI

struct SplashView: View {
    // Remove unused animation states to improve performance
    // Static properties for pre-computed values to avoid recalculation each time
    private static let precomputedGradient = LinearGradient(
        gradient: Gradient(
            stops: [
                Gradient.Stop(color: Color(red: 0.129, green: 0.200, blue: 0.337), location: 0.0),
                Gradient.Stop(color: Color(red: 0.169, green: 0.278, blue: 0.412), location: 0.1),
                Gradient.Stop(color: Color(red: 0.208, green: 0.353, blue: 0.486), location: 0.2),
                Gradient.Stop(color: Color(red: 0.255, green: 0.431, blue: 0.561), location: 0.3),
                Gradient.Stop(color: Color(red: 0.298, green: 0.506, blue: 0.639), location: 0.4),
                Gradient.Stop(color: Color(red: 0.345, green: 0.580, blue: 0.710), location: 0.5),
                Gradient.Stop(color: Color(red: 0.404, green: 0.651, blue: 0.769), location: 0.6),
                Gradient.Stop(color: Color(red: 0.459, green: 0.718, blue: 0.824), location: 0.7),
                Gradient.Stop(color: Color(red: 0.569, green: 0.788, blue: 0.875), location: 0.8),
                Gradient.Stop(color: Color(red: 0.710, green: 0.863, blue: 0.929), location: 0.9),
                Gradient.Stop(color: Color(red: 0.843, green: 0.929, blue: 0.969), location: 1.0)
            ]
        ),
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Cached text for better performance
    private static let roundsText: some View = {
        Text("ROUNDS")
            .font(.system(size: 56, weight: .bold))
            .tracking(2)
            .foregroundColor(.white)
            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
    }()
    
    var body: some View {
        // Simplified view hierarchy for faster rendering
        ZStack {
            // Use precomputed gradient
            Self.precomputedGradient
                .ignoresSafeArea()
                .drawingGroup() // Use Metal acceleration for the gradient
            
            // Use cached text
            Self.roundsText
        }
        .edgesIgnoringSafeArea(.all)
    }
}

// Use a separate preview provider to avoid impacting the main view's performance
struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
} 