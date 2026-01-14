//
//  SentinelActivityAttributes.swift
//  iguardian
//
//  Created by Sukru Demir on 14.01.2026.
//

import ActivityKit
import Foundation

struct SentinelActivityAttributes: ActivityAttributes {
    // Static data that doesn't change during the activity
    public struct ContentState: Codable, Hashable {
        // Dynamic data that updates
        var uploadSpeed: Double      // bytes per second
        var downloadSpeed: Double    // bytes per second
        var cpuUsage: Double         // percentage
        var threatLevel: Int         // 0 = normal, 1 = warning, 2 = alert
        var threatScore: Int         // 0-100
    }
    
    // Static attributes (set when activity starts)
    var startTime: Date
}

// Helper extension for formatting
extension SentinelActivityAttributes.ContentState {
    var uploadFormatted: String {
        formatSpeed(uploadSpeed)
    }
    
    var downloadFormatted: String {
        formatSpeed(downloadSpeed)
    }
    
    var statusColor: String {
        switch threatLevel {
        case 0: return "green"
        case 1: return "orange"
        default: return "red"
        }
    }
    
    var statusText: String {
        switch threatLevel {
        case 0: return "Normal"
        case 1: return "Warning"
        default: return "Alert"
        }
    }
    
    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1024 {
            return String(format: "%.0f B/s", bytesPerSecond)
        } else if bytesPerSecond < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytesPerSecond / 1024)
        } else {
            return String(format: "%.1f MB/s", bytesPerSecond / (1024 * 1024))
        }
    }
}
