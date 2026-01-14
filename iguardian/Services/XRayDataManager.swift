//
//  XRayDataManager.swift
//  iguardian
//
//  High-frequency data collector for Guardian X-Ray feature
//  Updates at 1Hz for real-time system insights
//

import Foundation
import Combine
import UIKit

// MARK: - Semantic Event
struct XRayEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let icon: String
    let color: String // "cyan", "green", "orange", "red", "purple"
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}

// MARK: - Traffic Pattern
enum TrafficPattern: String {
    case burst = "Burst"      // Ads, telemetry
    case stream = "Stream"    // Video, audio
    case background = "Background" // Keep-alive
    case idle = "Idle"
    
    var icon: String {
        switch self {
        case .burst: return "bolt.fill"
        case .stream: return "waveform"
        case .background: return "dot.radiowaves.left.and.right"
        case .idle: return "sleep"
        }
    }
    
    var color: String {
        switch self {
        case .burst: return "red"
        case .stream: return "blue"
        case .background: return "gray"
        case .idle: return "gray"
        }
    }
}

// MARK: - Pulse Data Point
struct PulsePoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double // 0.0 to 1.0 normalized stress level
    let cpu: Double
    let network: Double
    let thermal: Double
}

// MARK: - Threat Factor
struct ThreatFactor: Identifiable {
    let id = UUID()
    let name: String
    let score: Int
    let reason: String
    let icon: String
}

// MARK: - X-Ray Data Manager
@MainActor
class XRayDataManager: ObservableObject {
    static let shared = XRayDataManager()
    
    // MARK: - Published Properties
    @Published var pulseHistory: [PulsePoint] = []
    @Published var events: [XRayEvent] = []
    @Published var threatFactors: [ThreatFactor] = []
    @Published var threatScore: Int = 0
    @Published var confidence: Int = 95
    
    // Traffic pattern percentages
    @Published var burstPercent: Double = 0
    @Published var streamPercent: Double = 0
    @Published var backgroundPercent: Double = 0
    @Published var currentPattern: TrafficPattern = .idle
    
    // Energy breakdown (estimated %/hr)
    @Published var radioEnergyPerHour: Double = 0
    @Published var cpuEnergyPerHour: Double = 0
    @Published var idleEnergyPerHour: Double = 3.0 // Base idle drain
    
    // Current readings
    @Published var currentCPU: Double = 0
    @Published var currentNetworkRate: Double = 0 // bytes/sec
    @Published var currentThermalLevel: Int = 0
    @Published var connectionType: String = "Unknown"
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var monitoringManager: MonitoringManager?
    private let maxPulseHistory = 60 // 60 seconds
    private let maxEvents = 50
    
    // For change detection
    private var lastConnectionType: String = ""
    private var lastThermalState: String = ""
    private var lastNetworkRate: Double = 0
    private var lastCPU: Double = 0
    
    // Traffic pattern tracking
    private var recentTrafficSamples: [(timestamp: Date, bytes: Double)] = []
    
    private init() {}
    
    // MARK: - Public Methods
    func configure(monitoringManager: MonitoringManager) {
        self.monitoringManager = monitoringManager
    }
    
    func startMonitoring() {
        stopMonitoring()
        
        // Initial reading
        collectData()
        
        // 1Hz updates
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.collectData()
            }
        }
        
        addEvent("X-Ray monitoring started", icon: "eye.fill", color: "cyan")
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func clearEvents() {
        events.removeAll()
        addEvent("Event log cleared", icon: "trash", color: "gray")
    }
    
    // MARK: - Private Methods
    private func collectData() {
        guard let manager = monitoringManager else { return }
        
        let network = manager.networkMonitor
        let cpu = manager.cpuMonitor
        let battery = manager.batteryMonitor
        let thermal = manager.thermalMonitor
        
        // Current readings
        currentCPU = cpu.cpuUsagePercent
        currentNetworkRate = network.uploadBytesPerSecond + network.downloadBytesPerSecond
        currentThermalLevel = thermalToInt(thermal.thermalState)
        
        // Detect connection type
        if network.wifiDownloadBytesPerSecond > 0 || network.wifiUploadBytesPerSecond > 0 {
            connectionType = "WiFi"
        } else if network.cellularDownloadBytesPerSecond > 0 || network.cellularUploadBytesPerSecond > 0 {
            connectionType = "Cellular"
        } else {
            connectionType = "Idle"
        }
        
        // Calculate normalized stress (0-1)
        let cpuStress = min(1.0, currentCPU / 100.0)
        let networkStress = min(1.0, currentNetworkRate / 1_000_000) // 1MB/s = max
        let thermalStress = Double(currentThermalLevel) / 4.0
        let combinedStress = (cpuStress + networkStress + thermalStress) / 3.0
        
        // Add to pulse history
        let pulse = PulsePoint(
            timestamp: Date(),
            value: combinedStress,
            cpu: cpuStress,
            network: networkStress,
            thermal: thermalStress
        )
        pulseHistory.append(pulse)
        if pulseHistory.count > maxPulseHistory {
            pulseHistory.removeFirst()
        }
        
        // -- Detect semantic events --
        detectEvents(network: network, thermal: thermal)
        
        // -- Update traffic patterns --
        updateTrafficPatterns()
        
        // -- Update threat factors --
        updateThreatFactors(cpu: cpu, network: network, battery: battery, thermal: thermal)
        
        // -- Update energy estimates --
        updateEnergyEstimates(battery: battery)
        
        // Store for next comparison
        lastConnectionType = connectionType
        lastThermalState = thermal.thermalState.rawValue
        lastNetworkRate = currentNetworkRate
        lastCPU = currentCPU
    }
    
    private func detectEvents(network: NetworkMonitor, thermal: ThermalMonitor) {
        let now = Date()
        
        // Connection type change
        if connectionType != lastConnectionType && lastConnectionType != "" {
            addEvent("Switched to \(connectionType)", icon: connectionType == "WiFi" ? "wifi" : "antenna.radiowaves.left.and.right", color: connectionType == "WiFi" ? "blue" : "orange")
        }
        
        // Thermal change
        if thermal.thermalState.rawValue != lastThermalState && lastThermalState != "" {
            let color = thermal.thermalState == .nominal ? "green" : (thermal.thermalState == .critical ? "red" : "orange")
            addEvent("Thermal: \(thermal.thermalState.rawValue)", icon: "thermometer.medium", color: color)
        }
        
        // CPU spike (>50% increase)
        if currentCPU > lastCPU + 20 && currentCPU > 30 {
            addEvent("CPU spike: \(Int(currentCPU))%", icon: "cpu", color: "orange")
        }
        
        // Network spike (>500KB/s sudden increase)
        if currentNetworkRate > lastNetworkRate + 500_000 && currentNetworkRate > 100_000 {
            addEvent("Network spike: \(formatRate(currentNetworkRate))", icon: "arrow.up.arrow.down", color: "cyan")
        }
        
        // Track traffic samples for pattern detection
        recentTrafficSamples.append((timestamp: now, bytes: currentNetworkRate))
        let cutoff = now.addingTimeInterval(-10) // Last 10 seconds
        recentTrafficSamples.removeAll { $0.timestamp < cutoff }
    }
    
    private func updateTrafficPatterns() {
        guard recentTrafficSamples.count >= 3 else {
            currentPattern = .idle
            burstPercent = 0
            streamPercent = 0
            backgroundPercent = 100
            return
        }
        
        let avgRate = recentTrafficSamples.map { $0.bytes }.reduce(0, +) / Double(recentTrafficSamples.count)
        let maxRate = recentTrafficSamples.map { $0.bytes }.max() ?? 0
        let variance = recentTrafficSamples.map { pow($0.bytes - avgRate, 2) }.reduce(0, +) / Double(recentTrafficSamples.count)
        let stdDev = sqrt(variance)
        
        // Categorize based on patterns
        if avgRate < 10_000 {
            // Low traffic = mostly background
            currentPattern = .background
            burstPercent = 5
            streamPercent = 5
            backgroundPercent = 90
        } else if stdDev > avgRate * 0.5 {
            // High variance = burst pattern
            currentPattern = .burst
            burstPercent = 60
            streamPercent = 20
            backgroundPercent = 20
        } else if avgRate > 50_000 {
            // Sustained high rate = streaming
            currentPattern = .stream
            burstPercent = 10
            streamPercent = 70
            backgroundPercent = 20
        } else {
            // Mixed
            currentPattern = .background
            burstPercent = 20
            streamPercent = 30
            backgroundPercent = 50
        }
    }
    
    private func updateThreatFactors(cpu: CPUMonitor, network: NetworkMonitor, battery: BatteryMonitor, thermal: ThermalMonitor) {
        var factors: [ThreatFactor] = []
        var score = 0
        
        // CPU factor
        let cpuScore = min(25, Int(cpu.cpuUsagePercent / 4))
        factors.append(ThreatFactor(
            name: "CPU",
            score: cpuScore,
            reason: cpu.cpuUsagePercent < 30 ? "Normal load" : (cpu.cpuUsagePercent < 60 ? "Elevated" : "High load"),
            icon: "cpu"
        ))
        score += cpuScore
        
        // Network factor
        let uploadMB = network.lastHourUploadMB
        let networkScore = min(25, Int(uploadMB / 4))
        factors.append(ThreatFactor(
            name: "Upload",
            score: networkScore,
            reason: uploadMB < 10 ? "Normal volume" : (uploadMB < 50 ? "Elevated" : "High volume"),
            icon: "arrow.up.circle"
        ))
        score += networkScore
        
        // Battery factor
        let drainScore = min(25, Int(battery.drainRatePerHour / 4))
        factors.append(ThreatFactor(
            name: "Battery",
            score: drainScore,
            reason: battery.drainRatePerHour < 10 ? "Normal drain" : (battery.drainRatePerHour < 20 ? "Elevated" : "Fast drain"),
            icon: "battery.50"
        ))
        score += drainScore
        
        // Thermal factor
        let thermalScore = currentThermalLevel * 8
        factors.append(ThreatFactor(
            name: "Thermal",
            score: thermalScore,
            reason: thermal.thermalState.rawValue,
            icon: "thermometer.medium"
        ))
        score += thermalScore
        
        threatFactors = factors
        threatScore = min(100, score)
        
        // Confidence based on data quality
        confidence = pulseHistory.count >= 30 ? 98 : (pulseHistory.count >= 10 ? 85 : 60)
    }
    
    private func updateEnergyEstimates(battery: BatteryMonitor) {
        let totalDrain = Double(battery.drainRatePerHour)
        
        // Estimate breakdown (simplified model)
        let networkActivity = min(1.0, currentNetworkRate / 500_000)
        let cpuActivity = currentCPU / 100.0
        
        radioEnergyPerHour = totalDrain * 0.3 * networkActivity
        cpuEnergyPerHour = totalDrain * 0.4 * cpuActivity
        idleEnergyPerHour = max(0, totalDrain - radioEnergyPerHour - cpuEnergyPerHour)
    }
    
    private func addEvent(_ message: String, icon: String, color: String) {
        let event = XRayEvent(timestamp: Date(), message: message, icon: icon, color: color)
        events.insert(event, at: 0)
        if events.count > maxEvents {
            events.removeLast()
        }
    }
    
    private func thermalToInt(_ state: ThermalState) -> Int {
        switch state {
        case .nominal: return 1
        case .fair: return 2
        case .serious: return 3
        case .critical: return 4
        }
    }
    
    private func formatRate(_ bytesPerSec: Double) -> String {
        if bytesPerSec < 1024 {
            return String(format: "%.0f B/s", bytesPerSec)
        } else if bytesPerSec < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytesPerSec / 1024)
        } else {
            return String(format: "%.1f MB/s", bytesPerSec / (1024 * 1024))
        }
    }
}
