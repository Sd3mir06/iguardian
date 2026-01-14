//
//  MonitoringManager.swift
//  iguardian
//
//  Created by Sukru Demir on 13.01.2026.
//

import Foundation
import Combine
import SwiftUI

/// Central coordinator for all monitoring services
/// Aggregates data and calculates threat scores
@MainActor
class MonitoringManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var threatScore: Int = 0
    @Published var threatLevel: ThreatLevel = .normal
    @Published var currentSnapshot: MetricSnapshot = MetricSnapshot()
    @Published var recentActivity: [ActivityEntry] = []
    @Published var isMonitoring: Bool = false
    
    // MARK: - Monitors
    let networkMonitor = NetworkMonitor()
    let cpuMonitor = CPUMonitor()
    let batteryMonitor = BatteryMonitor()
    let thermalMonitor = ThermalMonitor()
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    private let threatCalculationInterval: TimeInterval = 2.0
    
    // Hourly Tracking
    private var hourlySnapshots: [(Date, UInt64, UInt64)] = [] // (Time, TotalUp, TotalDown)
    private let hourlyWindow: TimeInterval = 3600 // 1 hour
    
    // MARK: - Thresholds (configurable later)
    struct Thresholds {
        static let highUploadBytesPerSecond: Double = 500_000 // 500 KB/s
        static let veryHighUploadBytesPerSecond: Double = 2_000_000 // 2 MB/s
        static let highCPUPercent: Double = 30
        static let veryHighCPUPercent: Double = 60
        static let highBatteryDrainPerHour: Float = 5 // 5% per hour
        static let veryHighBatteryDrainPerHour: Float = 10 // 10% per hour
    }
    
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
        
        // Add monitoring started entry
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
        
        updateHourlyTracking()
        
        LogManager.shared.log("Snapshot updated - Up: \(String(format: "%.1f", currentSnapshot.uploadBytesPerSecond/1024)) KB/s, CPU: \(Int(currentSnapshot.cpuUsagePercent))%", level: .debug, category: "Metrics")
    }
    
    private func updateHourlyTracking() {
        let now = Date()
        hourlySnapshots.append((now, networkMonitor.totalUploadBytes, networkMonitor.totalDownloadBytes))
        
        // Remove snapshots older than 1 hour
        hourlySnapshots.removeAll { now.timeIntervalSince($0.0) > hourlyWindow }
    }
    
    private var lastHourUploadMB: Double {
        guard let first = hourlySnapshots.first, let last = hourlySnapshots.last else { return 0 }
        let bytes = last.1 > first.1 ? last.1 - first.1 : 0
        return Double(bytes) / (1024 * 1024)
    }
    
    private var lastHourDownloadMB: Double {
        guard let first = hourlySnapshots.first, let last = hourlySnapshots.last else { return 0 }
        let bytes = last.2 > first.2 ? last.2 - first.2 : 0
        return Double(bytes) / (1024 * 1024)
    }

    
    /// Multi-factor threat detection algorithm
    private func calculateThreatLevel() {
        var score = 0
        var factors: [String] = []
        
        // Network Thresholds (Dynamic from ThresholdManager)
        let tm = ThresholdManager.shared
        
        // 1. Instant Upload Rate (MB/h equivalent)
        // Rate in MB/h = (Bytes/s * 3600) / 1024^2
        let currentUploadRateMBH = (networkMonitor.uploadBytesPerSecond * 3600) / (1024 * 1024)
        let uploadThreshold = tm.threshold(for: .uploadRate)
        if uploadThreshold.isEnabled && currentUploadRateMBH > uploadThreshold.value {
            score += 30
            factors.append("High Upload Rate (\(Int(currentUploadRateMBH)) MB/h)")
        }
        
        // 2. Instant Download Rate
        let currentDownRateMBH = (networkMonitor.downloadBytesPerSecond * 3600) / (1024 * 1024)
        let downThreshold = tm.threshold(for: .downloadRate)
        if downThreshold.isEnabled && currentDownRateMBH > downThreshold.value {
            score += 20
            factors.append("High Download Rate (\(Int(currentDownRateMBH)) MB/h)")
        }
        
        // 3. Total Upload (Last 1h)
        let totalUpMB = lastHourUploadMB
        let totalUpThreshold = tm.threshold(for: .totalUpload)
        if totalUpThreshold.isEnabled && totalUpMB > totalUpThreshold.value {
            score += 40
            factors.append("Total Upload Exceeded (\(Int(totalUpMB)) MB/h)")
        }
        
        // 4. Total Download (Last 1h)
        let totalDownMB = lastHourDownloadMB
        let totalDownThreshold = tm.threshold(for: .totalDownload)
        if totalDownThreshold.isEnabled && totalDownMB > totalDownThreshold.value {
            score += 25
            factors.append("Total Download Exceeded (\(Int(totalDownMB)) MB/h)")
        }
        
        // Factor 2: CPU usage
        let cpuUsage = cpuMonitor.cpuUsagePercent
        let cpuThreshold = tm.threshold(for: .cpuUsage)
        if cpuThreshold.isEnabled && cpuUsage > cpuThreshold.value {
            score += 30
            factors.append("High CPU (\(Int(cpuUsage))%)")
        }
        
        // Factor 3: Battery drain
        let drainRate = batteryMonitor.drainRatePerHour
        let batteryThreshold = tm.threshold(for: .batteryDrain)
        if batteryThreshold.isEnabled && Double(drainRate) > batteryThreshold.value {
            score += 20
            factors.append("Fast Battery Drain (\(Int(drainRate))%/h)")
        }
        
        // Factor 4: Thermal state
        let thermal = thermalMonitor.thermalState
        switch thermal {
        case .critical:
            score += 20
            factors.append("Critical Thermal")
        case .serious:
            score += 15
            factors.append("Serious Thermal")
        case .fair:
            score += 5
            factors.append("Elevated Thermal")
        case .nominal:
            break
        }
        
        // Bonus for multi-factor anomaly
        if factors.count >= 3 {
            score += 20
            factors.append("Multi-factor anomaly")
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
            LogManager.shared.log("Threat level changed: \(threatLevel.rawValue) (Score: \(score))", level: newThreatLevel == .normal ? .info : .warning, category: "Security")
            
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
    
    private func addActivityEntry(type: ActivityType, title: String, description: String, threatLevel: ThreatLevel) {
        let entry = ActivityEntry(
            type: type,
            title: title,
            description: description,
            threatLevel: threatLevel
        )
        
        // Add to beginning of array
        recentActivity.insert(entry, at: 0)
        
        // Keep only last 50 entries
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
