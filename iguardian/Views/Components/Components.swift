//
//  Components.swift
//  iguardian
//
//  Reusable UI components - IMPROVED with total data display
//

import SwiftUI

// MARK: - Threat Score Ring - SHIELD CORE DESIGN
struct ThreatScoreRing: View {
    let score: Int
    let threatLevel: ThreatLevel
    
    @State private var animatedScore: Int = 0
    @State private var pulse: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var innerRotation: Double = 0
    @State private var glowOpacity: Double = 0.5
    @State private var particleScale: CGFloat = 1.0
    
    // Core theme colors (Purple/Cyan holographic)
    private let primaryTech = Color(red: 0.6, green: 0.3, blue: 1.0)
    private let secondaryTech = Color(red: 0.3, green: 0.8, blue: 1.0)
    
    var body: some View {
        ZStack {
            // Layer 1: Outer holographic data rings
            holographicRings
            
            // Layer 2: Rotating data segments
            dataSegments
            
            // Layer 3: Progress Ring (Holographic arc)
            holographicProgressRing
            
            // Layer 4: Central Shield Core (AppLogo)
            shieldCore
            
            // Layer 5: Dynamic Particles
            techParticles
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: score) { _, newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedScore = newValue
            }
        }
    }
    
    // MARK: - Holographic Rings
    private var holographicRings: some View {
        ZStack {
            // Farthest faint orbit
            Circle()
                .stroke(primaryTech.opacity(0.1), lineWidth: 1)
                .frame(width: 220, height: 220)
            
            // Middle dashed orbit
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [2, 10]))
                .foregroundColor(secondaryTech.opacity(0.3))
                .frame(width: 190, height: 190)
                .rotationEffect(.degrees(rotation))
            
            // Inner glowing technical border
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [primaryTech.opacity(0.4), .clear, secondaryTech.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
                .frame(width: 170, height: 170)
                .rotationEffect(.degrees(-rotation * 0.5))
        }
    }
    
    // MARK: - Data Segments
    private var dataSegments: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Capsule()
                    .fill(primaryTech.opacity(0.4))
                    .frame(width: 2, height: 12)
                    .offset(y: -105)
                    .rotationEffect(.degrees(Double(index) * 45 + rotation * 0.2))
            }
            
            ForEach(0..<20, id: \.self) { index in
                Rectangle()
                    .fill(secondaryTech.opacity(0.2))
                    .frame(width: 1, height: 4)
                    .offset(y: -95)
                    .rotationEffect(.degrees(Double(index) * 18 - rotation * 0.3))
            }
        }
    }
    
    // MARK: - Holographic Progress Ring
    private var holographicProgressRing: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Theme.backgroundTertiary.opacity(0.3), lineWidth: 8)
                .frame(width: 150, height: 150)
            
            // The progress arc with vibrant tech gradient
            Circle()
                .trim(from: 0, to: CGFloat(animatedScore) / 100)
                .stroke(
                    LinearGradient(
                        colors: [primaryTech, secondaryTech, primaryTech],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 150, height: 150)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: animatedScore)
            
            // Progress glow
            Circle()
                .trim(from: 0, to: CGFloat(animatedScore) / 100)
                .stroke(primaryTech.opacity(0.5), lineWidth: 10)
                .frame(width: 150, height: 150)
                .blur(radius: 10)
                .opacity(glowOpacity)
                .rotationEffect(.degrees(-90))
            
            // Moving tick mark
            if animatedScore > 0 {
                Circle()
                    .fill(.white)
                    .frame(width: 6, height: 6)
                    .shadow(color: secondaryTech, radius: 10)
                    .offset(y: -75)
                    .rotationEffect(.degrees(-90 + (Double(animatedScore) / 100 * 360)))
            }
        }
    }
    
    // MARK: - Shield Core
    private var shieldCore: some View {
        ZStack {
            // Outer pulse layer 1
            Circle()
                .stroke(primaryTech.opacity(0.2), lineWidth: 1)
                .frame(width: 110, height: 110)
                .scaleEffect(pulse)
                .opacity(2.0 - pulse)
            
            // Outer pulse layer 2
            Circle()
                .stroke(secondaryTech.opacity(0.15), lineWidth: 1)
                .frame(width: 130, height: 130)
                .scaleEffect(pulse * 0.9)
                .opacity(1.5 - pulse)
            
            // Central background glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [primaryTech.opacity(0.2), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
            
            // The App Logo (Shield)
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 85, height: 85)
                .shadow(color: primaryTech.opacity(0.6), radius: 15)
                .scaleEffect(1.0 + (pulse - 1.0) * 0.2) // Subtle pulse on icon
            
            // Score overlay below center
            VStack {
                Spacer()
                    .frame(height: 70)
                
                Text("\(animatedScore)")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: secondaryTech, radius: 8)
                
                Text(threatLevel.rawValue.uppercased())
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(Theme.textSecondary)
                    .kerning(1.5)
            }
        }
    }
    
    // MARK: - Tech Particles
    private var techParticles: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                Circle()
                    .fill(.white.opacity(0.6))
                    .frame(width: 2, height: 2)
                    .offset(x: cos(Double(index) * .pi / 6) * 115, y: sin(Double(index) * .pi / 6) * 115)
                    .scaleEffect(particleScale)
                    .blur(radius: 0.5)
            }
        }
    }
    
    // MARK: - Animations
    private func startAnimations() {
        // Linear score animate
        withAnimation(.easeInOut(duration: 1.2)) {
            animatedScore = score
        }
        
        // Continuous rotation
        withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        
        // Inner rotation
        withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
            innerRotation = 360
        }
        
        // Pulsing core
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulse = 1.2
        }
        
        // Glow breathing
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            glowOpacity = 0.8
        }
        
        // Particles breathing
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            particleScale = 1.5
        }
    }
}

// MARK: - Base Metric Card
struct MetricCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let status: ThreatLevel
    let content: Content
    
    init(
        title: String,
        icon: String,
        iconColor: Color,
        status: ThreatLevel = .normal,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.status = status
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
                
                Text(title.uppercased())
                    .font(Theme.micro)
                    .foregroundColor(Theme.textTertiary)
                    .kerning(1.2)
                
                Spacer()
                
                // Status dot
                Circle()
                    .fill(status.color)
                    .frame(width: 6, height: 6)
            }
            
            content
        }
        .padding()
        .cardStyle(status: status)
    }
}

// MARK: - NEW: Upload Metric Card with Total
struct UploadMetricCard: View {
    let bytesPerSecond: Double
    let totalMB: Double          // Session or hourly total
    let thresholdMB: Double      // Alert threshold
    var status: ThreatLevel = .normal
    
    // Legacy init for backwards compatibility
    init(bytesPerSecond: Double, status: ThreatLevel = .normal) {
        self.bytesPerSecond = bytesPerSecond
        self.totalMB = 0
        self.thresholdMB = 100
        self.status = status
    }
    
    // Full init with totals
    init(bytesPerSecond: Double, totalMB: Double, thresholdMB: Double, status: ThreatLevel = .normal) {
        self.bytesPerSecond = bytesPerSecond
        self.totalMB = totalMB
        self.thresholdMB = thresholdMB
        self.status = status
    }
    
    var body: some View {
        MetricCard(
            title: "Upload",
            icon: "arrow.up",
            iconColor: .cyan,
            status: status
        ) {
            VStack(alignment: .leading, spacing: 8) {
                // Instant rate
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formatSpeed(bytesPerSecond))
                        .font(Theme.dataLarge)
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("/s")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textTertiary)
                }
                
                // Total with progress bar (if total > 0)
                if totalMB > 0 || thresholdMB > 0 {
                    Divider()
                        .background(Theme.backgroundTertiary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("TOTAL (1hr)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Theme.textTertiary)
                            
                            Spacer()
                            
                            Text("\(Int(totalMB)) / \(Int(thresholdMB)) MB")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(totalMB > thresholdMB ? Theme.statusDanger : Theme.textSecondary)
                        }
                        
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Theme.backgroundTertiary)
                                    .frame(height: 4)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(progressColor)
                                    .frame(width: min(geo.size.width, geo.size.width * CGFloat(totalMB / thresholdMB)), height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                }
            }
        }
    }
    
    private var progressColor: Color {
        let ratio = totalMB / thresholdMB
        if ratio >= 1.0 { return Theme.statusDanger }
        if ratio >= 0.7 { return Theme.statusWarning }
        return Theme.statusSafe
    }
    
    private func formatSpeed(_ bytes: Double) -> String {
        if bytes < 1024 {
            return String(format: "%.0f B", bytes)
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", bytes / 1024)
        } else {
            return String(format: "%.1f MB", bytes / (1024 * 1024))
        }
    }
}

// MARK: - NEW: Download Metric Card with Total
struct DownloadMetricCard: View {
    let bytesPerSecond: Double
    let totalMB: Double
    let thresholdMB: Double
    var status: ThreatLevel = .normal
    
    // Legacy init
    init(bytesPerSecond: Double, status: ThreatLevel = .normal) {
        self.bytesPerSecond = bytesPerSecond
        self.totalMB = 0
        self.thresholdMB = 500
        self.status = status
    }
    
    // Full init
    init(bytesPerSecond: Double, totalMB: Double, thresholdMB: Double, status: ThreatLevel = .normal) {
        self.bytesPerSecond = bytesPerSecond
        self.totalMB = totalMB
        self.thresholdMB = thresholdMB
        self.status = status
    }
    
    var body: some View {
        MetricCard(
            title: "Download",
            icon: "arrow.down",
            iconColor: .green,
            status: status
        ) {
            VStack(alignment: .leading, spacing: 8) {
                // Instant rate
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formatSpeed(bytesPerSecond))
                        .font(Theme.dataLarge)
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("/s")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textTertiary)
                }
                
                // Total with progress bar
                if totalMB > 0 || thresholdMB > 0 {
                    Divider()
                        .background(Theme.backgroundTertiary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("TOTAL (1hr)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Theme.textTertiary)
                            
                            Spacer()
                            
                            Text("\(Int(totalMB)) / \(Int(thresholdMB)) MB")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(totalMB > thresholdMB ? Theme.statusDanger : Theme.textSecondary)
                        }
                        
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Theme.backgroundTertiary)
                                    .frame(height: 4)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(progressColor)
                                    .frame(width: min(geo.size.width, geo.size.width * CGFloat(totalMB / thresholdMB)), height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                }
            }
        }
    }
    
    private var progressColor: Color {
        let ratio = totalMB / thresholdMB
        if ratio >= 1.0 { return Theme.statusDanger }
        if ratio >= 0.7 { return Theme.statusWarning }
        return Theme.statusSafe
    }
    
    private func formatSpeed(_ bytes: Double) -> String {
        if bytes < 1024 {
            return String(format: "%.0f B", bytes)
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", bytes / 1024)
        } else {
            return String(format: "%.1f MB", bytes / (1024 * 1024))
        }
    }
}

// MARK: - NEW: Network Summary Card (Alternative full-width view)
struct NetworkSummaryCard: View {
    let uploadRate: Double
    let downloadRate: Double
    let uploadTotalMB: Double
    let downloadTotalMB: Double
    let uploadThresholdMB: Double
    let downloadThresholdMB: Double
    var status: ThreatLevel = .normal
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "network")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.accentPrimary)
                
                Text("NETWORK ACTIVITY")
                    .font(Theme.micro)
                    .foregroundColor(Theme.textTertiary)
                    .kerning(1.2)
                
                Spacer()
                
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
            }
            
            // Upload Row
            NetworkRow(
                icon: "arrow.up.circle.fill",
                iconColor: .cyan,
                label: "Upload",
                rate: uploadRate,
                totalMB: uploadTotalMB,
                thresholdMB: uploadThresholdMB
            )
            
            Divider()
                .background(Theme.backgroundTertiary)
            
            // Download Row
            NetworkRow(
                icon: "arrow.down.circle.fill",
                iconColor: .green,
                label: "Download",
                rate: downloadRate,
                totalMB: downloadTotalMB,
                thresholdMB: downloadThresholdMB
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(Theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                        .stroke(status.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct NetworkRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let rate: Double
    let totalMB: Double
    let thresholdMB: Double
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Theme.caption)
                    .foregroundColor(Theme.textSecondary)
                
                Text(formatSpeed(rate))
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
            }
            
            Spacer()
            
            // Total usage indicator
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(totalMB)) MB")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(totalMB > thresholdMB ? Theme.statusDanger : Theme.textPrimary)
                
                Text("of \(Int(thresholdMB)) MB limit")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textTertiary)
                
                // Mini progress
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.backgroundTertiary)
                        .frame(width: 60, height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(progressColor)
                        .frame(width: min(60, 60 * CGFloat(totalMB / thresholdMB)), height: 4)
                }
            }
        }
    }
    
    private var progressColor: Color {
        let ratio = totalMB / thresholdMB
        if ratio >= 1.0 { return Theme.statusDanger }
        if ratio >= 0.7 { return Theme.statusWarning }
        return Theme.statusSafe
    }
    
    private func formatSpeed(_ bytes: Double) -> String {
        if bytes < 1024 {
            return String(format: "%.0f B/s", bytes)
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytes / 1024)
        } else {
            return String(format: "%.1f MB/s", bytes / (1024 * 1024))
        }
    }
}

// MARK: - CPU Metric Card
struct CPUMetricCard: View {
    let usagePercent: Double
    var status: ThreatLevel = .normal
    
    var body: some View {
        MetricCard(
            title: "CPU",
            icon: "cpu",
            iconColor: .orange,
            status: status
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.0f", usagePercent))
                        .font(Theme.dataLarge)
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("%")
                        .font(Theme.dataMedium)
                        .foregroundColor(Theme.textSecondary)
                }
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.backgroundTertiary)
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(status.color)
                            .frame(width: geo.size.width * CGFloat(usagePercent) / 100, height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
    }
}

// MARK: - Battery Metric Card
struct BatteryMetricCard: View {
    let drainRatePerHour: Float
    var status: ThreatLevel = .normal
    
    var body: some View {
        MetricCard(
            title: "Battery Drain",
            icon: "battery.50",
            iconColor: .yellow,
            status: status
        ) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", drainRatePerHour))
                        .font(Theme.dataLarge)
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("%/hr")
                        .font(Theme.dataMedium)
                        .foregroundColor(Theme.textSecondary)
                }
                
                Text("drain rate")
                    .font(Theme.caption)
                    .foregroundColor(Theme.textTertiary)
            }
        }
    }
}

// MARK: - Activity Feed
struct ActivityFeed: View {
    let entries: [ActivityEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RECENT ACTIVITY")
                    .font(Theme.micro)
                    .foregroundColor(Theme.textTertiary)
                    .kerning(1.2)
                
                Spacer()
                
                if !entries.isEmpty {
                    Text("\(entries.count) events")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textTertiary)
                }
            }
            
            if entries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.title)
                        .foregroundColor(Theme.statusSafe.opacity(0.5))
                    
                    Text("No recent activity")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 8) {
                    ForEach(entries.prefix(5)) { entry in
                        ActivityRow(entry: entry)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(Theme.backgroundSecondary)
        )
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let entry: ActivityEntry
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.type.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(entry.type.color)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(entry.type.color.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(Theme.caption)
                    .foregroundColor(Theme.textPrimary)
                
                Text(entry.description)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textTertiary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(entry.timeFormatted)
                .font(Theme.micro)
                .foregroundColor(Theme.textTertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews
#Preview("Network Summary Card") {
    ZStack {
        Theme.backgroundPrimary
        NetworkSummaryCard(
            uploadRate: 125000,
            downloadRate: 350000,
            uploadTotalMB: 75,
            downloadTotalMB: 320,
            uploadThresholdMB: 100,
            downloadThresholdMB: 500,
            status: .warning
        )
        .padding()
    }
}

#Preview("Metric Cards") {
    ZStack {
        Theme.backgroundPrimary
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                UploadMetricCard(
                    bytesPerSecond: 125000,
                    totalMB: 85,
                    thresholdMB: 100,
                    status: .warning
                )
                DownloadMetricCard(
                    bytesPerSecond: 2500000,
                    totalMB: 450,
                    thresholdMB: 500,
                    status: .warning
                )
            }
            HStack(spacing: 16) {
                CPUMetricCard(usagePercent: 45, status: .warning)
                BatteryMetricCard(drainRatePerHour: 8.5, status: .warning)
            }
        }
        .padding()
    }
}
