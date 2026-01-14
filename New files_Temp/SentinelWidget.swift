//
//  SentinelWidget.swift
//  SentinelWidget
//
//  IMPROVED: Real data from App Group, auto-refresh
//

import WidgetKit
import SwiftUI

// MARK: - Shared Data Keys (for App Group)
struct WidgetDataKeys {
    static let appGroupID = "group.com.sukrudemir.iguardian"
    static let uploadSpeed = "widget_uploadSpeed"
    static let downloadSpeed = "widget_downloadSpeed"
    static let threatScore = "widget_threatScore"
    static let threatLevel = "widget_threatLevel"
    static let lastUpdate = "widget_lastUpdate"
    static let isIdle = "widget_isIdle"
}

// MARK: - Widget Entry
struct SentinelEntry: TimelineEntry {
    let date: Date
    let uploadSpeed: Double
    let downloadSpeed: Double
    let threatScore: Int
    let threatLevel: Int
    let isIdle: Bool
    let lastUpdate: Date?
}

// MARK: - Timeline Provider
struct SentinelProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> SentinelEntry {
        SentinelEntry(
            date: Date(),
            uploadSpeed: 0,
            downloadSpeed: 0,
            threatScore: 0,
            threatLevel: 0,
            isIdle: false,
            lastUpdate: nil
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SentinelEntry) -> Void) {
        let entry = loadFromAppGroup()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SentinelEntry>) -> Void) {
        let entry = loadFromAppGroup()
        
        // Refresh every minute
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    // Load data from App Group UserDefaults
    private func loadFromAppGroup() -> SentinelEntry {
        guard let defaults = UserDefaults(suiteName: WidgetDataKeys.appGroupID) else {
            return SentinelEntry(
                date: Date(),
                uploadSpeed: 0,
                downloadSpeed: 0,
                threatScore: 0,
                threatLevel: 0,
                isIdle: false,
                lastUpdate: nil
            )
        }
        
        return SentinelEntry(
            date: Date(),
            uploadSpeed: defaults.double(forKey: WidgetDataKeys.uploadSpeed),
            downloadSpeed: defaults.double(forKey: WidgetDataKeys.downloadSpeed),
            threatScore: defaults.integer(forKey: WidgetDataKeys.threatScore),
            threatLevel: defaults.integer(forKey: WidgetDataKeys.threatLevel),
            isIdle: defaults.bool(forKey: WidgetDataKeys.isIdle),
            lastUpdate: defaults.object(forKey: WidgetDataKeys.lastUpdate) as? Date
        )
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
            // Shield with status
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "shield.checkered")
                    .font(.system(size: 28))
                    .foregroundStyle(statusColor.gradient)
            }
            
            Text("\(entry.threatScore)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(statusColor)
            
            Text(statusText)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            
            // Last update indicator
            if let lastUpdate = entry.lastUpdate {
                Text(lastUpdate, style: .relative)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
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
        if entry.isIdle {
            switch entry.threatLevel {
            case 0: return "Monitoring"
            case 1: return "Warning"
            default: return "Alert!"
            }
        } else {
            return "Active"
        }
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: SentinelEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left - Status
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 24))
                        .foregroundStyle(statusColor.gradient)
                }
                
                Text("\(entry.threatScore)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(statusColor)
                
                Text(statusText)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80)
            
            // Divider
            Rectangle()
                .fill(.secondary.opacity(0.2))
                .frame(width: 1)
            
            // Right - Stats
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "arrow.up")
                        .foregroundStyle(.cyan)
                        .frame(width: 16)
                    Text("Upload")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatSpeed(entry.uploadSpeed))
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Image(systemName: "arrow.down")
                        .foregroundStyle(.green)
                        .frame(width: 16)
                    Text("Download")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatSpeed(entry.downloadSpeed))
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.semibold)
                }
                
                // Status row
                HStack {
                    Circle()
                        .fill(entry.isIdle ? .green : .blue)
                        .frame(width: 6, height: 6)
                    Text(entry.isIdle ? "Monitoring" : "Active")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let lastUpdate = entry.lastUpdate {
                        Text(lastUpdate, style: .relative)
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
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
            return "0 B/s"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.0f KB/s", bytes / 1024)
        } else {
            return String(format: "%.1f MB/s", bytes / (1024 * 1024))
        }
    }
}

// MARK: - Lock Screen Circular Widget
struct CircularWidgetView: View {
    let entry: SentinelEntry
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            VStack(spacing: 1) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 16))
                Text("\(entry.threatScore)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundStyle(entry.threatLevel == 0 ? .primary : (entry.threatLevel == 1 ? .orange : .red))
        }
    }
}

// MARK: - Lock Screen Rectangular Widget
struct RectangularWidgetView: View {
    let entry: SentinelEntry
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "shield.checkered")
                .font(.title3)
                .foregroundStyle(entry.threatLevel == 0 ? .green : (entry.threatLevel == 1 ? .orange : .red))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("iGuardian")
                    .font(.caption.bold())
                
                HStack(spacing: 6) {
                    Text("↑\(formatCompact(entry.uploadSpeed))")
                    Text("↓\(formatCompact(entry.downloadSpeed))")
                }
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(entry.threatScore)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(entry.threatLevel == 0 ? .green : (entry.threatLevel == 1 ? .orange : .red))
        }
    }
    
    private func formatCompact(_ bytes: Double) -> String {
        if bytes < 1024 {
            return "0"
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
        .description("Monitor your device security status")
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
    SentinelEntry(date: .now, uploadSpeed: 1024, downloadSpeed: 2048, threatScore: 0, threatLevel: 0, isIdle: true, lastUpdate: Date())
    SentinelEntry(date: .now, uploadSpeed: 500000, downloadSpeed: 100000, threatScore: 35, threatLevel: 1, isIdle: true, lastUpdate: Date())
}
