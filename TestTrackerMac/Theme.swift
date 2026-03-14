import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

// MARK: - Liquid Glass Design: фиолетовый градиент, фуксия, белый текст

enum Theme {
    // Градиент фона (как в референсе)
    static let gradientDark = Color(hex: "4A3570")
    static let gradientMid = Color(hex: "6B4E8E")
    static let gradientLight = Color(hex: "7B5EAD")
    static let gradientFuchsia = Color(hex: "9B4A7A")
    
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [gradientDark, gradientMid, gradientLight, gradientFuchsia],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Жидкое стекло: полупрозрачные поверхности (чуть темнее — чтобы белый текст читался)
    static let glassWhite = Color.white.opacity(0.14)
    static let glassWhiteBright = Color.white.opacity(0.2)
    static let glassBorder = Color.white.opacity(0.35)
    static let glassHighlight = Color.white.opacity(0.12)
    
    static var contentBackground: Color { gradientDark }
    static var cardBackground: Color { glassWhite }
    static var cardBackgroundSolid: Color { glassWhiteBright }
    static var inputBackground: Color { Color.white.opacity(0.18) }
    static var rowBackground: Color { Color.white.opacity(0.1) }
    static var rowBackgroundAlt: Color { Color.white.opacity(0.06) }
    
    // Текст — белый на тёмном градиенте и стекле
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.9)
    static let textMuted = Color.white.opacity(0.75)
    static var border: Color { glassBorder }
    
    // Акцент — фуксия (как в референсе)
    static let accent = Color(hex: "E91E8C")
    static let accentGlow = Color(hex: "E91E8C").opacity(0.6)
    static let accentLight = Color(hex: "E91E8C").opacity(0.25)
    
    static let success = Color(hex: "4CAF50")
    static var successLight: Color { success.opacity(0.3) }
    static let danger = Color(hex: "FF5252")
    static var dangerLight: Color { danger.opacity(0.3) }
    
    // Стиль сайдбара: подсветка выбранного (liquid glass pill)
    static let sidebarGlass = Color.white.opacity(0.2)
    
    // Типографика — Avenir Next (выразительный современный гротеск без засечек)
    static let titleFont = Font.custom("Avenir Next Heavy", size: 22)
    static let sectionFont = Font.custom("Avenir Next Demi Bold", size: 17)
    static let bodyFont = Font.custom("Avenir Next Medium", size: 15)
    static let labelFont = Font.custom("Avenir Next Demi Bold", size: 14)
    static let smallFont = Font.custom("Avenir Next Regular", size: 12)
    
    static let spacingXXS: CGFloat = 4
    static let spacingXS: CGFloat = 8
    static let spacingS: CGFloat = 12
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 20
    static let spacingXL: CGFloat = 24
    
    static let formFieldWidth: CGFloat = 320
    static let formLabelWidth: CGFloat = 110
    static let cornerRadius: CGFloat = 12
    static let cornerRadiusSmall: CGFloat = 8
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Liquid Glass: размытый полупрозрачный фон

struct GlassBackground: ViewModifier {
    var cornerRadius: CGFloat = Theme.cornerRadius
    var useMaterial: Bool = true
    
    func body(content: Content) -> some View {
        content
            .background {
                if useMaterial {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(Theme.glassWhite)
                                .blendMode(.plusLighter)
                        )
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Theme.glassWhite)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Theme.glassBorder, lineWidth: 1)
            )
    }
}

extension View {
    func glassBackground(cornerRadius: CGFloat = Theme.cornerRadius, material: Bool = true) -> some View {
        modifier(GlassBackground(cornerRadius: cornerRadius, useMaterial: material))
    }
}

// MARK: - Кнопки в стиле Liquid Glass

struct FramedPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, Theme.spacingL)
            .padding(.vertical, Theme.spacingS)
            .background(Theme.accent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .shadow(color: Theme.accentGlow, radius: configuration.isPressed ? 4 : 12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct FramedSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingS)
            .background(Theme.glassWhiteBright)
            .foregroundStyle(.white)
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall).stroke(Theme.glassBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall))
    }
}

struct FramedDangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingS)
            .background(Theme.danger.opacity(0.85))
            .foregroundStyle(.white)
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall).stroke(Theme.danger.opacity(0.6), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall))
    }
}

struct FramedSuccessButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingS)
            .background(Theme.success.opacity(0.9))
            .foregroundStyle(.white)
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall).stroke(Theme.success.opacity(0.6), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall))
    }
}

// MARK: - GroupBox в стиле Liquid Glass

struct ThemeGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            configuration.label
                .font(Theme.sectionFont)
                .foregroundStyle(Theme.textPrimary)
            configuration.content
        }
        .padding(Theme.spacingL)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassBackground(cornerRadius: Theme.cornerRadius)
    }
}
