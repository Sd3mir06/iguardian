//
//  IncidentManager.swift
//  iguardian
//
//  Incident tracking and storage
//

import Foundation
import Combine
import SwiftUI
import SwiftData

@MainActor
class IncidentManager: ObservableObject {
    static let shared = IncidentManager()
    
    @Published var activeIncidents: [Incident] = []
    @Published var recentIncidents: [Incident] = []
    
    private var modelContext: ModelContext?
    private let monitoringManager = MonitoringManager.shared
    private let thresholdManager = ThresholdManager.shared
    
    private init() {}
    
    // MARK: - Configuration
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadRecentIncidents()
    }
    
    // MARK: - Incident Detection
    func evaluateMetrics(_ snapshot: MetricSnapshot) {
        // Check for screen surveillance pattern
        if shouldTriggerScreenSurveillance(snapshot) {
            createIncident(type: .screenSurveillance, severity: .critical, from: snapshot)
        }
        
        // Check for data exfiltration
        if shouldTriggerDataExfiltration(snapshot) {
            createIncident(type: .dataExfiltration, severity: .high, from: snapshot)
        }
        
        // Check for CPU anomaly
        if shouldTriggerCPUAnomaly(snapshot) {
            createIncident(type: .cpuAnomaly, severity: .medium, from: snapshot)
        }
        
        // Check for battery anomaly
        if shouldTriggerBatteryAnomaly(snapshot) {
            createIncident(type: .batteryAnomaly, severity: .medium, from: snapshot)
        }
        
        // Check for multi-factor alert
        if shouldTriggerMultiFactor(snapshot) {
            createIncident(type: .multiFactorAlert, severity: .critical, from: snapshot)
        }
    }
    
    // MARK: - Detection Logic
    private func shouldTriggerScreenSurveillance(_ snapshot: MetricSnapshot) -> Bool {
        let uploadThreshold = thresholdManager.threshold(for: .uploadRate)
        guard uploadThreshold.isEnabled else { return false }
        
        // Convert bytes/sec to MB/hour
        let uploadMBPerHour = (snapshot.uploadBytesPerSecond * 3600) / (1024 * 1024)
        
        // Continuous high upload + elevated CPU
        return uploadMBPerHour > uploadThreshold.value * 2 && 
               snapshot.cpuUsagePercent > 25 &&
               snapshot.thermalState != .nominal
    }
    
    private func shouldTriggerDataExfiltration(_ snapshot: MetricSnapshot) -> Bool {
        let uploadThreshold = thresholdManager.threshold(for: .uploadRate)
        guard uploadThreshold.isEnabled else { return false }
        
        let uploadMBPerHour = (snapshot.uploadBytesPerSecond * 3600) / (1024 * 1024)
        return uploadMBPerHour > uploadThreshold.value
    }
    
    private func shouldTriggerCPUAnomaly(_ snapshot: MetricSnapshot) -> Bool {
        let cpuThreshold = thresholdManager.threshold(for: .cpuUsage)
        guard cpuThreshold.isEnabled else { return false }
        
        return snapshot.cpuUsagePercent > cpuThreshold.value
    }
    
    private func shouldTriggerBatteryAnomaly(_ snapshot: MetricSnapshot) -> Bool {
        let batteryThreshold = thresholdManager.threshold(for: .batteryDrain)
        guard batteryThreshold.isEnabled else { return false }
        
        return snapshot.batteryDrainPerHour > Float(batteryThreshold.value)
    }
    
    private func shouldTriggerMultiFactor(_ snapshot: MetricSnapshot) -> Bool {
        var factors = 0
        
        let uploadMBPerHour = (snapshot.uploadBytesPerSecond * 3600) / (1024 * 1024)
        if uploadMBPerHour > 30 { factors += 1 }
        if snapshot.cpuUsagePercent > 25 { factors += 1 }
        if snapshot.batteryDrainPerHour > 5 { factors += 1 }
        if snapshot.thermalState == .serious || snapshot.thermalState == .critical { factors += 1 }
        
        return factors >= 3
    }
    
    // MARK: - Incident Management
    private func createIncident(type: IncidentType, severity: IncidentSeverity, from snapshot: MetricSnapshot) {
        // Check if similar incident already active
        if activeIncidents.contains(where: { $0.type == type && !$0.isResolved }) {
            return
        }
        
        let thermalInt: Int
        switch snapshot.thermalState {
        case .nominal: thermalInt = 0
        case .fair: thermalInt = 1
        case .serious: thermalInt = 2
        case .critical: thermalInt = 3
        }
        
        let incident = Incident(
            type: type,
            severity: severity,
            uploadRate: snapshot.uploadBytesPerSecond,
            downloadRate: snapshot.downloadBytesPerSecond,
            cpuUsage: snapshot.cpuUsagePercent,
            batteryDrain: Double(snapshot.batteryDrainPerHour),
            thermalState: thermalInt,
            threatScore: snapshot.threatScore
        )
        
        activeIncidents.append(incident)
        recentIncidents.insert(incident, at: 0)
        
        // Save to database
        if let context = modelContext {
            context.insert(incident)
            try? context.save()
        }
        
        // Notify Sleep Guard if active
        SleepGuardManager.shared.recordIncident(incident)
        
        print("Created incident: \(type.title) - \(severity.label)")
    }
    
    func resolveIncident(_ incident: Incident) {
        incident.isResolved = true
        incident.endTimestamp = Date()
        
        if let index = activeIncidents.firstIndex(where: { $0.id == incident.id }) {
            activeIncidents.remove(at: index)
        }
        
        try? modelContext?.save()
    }
    
    func acknowledgeIncident(_ incident: Incident) {
        incident.isAcknowledged = true
        try? modelContext?.save()
    }
    
    // MARK: - History
    private func loadRecentIncidents() {
        // Load from SwiftData
    }
    
    func getIncidents(from startDate: Date, to endDate: Date) -> [Incident] {
        // Query SwiftData
        return recentIncidents.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }
}
