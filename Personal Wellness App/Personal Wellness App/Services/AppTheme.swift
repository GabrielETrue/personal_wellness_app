import SwiftUI

struct AppTheme {
    // Backgrounds
    static let backgroundPrimary   = Color(hex: "0A0F1E")
    static let backgroundSecondary = Color(hex: "131929")
    static let backgroundCard      = Color(hex: "1A2235")

    // Accents
    static let accentBlue   = Color(hex: "4A9FFF")
    static let accentPurple = Color(hex: "9B6BFF")
    static let accentCyan   = Color(hex: "00E5FF")

    // Gradients
    static let xpGradient = LinearGradient(
        colors: [Color(hex: "4A9FFF"), Color(hex: "9B6BFF")],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let cardGradient = LinearGradient(
        colors: [Color(hex: "1A2235"), Color(hex: "131929")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Text
    static let textPrimary   = Color.white
    static let textSecondary = Color(hex: "8A9BB5")

    // Status
    static let success = Color(hex: "00E5FF")
    static let warning = Color(hex: "FFB347")
    static let danger  = Color(hex: "FF6B6B")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF,
                            int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Shared UI Components

struct GradientProgressBar: View {
    let value: Double
    var height: CGFloat = 8
    var tintColor: Color? = nil

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.backgroundSecondary)
                    .frame(height: height)
                let fillWidth = max(0, geometry.size.width * max(0, min(value, 1.0)))
                if let color = tintColor {
                    Capsule()
                        .fill(color)
                        .frame(width: fillWidth, height: height)
                } else {
                    Capsule()
                        .fill(AppTheme.xpGradient)
                        .frame(width: fillWidth, height: height)
                }
            }
        }
        .frame(height: height)
    }
}

struct GradientSaveButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline).fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(isEnabled ? AnyShapeStyle(AppTheme.xpGradient) : AnyShapeStyle(AppTheme.backgroundCard))
                .clipShape(Capsule())
                .shadow(color: isEnabled ? AppTheme.accentBlue.opacity(0.4) : .clear, radius: 12)
        }
        .disabled(!isEnabled)
    }
}
