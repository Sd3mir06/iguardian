//
//  SleepSession.swift
//  iguardian
//
//  Sleep monitoring session data model
//

import Foundation
import SwiftData

@Model
class SleepSession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var isActive: Bool
    
    // Aggregated metrics
    var totalUploadBytes: Int64
    var totalDownloadBytes: Int64
    var peakCPU: Double
    var averageCPU: Double
    var batteryStart: Double
    var batteryEnd: Double
    var peakThreatScore: Int
    var averageThreatScore: Double
    
    // Incidents during sleep
    var incidentCount: Int
    var hasAnomalies: Bool
    
    // Snapshots (stored as JSON)
    var snapshotsData: Data?
    
    init(startTime: Date = Date()) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = nil
        self.isActive = true
        self.totalUploadBytes = 0
        self.totalDownloadBytes = 0
        self.peakCPU = 0
        self.averageCPU = 0
        self.batteryStart = 0
        self.batteryEnd = 0
        self.peakThreatScore = 0
        self.averageThreatScore = 0
        self.incidentCount = 0
        self.hasAnomalies = false
    }
    
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    var durationFormatted: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    var batteryUsed: Double {
        batteryStart - batteryEnd
    }
    
    var totalUploadFormatted: String {
        ByteCountFormatter.string(fromByteCount: totalUploadBytes, countStyle: .file)
    }
    
    var totalDownloadFormatted: String {
        ByteCountFormatter.string(fromByteCount: totalDownloadBytes, countStyle: .file)
    }
    
    var statusSummary: String {
        if hasAnomalies {
            return "⚠️ Anomalies Detected"
        } else if incidentCount > 0 {
            return "⚡ \(incidentCount) Events"
        } else {
            return "✅ All Clear"
        }
    }
}
