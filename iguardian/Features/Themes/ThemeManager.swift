//
//  ThemeManager.swift
//  iguardian
//
//  Theme management system with multiple theme options
//

import SwiftUI
import Combine

// MARK: - Theme Definition
struct AppTheme: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let icon: String
    let isPremium: Bool
    
    // Colors (stored as hex strings for Codable)
    let backgroundPrimary: String
    let backgroundSecondary: String
    let backgroundTertiary: String
    let accentPrimary: String
    let accentSecondary: String
    let textPrimary: String
    let textSecondary: String
    let textTertiary: String
    let statusSafe: String
    let statusWarning: String
    let statusDanger: String
    
    // Computed color properties
    var bgPrimary: Color { Color(hex: backgroundPrimary) }
    var bgSecondary: Color { Color(hex: backgroundSecondary) }
    var bgTertiary: Color { Color(hex: backgroundTertiary) }
    var accent: Color { Color(hex: accentPrimary) }
    var accentAlt: Color { Color(hex: accentSecondary) }
    var txtPrimary: Color { Color(hex: textPrimary) }
    var txtSecondary: Color { Color(hex: textSecondary) }
    var txtTertiary: Color { Color(hex: textTertiary) }
    var safe: Color { Color(hex: statusSafe) }
    var warning: Color { Color(hex: statusWarning) }
    var danger: Color { Color(hex: statusDanger) }
}

// MARK: - Built-in Themes
extension AppTheme {
    
    // Default Dark Theme (Midnight)
    static let midnight = AppTheme(
        id: "midnight",
        name: "Midnight",
        icon: "moon.stars.fill",
        isPremium: false,
        backgroundPrimary: "0A0E14",
        backgroundSecondary: "131920",
        backgroundTertiary: "1A2230",
        accentPrimary: "00D9FF",
        accentSecondary: "6366F1",
        textPrimary: "F8FAFC",
        textSecondary: "94A3B8",
        textTertiary: "64748B",
        statusSafe: "10B981",
        statusWarning: "F59E0B",
        statusDanger: "EF4444"
    )
    
    // OLED Pure Black
    static let oled = AppTheme(
        id: "oled",
        name: "OLED Black",
        icon: "circle.fill",
        isPremium: true,
        backgroundPrimary: "000000",
        backgroundSecondary: "0A0A0A",
        backgroundTertiary: "141414",
        accentPrimary: "00D9FF",
        accentSecondary: "8B5CF6",
        textPrimary: "FFFFFF",
        textSecondary: "A0A0A0",
        textTertiary: "606060",
        statusSafe: "00FF88",
        statusWarning: "FFB800",
        statusDanger: "FF3B3B"
    )
    
    // Cyberpunk Neon
    static let neon = AppTheme(
        id: "neon",
        name: "Neon",
        icon: "bolt.fill",
        isPremium: true,
        backgroundPrimary: "0D0221",
        backgroundSecondary: "150734",
        backgroundTertiary: "1A0A3E",
        accentPrimary: "FF00FF",
        accentSecondary: "00FFFF",
        textPrimary: "FFFFFF",
        textSecondary: "B794F4",
        textTertiary: "7C3AED",
        statusSafe: "00FF9F",
        statusWarning: "FFE600",
        statusDanger: "FF0055"
    )
    
    // Military Green
    static let tactical = AppTheme(
        id: "tactical",
        name: "Tactical",
        icon: "shield.checkered",
        isPremium: true,
        backgroundPrimary: "0A1208",
        backgroundSecondary: "111E0F",
        backgroundTertiary: "182816",
        accentPrimary: "4ADE80",
        accentSecondary: "22C55E",
        textPrimary: "E8F5E9",
        textSecondary: "81C784",
        textTertiary: "4CAF50",
        statusSafe: "00E676",
        statusWarning: "FFC107",
        statusDanger: "FF5252"
    )
    
    // Ocean Blue
    static let ocean = AppTheme(
        id: "ocean",
        name: "Ocean",
        icon: "water.waves",
        isPremium: true,
        backgroundPrimary: "0A1628",
        backgroundSecondary: "0F2140",
        backgroundTertiary: "142952",
        accentPrimary: "38BDF8",
        accentSecondary: "0EA5E9",
        textPrimary: "F0F9FF",
        textSecondary: "7DD3FC",
        textTertiary: "38BDF8",
        statusSafe: "34D399",
        statusWarning: "FBBF24",
        statusDanger: "F87171"
    )
    
    // Sunset Orange
    static let sunset = AppTheme(
        id: "sunset",
        name: "Sunset",
        icon: "sun.horizon.fill",
        isPremium: true,
        backgroundPrimary: "1A0F0A",
        backgroundSecondary: "2D1810",
        backgroundTertiary: "3D2218",
        accentPrimary: "FB923C",
        accentSecondary: "F97316",
        textPrimary: "FFF7ED",
        textSecondary: "FDBA74",
        textTertiary: "EA580C",
        statusSafe: "4ADE80",
        statusWarning: "FACC15",
        statusDanger: "EF4444"
    )
    
    // All themes
    static let allThemes: [AppTheme] = [
        .midnight,
        .oled,
        .neon,
        .tactical,
        .ocean,
        .sunset
    ]
}

// MARK: - Theme Manager
@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme {
        didSet { saveTheme() }
    }
    
    @Published var availableThemes: [AppTheme] = AppTheme.allThemes
    
    private let key = "selected_theme_id"
    
    private init() {
        if let savedId = UserDefaults.standard.string(forKey: key),
           let theme = AppTheme.allThemes.first(where: { $0.id == savedId }) {
            currentTheme = theme
        } else {
            currentTheme = .midnight
        }
    }
    
    func selectTheme(_ theme: AppTheme) {
        guard !theme.isPremium || StoreManager.shared.isPremium else {
            return
        }
        currentTheme = theme
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.id, forKey: key)
    }
}
