//
//  Components.swift
//  iguardian
//
//  Reusable UI components - IMPROVED with total data display
//

import SwiftUI

// MARK: - Threat Score Ring
struct ThreatScoreRing: View {
    let score: Int
    let threatLevel: ThreatLevel
    
    @State private var animatedScore: Int = 0
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Theme.backgroundTertiary, lineWidth: 12)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(animatedScore) / 100)
                .stroke(
                    ringGradient,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: animatedScore)
            
            // Glow effect
            Circle()
                .trim(from: 0, to: CGFloat(animatedScore) / 100)
                .stroke(threatLevel.color, lineWidth: 12)
                .blur(radius: 8)
                .opacity(0.5)
                .rotationEffect(.degrees(-90))
            
            // Center content
            VStack(spacing: 4) {
                Text("\(animatedScore)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(threatLevel.color)
                    .contentTransition(.numericText())
                
                Text(threatLevel.rawValue)
                    .font(Theme.caption)
                    .foregroundColor(Theme.textSecondary)
                
                Image(systemName: threatLevel.icon)
                    .font(.title3)
                    .foregroundColor(threatLevel.color)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1)) {
                animatedScore = score
            }
        }
        .onChange(of: score) { _, newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedScore = newValue
            }
        }
    }
    
    private var ringGradient: AngularGradient {
        AngularGradient(
            colors: [threatLevel.color.opacity(0.3), threatLevel.color],
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360 * Double(score) / 100)
        )
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
