//
//  SentinelWidget.swift
//  SentinelWidget
//
//  Created by Sukru Demir on 14.01.2026.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct SentinelEntry: TimelineEntry {
    let date: Date
    let uploadSpeed: Double
    let downloadSpeed: Double
    let threatScore: Int
    let threatLevel: Int
}

// MARK: - Timeline Provider
struct SentinelProvider: TimelineProvider {
    func placeholder(in context: Context) -> SentinelEntry {
        SentinelEntry(
            date: Date(),
            uploadSpeed: 1024,
            downloadSpeed: 2048,
            threatScore: 12,
            threatLevel: 0
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SentinelEntry) -> Void) {
        let entry = SentinelEntry(
            date: Date(),
            uploadSpeed: 1024,
            downloadSpeed: 2048,
            threatScore: 12,
            threatLevel: 0
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SentinelEntry>) -> Void) {
        // In real implementation, read from App Group shared storage
        let entry = SentinelEntry(
            date: Date(),
            uploadSpeed: 1536,
            downloadSpeed: 3072,
            threatScore: 8,
            threatLevel: 0
        )
        
        // Update every 5 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View
struct SentinelWidgetView: View {
    var entry: SentinelEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .accessoryCircular:
            CircularWidgetView(entry: entry)
        case .accessoryRectangular:
            RectangularWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: SentinelEntry
    
    var body: some View {
        VStack(spacing: 8) {
            // Shield with score
            ZStack {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 40))
                    .foregroundStyle(statusColor.gradient)
            }
            
            Text("\(entry.threatScore)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(statusColor)
            
            Text(statusText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            Color.black
        }
    }
    
    private var statusColor: Color {
        switch entry.threatLevel {
        case 0: return .green
        case 1: return .orange
        default: return .red
        }
    }
    
    private var statusText: String {
        switch entry.threatLevel {
        case 0: return "All Clear"
        case 1: return "Warning"
        default: return "Alert!"
        }
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: SentinelEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left - Shield & Score
            VStack(spacing: 4) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 32))
                    .foregroundStyle(statusColor.gradient)
                
                Text("\(entry.threatScore)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(statusColor)
                
                Text(statusText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80)
            
            // Right - Stats
            VStack(alignment: .leading, spacing: 8) {
                StatRow(
                    icon: "arrow.up",
                    label: "Upload",
                    value: formatSpeed(entry.uploadSpeed),
                    color: .cyan
                )
                
                StatRow(
                    icon: "arrow.down",
                    label: "Download",
                    value: formatSpeed(entry.downloadSpeed),
                    color: .green
                )
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(for: .widget) {
            Color.black
        }
    }
    
    private var statusColor: Color {
        switch entry.threatLevel {
        case 0: return .green
        case 1: return .orange
        default: return .red
        }
    }
    
    private var statusText: String {
        switch entry.threatLevel {
        case 0: return "All Clear"
        case 1: return "Warning"
        default: return "Alert!"
        }
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

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Lock Screen Circular Widget
struct CircularWidgetView: View {
    let entry: SentinelEntry
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            VStack(spacing: 2) {
                Image(systemName: "shield.checkered")
                    .font(.title3)
                Text("\(entry.threatScore)")
                    .font(.system(.body, design: .rounded, weight: .bold))
            }
        }
    }
}

// MARK: - Lock Screen Rectangular Widget
struct RectangularWidgetView: View {
    let entry: SentinelEntry
    
    var body: some View {
        HStack {
            Image(systemName: "shield.checkered")
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text("iGuardian")
                    .font(.caption.bold())
                HStack(spacing: 8) {
                    Label(formatSpeed(entry.uploadSpeed), systemImage: "arrow.up")
                    Label(formatSpeed(entry.downloadSpeed), systemImage: "arrow.down")
                }
                .font(.system(.caption2, design: .monospaced))
            }
        }
    }
    
    private func formatSpeed(_ bytes: Double) -> String {
        if bytes < 1024 {
            return String(format: "%.0f", bytes)
        } else if bytes < 1024 * 1024 {
            return String(format: "%.0fK", bytes / 1024)
        } else {
            return String(format: "%.1fM", bytes / (1024 * 1024))
        }
    }
}

// MARK: - Widget Configuration
struct SentinelHomeWidget: Widget {
    let kind: String = "iGuardianWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SentinelProvider()) { entry in
            SentinelWidgetView(entry: entry)
        }
        .configurationDisplayName("iGuardian")
        .description("Monitor your device security")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

#Preview(as: .systemSmall) {
    SentinelHomeWidget()
} timeline: {
    SentinelEntry(date: .now, uploadSpeed: 1024, downloadSpeed: 2048, threatScore: 12, threatLevel: 0)
}
