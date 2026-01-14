//
//  Components.swift
//  iguardian
//
//  Reusable UI components - IMPROVED with total data display
//

import SwiftUI

// MARK: - Threat Score Ring - ULTIMATE TECH DESIGN
struct ThreatScoreRing: View {
    let score: Int
    let threatLevel: ThreatLevel
    
    @State private var animatedScore: Int = 0
    @State private var rotation: Double = 0
    @State private var innerRotation: Double = 0
    @State private var radarRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    @State private var particleOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Layer 1: Outer rotating orbital rings
            orbitingRingsLayer
            
            // Layer 2: Hex grid pattern (subtle background)
            hexGridPattern
            
            // Layer 3: Radar sweep effect
            radarSweep
            
            // Layer 4: Main progress ring
            mainProgressRing
            
            // Layer 5: Inner tech ring
            innerTechRing
            
            // Layer 6: Floating particles
            floatingParticles
            
            // Layer 7: Central core with score
            centralCore
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
    
    // MARK: - Orbiting Rings Layer
    private var orbitingRingsLayer: some View {
        ZStack {
            // Outer dashed orbit
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 6]))
                .foregroundColor(threatLevel.color.opacity(0.2))
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(rotation))
            
            // Middle orbit with dots
            ForEach(0..<12, id: \.self) { index in
                Circle()
                    .fill(threatLevel.color.opacity(0.3))
                    .frame(width: 4, height: 4)
                    .offset(y: -95)
                    .rotationEffect(.degrees(Double(index) * 30 + rotation))
            }
            
            // Inner orbit ring
            Circle()
                .stroke(threatLevel.color.opacity(0.15), lineWidth: 0.5)
                .frame(width: 170, height: 170)
                .rotationEffect(.degrees(-rotation * 0.5))
        }
    }
    
    // MARK: - Hex Grid Pattern
    private var hexGridPattern: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                HexagonShape()
                    .stroke(threatLevel.color.opacity(0.05), lineWidth: 1)
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(Double(index) * 10))
            }
        }
    }
    
    // MARK: - Radar Sweep
    private var radarSweep: some View {
        ZStack {
            // Radar sweep cone
            AngularGradient(
                colors: [
                    threatLevel.color.opacity(0.4),
                    threatLevel.color.opacity(0.1),
                    .clear, .clear, .clear, .clear, .clear, .clear
                ],
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360)
            )
            .mask(
                Circle()
                    .frame(width: 160, height: 160)
            )
            .rotationEffect(.degrees(radarRotation))
            
            // Radar line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [threatLevel.color, threatLevel.color.opacity(0)],
                        startPoint: .center,
                        endPoint: .top
                    )
                )
                .frame(width: 2, height: 80)
                .offset(y: -40)
                .rotationEffect(.degrees(radarRotation))
        }
    }
    
    // MARK: - Main Progress Ring
    private var mainProgressRing: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Theme.backgroundTertiary.opacity(0.5), lineWidth: 10)
                .frame(width: 150, height: 150)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(animatedScore) / 100)
                .stroke(
                    AngularGradient(
                        colors: [
                            threatLevel.color.opacity(0.3),
                            threatLevel.color,
                            threatLevel.color
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 150, height: 150)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: animatedScore)
            
            // Glow effect on progress
            Circle()
                .trim(from: 0, to: CGFloat(animatedScore) / 100)
                .stroke(threatLevel.color, lineWidth: 10)
                .frame(width: 150, height: 150)
                .blur(radius: 12)
                .opacity(glowOpacity)
                .rotationEffect(.degrees(-90))
            
            // End cap glow dot
            if animatedScore > 0 {
                Circle()
                    .fill(threatLevel.color)
                    .frame(width: 14, height: 14)
                    .shadow(color: threatLevel.color, radius: 10)
                    .offset(y: -75)
                    .rotationEffect(.degrees(-90 + (Double(animatedScore) / 100 * 360)))
            }
        }
    }
    
    // MARK: - Inner Tech Ring
    private var innerTechRing: some View {
        ZStack {
            // Segmented inner ring
            ForEach(0..<24, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index < Int(Double(animatedScore) / 100 * 24) ? threatLevel.color : Theme.backgroundTertiary.opacity(0.3))
                    .frame(width: 2, height: 8)
                    .offset(y: -60)
                    .rotationEffect(.degrees(Double(index) * 15 + innerRotation))
            }
            
            // Rotating accent marks
            ForEach(0..<4, id: \.self) { index in
                Rectangle()
                    .fill(threatLevel.color.opacity(0.6))
                    .frame(width: 1, height: 12)
                    .offset(y: -52)
                    .rotationEffect(.degrees(Double(index) * 90 - innerRotation * 2))
            }
        }
    }
    
    // MARK: - Floating Particles
    private var floatingParticles: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(threatLevel.color.opacity(0.6))
                    .frame(width: CGFloat.random(in: 2...4), height: CGFloat.random(in: 2...4))
                    .offset(
                        x: cos(CGFloat(index) * .pi / 4 + particleOffset) * 90,
                        y: sin(CGFloat(index) * .pi / 4 + particleOffset) * 90
                    )
                    .blur(radius: 1)
            }
        }
    }
    
    // MARK: - Central Core
    private var centralCore: some View {
        ZStack {
            // Inner glow circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [threatLevel.color.opacity(0.15), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .scaleEffect(pulseScale)
            
            // Core content
            VStack(spacing: 2) {
                Text("\(animatedScore)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(threatLevel.color)
                    .contentTransition(.numericText())
                    .shadow(color: threatLevel.color.opacity(0.5), radius: 10)
                
                Text(threatLevel.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
                    .kerning(2)
                
                Image(systemName: threatLevel.icon)
                    .font(.system(size: 16))
                    .foregroundColor(threatLevel.color)
                    .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Animations
    private func startAnimations() {
        // Animate score in
        withAnimation(.easeInOut(duration: 1)) {
            animatedScore = score
        }
        
        // Outer ring rotation
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        
        // Inner ring rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            innerRotation = 360
        }
        
        // Radar sweep
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            radarRotation = 360
        }
        
        // Pulse effect
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }
        
        // Glow pulsing
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowOpacity = 0.6
        }
        
        // Particle movement
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            particleOffset = .pi * 2
        }
    }
}

// MARK: - Hexagon Shape
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 2
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
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
