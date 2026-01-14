//
//  Incident.swift
//  iguardian
//
//  Security incident data model
//

import Foundation
import SwiftData
import SwiftUI

enum IncidentType: String, Codable, CaseIterable {
    case screenSurveillance = "screen_surveillance"
    case dataExfiltration = "data_exfiltration"
    case cpuAnomaly = "cpu_anomaly"
    case batteryAnomaly = "battery_anomaly"
    case thermalAnomaly = "thermal_anomaly"
    case multiFactorAlert = "multi_factor_alert"
    
    var title: String {
        switch self {
        case .screenSurveillance: return "Possible Screen Surveillance"
        case .dataExfiltration: return "Suspicious Data Upload"
        case .cpuAnomaly: return "Abnormal CPU Activity"
        case .batteryAnomaly: return "Unusual Battery Drain"
        case .thermalAnomaly: return "Thermal Anomaly"
        case .multiFactorAlert: return "Multi-Factor Security Alert"
        }
    }
    
    var icon: String {
        switch self {
        case .screenSurveillance: return "eye.trianglebadge.exclamationmark"
        case .dataExfiltration: return "arrow.up.doc"
        case .cpuAnomaly: return "cpu"
        case .batteryAnomaly: return "battery.25"
        case .thermalAnomaly: return "thermometer.sun"
        case .multiFactorAlert: return "exclamationmark.shield"
        }
    }
    
    var color: Color {
        switch self {
        case .screenSurveillance, .multiFactorAlert: return .red
        case .dataExfiltration, .cpuAnomaly: return .orange
        case .batteryAnomaly, .thermalAnomaly: return .yellow
        }
    }
}

enum IncidentSeverity: Int, Codable, Comparable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
    
    static func < (lhs: IncidentSeverity, rhs: IncidentSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

@Model
class Incident {
    var id: UUID
    var timestamp: Date
    var endTimestamp: Date?
    var typeRaw: String
    var severityRaw: Int
    var isResolved: Bool
    var isAcknowledged: Bool
    
    // Metrics at time of incident
    var uploadRate: Double        // bytes/sec
    var downloadRate: Double      // bytes/sec
    var cpuUsage: Double          // percentage
    var batteryDrain: Double      // %/hour
    var thermalState: Int         // 0-3
    var threatScore: Int          // 0-100
    
    // Totals during incident
    var totalBytesUploaded: Int64
    var totalBytesDownloaded: Int64
    
    // Description
    var summary: String
    var details: String
    
    var type: IncidentType {
        get { IncidentType(rawValue: typeRaw) ?? .cpuAnomaly }
        set { typeRaw = newValue.rawValue }
    }
    
    var severity: IncidentSeverity {
        get { IncidentSeverity(rawValue: severityRaw) ?? .low }
        set { severityRaw = newValue.rawValue }
    }
    
    init(
        type: IncidentType,
        severity: IncidentSeverity,
        uploadRate: Double,
        downloadRate: Double,
        cpuUsage: Double,
        batteryDrain: Double,
        thermalState: Int,
        threatScore: Int
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.endTimestamp = nil
        self.typeRaw = type.rawValue
        self.severityRaw = severity.rawValue
        self.isResolved = false
        self.isAcknowledged = false
        self.uploadRate = uploadRate
        self.downloadRate = downloadRate
        self.cpuUsage = cpuUsage
        self.batteryDrain = batteryDrain
        self.thermalState = thermalState
        self.threatScore = threatScore
        self.totalBytesUploaded = 0
        self.totalBytesDownloaded = 0
        self.summary = type.title
        self.details = ""
    }
    
    var duration: TimeInterval? {
        guard let end = endTimestamp else { return nil }
        return end.timeIntervalSince(timestamp)
    }
    
    var durationFormatted: String {
        guard let duration = duration else { return "Ongoing" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}
