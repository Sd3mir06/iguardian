//
//  XRayView.swift
//  iguardian
//
//  Guardian X-Ray - Stats for Nerds / Real-time System Insights
//

import SwiftUI

struct XRayView: View {
    @StateObject private var xray = XRayDataManager.shared
    @ObservedObject var monitoringManager: MonitoringManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // System Pulse
                    PulseSection(pulseHistory: xray.pulseHistory, cpu: xray.currentCPU, networkRate: xray.currentNetworkRate, thermalLevel: xray.currentThermalLevel)
                    
                    // Threat Score Breakdown
                    ThreatScoreSection(score: xray.threatScore, confidence: xray.confidence, factors: xray.threatFactors)
                    
                    // Intelligence Feed
                    IntelligenceFeedSection(events: xray.events, onClear: { xray.clearEvents() })
                    
                    // Traffic Pattern
                    TrafficPatternSection(
                        currentPattern: xray.currentPattern,
                        burstPercent: xray.burstPercent,
                        streamPercent: xray.streamPercent,
                        backgroundPercent: xray.backgroundPercent
                    )
                    
                    // Energy Breakdown
                    EnergyBreakdownSection(
                        radio: xray.radioEnergyPerHour,
                        cpu: xray.cpuEnergyPerHour,
                        idle: xray.idleEnergyPerHour
                    )
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("GUARDIAN X-RAY")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Theme.accentPrimary)
                }
            }
        }
        .onAppear {
            xray.configure(monitoringManager: monitoringManager)
            xray.startMonitoring()
        }
        .onDisappear {
            xray.stopMonitoring()
        }
    }
}

// MARK: - Pulse Section
struct PulseSection: View {
    let pulseHistory: [PulsePoint]
    let cpu: Double
    let networkRate: Double
    let thermalLevel: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.cyan)
                Text("SYSTEM PULSE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                    .kerning(2)
                Spacer()
                Text("60s")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            // Pulse waveform
            GeometryReader { geo in
                HStack(spacing: 1) {
                    ForEach(pulseHistory.suffix(60)) { point in
                        Rectangle()
                            .fill(pulseColor(point.value))
                            .frame(width: max(1, (geo.size.width - 60) / 60), height: max(4, CGFloat(point.value) * geo.size.height))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(height: 40)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            // Current readings
            HStack(spacing: 16) {
                MetricPill(label: "CPU", value: "\(Int(cpu))%", color: cpu > 50 ? .orange : .cyan)
                MetricPill(label: "NET", value: formatRate(networkRate), color: networkRate > 500000 ? .orange : .green)
                MetricPill(label: "THERM", value: thermalText, color: thermalColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func pulseColor(_ value: Double) -> Color {
        if value < 0.3 { return .green }
        else if value < 0.6 { return .cyan }
        else if value < 0.8 { return .orange }
        else { return .red }
    }
    
    private var thermalText: String {
        switch thermalLevel {
        case 1: return "🟢"
        case 2: return "🟡"
        case 3: return "🟠"
        case 4: return "🔴"
        default: return "⚪"
        }
    }
    
    private var thermalColor: Color {
        switch thermalLevel {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        default: return .gray
        }
    }
    
    private func formatRate(_ bps: Double) -> String {
        if bps < 1024 { return "0 KB/s" }
        else if bps < 1024 * 1024 { return String(format: "%.0f KB/s", bps / 1024) }
        else { return String(format: "%.1f MB/s", bps / (1024 * 1024)) }
    }
}

// MARK: - Metric Pill
struct MetricPill: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Threat Score Section
struct ThreatScoreSection: View {
    let score: Int
    let confidence: Int
    let factors: [ThreatFactor]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundColor(scoreColor)
                Text("THREAT SCORE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .kerning(2)
                Spacer()
                Text("\(score)/100")
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .foregroundColor(scoreColor)
            }
            
            // Factors
            ForEach(factors) { factor in
                HStack(spacing: 8) {
                    Text("+\(factor.score)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(factor.score > 10 ? .orange : .green)
                        .frame(width: 35, alignment: .leading)
                    
                    Image(systemName: factor.icon)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    
                    Text(factor.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(factor.reason)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
            
            HStack {
                Text("Confidence: \(confidence)%")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Confidence bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1))
                        Capsule().fill(Color.green).frame(width: geo.size.width * CGFloat(confidence) / 100)
                    }
                }
                .frame(width: 60, height: 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(scoreColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var scoreColor: Color {
        if score < 25 { return .green }
        else if score < 50 { return .yellow }
        else if score < 75 { return .orange }
        else { return .red }
    }
}

// MARK: - Intelligence Feed Section
struct IntelligenceFeedSection: View {
    let events: [XRayEvent]
    let onClear: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.purple)
                Text("LIVE INTELLIGENCE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.purple)
                    .kerning(2)
                Spacer()
                Button {
                    onClear()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(events.prefix(15)) { event in
                        HStack(spacing: 8) {
                            Text(event.timeString)
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            Image(systemName: event.icon)
                                .font(.system(size: 10))
                                .foregroundColor(eventColor(event.color))
                            
                            Text(event.message)
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                    }
                }
            }
            .frame(maxHeight: 150)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func eventColor(_ color: String) -> Color {
        switch color {
        case "cyan": return .cyan
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "blue": return .blue
        default: return .gray
        }
    }
}

// MARK: - Traffic Pattern Section
struct TrafficPatternSection: View {
    let currentPattern: TrafficPattern
    let burstPercent: Double
    let streamPercent: Double
    let backgroundPercent: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.orange)
                Text("TRAFFIC PATTERN")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
                    .kerning(2)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: currentPattern.icon)
                        .font(.system(size: 12))
                    Text(currentPattern.rawValue)
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(patternColor(currentPattern))
            }
            
            VStack(spacing: 6) {
                PatternRow(icon: "bolt.fill", label: "Burst", sublabel: "ads/telemetry", percent: burstPercent, color: .red)
                PatternRow(icon: "waveform", label: "Stream", sublabel: "video/audio", percent: streamPercent, color: .blue)
                PatternRow(icon: "dot.radiowaves.left.and.right", label: "Background", sublabel: "keep-alive", percent: backgroundPercent, color: .gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func patternColor(_ pattern: TrafficPattern) -> Color {
        switch pattern {
        case .burst: return .red
        case .stream: return .blue
        case .background: return .gray
        case .idle: return .gray
        }
    }
}

// MARK: - Pattern Row
struct PatternRow: View {
    let icon: String
    let label: String
    let sublabel: String
    let percent: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 70, alignment: .leading)
            
            Text(sublabel)
                .font(.system(size: 9))
                .foregroundColor(.gray)
            
            Spacer()
            
            // Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule().fill(color).frame(width: geo.size.width * CGFloat(percent) / 100)
                }
            }
            .frame(width: 60, height: 6)
            
            Text("\(Int(percent))%")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

// MARK: - Energy Breakdown Section
struct EnergyBreakdownSection: View {
    let radio: Double
    let cpu: Double
    let idle: Double
    
    var total: Double { radio + cpu + idle }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
                Text("ENERGY BREAKDOWN")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.yellow)
                    .kerning(2)
                Spacer()
                Text(String(format: "%.1f%%/hr", total))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.yellow)
            }
            
            HStack(spacing: 16) {
                EnergyPill(icon: "antenna.radiowaves.left.and.right", label: "Radio", value: String(format: "%.1f%%", radio), color: .orange)
                EnergyPill(icon: "cpu", label: "CPU", value: String(format: "%.1f%%", cpu), color: .cyan)
                EnergyPill(icon: "zzz", label: "Idle", value: String(format: "%.1f%%", idle), color: .gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Energy Pill
struct EnergyPill: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview
#Preview {
    XRayView(monitoringManager: MonitoringManager.shared)
        .preferredColorScheme(.dark)
}
