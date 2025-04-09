import Foundation

// Model to hold all round settings
struct RoundSettings {
    var concedePutt: String
    var puttingAssist: String
    var greenSpeed: String
    var windStrength: String
    var mulligans: String
    var caddyAssist: String
    var startingHole: Int = 1 // Default to hole 1
    
    // Default settings
    static var defaultSettings: RoundSettings {
        RoundSettings(
            concedePutt: "5 ft / 4.6 m",
            puttingAssist: "Off",
            greenSpeed: "Fast",
            windStrength: "Low",
            mulligans: "None",
            caddyAssist: "None"
        )
    }
} 