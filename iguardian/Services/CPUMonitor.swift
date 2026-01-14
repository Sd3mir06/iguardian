//
//  CPUMonitor.swift
//  iguardian
//
//  Monitors CPU usage using host_processor_info()
//

import Foundation
import Combine

class CPUMonitor: ObservableObject {
    
    @Published var cpuUsagePercent: Double = 0
    
    private var timer: Timer?
    private let updateInterval: TimeInterval = 2.0
    
    // Previous CPU info for delta calculation
    private var previousCPUInfo: host_cpu_load_info?
    
    // MARK: - Public Methods
    func startMonitoring() {
        // Get initial reading
        previousCPUInfo = getCPULoadInfo()
        LogManager.shared.log("CPU monitoring started", level: .info, category: "CPU")
        
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateCPUUsage()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        LogManager.shared.log("CPU monitoring stopped", level: .info, category: "CPU")
    }
    
    // MARK: - Private Methods
    private func updateCPUUsage() {
        guard let currentInfo = getCPULoadInfo(),
              let previousInfo = previousCPUInfo else {
            return
        }
        
        // Calculate deltas
        let userDelta = Double(currentInfo.cpu_ticks.0 - previousInfo.cpu_ticks.0)
        let systemDelta = Double(currentInfo.cpu_ticks.1 - previousInfo.cpu_ticks.1)
        let idleDelta = Double(currentInfo.cpu_ticks.2 - previousInfo.cpu_ticks.2)
        let niceDelta = Double(currentInfo.cpu_ticks.3 - previousInfo.cpu_ticks.3)
        
        let totalDelta = userDelta + systemDelta + idleDelta + niceDelta
        
        if totalDelta > 0 {
            let usage = ((userDelta + systemDelta + niceDelta) / totalDelta) * 100.0
            
            DispatchQueue.main.async {
                self.cpuUsagePercent = max(0, min(100, usage))
            }
        }
        
        previousCPUInfo = currentInfo
    }
    
    private func getCPULoadInfo() -> host_cpu_load_info? {
        var size = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)
        var cpuLoadInfo = host_cpu_load_info()
        
        let result = withUnsafeMutablePointer(to: &cpuLoadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }
        
        guard result == KERN_SUCCESS else {
            LogManager.shared.log("Failed to get CPU stats: result code \(result)", level: .error, category: "CPU")
            return nil
        }
        
        return cpuLoadInfo
    }
}
