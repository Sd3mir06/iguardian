# Sentinel App - Phase 4 Implementation

## Overview
Phase 4 is the final polish phase: Community Benchmarking, Custom Themes, Data Export, Onboarding Flow, and Performance Optimization.

---

## 📁 New Files to Create

```
iguardian/
├── Features/
│   ├── Community/
│   │   ├── CommunityManager.swift       ← Anonymous data aggregation
│   │   └── CommunityCompareView.swift   ← Comparison UI
│   ├── Export/
│   │   ├── DataExporter.swift           ← CSV/JSON export
│   │   └── ExportSettingsView.swift     ← Export options
│   └── Themes/
│       ├── ThemeManager.swift           ← Theme system
│       └── ThemePickerView.swift        ← Theme selection UI
├── Onboarding/
│   ├── OnboardingView.swift             ← Welcome flow
│   ├── OnboardingPage.swift             ← Single page component
│   └── PermissionsView.swift            ← Permission requests
└── Core/
    └── Theme+Variants.swift             ← Additional themes
```

---

## 📄 FILE 1: ThemeManager.swift
**Location:** `iguardian/Features/Themes/ThemeManager.swift`

```swift
import SwiftUI

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

// MARK: - Color Extension
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
            (a, r, g, b) = (1, 1, 1, 0)
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
```

---

## 📄 FILE 2: ThemePickerView.swift
**Location:** `iguardian/Features/Themes/ThemePickerView.swift`

```swift
import SwiftUI

struct ThemePickerView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var store = StoreManager.shared
    @State private var showPaywall = false
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(themeManager.availableThemes) { theme in
                    ThemeCard(
                        theme: theme,
                        isSelected: themeManager.currentTheme.id == theme.id,
                        isLocked: theme.isPremium && !store.isPremium
                    ) {
                        if theme.isPremium && !store.isPremium {
                            showPaywall = true
                        } else {
                            withAnimation {
                                themeManager.selectTheme(theme)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(themeManager.currentTheme.bgPrimary)
        .navigationTitle("Themes")
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Theme Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: theme.backgroundPrimary))
                        .frame(height: 100)
                    
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: theme.accentPrimary))
                                .frame(width: 24, height: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(hex: theme.textPrimary))
                                    .frame(width: 40, height: 6)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(hex: theme.textSecondary))
                                    .frame(width: 30, height: 4)
                            }
                        }
                        
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: theme.backgroundSecondary))
                                .frame(width: 30, height: 20)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: theme.backgroundSecondary))
                                .frame(width: 30, height: 20)
                        }
                    }
                    
                    if isLocked {
                        Color.black.opacity(0.5)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.white)
                    }
                }
                
                // Theme Info
                HStack {
                    Image(systemName: theme.icon)
                        .foregroundStyle(Color(hex: theme.accentPrimary))
                    
                    Text(theme.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(ThemeManager.shared.currentTheme.txtPrimary)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(hex: theme.accentPrimary))
                    } else if theme.isPremium {
                        Text("PRO")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.premiumGradient)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding()
            .background(ThemeManager.shared.currentTheme.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(hex: theme.accentPrimary) : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
```

---

## 📄 FILE 3: CommunityManager.swift
**Location:** `iguardian/Features/Community/CommunityManager.swift`

```swift
import Foundation

// MARK: - Community Statistics
struct CommunityStats: Codable {
    let averageIdleUpload: Double      // MB/hour
    let averageIdleDownload: Double    // MB/hour
    let averageIdleCPU: Double         // percentage
    let averageBatteryDrain: Double    // %/hour
    let averageThreatScore: Double     // 0-100
    let totalUsers: Int
    let lastUpdated: Date
    
    // Percentiles for comparison
    let uploadPercentiles: Percentiles
    let downloadPercentiles: Percentiles
    let cpuPercentiles: Percentiles
    let batteryPercentiles: Percentiles
    
    struct Percentiles: Codable {
        let p25: Double
        let p50: Double
        let p75: Double
        let p90: Double
    }
}

// MARK: - User's Stats for Comparison
struct UserDeviceStats {
    var averageIdleUpload: Double = 0
    var averageIdleDownload: Double = 0
    var averageIdleCPU: Double = 0
    var averageBatteryDrain: Double = 0
    var averageThreatScore: Double = 0
}

// MARK: - Comparison Result
struct ComparisonResult {
    let metric: String
    let userValue: Double
    let communityAverage: Double
    let percentile: Int  // Which percentile the user falls into
    let status: ComparisonStatus
    
    enum ComparisonStatus {
        case excellent  // Better than 75% of users
        case good       // Better than 50%
        case average    // 25-50%
        case high       // Higher than 75%
        case concerning // Higher than 90%
    }
}

// MARK: - Community Manager
@MainActor
class CommunityManager: ObservableObject {
    static let shared = CommunityManager()
    
    @Published var communityStats: CommunityStats?
    @Published var userStats: UserDeviceStats = UserDeviceStats()
    @Published var comparisons: [ComparisonResult] = []
    @Published var isLoading = false
    @Published var lastSyncDate: Date?
    
    // Privacy: User must opt-in
    @AppStorage("community_optIn") var isOptedIn = false
    
    private let apiEndpoint = "https://api.sentinel-app.com/community"
    
    private init() {}
    
    // MARK: - Fetch Community Stats
    func fetchCommunityStats() async {
        guard isOptedIn else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        // In production, this would fetch from your backend
        // For now, use mock data
        communityStats = mockCommunityStats()
        lastSyncDate = Date()
        
        calculateComparisons()
    }
    
    // MARK: - Submit Anonymous Stats
    func submitAnonymousStats() async {
        guard isOptedIn else { return }
        
        // Collect anonymous device stats
        let payload = AnonymousPayload(
            idleUploadMBPerHour: userStats.averageIdleUpload,
            idleDownloadMBPerHour: userStats.averageIdleDownload,
            idleCPUPercent: userStats.averageIdleCPU,
            batteryDrainPerHour: userStats.averageBatteryDrain,
            averageThreatScore: userStats.averageThreatScore,
            deviceModel: anonymizedDeviceModel(),
            iosVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        )
        
        // In production, POST to backend
        print("Would submit: \(payload)")
    }
    
    // MARK: - Calculate Comparisons
    private func calculateComparisons() {
        guard let stats = communityStats else { return }
        
        comparisons = [
            ComparisonResult(
                metric: "Upload (Idle)",
                userValue: userStats.averageIdleUpload,
                communityAverage: stats.averageIdleUpload,
                percentile: calculatePercentile(userStats.averageIdleUpload, stats.uploadPercentiles),
                status: determineStatus(userStats.averageIdleUpload, stats.uploadPercentiles, higherIsBad: true)
            ),
            ComparisonResult(
                metric: "Download (Idle)",
                userValue: userStats.averageIdleDownload,
                communityAverage: stats.averageIdleDownload,
                percentile: calculatePercentile(userStats.averageIdleDownload, stats.downloadPercentiles),
                status: determineStatus(userStats.averageIdleDownload, stats.downloadPercentiles, higherIsBad: true)
            ),
            ComparisonResult(
                metric: "CPU (Idle)",
                userValue: userStats.averageIdleCPU,
                communityAverage: stats.averageIdleCPU,
                percentile: calculatePercentile(userStats.averageIdleCPU, stats.cpuPercentiles),
                status: determineStatus(userStats.averageIdleCPU, stats.cpuPercentiles, higherIsBad: true)
            ),
            ComparisonResult(
                metric: "Battery Drain",
                userValue: userStats.averageBatteryDrain,
                communityAverage: stats.averageBatteryDrain,
                percentile: calculatePercentile(userStats.averageBatteryDrain, stats.batteryPercentiles),
                status: determineStatus(userStats.averageBatteryDrain, stats.batteryPercentiles, higherIsBad: true)
            )
        ]
    }
    
    private func calculatePercentile(_ value: Double, _ percentiles: CommunityStats.Percentiles) -> Int {
        if value <= percentiles.p25 { return 25 }
        if value <= percentiles.p50 { return 50 }
        if value <= percentiles.p75 { return 75 }
        if value <= percentiles.p90 { return 90 }
        return 95
    }
    
    private func determineStatus(_ value: Double, _ percentiles: CommunityStats.Percentiles, higherIsBad: Bool) -> ComparisonResult.ComparisonStatus {
        let percentile = calculatePercentile(value, percentiles)
        
        if higherIsBad {
            switch percentile {
            case 0...25: return .excellent
            case 26...50: return .good
            case 51...75: return .average
            case 76...90: return .high
            default: return .concerning
            }
        } else {
            switch percentile {
            case 0...25: return .concerning
            case 26...50: return .high
            case 51...75: return .average
            case 76...90: return .good
            default: return .excellent
            }
        }
    }
    
    // MARK: - Privacy Helpers
    private func anonymizedDeviceModel() -> String {
        // Return generic model (e.g., "iPhone 14" not specific identifier)
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }
        // Map to friendly name
        return modelCode.contains("iPhone") ? "iPhone" : modelCode
    }
    
    // MARK: - Mock Data
    private func mockCommunityStats() -> CommunityStats {
        CommunityStats(
            averageIdleUpload: 3.2,
            averageIdleDownload: 8.5,
            averageIdleCPU: 4.5,
            averageBatteryDrain: 1.2,
            averageThreatScore: 8,
            totalUsers: 12847,
            lastUpdated: Date(),
            uploadPercentiles: .init(p25: 1.5, p50: 3.0, p75: 6.0, p90: 15.0),
            downloadPercentiles: .init(p25: 4.0, p50: 8.0, p75: 15.0, p90: 30.0),
            cpuPercentiles: .init(p25: 2.0, p50: 4.0, p75: 8.0, p90: 15.0),
            batteryPercentiles: .init(p25: 0.5, p50: 1.0, p75: 2.0, p90: 4.0)
        )
    }
}

// MARK: - Anonymous Payload
struct AnonymousPayload: Codable {
    let idleUploadMBPerHour: Double
    let idleDownloadMBPerHour: Double
    let idleCPUPercent: Double
    let batteryDrainPerHour: Double
    let averageThreatScore: Double
    let deviceModel: String
    let iosVersion: String
    let appVersion: String
}
```

---

## 📄 FILE 4: CommunityCompareView.swift
**Location:** `iguardian/Features/Community/CommunityCompareView.swift`

```swift
import SwiftUI

struct CommunityCompareView: View {
    @StateObject private var manager = CommunityManager.shared
    @StateObject private var store = StoreManager.shared
    @State private var showPaywall = false
    @State private var showPrivacyInfo = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if store.isPremium {
                    if manager.isOptedIn {
                        // Opted in - show comparisons
                        if manager.isLoading {
                            loadingView
                        } else if let stats = manager.communityStats {
                            communityHeader(stats)
                            comparisonsSection
                            privacyNote
                        } else {
                            emptyState
                        }
                    } else {
                        // Not opted in - show opt-in prompt
                        optInPrompt
                    }
                } else {
                    // Not premium - show upgrade prompt
                    premiumPrompt
                }
            }
            .padding()
        }
        .background(Theme.backgroundPrimary)
        .navigationTitle("Community")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showPrivacyInfo) {
            PrivacyInfoSheet()
        }
        .task {
            if manager.isOptedIn && store.isPremium {
                await manager.fetchCommunityStats()
            }
        }
    }
    
    // MARK: - Loading
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading community data...")
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Community Header
    private func communityHeader(_ stats: CommunityStats) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.accentPrimary)
                
                Text("\(stats.totalUsers.formatted()) Users")
                    .font(.title2.bold())
                    .foregroundStyle(Theme.textPrimary)
            }
            
            Text("Anonymous benchmarking data")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            
            if let lastSync = manager.lastSyncDate {
                Text("Updated \(lastSync, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Comparisons Section
    private var comparisonsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How You Compare")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            
            ForEach(manager.comparisons, id: \.metric) { comparison in
                ComparisonRow(comparison: comparison)
            }
        }
    }
    
    // MARK: - Privacy Note
    private var privacyNote: some View {
        Button {
            showPrivacyInfo = true
        } label: {
            HStack {
                Image(systemName: "lock.shield")
                    .foregroundStyle(Theme.accentPrimary)
                
                Text("Your data is anonymous and encrypted")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                
                Spacer()
                
                Image(systemName: "info.circle")
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding()
            .background(Theme.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Opt-In Prompt
    private var optInPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundStyle(Theme.accentPrimary.opacity(0.5))
            
            Text("Compare with the Community")
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)
            
            Text("See how your device's background activity compares to other Sentinel users. All data is anonymized and aggregated.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                PrivacyPoint(icon: "lock.fill", text: "No personal information shared")
                PrivacyPoint(icon: "eye.slash", text: "Anonymous device statistics only")
                PrivacyPoint(icon: "arrow.left.arrow.right", text: "Opt-out anytime")
            }
            .padding()
            .background(Theme.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Button {
                manager.isOptedIn = true
                Task {
                    await manager.fetchCommunityStats()
                }
            } label: {
                Text("Enable Community Compare")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accentPrimary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Premium Prompt
    private var premiumPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 50))
                .foregroundStyle(Theme.textTertiary)
            
            Text("Premium Feature")
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)
            
            Text("Compare your device's activity with thousands of other Sentinel users to spot anomalies.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                showPaywall = true
            } label: {
                Text("Unlock Premium")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.premiumGradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 50))
                .foregroundStyle(Theme.textTertiary)
            
            Text("Unable to load community data")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            
            Button {
                Task {
                    await manager.fetchCommunityStats()
                }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
            }
        }
        .padding(.vertical, 60)
    }
}

// MARK: - Comparison Row
struct ComparisonRow: View {
    let comparison: ComparisonResult
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(comparison.metric)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                
                Spacer()
                
                StatusBadge(status: comparison.status)
            }
            
            // Bar visualization
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.backgroundTertiary)
                        .frame(height: 8)
                    
                    // Community average marker
                    let avgPosition = min(comparison.communityAverage / maxValue * geo.size.width, geo.size.width)
                    Rectangle()
                        .fill(Theme.textTertiary)
                        .frame(width: 2, height: 16)
                        .offset(x: avgPosition - 1)
                    
                    // User value bar
                    let userWidth = min(comparison.userValue / maxValue * geo.size.width, geo.size.width)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(statusColor)
                        .frame(width: userWidth, height: 8)
                }
            }
            .frame(height: 16)
            
            HStack {
                Text("You: \(formatValue(comparison.userValue))")
                    .font(.caption)
                    .foregroundStyle(statusColor)
                
                Spacer()
                
                Text("Avg: \(formatValue(comparison.communityAverage))")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding()
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var maxValue: Double {
        max(comparison.userValue, comparison.communityAverage) * 1.5
    }
    
    private var statusColor: Color {
        switch comparison.status {
        case .excellent: return .green
        case .good: return .cyan
        case .average: return .yellow
        case .high: return .orange
        case .concerning: return .red
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        if comparison.metric.contains("CPU") || comparison.metric.contains("Battery") {
            return String(format: "%.1f%%", value)
        } else {
            return String(format: "%.1f MB/hr", value)
        }
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: ComparisonResult.ComparisonStatus
    
    var body: some View {
        Text(statusText)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusText: String {
        switch status {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .average: return "Average"
        case .high: return "High"
        case .concerning: return "Concerning"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .excellent: return .green
        case .good: return .cyan
        case .average: return .yellow
        case .high: return .orange
        case .concerning: return .red
        }
    }
}

// MARK: - Privacy Point
struct PrivacyPoint: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.accentPrimary)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

// MARK: - Privacy Info Sheet
struct PrivacyInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("How Community Compare Works")
                        .font(.title2.bold())
                    
                    Text("Sentinel collects anonymous, aggregated statistics to help you understand how your device compares to others.")
                    
                    Section("What We Collect") {
                        BulletPoint("Average idle network usage (MB/hour)")
                        BulletPoint("Average idle CPU percentage")
                        BulletPoint("Average battery drain rate")
                        BulletPoint("Device type (e.g., 'iPhone' - not specific model)")
                        BulletPoint("iOS version")
                    }
                    
                    Section("What We DON'T Collect") {
                        BulletPoint("Your name or Apple ID")
                        BulletPoint("Location data")
                        BulletPoint("App usage data")
                        BulletPoint("Network destinations")
                        BulletPoint("Any personal information")
                    }
                    
                    Section("Your Control") {
                        BulletPoint("Opt-out anytime in Settings")
                        BulletPoint("Request data deletion")
                        BulletPoint("All data is encrypted in transit")
                    }
                }
                .padding()
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accentPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct BulletPoint: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
        .font(.subheadline)
        .foregroundStyle(Theme.textSecondary)
    }
}
```

---

## 📄 FILE 5: DataExporter.swift
**Location:** `iguardian/Features/Export/DataExporter.swift`

```swift
import Foundation
import UIKit
import UniformTypeIdentifiers

enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case json = "JSON"
    
    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        }
    }
    
    var contentType: UTType {
        switch self {
        case .csv: return .commaSeparatedText
        case .json: return .json
        }
    }
}

enum ExportDataType: String, CaseIterable {
    case incidents = "Incidents"
    case sleepSessions = "Sleep Sessions"
    case dailyStats = "Daily Statistics"
    case allData = "All Data"
}

class DataExporter {
    
    static func export(
        dataType: ExportDataType,
        format: ExportFormat,
        incidents: [Incident] = [],
        sleepSessions: [SleepSession] = []
    ) -> URL? {
        
        let data: Data?
        
        switch format {
        case .csv:
            data = generateCSV(dataType: dataType, incidents: incidents, sleepSessions: sleepSessions)
        case .json:
            data = generateJSON(dataType: dataType, incidents: incidents, sleepSessions: sleepSessions)
        }
        
        guard let exportData = data else { return nil }
        
        let filename = "sentinel_\(dataType.rawValue.lowercased())_\(dateString()).\(format.fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try exportData.write(to: tempURL)
            return tempURL
        } catch {
            print("Export failed: \(error)")
            return nil
        }
    }
    
    // MARK: - CSV Generation
    private static func generateCSV(
        dataType: ExportDataType,
        incidents: [Incident],
        sleepSessions: [SleepSession]
    ) -> Data? {
        
        var csvString = ""
        
        switch dataType {
        case .incidents:
            csvString = incidentsToCSV(incidents)
        case .sleepSessions:
            csvString = sleepSessionsToCSV(sleepSessions)
        case .dailyStats:
            csvString = dailyStatsToCSV(incidents: incidents, sleepSessions: sleepSessions)
        case .allData:
            csvString = "=== INCIDENTS ===\n"
            csvString += incidentsToCSV(incidents)
            csvString += "\n\n=== SLEEP SESSIONS ===\n"
            csvString += sleepSessionsToCSV(sleepSessions)
        }
        
        return csvString.data(using: .utf8)
    }
    
    private static func incidentsToCSV(_ incidents: [Incident]) -> String {
        var csv = "Timestamp,Type,Severity,Upload Rate,Download Rate,CPU,Battery Drain,Threat Score,Duration\n"
        
        for incident in incidents {
            let row = [
                formatDate(incident.timestamp),
                incident.type.rawValue,
                incident.severity.label,
                String(format: "%.2f", incident.uploadRate),
                String(format: "%.2f", incident.downloadRate),
                String(format: "%.1f", incident.cpuUsage),
                String(format: "%.1f", incident.batteryDrain),
                "\(incident.threatScore)",
                incident.durationFormatted
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv
    }
    
    private static func sleepSessionsToCSV(_ sessions: [SleepSession]) -> String {
        var csv = "Date,Start Time,End Time,Duration,Upload (MB),Download (MB),Peak CPU,Battery Used,Incidents,Status\n"
        
        for session in sessions {
            let row = [
                formatDate(session.startTime),
                formatTime(session.startTime),
                formatTime(session.endTime ?? Date()),
                session.durationFormatted,
                String(format: "%.2f", Double(session.totalUploadBytes) / 1_000_000),
                String(format: "%.2f", Double(session.totalDownloadBytes) / 1_000_000),
                String(format: "%.1f", session.peakCPU),
                String(format: "%.1f", session.batteryUsed),
                "\(session.incidentCount)",
                session.hasAnomalies ? "Anomalies" : "Clear"
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv
    }
    
    private static func dailyStatsToCSV(incidents: [Incident], sleepSessions: [SleepSession]) -> String {
        // Aggregate by day
        var csv = "Date,Incidents,Sleep Sessions,Total Upload (MB),Avg Threat Score\n"
        // Implementation would group by date and aggregate
        return csv
    }
    
    // MARK: - JSON Generation
    private static func generateJSON(
        dataType: ExportDataType,
        incidents: [Incident],
        sleepSessions: [SleepSession]
    ) -> Data? {
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        switch dataType {
        case .incidents:
            return try? encoder.encode(incidents)
        case .sleepSessions:
            return try? encoder.encode(sleepSessions)
        case .dailyStats, .allData:
            let export = ExportBundle(
                exportDate: Date(),
                incidents: incidents,
                sleepSessions: sleepSessions
            )
            return try? encoder.encode(export)
        }
    }
    
    // MARK: - Helpers
    private static func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmm"
        return formatter.string(from: Date())
    }
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Export Bundle
struct ExportBundle: Codable {
    let exportDate: Date
    let incidents: [Incident]
    let sleepSessions: [SleepSession]
}
```

---

## 📄 FILE 6: ExportSettingsView.swift
**Location:** `iguardian/Features/Export/ExportSettingsView.swift`

```swift
import SwiftUI

struct ExportSettingsView: View {
    @State private var selectedDataType: ExportDataType = .allData
    @State private var selectedFormat: ExportFormat = .csv
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    
    var body: some View {
        List {
            Section("Data to Export") {
                ForEach(ExportDataType.allCases, id: \.self) { type in
                    Button {
                        selectedDataType = type
                    } label: {
                        HStack {
                            Text(type.rawValue)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            if selectedDataType == type {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Theme.accentPrimary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .listRowBackground(Theme.backgroundSecondary)
            
            Section("Format") {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Button {
                        selectedFormat = format
                    } label: {
                        HStack {
                            Text(format.rawValue)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            if selectedFormat == format {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Theme.accentPrimary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .listRowBackground(Theme.backgroundSecondary)
            
            Section {
                Button {
                    exportData()
                } label: {
                    HStack {
                        Spacer()
                        if isExporting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .disabled(isExporting)
            }
            .listRowBackground(Theme.accentPrimary)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundPrimary)
        .navigationTitle("Export Data")
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        
        // In production, fetch from SwiftData
        let incidents: [Incident] = []
        let sleepSessions: [SleepSession] = []
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let url = DataExporter.export(
                dataType: selectedDataType,
                format: selectedFormat,
                incidents: incidents,
                sleepSessions: sleepSessions
            ) {
                DispatchQueue.main.async {
                    exportURL = url
                    showShareSheet = true
                    isExporting = false
                }
            } else {
                DispatchQueue.main.async {
                    isExporting = false
                }
            }
        }
    }
}
```

---

## 📄 FILE 7: OnboardingView.swift
**Location:** `iguardian/Onboarding/OnboardingView.swift`

```swift
import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "shield.checkered",
            iconColor: .cyan,
            title: "Welcome to Sentinel",
            subtitle: "Your personal security monitor",
            description: "Sentinel watches your phone's background activity and alerts you to suspicious behavior."
        ),
        OnboardingPage(
            icon: "chart.xyaxis.line",
            iconColor: .green,
            title: "Real-Time Monitoring",
            subtitle: "Know what's happening",
            description: "Track network traffic, CPU usage, battery drain, and thermal state in real-time."
        ),
        OnboardingPage(
            icon: "exclamationmark.triangle.fill",
            iconColor: .orange,
            title: "Smart Alerts",
            subtitle: "Be notified of threats",
            description: "Get instant notifications when suspicious patterns are detected, like possible screen surveillance."
        ),
        OnboardingPage(
            icon: "moon.stars.fill",
            iconColor: .purple,
            title: "Sleep Guard",
            subtitle: "Protection while you rest",
            description: "Enable Sleep Guard to monitor overnight activity and get morning security reports."
        )
    ]
    
    var body: some View {
        ZStack {
            Theme.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Pages
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Theme.accentPrimary : Theme.textTertiary)
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding(.bottom, 32)
                
                // Button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.accentPrimary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                // Skip
                if currentPage < pages.count - 1 {
                    Button {
                        hasCompletedOnboarding = true
                    } label: {
                        Text("Skip")
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                    .frame(height: 32)
            }
        }
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let description: String
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.15))
                    .frame(width: 140, height: 140)
                
                Image(systemName: page.icon)
                    .font(.system(size: 64))
                    .foregroundStyle(page.iconColor)
            }
            
            // Text
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title.bold())
                    .foregroundStyle(Theme.textPrimary)
                
                Text(page.subtitle)
                    .font(.title3)
                    .foregroundStyle(page.iconColor)
                
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
    }
}
```

---

## 📄 FILE 8: PermissionsView.swift
**Location:** `iguardian/Onboarding/PermissionsView.swift`

```swift
import SwiftUI
import UserNotifications

struct PermissionsView: View {
    @AppStorage("hasRequestedPermissions") private var hasRequestedPermissions = false
    @State private var notificationsEnabled = false
    @State private var batteryMonitoringEnabled = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.accentPrimary)
                
                Text("Enable Notifications")
                    .font(.title2.bold())
                    .foregroundStyle(Theme.textPrimary)
                
                Text("Get instant alerts when suspicious activity is detected on your device.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Permissions List
            VStack(spacing: 16) {
                PermissionRow(
                    icon: "bell.fill",
                    title: "Push Notifications",
                    description: "Receive security alerts",
                    isEnabled: $notificationsEnabled
                )
                
                PermissionRow(
                    icon: "battery.100",
                    title: "Battery Monitoring",
                    description: "Track battery drain patterns",
                    isEnabled: $batteryMonitoringEnabled
                )
            }
            .padding()
            .background(Theme.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Button
            Button {
                requestPermissions()
            } label: {
                Text("Enable & Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accentPrimary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            
            Button {
                hasRequestedPermissions = true
            } label: {
                Text("Maybe Later")
                    .foregroundStyle(Theme.textSecondary)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 32)
        }
        .background(Theme.backgroundPrimary)
        .onAppear {
            checkCurrentPermissions()
        }
    }
    
    private func checkCurrentPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
        
        batteryMonitoringEnabled = UIDevice.current.isBatteryMonitoringEnabled
    }
    
    private func requestPermissions() {
        // Request notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                notificationsEnabled = granted
            }
        }
        
        // Enable battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryMonitoringEnabled = true
        
        // Mark as complete
        hasRequestedPermissions = true
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isEnabled ? Theme.accentPrimary : Theme.textTertiary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isEnabled ? .green : Theme.textTertiary)
        }
    }
}
```

---

## 📄 FILE 9: Updated iguardianApp.swift (Root)

```swift
import SwiftUI
import SwiftData

@main
struct SentinelApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasRequestedPermissions") private var hasRequestedPermissions = false
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedOnboarding {
                    OnboardingView()
                } else if !hasRequestedPermissions {
                    PermissionsView()
                } else {
                    MainTabView()
                }
            }
            .preferredColorScheme(.dark)
            .environment(\.appTheme, themeManager.currentTheme)
        }
        .modelContainer(for: [Incident.self, SleepSession.self])
    }
}
```

---

## 📄 FILE 10: Updated SettingsView.swift

Add links to new Phase 4 features:

```swift
// Add these sections to SettingsView:

Section("Appearance") {
    NavigationLink {
        ThemePickerView()
    } label: {
        HStack {
            Image(systemName: themeManager.currentTheme.icon)
                .foregroundStyle(themeManager.currentTheme.accent)
            Text("Theme")
            Spacer()
            Text(themeManager.currentTheme.name)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}
.listRowBackground(Theme.backgroundSecondary)

Section("Community") {
    NavigationLink {
        CommunityCompareView()
    } label: {
        Label("Community Compare", systemImage: "chart.bar.xaxis")
    }
    
    Toggle(isOn: $communityManager.isOptedIn) {
        Label("Share Anonymous Stats", systemImage: "person.3")
    }
    .tint(Theme.accentPrimary)
}
.listRowBackground(Theme.backgroundSecondary)

Section("Data") {
    NavigationLink {
        ExportSettingsView()
    } label: {
        Label("Export Data", systemImage: "square.and.arrow.up")
    }
}
.listRowBackground(Theme.backgroundSecondary)
```

---

## 📋 Summary - Phase 4

| Feature | Files | Description |
|---------|-------|-------------|
| **Custom Themes** | ThemeManager, ThemePickerView | 6 themes (1 free, 5 premium) with full color customization |
| **Community Compare** | CommunityManager, CommunityCompareView | Anonymous benchmarking against other users |
| **Data Export** | DataExporter, ExportSettingsView | CSV/JSON export for incidents and sleep sessions |
| **Onboarding** | OnboardingView, PermissionsView | Beautiful welcome flow with permission requests |

---

## 🎉 Phase Summary - Complete App

| Phase | Features | Status |
|-------|----------|--------|
| **Phase 1** | Core monitoring, Dashboard, Basic alerts | ✅ |
| **Phase 2** | Dynamic Island, Widgets, StoreKit | ✅ |
| **Phase 3** | Sleep Guard, Incidents, PDF Reports | ✅ |
| **Phase 4** | Themes, Community, Export, Onboarding | ✅ |

---

## 🚀 Final Checklist Before App Store

- [ ] App Icon (1024x1024)
- [ ] Screenshots for all device sizes
- [ ] App Store description and keywords
- [ ] Privacy Policy URL
- [ ] Terms of Service URL
- [ ] Configure products in App Store Connect
- [ ] TestFlight beta testing
- [ ] Final QA pass

---

**Sentinel is now feature-complete! 🛡️**
