//
//  Components.swift
//  iguardian
//
//  Reusable UI components
//

import SwiftUI

// MARK: - Threat Score Ring
struct ThreatScoreRing: View {
    let score: Int
    let threatLevel: ThreatLevel
    
    @State private var animatedScore: Int = 0
    @State private var isAnimating = false
    
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

// MARK: - Upload Metric Card
struct UploadMetricCard: View {
    let bytesPerSecond: Double
    var status: ThreatLevel = .normal
    
    var body: some View {
        MetricCard(
            title: "Upload",
            icon: "arrow.up",
            iconColor: .cyan,
            status: status
        ) {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatSpeed(bytesPerSecond))
                    .font(Theme.dataLarge)
                    .foregroundColor(Theme.textPrimary)
                
                Text("per second")
                    .font(Theme.caption)
                    .foregroundColor(Theme.textTertiary)
            }
        }
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

// MARK: - Download Metric Card
struct DownloadMetricCard: View {
    let bytesPerSecond: Double
    var status: ThreatLevel = .normal
    
    var body: some View {
        MetricCard(
            title: "Download",
            icon: "arrow.down",
            iconColor: .green,
            status: status
        ) {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatSpeed(bytesPerSecond))
                    .font(Theme.dataLarge)
                    .foregroundColor(Theme.textPrimary)
                
                Text("per second")
                    .font(Theme.caption)
                    .foregroundColor(Theme.textTertiary)
            }
        }
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
            // Header
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
                // Empty state
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
                // Activity list
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
            // Icon
            Image(systemName: entry.type.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(entry.type.color)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(entry.type.color.opacity(0.15))
                )
            
            // Content
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
            
            // Time
            Text(entry.timeFormatted)
                .font(Theme.micro)
                .foregroundColor(Theme.textTertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews
#Preview("Threat Score Ring") {
    ZStack {
        Theme.backgroundPrimary
        ThreatScoreRing(score: 35, threatLevel: .warning)
            .frame(width: 200, height: 200)
    }
}

#Preview("Metric Cards") {
    ZStack {
        Theme.backgroundPrimary
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                UploadMetricCard(bytesPerSecond: 125000, status: .normal)
                DownloadMetricCard(bytesPerSecond: 350000)
            }
            HStack(spacing: 16) {
                CPUMetricCard(usagePercent: 45, status: .warning)
                BatteryMetricCard(drainRatePerHour: 8.5, status: .warning)
            }
        }
        .padding()
    }
}
