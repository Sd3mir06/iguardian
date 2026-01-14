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
    
    private var timer: Timer?
    private let updateInterval: TimeInterval = 30.0 // Check every 30 seconds
    
    // For drain rate calculation
    private var levelHistory: [(timestamp: Date, level: Float)] = []
    private let historyWindowSeconds: TimeInterval = 300 // 5 minute window
    
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
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        UIDevice.current.isBatteryMonitoringEnabled = false
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Private Methods
    private func updateBatteryLevel() {
        let level = UIDevice.current.batteryLevel
        let state = UIDevice.current.batteryState
        
        // -1 means battery level unknown (simulator)
        let actualLevel = level >= 0 ? level : 0.75
        
        DispatchQueue.main.async {
            self.batteryLevel = actualLevel
            self.batteryState = state
        }
        
        // Add to history for drain rate calculation
        let now = Date()
        levelHistory.append((timestamp: now, level: actualLevel))
        
        // Remove old entries
        let cutoff = now.addingTimeInterval(-historyWindowSeconds)
        levelHistory.removeAll { $0.timestamp < cutoff }
        
        // Calculate drain rate
        calculateDrainRate()
    }
    
    private func calculateDrainRate() {
        guard levelHistory.count >= 2 else {
            DispatchQueue.main.async {
                self.drainRatePerHour = 0
            }
            return
        }
        
        let oldest = levelHistory.first!
        let newest = levelHistory.last!
        
        let timeDelta = newest.timestamp.timeIntervalSince(oldest.timestamp)
        let levelDelta = oldest.level - newest.level // Positive if draining
        
        guard timeDelta > 0 else {
            return
        }
        
        // Convert to per-hour rate (as percentage)
        let drainPerSecond = levelDelta / Float(timeDelta)
        let drainPerHour = drainPerSecond * 3600 * 100 // Convert to percentage per hour
        
        DispatchQueue.main.async {
            // Only show positive drain rates (ignore charging)
            self.drainRatePerHour = max(0, drainPerHour)
        }
    }
    
    @objc private func batteryLevelDidChange() {
        updateBatteryLevel()
    }
    
    @objc private func batteryStateDidChange() {
        DispatchQueue.main.async {
            self.batteryState = UIDevice.current.batteryState
        }
    }
}
