//
//  Theme.swift
//  iguardian
//
//  Created by Sukru Demir on 13.01.2026.
//

import SwiftUI

// MARK: - Color Extension for Hex
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

// MARK: - App Theme
struct Theme {
    
    // MARK: - Primary Palette
    static let backgroundPrimary = Color(hex: "0A0E14")     // Deep space black
    static let backgroundSecondary = Color(hex: "131920")   // Card backgrounds
    static let backgroundTertiary = Color(hex: "1A2230")    // Elevated surfaces
    
    // MARK: - Accent Colors
    static let accentPrimary = Color(hex: "00D9FF")         // Cyan glow - primary actions
    static let accentSecondary = Color(hex: "6366F1")       // Indigo - secondary elements
    
    // MARK: - Status Colors
    static let statusSafe = Color(hex: "10B981")            // Emerald green
    static let statusWarning = Color(hex: "F59E0B")         // Amber
    static let statusDanger = Color(hex: "EF4444")          // Red alert
    static let statusCritical = Color(hex: "DC2626")        // Deep red - pulsing
    
    // MARK: - Text Colors
    static let textPrimary = Color(hex: "F8FAFC")           // Primary text
    static let textSecondary = Color(hex: "94A3B8")         // Secondary/muted
    static let textTertiary = Color(hex: "64748B")          // Hints, timestamps
    
    // MARK: - Gradients
    static let safeGradient = LinearGradient(
        colors: [Color(hex: "10B981"), Color(hex: "059669")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    
    static let warningGradient = LinearGradient(
        colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    
    static let dangerGradient = LinearGradient(
        colors: [Color(hex: "EF4444"), Color(hex: "DC2626")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    
    static let premiumGradient = LinearGradient(
        colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6"), Color(hex: "A855F7")],
        startPoint: .leading, endPoint: .trailing
    )
    
    static let cyanGradient = LinearGradient(
        colors: [Color(hex: "00D9FF"), Color(hex: "0EA5E9")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    
    // MARK: - Typography
    static let displayLarge = Font.system(size: 48, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 34, weight: .bold, design: .rounded)
    static let headline = Font.system(size: 22, weight: .semibold)
    static let title = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 15, weight: .regular)
    static let caption = Font.system(size: 13, weight: .medium)
    static let micro = Font.system(size: 11, weight: .medium)
    
    // Monospace for data
    static let dataLarge = Font.system(size: 28, weight: .bold, design: .monospaced)
    static let dataMedium = Font.system(size: 17, weight: .semibold, design: .monospaced)
    static let dataSmall = Font.system(size: 13, weight: .medium, design: .monospaced)
    
    // MARK: - Shadows
    static let cardShadow = Color.black.opacity(0.3)
    static let glowShadow = Color(hex: "00D9FF").opacity(0.3)
    
    // MARK: - Corner Radius
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusXL: CGFloat = 24
}

// MARK: - Card Style Modifier
struct CardStyle: ViewModifier {
    var status: ThreatLevel = .normal
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .fill(Theme.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                            .stroke(borderColor.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: Theme.cardShadow, radius: 8, x: 0, y: 4)
    }
    
    var borderColor: Color {
        switch status {
        case .normal:
            return Theme.statusSafe
        case .warning:
            return Theme.statusWarning
        case .alert:
            return Theme.statusDanger
        case .critical:
            return Theme.statusCritical
        }
    }
}

extension View {
    func cardStyle(status: ThreatLevel = .normal) -> some View {
        modifier(CardStyle(status: status))
    }
}

// MARK: - Glow Effect Modifier
struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius / 2)
            .shadow(color: color.opacity(0.4), radius: radius)
            .shadow(color: color.opacity(0.2), radius: radius * 1.5)
    }
}

extension View {
    func glow(color: Color, radius: CGFloat = 10) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }
}
