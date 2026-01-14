//
//  ThermalMonitor.swift
//  iguardian
//
//  Monitors device thermal state
//

import Foundation
import Combine

class ThermalMonitor: ObservableObject {
    
    @Published var thermalState: ThermalState = .nominal
    
    private var timer: Timer?
    private let updateInterval: TimeInterval = 5.0
    
    // MARK: - Public Methods
    func startMonitoring() {
        // Get initial reading
        updateThermalState()
        
        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateThermalState()
        }
        
        // Listen for thermal state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(thermalStateDidChange),
            name: ProcessInfo.thermalStateDidChangeNotification,
            object: nil
        )
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Private Methods
    private func updateThermalState() {
        let state = ProcessInfo.processInfo.thermalState
        
        DispatchQueue.main.async {
            self.thermalState = ThermalState.from(state)
        }
    }
    
    @objc private func thermalStateDidChange() {
        updateThermalState()
    }
}
