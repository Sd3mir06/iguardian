//
//  SentinelLiveActivity.swift
//  SentinelWidget
//
//  IMPROVED: More compact Dynamic Island, cleaner design
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SentinelLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SentinelActivityAttributes.self) { context in
            // LOCK SCREEN BANNER - Cleaner
            LockScreenBannerView(state: context.state)
                .activityBackgroundTint(.black.opacity(0.9))
                .activitySystemActionForegroundColor(.white)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // EXPANDED VIEW - Only when user taps
                DynamicIslandExpandedRegion(.leading) {
                    CompactStatView(
                        icon: "arrow.up",
                        value: context.state.uploadFormatted,
                        color: .cyan
                    )
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    CompactStatView(
                        icon: "arrow.down",
                        value: context.state.downloadFormatted,
                        color: .green
                    )
                }
                
                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 8) {
                        Image(systemName: "shield.checkered")
                            .font(.title3)
                            .foregroundStyle(statusColor(context.state.threatLevel))
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(context.state.statusText)
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                            Text("Score: \(context.state.threatScore)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Label("\(context.state.cpuUsage, specifier: "%.0f")%", systemImage: "cpu")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text(context.state.isIdle ? "Monitoring" : "Active")
                            .font(.caption2)
                            .foregroundStyle(context.state.isIdle ? .green : .secondary)
                    }
                }
                
            } compactLeading: {
                // COMPACT LEFT - Just shield icon with color
                Image(systemName: "shield.checkered")
                    .font(.system(size: 14))
                    .foregroundStyle(statusColor(context.state.threatLevel))
                
            } compactTrailing: {
                // COMPACT RIGHT - Just the score number
                Text("\(context.state.threatScore)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(statusColor(context.state.threatLevel))
                
            } minimal: {
                // MINIMAL - Tiny shield
                Image(systemName: "shield.checkered")
                    .font(.system(size: 12))
                    .foregroundStyle(statusColor(context.state.threatLevel))
            }
        }
    }
    
    private func statusColor(_ level: Int) -> Color {
        switch level {
        case 0: return .green
        case 1: return .orange
        default: return .red
        }
    }
}

// MARK: - Compact Stat View
struct CompactStatView: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
        }
    }
}

// MARK: - Lock Screen Banner View - Cleaner
struct LockScreenBannerView: View {
    let state: SentinelActivityAttributes.ContentState
    
    var body: some View {
        HStack(spacing: 12) {
            // Shield with status color
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "shield.checkered")
                    .font(.title3)
                    .foregroundStyle(statusColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(state.statusText)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                
                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up")
                            .font(.caption2)
                            .foregroundStyle(.cyan)
                        Text(state.uploadFormatted)
                            .font(.system(.caption, design: .monospaced))
                    }
                    
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.down")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        Text(state.downloadFormatted)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Score
            Text("\(state.threatScore)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var statusColor: Color {
        switch state.threatLevel {
        case 0: return .green
        case 1: return .orange
        default: return .red
        }
    }
}
