import SwiftUI

extension Color {
    // Icon backgrounds theo content type
    static let iconText   = Color(hex: "#EEEDFE")
    static let iconURL    = Color(hex: "#E1F5EE")
    static let iconImage  = Color(hex: "#FAEEDA")
    static let iconFile   = Color(hex: "#E6F1FB")

    // Icon foregrounds
    static let iconTextFG  = Color(hex: "#B8860B") // Gold đậm, hài hòa với accent mới
    static let iconURLFG   = Color(hex: "#0F6E56")
    static let iconImageFG = Color(hex: "#854F0B")
    static let iconFileFG  = Color(hex: "#185FA5")

    // Accent chính
    static let accent = Color(hex: "#D4AF37") // Gold cổ điển

    // Helper init từ hex string
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
