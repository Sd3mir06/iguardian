//
//  MonitoringManager.swift
//  iguardian
//
//  Central coordinator - IMPROVED with better network total tracking
//

import Foundation
import Combine
import SwiftUI

@MainActor
class MonitoringManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var threatScore: Int = 0
    @Published var threatLevel: ThreatLevel = .normal
    @Published var currentSnapshot: MetricSnapshot = MetricSnapshot()
    @Published var recentActivity: [ActivityEntry] = []
    @Published var isMonitoring: Bool = false
    
    // MARK: - Monitors (public for direct access to totals)
    let networkMonitor = NetworkMonitor()
    let cpuMonitor = CPUMonitor()
    let batteryMonitor = BatteryMonitor()
    let thermalMonitor = ThermalMonitor()
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    private let threatCalculationInterval: TimeInterval = 2.0
    
    // Alert cooldowns to prevent spam
    private var lastAlertTime: [String: Date] = [:]
    private let alertCooldown: TimeInterval = 60 // 1 minute between same alerts
    
    // MARK: - Singleton
    static let shared = MonitoringManager()
    
    // MARK: - Initialization
    init() {
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        networkMonitor.startMonitoring()
        cpuMonitor.startMonitoring()
        batteryMonitor.startMonitoring()
        thermalMonitor.startMonitoring()
        
        LogManager.shared.log("Monitoring started", level: .info, category: "Monitoring")
        
        addActivityEntry(
            type: .monitoringStarted,
            title: "Monitoring Started",
            description: "iGuardian is now actively monitoring your device",
            threatLevel: .normal
        )
        
        // Start threat calculation timer
        updateTimer = Timer.scheduledTimer(withTimeInterval: threatCalculationInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
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
    
    // MARK: - Private Methods
    private func setupSubscriptions() {
        // Combine all monitor updates
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
            .sink { [weak self] _ in
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
        
        LogManager.shared.log(
            "Snapshot: Up=\(String(format: "%.1f", networkMonitor.uploadBytesPerSecond/1024))KB/s, " +
            "TotalUp=\(String(format: "%.1f", networkMonitor.lastHourUploadMB))MB/h, " +
            "CPU=\(Int(cpuMonitor.cpuUsagePercent))%",
            level: .debug,
            category: "Metrics"
        )
    }
    
    /// Multi-factor threat detection algorithm - IMPROVED
    private func calculateThreatLevel() {
        var score = 0
        var factors: [String] = []
        
        let tm = ThresholdManager.shared
        
        // ===== NETWORK TOTALS (Primary concern for data usage) =====
        
        // 1. Total Upload in last hour (THIS IS THE KEY METRIC YOU WANTED)
        let totalUpMB = networkMonitor.lastHourUploadMB
        let totalUpThreshold = tm.threshold(for: .totalUpload)
        if totalUpThreshold.isEnabled && totalUpMB > totalUpThreshold.value {
            score += 35  // High score for exceeding total
            factors.append("⚠️ Upload exceeded \(Int(totalUpThreshold.value))MB limit (\(Int(totalUpMB))MB)")
            triggerAlert(key: "totalUpload", message: "Upload data exceeded \(Int(totalUpThreshold.value))MB in the last hour")
        } else if totalUpThreshold.isEnabled && totalUpMB > totalUpThreshold.value * 0.7 {
            score += 15
            factors.append("Upload approaching limit (\(Int(totalUpMB))/\(Int(totalUpThreshold.value))MB)")
        }
        
        // 2. Total Download in last hour
        let totalDownMB = networkMonitor.lastHourDownloadMB
        let totalDownThreshold = tm.threshold(for: .totalDownload)
        if totalDownThreshold.isEnabled && totalDownMB > totalDownThreshold.value {
            score += 25
            factors.append("⚠️ Download exceeded \(Int(totalDownThreshold.value))MB limit (\(Int(totalDownMB))MB)")
            triggerAlert(key: "totalDownload", message: "Download data exceeded \(Int(totalDownThreshold.value))MB in the last hour")
        } else if totalDownThreshold.isEnabled && totalDownMB > totalDownThreshold.value * 0.7 {
            score += 10
            factors.append("Download approaching limit (\(Int(totalDownMB))/\(Int(totalDownThreshold.value))MB)")
        }
        
        // ===== INSTANT RATES (Secondary - for detecting spikes) =====
        
        // 3. Instant Upload Rate (useful for detecting sudden bursts)
        let uploadRateMBH = (networkMonitor.uploadBytesPerSecond * 3600) / (1024 * 1024)
        let uploadRateThreshold = tm.threshold(for: .uploadRate)
        if uploadRateThreshold.isEnabled && uploadRateMBH > uploadRateThreshold.value {
            score += 15
            factors.append("High upload rate (\(Int(uploadRateMBH))MB/h equivalent)")
        }
        
        // 4. Instant Download Rate
        let downloadRateMBH = (networkMonitor.downloadBytesPerSecond * 3600) / (1024 * 1024)
        let downloadRateThreshold = tm.threshold(for: .downloadRate)
        if downloadRateThreshold.isEnabled && downloadRateMBH > downloadRateThreshold.value {
            score += 10
            factors.append("High download rate (\(Int(downloadRateMBH))MB/h equivalent)")
        }
        
        // ===== OTHER METRICS =====
        
        // 5. CPU usage
        let cpuUsage = cpuMonitor.cpuUsagePercent
        let cpuThreshold = tm.threshold(for: .cpuUsage)
        if cpuThreshold.isEnabled && cpuUsage > cpuThreshold.value {
            score += 20
            factors.append("High CPU (\(Int(cpuUsage))%)")
        }
        
        // 6. Battery drain
        let drainRate = batteryMonitor.drainRatePerHour
        let batteryThreshold = tm.threshold(for: .batteryDrain)
        if batteryThreshold.isEnabled && Double(drainRate) > batteryThreshold.value {
            score += 15
            factors.append("Fast battery drain (\(Int(drainRate))%/h)")
        }
        
        // 7. Thermal state
        let thermal = thermalMonitor.thermalState
        switch thermal {
        case .critical:
            score += 20
            factors.append("Critical thermal state")
        case .serious:
            score += 12
            factors.append("Serious thermal state")
        case .fair:
            score += 5
        case .nominal:
            break
        }
        
        // ===== MULTI-FACTOR DETECTION =====
        // Suspicious pattern: High upload + High CPU + High battery drain = possible screen mirroring
        let suspiciousPattern = totalUpMB > 50 && cpuUsage > 25 && drainRate > 5
        if suspiciousPattern {
            score += 15
            factors.append("⚠️ Multi-factor anomaly detected")
        }
        
        // Cap at 100
        score = min(100, score)
        
        // Determine threat level
        let newThreatLevel: ThreatLevel
        switch score {
        case 0..<15:
            newThreatLevel = .normal
        case 15..<40:
            newThreatLevel = .warning
        case 40..<70:
            newThreatLevel = .alert
        default:
            newThreatLevel = .critical
        }
        
        // Check if threat level changed
        let levelChanged = newThreatLevel != threatLevel
        
        // Update published properties
        threatScore = score
        threatLevel = newThreatLevel
        updateCurrentSnapshot()
        
        // Log activity on threat level changes
        if levelChanged {
            LogManager.shared.log(
                "Threat level: \(threatLevel.rawValue) (Score: \(score)). Factors: \(factors.joined(separator: ", "))",
                level: newThreatLevel == .normal ? .info : .warning,
                category: "Security"
            )
            
            if newThreatLevel != .normal {
                let factorDesc = factors.isEmpty ? "Various indicators" : factors.joined(separator: ", ")
                addActivityEntry(
                    type: newThreatLevel == .warning ? .warning : .alert,
                    title: newThreatLevel.message,
                    description: factorDesc,
                    threatLevel: newThreatLevel
                )
            }
        }
    }
    
    private func triggerAlert(key: String, message: String) {
        let now = Date()
        
        // Check cooldown
        if let lastTime = lastAlertTime[key], now.timeIntervalSince(lastTime) < alertCooldown {
            return // Still in cooldown
        }
        
        lastAlertTime[key] = now
        
        // Log the alert
        LogManager.shared.log("ALERT: \(message)", level: .warning, category: "Alert")
        
        // TODO: Send notification if enabled
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
