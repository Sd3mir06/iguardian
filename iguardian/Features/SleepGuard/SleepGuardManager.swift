//
//  SleepGuardManager.swift
//  iguardian
//
//  Sleep Guard monitoring manager
//

import Foundation
import Combine
import SwiftUI
import SwiftData
import UserNotifications

@MainActor
class SleepGuardManager: ObservableObject {
    static let shared = SleepGuardManager()
    
    // Settings
    @AppStorage("sleepGuard_enabled") var isEnabled = false
    @AppStorage("sleepGuard_startHour") var startHour = 23      // 11 PM
    @AppStorage("sleepGuard_startMinute") var startMinute = 0
    @AppStorage("sleepGuard_endHour") var endHour = 7           // 7 AM
    @AppStorage("sleepGuard_endMinute") var endMinute = 0
    @AppStorage("sleepGuard_autoStart") var autoStart = true
    
    // State
    @Published var currentSession: SleepSession?
    @Published var isMonitoring = false
    @Published var lastReport: SleepSession?
    @Published var sessionHistory: [SleepSession] = []
    
    // Collected data during session
    private var snapshots: [SleepMetricSnapshot] = []
    private var incidents: [Incident] = []
    private var monitoringTimer: Timer?
    
    private let monitoringManager = MonitoringManager.shared
    private var modelContext: ModelContext?
    
    private init() {
        // Enable battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    
    // MARK: - Configuration
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadLastSession()
        loadSessionHistory()
    }
    
    var startTime: Date {
        Calendar.current.date(
            bySettingHour: startHour,
            minute: startMinute,
            second: 0,
            of: Date()
        ) ?? Date()
    }
    
    var endTime: Date {
        var date = Calendar.current.date(
            bySettingHour: endHour,
            minute: endMinute,
            second: 0,
            of: Date()
        ) ?? Date()
        
        // If end time is before start time, it's the next day
        if date <= startTime {
            date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
        }
        return date
    }
    
    var scheduleDescription: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) → \(formatter.string(from: endTime))"
    }
    
    var isWithinSchedule: Bool {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTime = currentHour * 60 + currentMinute
        
        let start = startHour * 60 + startMinute
        let end = endHour * 60 + endMinute
        
        if start > end {
            // Overnight schedule (e.g., 23:00 - 07:00)
            return currentTime >= start || currentTime < end
        } else {
            // Same day schedule
            return currentTime >= start && currentTime < end
        }
    }
    
    // MARK: - Session Control
    func startSession() {
        guard currentSession == nil else { return }
        
        let session = SleepSession(startTime: Date())
        let batteryLevel = UIDevice.current.batteryLevel
        session.batteryStart = batteryLevel >= 0 ? Double(batteryLevel * 100) : 100
        
        currentSession = session
        isMonitoring = true
        snapshots = []
        incidents = []
        
        LogManager.shared.log("Sleep Guard session started", level: .info, category: "SleepGuard")
        
        // Start monitoring timer - capture data every 30 seconds
        startMonitoringTimer()
        
        // Schedule notification for morning
        scheduleMorningNotification()
        
        print("Sleep Guard session started")
    }
    
    func endSession() {
        guard let session = currentSession else { return }
        
        // Stop the timer
        stopMonitoringTimer()
        
        session.endTime = Date()
        session.isActive = false
        let batteryLevel = UIDevice.current.batteryLevel
        session.batteryEnd = batteryLevel >= 0 ? Double(batteryLevel * 100) : 100
        
        // Calculate aggregates
        finalizeSession(session)
        
        // Save to database
        if let context = modelContext {
            context.insert(session)
            try? context.save()
        }
        
        lastReport = session
        sessionHistory.insert(session, at: 0)
        currentSession = nil
        isMonitoring = false
        
        LogManager.shared.log("Sleep Guard session ended. Duration: \(session.durationFormatted)", level: .info, category: "SleepGuard")
        
        // Show notification
        showReportReadyNotification()
        
        print("Sleep Guard session ended - Duration: \(session.durationFormatted)")
    }
    
    // MARK: - Monitoring Timer
    private func startMonitoringTimer() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.captureSnapshot()
            }
        }
        
        // Capture initial snapshot
        captureSnapshot()
    }
    
    private func stopMonitoringTimer() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    private func captureSnapshot() {
        let snapshot = SleepMetricSnapshot(
            timestamp: Date(),
            uploadBytes: monitoringManager.currentSnapshot.uploadBytesPerSecond * 30, // 30 sec worth
            downloadBytes: monitoringManager.currentSnapshot.downloadBytesPerSecond * 30,
            cpuUsage: monitoringManager.currentSnapshot.cpuUsagePercent,
            batteryLevel: Double(UIDevice.current.batteryLevel * 100),
            thermalState: thermalStateInt(monitoringManager.currentSnapshot.thermalState),
            threatScore: monitoringManager.threatScore
        )
        
        LogManager.shared.log("Sleep Guard snapshot: CPU \(Int(snapshot.cpuUsage))%, Score \(snapshot.threatScore)", level: .debug, category: "SleepGuard")
        recordSnapshot(snapshot)
    }
    
    private func thermalStateInt(_ state: ThermalState) -> Int {
        switch state {
        case .nominal: return 0
        case .fair: return 1
        case .serious: return 2
        case .critical: return 3
        }
    }
    
    // MARK: - Data Collection
    func recordSnapshot(_ snapshot: SleepMetricSnapshot) {
        guard isMonitoring else { return }
        snapshots.append(snapshot)
        
        // Update running totals
        if let session = currentSession {
            session.totalUploadBytes += Int64(snapshot.uploadBytes)
            session.totalDownloadBytes += Int64(snapshot.downloadBytes)
            
            if snapshot.cpuUsage > session.peakCPU {
                session.peakCPU = snapshot.cpuUsage
            }
            
            if snapshot.threatScore > session.peakThreatScore {
                session.peakThreatScore = snapshot.threatScore
            }
        }
    }
    
    func recordIncident(_ incident: Incident) {
        guard isMonitoring else { return }
        incidents.append(incident)
        
        if let session = currentSession {
            session.incidentCount += 1
            if incident.severity >= .high {
                session.hasAnomalies = true
            }
        }
    }
    
    // MARK: - Finalization
    private func finalizeSession(_ session: SleepSession) {
        // Calculate averages
        if !snapshots.isEmpty {
            let totalCPU = snapshots.reduce(0) { $0 + $1.cpuUsage }
            session.averageCPU = totalCPU / Double(snapshots.count)
            
            let totalScore = snapshots.reduce(0) { $0 + $1.threatScore }
            session.averageThreatScore = Double(totalScore) / Double(snapshots.count)
        }
        
        // Store snapshots as JSON
        if let data = try? JSONEncoder().encode(snapshots) {
            session.snapshotsData = data
        }
        
        session.incidentCount = incidents.count
        session.hasAnomalies = incidents.contains { $0.severity >= .high }
    }
    
    // MARK: - Notifications
    private func scheduleMorningNotification() {
        let content = UNMutableNotificationContent()
        content.title = "☀️ Sleep Guard Report Ready"
        content.body = "Tap to see what happened while you slept"
        content.sound = .default
        
        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: endTime)
        dateComponents.second = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "sleepguard.morning",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func showReportReadyNotification() {
        let content = UNMutableNotificationContent()
        
        if let session = lastReport {
            if session.hasAnomalies {
                content.title = "⚠️ Sleep Guard: Anomalies Detected"
                content.body = "We detected \(session.incidentCount) suspicious events while you slept"
            } else {
                content.title = "✅ Sleep Guard: All Clear"
                content.body = "No suspicious activity detected overnight"
            }
        } else {
            content.title = "Sleep Guard Report Ready"
            content.body = "Tap to view your overnight security report"
        }
        
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "sleepguard.report",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - History
    private func loadLastSession() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<SleepSession>(
            predicate: #Predicate { !$0.isActive },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        do {
            let sessions = try context.fetch(descriptor)
            lastReport = sessions.first
        } catch {
            print("Failed to load last session: \(error)")
        }
    }
    
    private func loadSessionHistory() {
        guard let context = modelContext else { return }
        
        var descriptor = FetchDescriptor<SleepSession>(
            predicate: #Predicate { !$0.isActive },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = 30
        
        do {
            sessionHistory = try context.fetch(descriptor)
        } catch {
            print("Failed to load session history: \(error)")
        }
    }
    
    func getSessionHistory(limit: Int = 30) -> [SleepSession] {
        return sessionHistory
    }
    
    func refreshHistory() {
        loadLastSession()
        loadSessionHistory()
    }
}

// MARK: - Metric Snapshot for Sleep Guard
struct SleepMetricSnapshot: Codable {
    let timestamp: Date
    let uploadBytes: Double
    let downloadBytes: Double
    let cpuUsage: Double
    let batteryLevel: Double
    let thermalState: Int
    let threatScore: Int
}
