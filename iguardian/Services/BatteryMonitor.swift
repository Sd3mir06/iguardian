//
//  BatteryMonitor.swift
//  iguardian
//
//  Monitors battery level and drain rate
//

import Foundation
import UIKit
import Combine

class BatteryMonitor: ObservableObject {
    
    @Published var batteryLevel: Float = 0
    @Published var batteryState: UIDevice.BatteryState = .unknown
    @Published var drainRatePerHour: Float = 0
    @Published var isCharging: Bool = false
    
    private var timer: Timer?
    private let updateInterval: TimeInterval = 10.0 // Check every 10 seconds for faster response
    
    // For drain rate calculation - shorter window for faster response
    private var levelHistory: [(timestamp: Date, level: Float)] = []
    private let historyWindowSeconds: TimeInterval = 120 // 2 minute window (was 5 min)
    private let minReadingsForCalculation = 3 // Need at least 3 readings
    
    // MARK: - Public Methods
    func startMonitoring() {
        // Enable battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        // Get initial reading
        updateBatteryLevel()
        
        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateBatteryLevel()
        }
        
        // Listen for battery level changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryLevelDidChange),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryStateDidChange),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )
        
        LogManager.shared.log("Battery monitoring started", level: .info, category: "Battery")
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        UIDevice.current.isBatteryMonitoringEnabled = false
        NotificationCenter.default.removeObserver(self)
        LogManager.shared.log("Battery monitoring stopped", level: .info, category: "Battery")
    }
    
    func update() {
        updateBatteryLevel()
    }
    
    // MARK: - Private Methods
    private func updateBatteryLevel() {
        let level = UIDevice.current.batteryLevel
        let state = UIDevice.current.batteryState
        
        // -1 means battery level unknown (simulator)
        let actualLevel: Float
        if level >= 0 {
            actualLevel = level
        } else {
            // Simulator - simulate drain for testing
            if levelHistory.isEmpty {
                actualLevel = 0.85
            } else {
                // Simulate 5% per hour drain on simulator
                let lastLevel = levelHistory.last?.level ?? 0.85
                let elapsed = Date().timeIntervalSince(levelHistory.last?.timestamp ?? Date())
                actualLevel = max(0.1, lastLevel - Float(elapsed / 3600) * 0.05)
            }
        }
        
        let isCurrentlyCharging = state == .charging || state == .full
        
        DispatchQueue.main.async {
            self.batteryLevel = actualLevel
            self.batteryState = state
            self.isCharging = isCurrentlyCharging
        }
        
        // Add to history for drain rate calculation
        let now = Date()
        levelHistory.append((timestamp: now, level: actualLevel))
        
        // Remove old entries
        let cutoff = now.addingTimeInterval(-historyWindowSeconds)
        levelHistory.removeAll { $0.timestamp < cutoff }
        
        // Calculate drain rate
        calculateDrainRate()
        
        LogManager.shared.log(
            "Battery: \(Int(actualLevel * 100))%, drain: \(String(format: "%.1f", drainRatePerHour))%/h, history: \(levelHistory.count) readings",
            level: .debug,
            category: "Battery"
        )
    }
    
    private func calculateDrainRate() {
        // Need minimum readings for accurate calculation
        guard levelHistory.count >= minReadingsForCalculation else {
            DispatchQueue.main.async {
                self.drainRatePerHour = 0
            }
            return
        }
        
        // Don't calculate drain when charging
        if batteryState == .charging || batteryState == .full {
            DispatchQueue.main.async {
                self.drainRatePerHour = 0
            }
            return
        }
        
        let oldest = levelHistory.first!
        let newest = levelHistory.last!
        
        let timeDelta = newest.timestamp.timeIntervalSince(oldest.timestamp)
        let levelDelta = oldest.level - newest.level // Positive if draining
        
        // Need at least 30 seconds of data
        guard timeDelta >= 30 else {
            return
        }
        
        // Convert to per-hour rate (as percentage)
        let drainPerSecond = levelDelta / Float(timeDelta)
        let drainPerHour = drainPerSecond * 3600 * 100 // Convert to percentage per hour
        
        DispatchQueue.main.async {
            // Only show positive drain rates (ignore charging or fluctuations)
            // Clamp to reasonable range (0-100% per hour)
            self.drainRatePerHour = min(100, max(0, drainPerHour))
        }
    }
    
    @objc private func batteryLevelDidChange() {
        updateBatteryLevel()
    }
    
    @objc private func batteryStateDidChange() {
        DispatchQueue.main.async {
            self.batteryState = UIDevice.current.batteryState
            self.isCharging = self.batteryState == .charging || self.batteryState == .full
        }
        // Recalculate when state changes
        updateBatteryLevel()
    }
}
