//
//  SentinelLiveActivity.swift
//  SentinelWidget
//
//  Created by Sukru Demir on 14.01.2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SentinelLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SentinelActivityAttributes.self) { context in
            // LOCK SCREEN BANNER
            LockScreenBannerView(state: context.state)
                .activityBackgroundTint(.black.opacity(0.8))
                .activitySystemActionForegroundColor(.white)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // EXPANDED VIEW
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Label {
                            Text(context.state.uploadFormatted)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.semibold)
                        } icon: {
                            Image(systemName: "arrow.up")
                                .foregroundStyle(.cyan)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Label {
                            Text(context.state.downloadFormatted)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.semibold)
                        } icon: {
                            Image(systemName: "arrow.down")
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Image(systemName: "shield.checkered")
                            .font(.title2)
                            .foregroundStyle(statusColor(context.state.threatLevel))
                        Text(context.state.statusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Label("\(context.state.cpuUsage, specifier: "%.0f")% CPU", systemImage: "cpu")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("Score: \(context.state.threatScore)")
                            .font(.caption.bold())
                            .foregroundStyle(statusColor(context.state.threatLevel))
                    }
                    .padding(.horizontal, 4)
                }
                
            } compactLeading: {
                // COMPACT LEFT
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .foregroundStyle(.cyan)
                        .font(.caption2)
                    Text(context.state.uploadFormatted)
                        .font(.system(.caption2, design: .monospaced))
                        .fontWeight(.medium)
                }
                
            } compactTrailing: {
                // COMPACT RIGHT
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .foregroundStyle(.green)
                        .font(.caption2)
                    Text(context.state.downloadFormatted)
                        .font(.system(.caption2, design: .monospaced))
                        .fontWeight(.medium)
                }
                
            } minimal: {
                // MINIMAL (just icon)
                Image(systemName: "shield.checkered")
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

// MARK: - Lock Screen Banner View
struct LockScreenBannerView: View {
    let state: SentinelActivityAttributes.ContentState
    
    var body: some View {
        HStack(spacing: 16) {
            // Shield icon
            Image(systemName: "shield.checkered")
                .font(.title)
                .foregroundStyle(statusColor)
            
            // Stats
            VStack(alignment: .leading, spacing: 4) {
                Text("iGUARDIAN")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 16) {
                    Label(state.uploadFormatted, systemImage: "arrow.up")
                        .foregroundStyle(.cyan)
                    Label(state.downloadFormatted, systemImage: "arrow.down")
                        .foregroundStyle(.green)
                }
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.semibold)
            }
            
            Spacer()
            
            // Threat Score
            VStack {
                Text("\(state.threatScore)")
                    .font(.title2.bold())
                    .foregroundStyle(statusColor)
                Text("Score")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
    
    private var statusColor: Color {
        switch state.threatLevel {
        case 0: return .green
        case 1: return .orange
        default: return .red
        }
    }
}
