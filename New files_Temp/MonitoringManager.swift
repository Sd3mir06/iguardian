//
//  MonitoringManager.swift
//  iguardian
//
//  IMPROVED: Smart idle detection, no false alarms, proper notifications
//  Only alerts when phone is IDLE and suspicious activity detected
//

import Foundation
import Combine
import SwiftUI
import UserNotifications

@MainActor
class MonitoringManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var threatScore: Int = 0
    @Published var threatLevel: ThreatLevel = .normal
    @Published var currentSnapshot: MetricSnapshot = MetricSnapshot()
    @Published var recentActivity: [ActivityEntry] = []
    @Published var isMonitoring: Bool = false
    
    // NEW: Idle state detection
    @Published var isDeviceIdle: Bool = false
    @Published var idleDuration: TimeInterval = 0
    @Published var lastUserInteraction: Date = Date()
    
    // MARK: - Monitors
    let networkMonitor = NetworkMonitor()
    let cpuMonitor = CPUMonitor()
    let batteryMonitor = BatteryMonitor()
    let thermalMonitor = ThermalMonitor()
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    private var idleCheckTimer: Timer?
    private let threatCalculationInterval: TimeInterval = 3.0  // Slower = less spam
    
    // Alert cooldowns - increased to prevent spam
    private var lastAlertTime: [String: Date] = [:]
    private let alertCooldown: TimeInterval = 300 // 5 minutes between same alerts
    private var lastThreatLevelChangeTime: Date = Date()
    private let levelChangeCooldown: TimeInterval = 60 // 1 minute between level changes
    
    // Idle detection thresholds
    private let idleThresholdSeconds: TimeInterval = 60 // Consider idle after 1 minute
    private let idleCPUThreshold: Double = 15 // CPU below this = likely idle
    private let idleNetworkThreshold: Double = 50_000 // 50 KB/s = background noise
    
    // Baseline learning (learns normal idle patterns)
    private var baselineUploadRate: Double = 0
    private var baselineDownloadRate: Double = 0
    private var baselineCPU: Double = 0
    private var baselineSamples: Int = 0
    private let baselineMinSamples = 30 // Need 30 samples to establish baseline
    
    // MARK: - Singleton
    static let shared = MonitoringManager()
    
    // MARK: - Initialization
    init() {
        setupSubscriptions()
        requestNotificationPermission()
    }
    
    // MARK: - Notification Permission
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                LogManager.shared.log("Notification permission granted", level: .info, category: "Notifications")
            } else if let error = error {
                LogManager.shared.log("Notification permission error: \(error)", level: .error, category: "Notifications")
            }
        }
    }
    
    // MARK: - Public Methods
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        lastUserInteraction = Date()
        
        networkMonitor.startMonitoring()
        cpuMonitor.startMonitoring()
        batteryMonitor.startMonitoring()
        thermalMonitor.startMonitoring()
        
        LogManager.shared.log("Monitoring started", level: .info, category: "Monitoring")
        
        addActivityEntry(
            type: .monitoringStarted,
            title: "Monitoring Started",
            description: "iGuardian is now protecting your device",
            threatLevel: .normal
        )
        
        // Threat calculation timer
        updateTimer = Timer.scheduledTimer(withTimeInterval: threatCalculationInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.updateIdleState()
                self.calculateThreatLevel()
                self.updateLiveActivity()
            }
        }
        
        // Initial calculation
        calculateThreatLevel()
    }
    
    func stopMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
        idleCheckTimer?.invalidate()
        idleCheckTimer = nil
        
        networkMonitor.stopMonitoring()
        cpuMonitor.stopMonitoring()
        batteryMonitor.stopMonitoring()
        thermalMonitor.stopMonitoring()
        
        isMonitoring = false
        
        addActivityEntry(
            type: .monitoringStopped,
            title: "Monitoring Stopped",
            description: "iGuardian monitoring has been paused",
            threatLevel: .normal
        )
        
        LogManager.shared.log("Monitoring stopped", level: .info, category: "Monitoring")
    }
    
    /// Call this when user interacts with the app
    func registerUserInteraction() {
        lastUserInteraction = Date()
        isDeviceIdle = false
    }
    
    // MARK: - Private Methods
    private func setupSubscriptions() {
        networkMonitor.$uploadBytesPerSecond
            .combineLatest(networkMonitor.$downloadBytesPerSecond)
            .sink { [weak self] _, _ in
                Task { @MainActor in
                    self?.updateCurrentSnapshot()
                }
            }
            .store(in: &cancellables)
        
        cpuMonitor.$cpuUsagePercent
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateCurrentSnapshot()
                }
            }
            .store(in: &cancellables)
        
        batteryMonitor.$batteryLevel
            .combineLatest(batteryMonitor.$drainRatePerHour)
            .sink { [weak self] _, _ in
                Task { @MainActor in
                    self?.updateCurrentSnapshot()
                }
            }
            .store(in: &cancellables)
        
        thermalMonitor.$thermalState
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateCurrentSnapshot()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateCurrentSnapshot() {
        currentSnapshot = MetricSnapshot(
            timestamp: Date(),
            uploadBytesPerSecond: networkMonitor.uploadBytesPerSecond,
            downloadBytesPerSecond: networkMonitor.downloadBytesPerSecond,
            cpuUsagePercent: cpuMonitor.cpuUsagePercent,
            batteryLevel: batteryMonitor.batteryLevel,
            batteryDrainPerHour: batteryMonitor.drainRatePerHour,
            thermalState: thermalMonitor.thermalState,
            threatLevel: threatLevel,
            threatScore: threatScore
        )
    }
    
    // MARK: - Idle State Detection
    private func updateIdleState() {
        let now = Date()
        idleDuration = now.timeIntervalSince(lastUserInteraction)
        
        // Check if device appears idle
        let cpuIdle = cpuMonitor.cpuUsagePercent < idleCPUThreshold
        let networkIdle = networkMonitor.uploadBytesPerSecond < idleNetworkThreshold &&
                         networkMonitor.downloadBytesPerSecond < idleNetworkThreshold
        let timeIdle = idleDuration > idleThresholdSeconds
        
        let wasIdle = isDeviceIdle
        isDeviceIdle = timeIdle && (cpuIdle || networkIdle)
        
        // Update baseline when truly idle
        if isDeviceIdle && cpuIdle && networkIdle {
            updateBaseline()
        }
        
        if isDeviceIdle && !wasIdle {
            LogManager.shared.log("Device entered idle state", level: .debug, category: "Idle")
        }
    }
    
    private func updateBaseline() {
        // Exponential moving average for baseline
        let alpha = 0.1
        
        if baselineSamples < baselineMinSamples {
            // Initial collection
            baselineUploadRate = (baselineUploadRate * Double(baselineSamples) + networkMonitor.uploadBytesPerSecond) / Double(baselineSamples + 1)
            baselineDownloadRate = (baselineDownloadRate * Double(baselineSamples) + networkMonitor.downloadBytesPerSecond) / Double(baselineSamples + 1)
            baselineCPU = (baselineCPU * Double(baselineSamples) + cpuMonitor.cpuUsagePercent) / Double(baselineSamples + 1)
            baselineSamples += 1
        } else {
            // EMA update
            baselineUploadRate = alpha * networkMonitor.uploadBytesPerSecond + (1 - alpha) * baselineUploadRate
            baselineDownloadRate = alpha * networkMonitor.downloadBytesPerSecond + (1 - alpha) * baselineDownloadRate
            baselineCPU = alpha * cpuMonitor.cpuUsagePercent + (1 - alpha) * baselineCPU
        }
    }
    
    // MARK: - Smart Threat Detection (NO FALSE ALARMS)
    private func calculateThreatLevel() {
        var score = 0
        var factors: [String] = []
        var isSuspicious = false
        
        let tm = ThresholdManager.shared
        
        // ============================================
        // ONLY CHECK FOR THREATS WHEN DEVICE IS IDLE
        // ============================================
        
        // If device is NOT idle, keep score at 0 (user is actively using phone)
        guard isDeviceIdle else {
            // Device in use - no alerts needed
            if threatLevel != .normal {
                // Return to normal when user starts using phone
                threatScore = 0
                threatLevel = .normal
                updateCurrentSnapshot()
            }
            return
        }
        
        // ============================================
        // IDLE MODE CHECKS - Only alert for REAL issues
        // ============================================
        
        // 1. TOTAL DATA UPLOAD in last hour (PRIMARY METRIC for data theft)
        let totalUpMB = networkMonitor.lastHourUploadMB
        let totalUpThreshold = tm.threshold(for: .totalUpload)
        
        if totalUpThreshold.isEnabled && totalUpMB > totalUpThreshold.value {
            // This is SERIOUS - large amount of data uploaded while phone idle
            score += 50
            factors.append("🚨 \(Int(totalUpMB))MB uploaded while idle (limit: \(Int(totalUpThreshold.value))MB)")
            isSuspicious = true
        } else if totalUpThreshold.isEnabled && totalUpMB > totalUpThreshold.value * 0.8 {
            score += 20
            factors.append("⚠️ Upload approaching limit: \(Int(totalUpMB))/\(Int(totalUpThreshold.value))MB")
        }
        
        // 2. TOTAL DATA DOWNLOAD in last hour
        let totalDownMB = networkMonitor.lastHourDownloadMB
        let totalDownThreshold = tm.threshold(for: .totalDownload)
        
        if totalDownThreshold.isEnabled && totalDownMB > totalDownThreshold.value {
            score += 30
            factors.append("📥 \(Int(totalDownMB))MB downloaded while idle")
            isSuspicious = true
        }
        
        // 3. SUSTAINED HIGH UPLOAD RATE (possible screen mirroring/streaming)
        // Only flag if rate is significantly above baseline AND sustained
        let uploadRateMBH = (networkMonitor.uploadBytesPerSecond * 3600) / (1024 * 1024)
        let uploadRateThreshold = tm.threshold(for: .uploadRate)
        let baselineMultiplier = 5.0 // Must be 5x baseline to be suspicious
        
        let isAboveBaseline = baselineSamples >= baselineMinSamples &&
            networkMonitor.uploadBytesPerSecond > (baselineUploadRate * baselineMultiplier)
        
        if uploadRateThreshold.isEnabled && uploadRateMBH > uploadRateThreshold.value && isAboveBaseline {
            score += 25
            factors.append("📤 Sustained upload: \(Int(uploadRateMBH))MB/h (5x normal)")
            isSuspicious = true
        }
        
        // 4. HIGH CPU WHILE IDLE (very suspicious)
        let cpuUsage = cpuMonitor.cpuUsagePercent
        let cpuThreshold = tm.threshold(for: .cpuUsage)
        
        if cpuThreshold.isEnabled && cpuUsage > cpuThreshold.value {
            score += 25
            factors.append("🔥 High CPU while idle: \(Int(cpuUsage))%")
            isSuspicious = true
        }
        
        // 5. ABNORMAL BATTERY DRAIN while idle
        let drainRate = batteryMonitor.drainRatePerHour
        let batteryThreshold = tm.threshold(for: .batteryDrain)
        
        if batteryThreshold.isEnabled && Double(drainRate) > batteryThreshold.value {
            score += 20
            factors.append("🔋 Fast drain while idle: \(Int(drainRate))%/hr")
        }
        
        // 6. THERMAL WARNING while idle
        let thermal = thermalMonitor.thermalState
        if thermal == .serious || thermal == .critical {
            score += 20
            factors.append("🌡️ Device heating up while idle")
            isSuspicious = true
        }
        
        // ============================================
        // MULTI-FACTOR DETECTION (Screen Mirroring Pattern)
        // ============================================
        // Classic screen mirroring: High upload + High CPU + Battery drain
        let possibleScreenMirror = totalUpMB > 30 && cpuUsage > 20 && drainRate > 3
        if possibleScreenMirror {
            score += 20
            factors.append("⚠️ Pattern matches possible screen surveillance")
            isSuspicious = true
        }
        
        // Cap at 100
        score = min(100, score)
        
        // ============================================
        // DETERMINE THREAT LEVEL (with hysteresis)
        // ============================================
        let newThreatLevel: ThreatLevel
        switch score {
        case 0..<20:
            newThreatLevel = .normal
        case 20..<45:
            newThreatLevel = .warning
        case 45..<70:
            newThreatLevel = .alert
        default:
            newThreatLevel = .critical
        }
        
        // Prevent rapid level changes (hysteresis)
        let now = Date()
        let canChangeLevel = now.timeIntervalSince(lastThreatLevelChangeTime) > levelChangeCooldown
        let levelChanged = newThreatLevel != threatLevel && canChangeLevel
        
        // Update state
        threatScore = score
        
        if levelChanged {
            threatLevel = newThreatLevel
            lastThreatLevelChangeTime = now
            
            // Log and create activity entry
            LogManager.shared.log(
                "Threat level: \(threatLevel.rawValue) (Score: \(score))",
                level: newThreatLevel == .normal ? .info : .warning,
                category: "Security"
            )
            
            // Only add activity entries for significant events
            if isSuspicious && newThreatLevel != .normal {
                let factorDesc = factors.joined(separator: "\n")
                addActivityEntry(
                    type: newThreatLevel == .warning ? .warning : .alert,
                    title: "⚠️ Suspicious Activity While Idle",
                    description: factorDesc,
                    threatLevel: newThreatLevel
                )
                
                // Send notification for real threats
                if newThreatLevel == .alert || newThreatLevel == .critical {
                    sendNotification(title: "Security Alert", body: factors.first ?? "Suspicious activity detected")
                }
            }
        }
        
        updateCurrentSnapshot()
    }
    
    // MARK: - Notifications
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = "🛡️ iGuardian"
        content.subtitle = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                LogManager.shared.log("Notification error: \(error)", level: .error, category: "Notifications")
            } else {
                LogManager.shared.log("Notification sent: \(title)", level: .info, category: "Notifications")
            }
        }
    }
    
    private func addActivityEntry(type: ActivityType, title: String, description: String, threatLevel: ThreatLevel) {
        let entry = ActivityEntry(
            type: type,
            title: title,
            description: description,
            threatLevel: threatLevel
        )
        
        recentActivity.insert(entry, at: 0)
        
        if recentActivity.count > 50 {
            recentActivity = Array(recentActivity.prefix(50))
        }
    }
    
    // MARK: - Live Activity Integration
    private func updateLiveActivity() {
        let liveActivityManager = LiveActivityManager.shared
        guard liveActivityManager.isActivityActive else { return }
        
        let threatLevelInt: Int
        switch threatLevel {
        case .normal: threatLevelInt = 0
        case .warning: threatLevelInt = 1
        case .alert, .critical: threatLevelInt = 2
        }
        
        liveActivityManager.updateActivity(
            uploadSpeed: networkMonitor.uploadBytesPerSecond,
            downloadSpeed: networkMonitor.downloadBytesPerSecond,
            cpuUsage: cpuMonitor.cpuUsagePercent,
            threatLevel: threatLevelInt,
            threatScore: threatScore
        )
    }
}
