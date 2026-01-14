//
//  DataExporter.swift
//  iguardian
//
//  Data export functionality for CSV/JSON
//

import Foundation
import Combine
import SwiftUI
import UniformTypeIdentifiers

class DataExporter: ObservableObject {
    static let shared = DataExporter()
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
        
        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .json: return "json"
            }
        }
        
        var contentType: UTType {
            switch self {
            case .csv: return .commaSeparatedText
            case .json: return .json
            }
        }
    }
    
    enum ExportDataType: String, CaseIterable {
        case incidents = "Incidents"
        case sleepSessions = "Sleep Sessions"
        case metrics = "Metrics History"
        
        var icon: String {
            switch self {
            case .incidents: return "exclamationmark.triangle"
            case .sleepSessions: return "moon.stars"
            case .metrics: return "chart.line.uptrend.xyaxis"
            }
        }
    }
    
    private init() {}
    
    // MARK: - Export Incidents
    func exportIncidents(_ incidents: [Incident], format: ExportFormat) -> Data? {
        switch format {
        case .csv:
            return exportIncidentsAsCSV(incidents)
        case .json:
            return exportIncidentsAsJSON(incidents)
        }
    }
    
    private func exportIncidentsAsCSV(_ incidents: [Incident]) -> Data? {
        var csv = "ID,Timestamp,Type,Severity,Upload Rate,Download Rate,CPU,Battery Drain,Threat Score,Duration,Resolved\n"
        
        for incident in incidents {
            let line = [
                incident.id.uuidString,
                ISO8601DateFormatter().string(from: incident.timestamp),
                incident.type.title,
                incident.severity.label,
                String(format: "%.2f", incident.uploadRate),
                String(format: "%.2f", incident.downloadRate),
                String(format: "%.1f", incident.cpuUsage),
                String(format: "%.1f", incident.batteryDrain),
                "\(incident.threatScore)",
                incident.durationFormatted,
                incident.isResolved ? "Yes" : "No"
            ].joined(separator: ",")
            
            csv += line + "\n"
        }
        
        return csv.data(using: .utf8)
    }
    
    private func exportIncidentsAsJSON(_ incidents: [Incident]) -> Data? {
        let exportData = incidents.map { incident in
            [
                "id": incident.id.uuidString,
                "timestamp": ISO8601DateFormatter().string(from: incident.timestamp),
                "type": incident.type.rawValue,
                "severity": incident.severity.label,
                "uploadRate": incident.uploadRate,
                "downloadRate": incident.downloadRate,
                "cpuUsage": incident.cpuUsage,
                "batteryDrain": incident.batteryDrain,
                "threatScore": incident.threatScore,
                "isResolved": incident.isResolved,
                "summary": incident.summary,
                "details": incident.details
            ] as [String : Any]
        }
        
        return try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
    
    // MARK: - Export Sleep Sessions
    func exportSleepSessions(_ sessions: [SleepSession], format: ExportFormat) -> Data? {
        switch format {
        case .csv:
            return exportSleepSessionsAsCSV(sessions)
        case .json:
            return exportSleepSessionsAsJSON(sessions)
        }
    }
    
    private func exportSleepSessionsAsCSV(_ sessions: [SleepSession]) -> Data? {
        var csv = "ID,Start Time,End Time,Duration,Upload Total,Download Total,Peak CPU,Avg CPU,Battery Used,Peak Threat Score,Incidents,Has Anomalies\n"
        
        for session in sessions {
            let line = [
                session.id.uuidString,
                ISO8601DateFormatter().string(from: session.startTime),
                session.endTime.map { ISO8601DateFormatter().string(from: $0) } ?? "Ongoing",
                session.durationFormatted,
                session.totalUploadFormatted,
                session.totalDownloadFormatted,
                String(format: "%.1f", session.peakCPU),
                String(format: "%.1f", session.averageCPU),
                String(format: "%.1f", session.batteryUsed),
                "\(session.peakThreatScore)",
                "\(session.incidentCount)",
                session.hasAnomalies ? "Yes" : "No"
            ].joined(separator: ",")
            
            csv += line + "\n"
        }
        
        return csv.data(using: .utf8)
    }
    
    private func exportSleepSessionsAsJSON(_ sessions: [SleepSession]) -> Data? {
        let exportData = sessions.map { session in
            [
                "id": session.id.uuidString,
                "startTime": ISO8601DateFormatter().string(from: session.startTime),
                "endTime": session.endTime.map { ISO8601DateFormatter().string(from: $0) } ?? nil,
                "duration": session.duration,
                "totalUploadBytes": session.totalUploadBytes,
                "totalDownloadBytes": session.totalDownloadBytes,
                "peakCPU": session.peakCPU,
                "averageCPU": session.averageCPU,
                "batteryUsed": session.batteryUsed,
                "peakThreatScore": session.peakThreatScore,
                "incidentCount": session.incidentCount,
                "hasAnomalies": session.hasAnomalies
            ] as [String : Any?]
        }
        
        return try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
    
    // MARK: - Generate Filename
    func generateFilename(for dataType: ExportDataType, format: ExportFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        return "iguardian_\(dataType.rawValue.lowercased().replacingOccurrences(of: " ", with: "_"))_\(timestamp).\(format.fileExtension)"
    }
}
