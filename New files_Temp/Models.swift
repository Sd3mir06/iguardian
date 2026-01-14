//
//  Models.swift
//  iguardian
//
//  Core data models for the app
//

import SwiftUI

// MARK: - Threat Level
enum ThreatLevel: String, CaseIterable {
    case normal = "All Clear"
    case warning = "Warning"
    case alert = "Alert"
    case critical = "Critical"
    
    var color: Color {
        switch self {
        case .normal: return Theme.statusSafe
        case .warning: return Theme.statusWarning
        case .alert: return Theme.statusDanger
        case .critical: return Theme.statusCritical
        }
    }
    
    var icon: String {
        switch self {
        case .normal: return "checkmark.shield.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .alert: return "exclamationmark.shield.fill"
        case .critical: return "xmark.shield.fill"
        }
    }
    
    var message: String {
        switch self {
        case .normal: return "Your device is secure"
        case .warning: return "Elevated activity detected"
        case .alert: return "Suspicious activity detected"
        case .critical: return "Critical threat detected"
        }
    }
}

// MARK: - Thermal State
enum ThermalState: String, CaseIterable {
    case nominal = "Nominal"
    case fair = "Fair"
    case serious = "Serious"
    case critical = "Critical"
    
    var color: Color {
        switch self {
        case .nominal: return Theme.statusSafe
        case .fair: return Theme.statusWarning
        case .serious: return Theme.statusDanger
        case .critical: return Theme.statusCritical
        }
    }
    
    static func from(_ state: ProcessInfo.ThermalState) -> ThermalState {
        switch state {
        case .nominal: return .nominal
        case .fair: return .fair
        case .serious: return .serious
        case .critical: return .critical
        @unknown default: return .nominal
        }
    }
}

// MARK: - Metric Snapshot
struct MetricSnapshot {
    var timestamp: Date = Date()
    var uploadBytesPerSecond: Double = 0
    var downloadBytesPerSecond: Double = 0
    var cpuUsagePercent: Double = 0
    var batteryLevel: Float = 0
    var batteryDrainPerHour: Float = 0
    var thermalState: ThermalState = .nominal
    var threatLevel: ThreatLevel = .normal
    var threatScore: Int = 0
    
    var uploadFormatted: String {
        formatBytes(uploadBytesPerSecond)
    }
    
    var downloadFormatted: String {
        formatBytes(downloadBytesPerSecond)
    }
    
    private func formatBytes(_ bytes: Double) -> String {
        if bytes < 1024 {
            return String(format: "%.0f B/s", bytes)
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytes / 1024)
        } else {
            return String(format: "%.1f MB/s", bytes / (1024 * 1024))
        }
    }
}

// MARK: - Activity Type
enum ActivityType {
    case monitoringStarted
    case monitoringStopped
    case normal
    case warning
    case alert
    case critical
    
    var icon: String {
        switch self {
        case .monitoringStarted: return "play.circle.fill"
        case .monitoringStopped: return "stop.circle.fill"
        case .normal: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .alert: return "exclamationmark.circle.fill"
        case .critical: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .monitoringStarted: return Theme.accentPrimary
        case .monitoringStopped: return Theme.textSecondary
        case .normal: return Theme.statusSafe
        case .warning: return Theme.statusWarning
        case .alert: return Theme.statusDanger
        case .critical: return Theme.statusCritical
        }
    }
}

// MARK: - Activity Entry
struct ActivityEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let type: ActivityType
    let title: String
    let description: String
    let threatLevel: ThreatLevel
    
    init(type: ActivityType, title: String, description: String, threatLevel: ThreatLevel) {
        self.timestamp = Date()
        self.type = type
        self.title = title
        self.description = description
        self.threatLevel = threatLevel
    }
    
    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}
