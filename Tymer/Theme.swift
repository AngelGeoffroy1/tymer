//
//  Theme.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI

// MARK: - Tymer Colors
extension Color {
    /// Noir pur - Fond principal
    static let tymerBlack = Color(hex: "000000")
    
    /// Blanc pur - Textes principaux
    static let tymerWhite = Color(hex: "FFFFFF")
    
    /// Gris - Textes secondaires
    static let tymerGray = Color(hex: "888888")
    
    /// Gris foncé - Bordures et séparateurs
    static let tymerDarkGray = Color(hex: "333333")
    
    /// Gris clair - Éléments subtils
    static let tymerLightGray = Color(hex: "CCCCCC")
}

// MARK: - Color Hex Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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

// MARK: - Tymer Fonts
extension Font {
    /// Funnel Display Light - Corps de texte
    static func funnelLight(_ size: CGFloat) -> Font {
        .custom("FunnelDisplay-Light", size: size)
    }
    
    /// Funnel Display SemiBold - Titres
    static func funnelSemiBold(_ size: CGFloat) -> Font {
        .custom("FunnelDisplay-SemiBold", size: size)
    }
    
    // MARK: Preset Sizes
    
    /// Titre principal - 48pt SemiBold
    static var tymerTitle: Font {
        .funnelSemiBold(48)
    }
    
    /// Titre secondaire - 32pt SemiBold
    static var tymerHeadline: Font {
        .funnelSemiBold(32)
    }
    
    /// Sous-titre - 24pt SemiBold
    static var tymerSubheadline: Font {
        .funnelSemiBold(24)
    }
    
    /// Corps de texte - 18pt Light
    static var tymerBody: Font {
        .funnelLight(18)
    }
    
    /// Texte secondaire - 14pt Light
    static var tymerCaption: Font {
        .funnelLight(14)
    }
    
    /// Petit texte - 12pt Light
    static var tymerSmall: Font {
        .funnelLight(12)
    }
}

// MARK: - View Modifiers
extension View {
    /// Applique le fond noir Tymer
    func tymerBackground() -> some View {
        self
            .background(Color.tymerBlack)
            .preferredColorScheme(.dark)
    }
    
    /// Style de texte principal blanc
    func tymerText() -> some View {
        self.foregroundColor(.tymerWhite)
    }
    
    /// Style de texte secondaire gris
    func tymerSecondaryText() -> some View {
        self.foregroundColor(.tymerGray)
    }
}

// MARK: - Button Styles
struct TymerPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.funnelSemiBold(18))
            .foregroundColor(.tymerBlack)
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(Color.tymerWhite)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct TymerSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.funnelLight(16))
            .foregroundColor(.tymerWhite)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .stroke(Color.tymerWhite, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct TymerGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.funnelLight(16))
            .foregroundColor(.tymerGray)
            .opacity(configuration.isPressed ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == TymerPrimaryButtonStyle {
    static var tymerPrimary: TymerPrimaryButtonStyle { TymerPrimaryButtonStyle() }
}

extension ButtonStyle where Self == TymerSecondaryButtonStyle {
    static var tymerSecondary: TymerSecondaryButtonStyle { TymerSecondaryButtonStyle() }
}

extension ButtonStyle where Self == TymerGhostButtonStyle {
    static var tymerGhost: TymerGhostButtonStyle { TymerGhostButtonStyle() }
}
