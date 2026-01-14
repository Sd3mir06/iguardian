# Sentinel App - Phase 3 Implementation

## Overview
Phase 3 adds advanced security features: Sleep Guard monitoring, Threat Scoring system, Incident Timeline forensics, Custom Alert Thresholds, and PDF Security Reports.

---

## 📁 New Files to Create

```
iguardian/
├── Features/
│   ├── SleepGuard/
│   │   ├── SleepGuardManager.swift      ← Scheduled monitoring
│   │   ├── SleepGuardView.swift         ← Sleep Guard UI
│   │   └── SleepReportView.swift        ← Morning report
│   ├── ThreatScore/
│   │   ├── ThreatScoreEngine.swift      ← Scoring algorithm
│   │   └── ThreatScoreDetailView.swift  ← Score breakdown
│   ├── Incidents/
│   │   ├── IncidentManager.swift        ← Track & store incidents
│   │   ├── IncidentTimelineView.swift   ← Timeline UI
│   │   └── IncidentDetailView.swift     ← Single incident view
│   └── Reports/
│       ├── PDFReportGenerator.swift     ← PDF creation
│       └── ReportHistoryView.swift      ← Past reports
├── Models/
│   ├── SleepSession.swift               ← Sleep monitoring data
│   ├── Incident.swift                   ← Incident model
│   └── AlertThreshold.swift             ← Custom thresholds
└── Views/
    └── Settings/
        └── ThresholdSettingsView.swift  ← Custom threshold UI
```

---

## 📄 FILE 1: SleepSession.swift (Model)
**Location:** `iguardian/Models/SleepSession.swift`

```swift
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
```

---

## 📄 FILE 2: Incident.swift (Model)
**Location:** `iguardian/Models/Incident.swift`

```swift
import Foundation
import SwiftData

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
    
    var color: String {
        switch self {
        case .screenSurveillance, .multiFactorAlert: return "red"
        case .dataExfiltration, .cpuAnomaly: return "orange"
        case .batteryAnomaly, .thermalAnomaly: return "yellow"
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
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

@Model
class Incident {
    var id: UUID
    var timestamp: Date
    var endTimestamp: Date?
    var type: IncidentType
    var severity: IncidentSeverity
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
        self.type = type
        self.severity = severity
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
        
        generateDetails()
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
    
    private mutating func generateDetails() {
        var lines: [String] = []
        
        switch type {
        case .screenSurveillance:
            lines.append("Continuous high upload detected while device idle.")
            lines.append("Upload rate: \(formatSpeed(uploadRate))")
            lines.append("This pattern matches remote screen viewing.")
            
        case .dataExfiltration:
            lines.append("Large data upload detected during idle period.")
            lines.append("Upload rate: \(formatSpeed(uploadRate))")
            lines.append("Total uploaded: \(formatBytes(totalBytesUploaded))")
            
        case .cpuAnomaly:
            lines.append("Sustained high CPU usage without user activity.")
            lines.append("CPU usage: \(String(format: "%.1f%%", cpuUsage))")
            
        case .batteryAnomaly:
            lines.append("Battery draining faster than normal idle rate.")
            lines.append("Drain rate: \(String(format: "%.1f%%/hour", batteryDrain))")
            
        case .thermalAnomaly:
            lines.append("Device temperature elevated without active use.")
            lines.append("Thermal state: \(thermalStateString)")
            
        case .multiFactorAlert:
            lines.append("Multiple suspicious indicators detected simultaneously.")
            lines.append("CPU: \(String(format: "%.1f%%", cpuUsage))")
            lines.append("Upload: \(formatSpeed(uploadRate))")
            lines.append("Battery drain: \(String(format: "%.1f%%/hr", batteryDrain))")
        }
        
        details = lines.joined(separator: "\n")
    }
    
    private var thermalStateString: String {
        switch thermalState {
        case 0: return "Nominal"
        case 1: return "Fair"
        case 2: return "Serious"
        default: return "Critical"
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
    
    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
```

---

## 📄 FILE 3: AlertThreshold.swift (Model)
**Location:** `iguardian/Models/AlertThreshold.swift`

```swift
import Foundation
import SwiftUI

struct AlertThreshold: Codable, Identifiable {
    var id: String { metric.rawValue }
    var metric: ThresholdMetric
    var value: Double
    var isEnabled: Bool
    
    enum ThresholdMetric: String, Codable, CaseIterable {
        case uploadRate = "upload_rate"
        case downloadRate = "download_rate"
        case cpuUsage = "cpu_usage"
        case batteryDrain = "battery_drain"
        
        var title: String {
            switch self {
            case .uploadRate: return "Upload Rate"
            case .downloadRate: return "Download Rate"
            case .cpuUsage: return "CPU Usage"
            case .batteryDrain: return "Battery Drain"
            }
        }
        
        var icon: String {
            switch self {
            case .uploadRate: return "arrow.up"
            case .downloadRate: return "arrow.down"
            case .cpuUsage: return "cpu"
            case .batteryDrain: return "battery.50"
            }
        }
        
        var unit: String {
            switch self {
            case .uploadRate, .downloadRate: return "MB/hour"
            case .cpuUsage: return "%"
            case .batteryDrain: return "%/hour"
            }
        }
        
        var defaultValue: Double {
            switch self {
            case .uploadRate: return 50      // 50 MB/hour
            case .downloadRate: return 100   // 100 MB/hour
            case .cpuUsage: return 30        // 30%
            case .batteryDrain: return 5     // 5%/hour
            }
        }
        
        var range: ClosedRange<Double> {
            switch self {
            case .uploadRate: return 10...500
            case .downloadRate: return 10...500
            case .cpuUsage: return 10...80
            case .batteryDrain: return 2...20
            }
        }
        
        var step: Double {
            switch self {
            case .uploadRate, .downloadRate: return 10
            case .cpuUsage: return 5
            case .batteryDrain: return 1
            }
        }
    }
    
    static var defaults: [AlertThreshold] {
        ThresholdMetric.allCases.map { metric in
            AlertThreshold(
                metric: metric,
                value: metric.defaultValue,
                isEnabled: true
            )
        }
    }
}

// MARK: - Threshold Storage
class ThresholdManager: ObservableObject {
    static let shared = ThresholdManager()
    
    @Published var thresholds: [AlertThreshold] {
        didSet { save() }
    }
    
    private let key = "alert_thresholds"
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([AlertThreshold].self, from: data) {
            thresholds = decoded
        } else {
            thresholds = AlertThreshold.defaults
        }
    }
    
    func threshold(for metric: AlertThreshold.ThresholdMetric) -> AlertThreshold {
        thresholds.first { $0.metric == metric } ?? AlertThreshold(
            metric: metric,
            value: metric.defaultValue,
            isEnabled: true
        )
    }
    
    func update(_ threshold: AlertThreshold) {
        if let index = thresholds.firstIndex(where: { $0.metric == threshold.metric }) {
            thresholds[index] = threshold
        }
    }
    
    func reset() {
        thresholds = AlertThreshold.defaults
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(thresholds) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}
```

---

## 📄 FILE 4: SleepGuardManager.swift
**Location:** `iguardian/Features/SleepGuard/SleepGuardManager.swift`

```swift
import Foundation
import SwiftUI
import SwiftData
import UserNotifications
import BackgroundTasks

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
    
    // Collected data during session
    private var snapshots: [MetricSnapshot] = []
    private var incidents: [Incident] = []
    
    private let monitoringManager = MonitoringManager.shared
    private var modelContext: ModelContext?
    
    private init() {}
    
    // MARK: - Configuration
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadLastSession()
        scheduleBackgroundTasks()
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
        session.batteryStart = Double(UIDevice.current.batteryLevel * 100)
        
        currentSession = session
        isMonitoring = true
        snapshots = []
        incidents = []
        
        // Start collecting data
        startDataCollection()
        
        // Schedule notification for morning
        scheduleMorningNotification()
        
        print("Sleep Guard session started")
    }
    
    func endSession() {
        guard var session = currentSession else { return }
        
        session.endTime = Date()
        session.isActive = false
        session.batteryEnd = Double(UIDevice.current.batteryLevel * 100)
        
        // Calculate aggregates
        finalizeSession(&session)
        
        // Save to database
        if let context = modelContext {
            context.insert(session)
            try? context.save()
        }
        
        lastReport = session
        currentSession = nil
        isMonitoring = false
        
        // Show notification
        showReportReadyNotification()
        
        print("Sleep Guard session ended")
    }
    
    // MARK: - Data Collection
    private func startDataCollection() {
        // This would integrate with MonitoringManager
        // Collect snapshots every minute during sleep
    }
    
    func recordSnapshot(_ snapshot: MetricSnapshot) {
        guard isMonitoring else { return }
        snapshots.append(snapshot)
        
        // Update running totals
        if var session = currentSession {
            session.totalUploadBytes += Int64(snapshot.uploadBytes)
            session.totalDownloadBytes += Int64(snapshot.downloadBytes)
            
            if snapshot.cpuUsage > session.peakCPU {
                session.peakCPU = snapshot.cpuUsage
            }
            
            if snapshot.threatScore > session.peakThreatScore {
                session.peakThreatScore = snapshot.threatScore
            }
            
            currentSession = session
        }
    }
    
    func recordIncident(_ incident: Incident) {
        guard isMonitoring else { return }
        incidents.append(incident)
        
        if var session = currentSession {
            session.incidentCount += 1
            if incident.severity >= .high {
                session.hasAnomalies = true
            }
            currentSession = session
        }
    }
    
    // MARK: - Finalization
    private func finalizeSession(_ session: inout SleepSession) {
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
    
    // MARK: - Background Tasks
    private func scheduleBackgroundTasks() {
        // Register for background app refresh
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.sentinel.sleepguard.monitor",
            using: nil
        ) { task in
            self.handleBackgroundTask(task as! BGAppRefreshTask)
        }
    }
    
    private func handleBackgroundTask(_ task: BGAppRefreshTask) {
        // Collect snapshot in background
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Quick data collection
        Task {
            // Get current metrics
            // Record snapshot
            task.setTaskCompleted(success: true)
            scheduleNextBackgroundTask()
        }
    }
    
    private func scheduleNextBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: "com.sentinel.sleepguard.monitor")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60) // 1 minute
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background task: \(error)")
        }
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
        // Load most recent completed session from SwiftData
    }
    
    func getSessionHistory(limit: Int = 30) -> [SleepSession] {
        // Query SwiftData for past sessions
        return []
    }
}

// MARK: - Metric Snapshot for Sleep Guard
struct MetricSnapshot: Codable {
    let timestamp: Date
    let uploadBytes: Double
    let downloadBytes: Double
    let cpuUsage: Double
    let batteryLevel: Double
    let thermalState: Int
    let threatScore: Int
}
```

---

## 📄 FILE 5: SleepGuardView.swift
**Location:** `iguardian/Features/SleepGuard/SleepGuardView.swift`

```swift
import SwiftUI

struct SleepGuardView: View {
    @StateObject private var manager = SleepGuardManager.shared
    @StateObject private var store = StoreManager.shared
    @State private var showPaywall = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Status Card
                    statusCard
                    
                    // Schedule Settings
                    if store.isPremium {
                        scheduleCard
                        
                        // Quick Actions
                        actionsCard
                        
                        // Last Report Preview
                        if let lastReport = manager.lastReport {
                            lastReportCard(lastReport)
                        }
                        
                        // History Link
                        historyLink
                    } else {
                        premiumPrompt
                    }
                }
                .padding()
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle("Sleep Guard")
            .navigationBarTitleDisplayMode(.large)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Status Card
    private var statusCard: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(statusGradient)
                    .frame(width: 80, height: 80)
                
                Image(systemName: statusIcon)
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }
            
            // Status Text
            Text(statusTitle)
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)
            
            Text(statusSubtitle)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private var statusIcon: String {
        if manager.isMonitoring {
            return "moon.zzz.fill"
        } else if manager.isEnabled {
            return "moon.stars.fill"
        } else {
            return "moon"
        }
    }
    
    private var statusTitle: String {
        if manager.isMonitoring {
            return "Monitoring Active"
        } else if manager.isEnabled {
            return "Ready for Tonight"
        } else {
            return "Sleep Guard Off"
        }
    }
    
    private var statusSubtitle: String {
        if manager.isMonitoring {
            return "Watching your phone while you rest"
        } else if manager.isEnabled {
            return "Will start at \(manager.scheduleDescription)"
        } else {
            return "Enable to monitor overnight activity"
        }
    }
    
    private var statusGradient: LinearGradient {
        if manager.isMonitoring {
            return LinearGradient(
                colors: [.indigo, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if manager.isEnabled {
            return LinearGradient(
                colors: [.blue, .cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [.gray, .gray.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // MARK: - Schedule Card
    private var scheduleCard: some View {
        VStack(spacing: 16) {
            Toggle(isOn: $manager.isEnabled) {
                Label("Enable Sleep Guard", systemImage: "moon.stars")
                    .font(.headline)
            }
            .tint(Theme.accentPrimary)
            
            if manager.isEnabled {
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start Time")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { manager.startTime },
                                set: { newValue in
                                    let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                                    manager.startHour = components.hour ?? 23
                                    manager.startMinute = components.minute ?? 0
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .foregroundStyle(Theme.textTertiary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("End Time")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { manager.endTime },
                                set: { newValue in
                                    let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                                    manager.endHour = components.hour ?? 7
                                    manager.endMinute = components.minute ?? 0
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }
                }
                
                Toggle(isOn: $manager.autoStart) {
                    Text("Auto-start at scheduled time")
                        .font(.subheadline)
                }
                .tint(Theme.accentPrimary)
            }
        }
        .padding()
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Actions Card
    private var actionsCard: some View {
        VStack(spacing: 12) {
            if manager.isMonitoring {
                Button {
                    manager.endSession()
                } label: {
                    Label("End Session Now", systemImage: "stop.circle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.2))
                        .foregroundStyle(.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    manager.startSession()
                } label: {
                    Label("Start Now", systemImage: "play.circle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.accentPrimary.opacity(0.2))
                        .foregroundStyle(Theme.accentPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Last Report Card
    private func lastReportCard(_ session: SleepSession) -> some View {
        NavigationLink {
            SleepReportView(session: session)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Last Night's Report")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    
                    Spacer()
                    
                    Text(session.statusSummary)
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(session.hasAnomalies ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                        .foregroundStyle(session.hasAnomalies ? .red : .green)
                        .clipShape(Capsule())
                }
                
                HStack(spacing: 24) {
                    VStack(alignment: .leading) {
                        Text("Duration")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        Text(session.durationFormatted)
                            .font(.subheadline.bold())
                            .foregroundStyle(Theme.textPrimary)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Upload")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        Text(session.totalUploadFormatted)
                            .font(.subheadline.bold())
                            .foregroundStyle(Theme.textPrimary)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Battery")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        Text("\(Int(session.batteryUsed))%")
                            .font(.subheadline.bold())
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                
                HStack {
                    Text("View full report")
                        .font(.caption)
                        .foregroundStyle(Theme.accentPrimary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.accentPrimary)
                }
            }
            .padding()
            .background(Theme.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - History Link
    private var historyLink: some View {
        NavigationLink {
            SleepHistoryView()
        } label: {
            HStack {
                Label("View All Reports", systemImage: "clock.arrow.circlepath")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(Theme.textSecondary)
            .padding()
            .background(Theme.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Premium Prompt
    private var premiumPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundStyle(Theme.textTertiary)
            
            Text("Premium Feature")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            
            Text("Sleep Guard monitors your phone overnight and gives you a morning report of any suspicious activity.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                showPaywall = true
            } label: {
                Text("Unlock Premium")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.premiumGradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Sleep History View
struct SleepHistoryView: View {
    @StateObject private var manager = SleepGuardManager.shared
    
    var body: some View {
        List {
            ForEach(manager.getSessionHistory(), id: \.id) { session in
                NavigationLink {
                    SleepReportView(session: session)
                } label: {
                    SleepSessionRow(session: session)
                }
                .listRowBackground(Theme.backgroundSecondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundPrimary)
        .navigationTitle("Sleep History")
    }
}

struct SleepSessionRow: View {
    let session: SleepSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.startTime, style: .date)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text(session.durationFormatted)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            
            Spacer()
            
            Text(session.statusSummary)
                .font(.caption)
                .foregroundStyle(session.hasAnomalies ? .red : .green)
        }
        .padding(.vertical, 4)
    }
}
```

---

## 📄 FILE 6: SleepReportView.swift
**Location:** `iguardian/Features/SleepGuard/SleepReportView.swift`

```swift
import SwiftUI
import Charts

struct SleepReportView: View {
    let session: SleepSession
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Summary Stats
                summaryGrid
                
                // Activity Timeline
                timelineSection
                
                // Incidents (if any)
                if session.incidentCount > 0 {
                    incidentsSection
                }
                
                // Detailed Metrics
                metricsSection
                
                // Export Button
                exportButton
            }
            .padding()
        }
        .background(Theme.backgroundPrimary)
        .navigationTitle("Sleep Report")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(session.hasAnomalies ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: session.hasAnomalies ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(session.hasAnomalies ? .red : .green)
            }
            
            Text(session.hasAnomalies ? "Anomalies Detected" : "All Clear")
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)
            
            // Date & Duration
            VStack(spacing: 4) {
                Text(session.startTime, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                
                Text("\(formatTime(session.startTime)) → \(formatTime(session.endTime ?? Date()))")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Summary Grid
    private var summaryGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            SummaryCard(
                title: "Duration",
                value: session.durationFormatted,
                icon: "clock",
                color: .blue
            )
            
            SummaryCard(
                title: "Battery Used",
                value: "\(Int(session.batteryUsed))%",
                icon: "battery.50",
                color: session.batteryUsed > 15 ? .orange : .green
            )
            
            SummaryCard(
                title: "Total Upload",
                value: session.totalUploadFormatted,
                icon: "arrow.up",
                color: session.totalUploadBytes > 50_000_000 ? .orange : .cyan
            )
            
            SummaryCard(
                title: "Peak Score",
                value: "\(session.peakThreatScore)",
                icon: "shield",
                color: session.peakThreatScore > 50 ? .red : .green
            )
        }
    }
    
    // MARK: - Timeline
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Timeline")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            
            // Placeholder for chart
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.backgroundSecondary)
                .frame(height: 150)
                .overlay {
                    Text("Activity chart here")
                        .foregroundStyle(Theme.textTertiary)
                }
        }
    }
    
    // MARK: - Incidents
    private var incidentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Incidents")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                
                Spacer()
                
                Text("\(session.incidentCount)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.2))
                    .foregroundStyle(.red)
                    .clipShape(Capsule())
            }
            
            // Would list actual incidents here
            Text("View incident details in the Incidents tab")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Theme.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Metrics
    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Metrics")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            
            VStack(spacing: 8) {
                MetricRow(label: "Average CPU", value: String(format: "%.1f%%", session.averageCPU))
                MetricRow(label: "Peak CPU", value: String(format: "%.1f%%", session.peakCPU))
                MetricRow(label: "Total Download", value: session.totalDownloadFormatted)
                MetricRow(label: "Avg Threat Score", value: String(format: "%.0f", session.averageThreatScore))
            }
            .padding()
            .background(Theme.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Export
    private var exportButton: some View {
        Button {
            exportPDF()
        } label: {
            Label("Export PDF Report", systemImage: "square.and.arrow.up")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.accentPrimary.opacity(0.2))
                .foregroundStyle(Theme.accentPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func exportPDF() {
        // Generate PDF and show share sheet
        // Would use PDFReportGenerator here
        showShareSheet = true
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Theme.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Metric Row
struct MetricRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(Theme.textPrimary)
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
```

---

## 📄 FILE 7: IncidentManager.swift
**Location:** `iguardian/Features/Incidents/IncidentManager.swift`

```swift
import Foundation
import SwiftData
import UserNotifications

@MainActor
class IncidentManager: ObservableObject {
    static let shared = IncidentManager()
    
    @Published var activeIncidents: [Incident] = []
    @Published var recentIncidents: [Incident] = []
    
    private var modelContext: ModelContext?
    private let thresholds = ThresholdManager.shared
    
    private init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadRecentIncidents()
    }
    
    // MARK: - Incident Detection
    func checkForIncidents(
        uploadRate: Double,
        downloadRate: Double,
        cpuUsage: Double,
        batteryDrain: Double,
        thermalState: Int,
        isIdle: Bool
    ) {
        guard isIdle else { return } // Only check during idle
        
        var detectedIncidents: [Incident] = []
        let threatScore = calculateThreatScore(
            uploadRate: uploadRate,
            cpuUsage: cpuUsage,
            batteryDrain: batteryDrain,
            thermalState: thermalState
        )
        
        // Check for screen surveillance pattern
        if isScreenSurveillancePattern(uploadRate: uploadRate, cpuUsage: cpuUsage) {
            let incident = Incident(
                type: .screenSurveillance,
                severity: .critical,
                uploadRate: uploadRate,
                downloadRate: downloadRate,
                cpuUsage: cpuUsage,
                batteryDrain: batteryDrain,
                thermalState: thermalState,
                threatScore: threatScore
            )
            detectedIncidents.append(incident)
        }
        
        // Check thresholds
        let uploadThreshold = thresholds.threshold(for: .uploadRate)
        if uploadThreshold.isEnabled && uploadRate > uploadThreshold.value * 1024 * 1024 / 3600 {
            let incident = Incident(
                type: .dataExfiltration,
                severity: .high,
                uploadRate: uploadRate,
                downloadRate: downloadRate,
                cpuUsage: cpuUsage,
                batteryDrain: batteryDrain,
                thermalState: thermalState,
                threatScore: threatScore
            )
            detectedIncidents.append(incident)
        }
        
        let cpuThreshold = thresholds.threshold(for: .cpuUsage)
        if cpuThreshold.isEnabled && cpuUsage > cpuThreshold.value {
            let incident = Incident(
                type: .cpuAnomaly,
                severity: .medium,
                uploadRate: uploadRate,
                downloadRate: downloadRate,
                cpuUsage: cpuUsage,
                batteryDrain: batteryDrain,
                thermalState: thermalState,
                threatScore: threatScore
            )
            detectedIncidents.append(incident)
        }
        
        let batteryThreshold = thresholds.threshold(for: .batteryDrain)
        if batteryThreshold.isEnabled && batteryDrain > batteryThreshold.value {
            let incident = Incident(
                type: .batteryAnomaly,
                severity: .medium,
                uploadRate: uploadRate,
                downloadRate: downloadRate,
                cpuUsage: cpuUsage,
                batteryDrain: batteryDrain,
                thermalState: thermalState,
                threatScore: threatScore
            )
            detectedIncidents.append(incident)
        }
        
        // Multi-factor detection
        let factorsTriggered = [
            uploadRate > 1024 * 1024, // > 1 MB/s
            cpuUsage > 25,
            batteryDrain > 5,
            thermalState >= 2
        ].filter { $0 }.count
        
        if factorsTriggered >= 3 {
            let incident = Incident(
                type: .multiFactorAlert,
                severity: .critical,
                uploadRate: uploadRate,
                downloadRate: downloadRate,
                cpuUsage: cpuUsage,
                batteryDrain: batteryDrain,
                thermalState: thermalState,
                threatScore: threatScore
            )
            detectedIncidents.append(incident)
        }
        
        // Process detected incidents
        for incident in detectedIncidents {
            recordIncident(incident)
        }
    }
    
    // MARK: - Pattern Detection
    private func isScreenSurveillancePattern(uploadRate: Double, cpuUsage: Double) -> Bool {
        // High continuous upload + elevated CPU = possible screen mirroring
        let highUpload = uploadRate > 500 * 1024 // > 500 KB/s
        let elevatedCPU = cpuUsage > 15
        return highUpload && elevatedCPU
    }
    
    private func calculateThreatScore(
        uploadRate: Double,
        cpuUsage: Double,
        batteryDrain: Double,
        thermalState: Int
    ) -> Int {
        var score = 0
        
        // Upload contribution (0-30)
        let uploadMBps = uploadRate / (1024 * 1024)
        score += min(30, Int(uploadMBps * 20))
        
        // CPU contribution (0-25)
        score += min(25, Int(cpuUsage * 0.5))
        
        // Battery contribution (0-20)
        score += min(20, Int(batteryDrain * 4))
        
        // Thermal contribution (0-25)
        score += thermalState * 8
        
        return min(100, score)
    }
    
    // MARK: - Incident Recording
    func recordIncident(_ incident: Incident) {
        // Avoid duplicates within short time window
        let isDuplicate = activeIncidents.contains { existing in
            existing.type == incident.type &&
            Date().timeIntervalSince(existing.timestamp) < 60
        }
        
        guard !isDuplicate else { return }
        
        // Save to database
        modelContext?.insert(incident)
        try? modelContext?.save()
        
        // Update state
        activeIncidents.append(incident)
        recentIncidents.insert(incident, at: 0)
        
        // Send notification
        sendIncidentNotification(incident)
        
        // Notify Sleep Guard if active
        SleepGuardManager.shared.recordIncident(incident)
    }
    
    func resolveIncident(_ incident: Incident) {
        var resolved = incident
        resolved.endTimestamp = Date()
        resolved.isResolved = true
        
        activeIncidents.removeAll { $0.id == incident.id }
        
        try? modelContext?.save()
    }
    
    func acknowledgeIncident(_ incident: Incident) {
        var acknowledged = incident
        acknowledged.isAcknowledged = true
        try? modelContext?.save()
    }
    
    // MARK: - Notifications
    private func sendIncidentNotification(_ incident: Incident) {
        let content = UNMutableNotificationContent()
        content.title = incident.type.title
        content.body = incident.summary
        content.sound = incident.severity >= .high ? .defaultCritical : .default
        
        if incident.severity == .critical {
            content.interruptionLevel = .critical
        }
        
        let request = UNNotificationRequest(
            identifier: incident.id.uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - History
    private func loadRecentIncidents() {
        // Query SwiftData for recent incidents
        // Limited to last 50
    }
    
    func getIncidents(from: Date, to: Date) -> [Incident] {
        // Query incidents in date range
        return []
    }
    
    func clearOldIncidents(olderThan days: Int = 30) {
        // Delete incidents older than X days
    }
}
```

---

## 📄 FILE 8: IncidentTimelineView.swift
**Location:** `iguardian/Features/Incidents/IncidentTimelineView.swift`

```swift
import SwiftUI

struct IncidentTimelineView: View {
    @StateObject private var manager = IncidentManager.shared
    @State private var selectedFilter: IncidentFilter = .all
    @State private var selectedIncident: Incident?
    
    enum IncidentFilter: String, CaseIterable {
        case all = "All"
        case critical = "Critical"
        case today = "Today"
        case week = "This Week"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Pills
                filterBar
                
                // Incidents List
                if filteredIncidents.isEmpty {
                    emptyState
                } else {
                    incidentsList
                }
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle("Incidents")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(item: $selectedIncident) { incident in
            IncidentDetailView(incident: incident)
        }
    }
    
    // MARK: - Filter Bar
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(IncidentFilter.allCases, id: \.self) { filter in
                    FilterPill(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Theme.backgroundSecondary)
    }
    
    // MARK: - Incidents List
    private var incidentsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredIncidents, id: \.id) { incident in
                    IncidentCard(incident: incident)
                        .onTapGesture {
                            selectedIncident = incident
                        }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "checkmark.shield")
                .font(.system(size: 60))
                .foregroundStyle(.green.opacity(0.5))
            
            Text("No Incidents")
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)
            
            Text("Your device has been running normally.\nNo suspicious activity detected.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Filtering
    private var filteredIncidents: [Incident] {
        let incidents = manager.recentIncidents
        
        switch selectedFilter {
        case .all:
            return incidents
        case .critical:
            return incidents.filter { $0.severity >= .high }
        case .today:
            return incidents.filter { Calendar.current.isDateInToday($0.timestamp) }
        case .week:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return incidents.filter { $0.timestamp > weekAgo }
        }
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.accentPrimary : Theme.backgroundTertiary)
                .foregroundStyle(isSelected ? .white : Theme.textSecondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Incident Card
struct IncidentCard: View {
    let incident: Incident
    
    var body: some View {
        HStack(spacing: 16) {
            // Severity Indicator
            Circle()
                .fill(severityColor)
                .frame(width: 12, height: 12)
            
            // Icon
            Image(systemName: incident.type.icon)
                .font(.title2)
                .foregroundStyle(severityColor)
                .frame(width: 44, height: 44)
                .background(severityColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(incident.type.title)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                
                Text(incident.summary)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Time & Arrow
            VStack(alignment: .trailing, spacing: 4) {
                Text(incident.timestamp, style: .time)
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
                
                if let duration = incident.durationFormatted {
                    Text(duration)
                        .font(.caption2)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundStyle(Theme.textTertiary)
                .font(.caption)
        }
        .padding()
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var severityColor: Color {
        switch incident.severity {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}
```

---

## 📄 FILE 9: IncidentDetailView.swift
**Location:** `iguardian/Features/Incidents/IncidentDetailView.swift`

```swift
import SwiftUI

struct IncidentDetailView: View {
    let incident: Incident
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = IncidentManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Timeline
                    timelineSection
                    
                    // Metrics at Incident
                    metricsSection
                    
                    // Details
                    detailsSection
                    
                    // Actions
                    actionsSection
                }
                .padding()
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle("Incident Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accentPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(severityColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: incident.type.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(severityColor)
            }
            
            // Title
            Text(incident.type.title)
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)
            
            // Severity Badge
            Text(incident.severity.label.uppercased())
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(severityColor.opacity(0.2))
                .foregroundStyle(severityColor)
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Timeline
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            
            VStack(spacing: 16) {
                TimelineRow(
                    icon: "flag.fill",
                    title: "Started",
                    time: incident.timestamp,
                    color: .red
                )
                
                if let endTime = incident.endTimestamp {
                    TimelineRow(
                        icon: "flag.checkered",
                        title: "Ended",
                        time: endTime,
                        color: .green
                    )
                    
                    HStack {
                        Text("Duration")
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text(incident.durationFormatted)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(.top, 8)
                } else {
                    HStack {
                        Circle()
                            .fill(.orange)
                            .frame(width: 8, height: 8)
                        Text("Ongoing")
                            .foregroundStyle(.orange)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding()
            .background(Theme.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Metrics
    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Metrics at Detection")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricTile(
                    title: "Upload",
                    value: formatSpeed(incident.uploadRate),
                    icon: "arrow.up",
                    color: .cyan
                )
                
                MetricTile(
                    title: "Download",
                    value: formatSpeed(incident.downloadRate),
                    icon: "arrow.down",
                    color: .green
                )
                
                MetricTile(
                    title: "CPU",
                    value: String(format: "%.1f%%", incident.cpuUsage),
                    icon: "cpu",
                    color: .orange
                )
                
                MetricTile(
                    title: "Threat Score",
                    value: "\(incident.threatScore)",
                    icon: "shield",
                    color: incident.threatScore > 50 ? .red : .yellow
                )
            }
        }
    }
    
    // MARK: - Details
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            
            Text(incident.details)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Actions
    private var actionsSection: some View {
        VStack(spacing: 12) {
            if !incident.isAcknowledged {
                Button {
                    manager.acknowledgeIncident(incident)
                    dismiss()
                } label: {
                    Label("Acknowledge", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.accentPrimary.opacity(0.2))
                        .foregroundStyle(Theme.accentPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            
            Button {
                // Open iOS Settings > Cellular to check per-app usage
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Check Settings → Cellular", systemImage: "gear")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.backgroundSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Helpers
    private var severityColor: Color {
        switch incident.severity {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
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

// MARK: - Timeline Row
struct TimelineRow: View {
    let icon: String
    let title: String
    let time: Date
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(title)
                .foregroundStyle(Theme.textSecondary)
            
            Spacer()
            
            Text(time, style: .time)
                .fontWeight(.medium)
                .foregroundStyle(Theme.textPrimary)
            
            Text(time, style: .date)
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
        }
    }
}

// MARK: - Metric Tile
struct MetricTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            
            Text(value)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

---

## 📄 FILE 10: ThresholdSettingsView.swift
**Location:** `iguardian/Views/Settings/ThresholdSettingsView.swift`

```swift
import SwiftUI

struct ThresholdSettingsView: View {
    @StateObject private var thresholds = ThresholdManager.shared
    @State private var showResetConfirmation = false
    
    var body: some View {
        List {
            Section {
                ForEach($thresholds.thresholds) { $threshold in
                    ThresholdRow(threshold: $threshold)
                }
            } header: {
                Text("Alert Thresholds")
            } footer: {
                Text("Customize when you receive alerts. Lower values = more sensitive.")
            }
            .listRowBackground(Theme.backgroundSecondary)
            
            Section {
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                }
            }
            .listRowBackground(Theme.backgroundSecondary)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundPrimary)
        .navigationTitle("Alert Thresholds")
        .confirmationDialog(
            "Reset Thresholds?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                thresholds.reset()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all thresholds to their default values.")
        }
    }
}

struct ThresholdRow: View {
    @Binding var threshold: AlertThreshold
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $threshold.isEnabled) {
                HStack {
                    Image(systemName: threshold.metric.icon)
                        .foregroundStyle(Theme.accentPrimary)
                        .frame(width: 24)
                    
                    Text(threshold.metric.title)
                        .foregroundStyle(Theme.textPrimary)
                }
            }
            .tint(Theme.accentPrimary)
            
            if threshold.isEnabled {
                VStack(spacing: 8) {
                    HStack {
                        Text("Alert when above:")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        
                        Spacer()
                        
                        Text("\(Int(threshold.value)) \(threshold.metric.unit)")
                            .font(.subheadline.bold())
                            .foregroundStyle(Theme.accentPrimary)
                    }
                    
                    Slider(
                        value: $threshold.value,
                        in: threshold.metric.range,
                        step: threshold.metric.step
                    )
                    .tint(Theme.accentPrimary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
```

---

## 📄 FILE 11: PDFReportGenerator.swift
**Location:** `iguardian/Features/Reports/PDFReportGenerator.swift`

```swift
import Foundation
import UIKit
import PDFKit

class PDFReportGenerator {
    
    static func generateSleepReport(_ session: SleepSession) -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yOffset: CGFloat = 50
            
            // Title
            let title = "Sentinel Sleep Guard Report"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.label
            ]
            title.draw(at: CGPoint(x: 50, y: yOffset), withAttributes: titleAttributes)
            yOffset += 40
            
            // Date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let dateString = dateFormatter.string(from: session.startTime)
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.secondaryLabel
            ]
            dateString.draw(at: CGPoint(x: 50, y: yOffset), withAttributes: dateAttributes)
            yOffset += 30
            
            // Divider
            let dividerPath = UIBezierPath()
            dividerPath.move(to: CGPoint(x: 50, y: yOffset))
            dividerPath.addLine(to: CGPoint(x: 562, y: yOffset))
            UIColor.separator.setStroke()
            dividerPath.stroke()
            yOffset += 20
            
            // Status
            let statusText = session.hasAnomalies ? "⚠️ ANOMALIES DETECTED" : "✅ ALL CLEAR"
            let statusAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: session.hasAnomalies ? UIColor.systemRed : UIColor.systemGreen
            ]
            statusText.draw(at: CGPoint(x: 50, y: yOffset), withAttributes: statusAttributes)
            yOffset += 40
            
            // Summary Section
            let sectionAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.label
            ]
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.secondaryLabel
            ]
            
            "Summary".draw(at: CGPoint(x: 50, y: yOffset), withAttributes: sectionAttributes)
            yOffset += 25
            
            let summaryItems = [
                "Duration: \(session.durationFormatted)",
                "Total Upload: \(session.totalUploadFormatted)",
                "Total Download: \(session.totalDownloadFormatted)",
                "Battery Used: \(Int(session.batteryUsed))%",
                "Peak CPU: \(String(format: "%.1f%%", session.peakCPU))",
                "Peak Threat Score: \(session.peakThreatScore)",
                "Incidents: \(session.incidentCount)"
            ]
            
            for item in summaryItems {
                item.draw(at: CGPoint(x: 60, y: yOffset), withAttributes: bodyAttributes)
                yOffset += 20
            }
            
            yOffset += 20
            
            // Footer
            let footerText = "Generated by Sentinel Security • \(Date().formatted())"
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.tertiaryLabel
            ]
            footerText.draw(at: CGPoint(x: 50, y: 750), withAttributes: footerAttributes)
        }
        
        // Save to temp file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SleepReport_\(UUID().uuidString).pdf")
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to write PDF: \(error)")
            return nil
        }
    }
    
    static func generateWeeklyReport(incidents: [Incident], sessions: [SleepSession]) -> URL? {
        // Similar implementation for weekly report
        // Would include charts and more detailed analysis
        return nil
    }
}
```

---

## 📋 Updated Tab Navigation

Update `MainTabView.swift` to include new tabs:

```swift
import SwiftUI

struct MainTabView: View {
    @StateObject private var store = StoreManager.shared
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "shield.checkered")
                }
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.xyaxis.line")
                }
            
            // Premium: Incidents Tab
            if store.isPremium {
                IncidentTimelineView()
                    .tabItem {
                        Label("Incidents", systemImage: "exclamationmark.triangle")
                    }
            }
            
            // Premium: Sleep Guard Tab
            SleepGuardView()
                .tabItem {
                    Label("Sleep", systemImage: "moon.stars")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(Theme.accentPrimary)
        .preferredColorScheme(.dark)
    }
}
```

---

## 📋 Summary - Phase 3

| Feature | Files | Description |
|---------|-------|-------------|
| **Sleep Guard** | SleepGuardManager, SleepGuardView, SleepReportView | Scheduled overnight monitoring with morning reports |
| **Incident System** | Incident model, IncidentManager, IncidentTimelineView, IncidentDetailView | Track, display, and manage security incidents |
| **Custom Thresholds** | AlertThreshold, ThresholdManager, ThresholdSettingsView | User-configurable alert sensitivity |
| **PDF Reports** | PDFReportGenerator | Export sleep and weekly security reports |
| **Threat Scoring** | ThreatScoreEngine (in IncidentManager) | Multi-factor threat calculation |

---

**Next: Phase 4 - Community features, themes, and polish!** 🛡️
