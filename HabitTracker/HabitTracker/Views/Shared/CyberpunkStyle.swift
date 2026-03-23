import SwiftUI

// MARK: - Palette
extension Color {
    static let neonGreen  = Color(hex: "#39FF14")
    static let neonBlue   = Color(hex: "#00F5FF")
    static let neonPink   = Color(hex: "#FF006E")
    static let voidBlack  = Color(hex: "#0A0A0F")
    static let darkNavy   = Color(hex: "#0D0D1A")
    static let dimGray    = Color(hex: "#1A1A2E")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Typography
extension Font {
    static func firaCode(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold:   return .custom("FiraCode-Bold", size: size)
        case .medium: return .custom("FiraCode-Medium", size: size)
        case .light:  return .custom("FiraCode-Light", size: size)
        default:      return .custom("FiraCode-Regular", size: size)
        }
    }
}

// MARK: - Shared Enums (used in models and UI)
enum HabitType: String, Codable {
    case boolean
    case quantified
}

enum Difficulty: String, Codable, CaseIterable {
    case easy, medium, hard

    var xp: Int {
        switch self {
        case .easy:   return 10
        case .medium: return 25
        case .hard:   return 50
        }
    }

    var label: String { rawValue.uppercased() }

    func next() -> Difficulty {
        let all = Difficulty.allCases
        let idx = all.firstIndex(of: self) ?? 0
        return all[(idx + 1) % all.count]
    }
}

enum NexusTab: String, CaseIterable {
    case dashboard    = "DASHBOARD"
    case habits       = "HABITS"
    case achievements = "ACHIEVEMENTS"
    case settings     = "SETTINGS"
}
