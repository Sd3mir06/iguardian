//
//  NetworkMonitor.swift
//  iguardian
//
//  Monitors network traffic using getifaddrs()
//  Tracks both instant rates AND cumulative totals
//

import Foundation
import Combine

class NetworkMonitor: ObservableObject {
    
    // MARK: - Instant Rate (for real-time display)
    @Published var uploadBytesPerSecond: Double = 0
    @Published var downloadBytesPerSecond: Double = 0
    
    // MARK: - Cumulative Totals (since device boot)
    @Published var totalUploadBytes: UInt64 = 0
    @Published var totalDownloadBytes: UInt64 = 0
    
    // MARK: - Session Totals (since monitoring started)
    @Published var sessionUploadBytes: UInt64 = 0
    @Published var sessionDownloadBytes: UInt64 = 0
    
    // MARK: - Rolling Window Totals (last N minutes)
    @Published var lastHourUploadBytes: UInt64 = 0
    @Published var lastHourDownloadBytes: UInt64 = 0
    @Published var last5MinUploadBytes: UInt64 = 0
    @Published var last5MinDownloadBytes: UInt64 = 0
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var lastUploadBytes: UInt64 = 0
    private var lastDownloadBytes: UInt64 = 0
    private var lastUpdateTime: Date?
    
    // Session baseline (values when monitoring started)
    private var sessionStartUploadBytes: UInt64 = 0
    private var sessionStartDownloadBytes: UInt64 = 0
    private var sessionStartTime: Date?
    
    // Rolling window history: (timestamp, totalUp, totalDown)
    private var history: [(Date, UInt64, UInt64)] = []
    
    private let updateInterval: TimeInterval = 1.0
    private let historyRetentionSeconds: TimeInterval = 3600 // Keep 1 hour of data
    
    // MARK: - Computed Properties (Formatted)
    var sessionUploadMB: Double {
        Double(sessionUploadBytes) / (1024 * 1024)
    }
    
    var sessionDownloadMB: Double {
        Double(sessionDownloadBytes) / (1024 * 1024)
    }
    
    var lastHourUploadMB: Double {
        Double(lastHourUploadBytes) / (1024 * 1024)
    }
    
    var lastHourDownloadMB: Double {
        Double(lastHourDownloadBytes) / (1024 * 1024)
    }
    
    var last5MinUploadMB: Double {
        Double(last5MinUploadBytes) / (1024 * 1024)
    }
    
    var last5MinDownloadMB: Double {
        Double(last5MinDownloadBytes) / (1024 * 1024)
    }
    
    var sessionDuration: TimeInterval {
        guard let start = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(start)
    }
    
    // MARK: - Public Methods
    func startMonitoring() {
        // Get initial values
        let (up, down) = getNetworkBytes()
        lastUploadBytes = up
        lastDownloadBytes = down
        lastUpdateTime = Date()
        
        // Set session baseline
        sessionStartUploadBytes = up
        sessionStartDownloadBytes = down
        sessionStartTime = Date()
        sessionUploadBytes = 0
        sessionDownloadBytes = 0
        
        // Clear history
        history.removeAll()
        history.append((Date(), up, down))
        
        LogManager.shared.log("Network monitoring started. Baseline: Up=\(formatBytes(up)), Down=\(formatBytes(down))", level: .info, category: "Network")
        
        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateNetworkStats()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        
        LogManager.shared.log("Network monitoring stopped. Session totals: Up=\(String(format: "%.1f", sessionUploadMB)) MB, Down=\(String(format: "%.1f", sessionDownloadMB)) MB", level: .info, category: "Network")
    }
    
    func resetSessionTotals() {
        let (up, down) = getNetworkBytes()
        sessionStartUploadBytes = up
        sessionStartDownloadBytes = down
        sessionStartTime = Date()
        sessionUploadBytes = 0
        sessionDownloadBytes = 0
        history.removeAll()
        history.append((Date(), up, down))
        
        LogManager.shared.log("Session totals reset", level: .info, category: "Network")
    }
    
    // MARK: - Private Methods
    private func updateNetworkStats() {
        let (currentUp, currentDown) = getNetworkBytes()
        let now = Date()
        
        if let lastTime = lastUpdateTime {
            let elapsed = now.timeIntervalSince(lastTime)
            
            if elapsed > 0 {
                // Calculate instant rate (bytes per second)
                let uploadDelta = currentUp > lastUploadBytes ? currentUp - lastUploadBytes : 0
                let downloadDelta = currentDown > lastDownloadBytes ? currentDown - lastDownloadBytes : 0
                
                // Calculate session totals
                let sessionUp = currentUp > sessionStartUploadBytes ? currentUp - sessionStartUploadBytes : 0
                let sessionDown = currentDown > sessionStartDownloadBytes ? currentDown - sessionStartDownloadBytes : 0
                
                // Add to history
                history.append((now, currentUp, currentDown))
                
                // Remove old history entries
                let cutoff = now.addingTimeInterval(-historyRetentionSeconds)
                history.removeAll { $0.0 < cutoff }
                
                // Calculate rolling window totals
                let (hourUp, hourDown) = calculateRollingTotal(seconds: 3600, currentUp: currentUp, currentDown: currentDown)
                let (fiveMinUp, fiveMinDown) = calculateRollingTotal(seconds: 300, currentUp: currentUp, currentDown: currentDown)
                
                DispatchQueue.main.async {
                    // Instant rates
                    self.uploadBytesPerSecond = Double(uploadDelta) / elapsed
                    self.downloadBytesPerSecond = Double(downloadDelta) / elapsed
                    
                    // Cumulative totals
                    self.totalUploadBytes = currentUp
                    self.totalDownloadBytes = currentDown
                    
                    // Session totals
                    self.sessionUploadBytes = sessionUp
                    self.sessionDownloadBytes = sessionDown
                    
                    // Rolling window totals
                    self.lastHourUploadBytes = hourUp
                    self.lastHourDownloadBytes = hourDown
                    self.last5MinUploadBytes = fiveMinUp
                    self.last5MinDownloadBytes = fiveMinDown
                }
            }
        }
        
        lastUploadBytes = currentUp
        lastDownloadBytes = currentDown
        lastUpdateTime = now
        
        // Record to persistent storage (every update)
        Task { @MainActor in
            TrafficLogManager.shared.recordTraffic(
                systemUpload: currentUp,
                systemDownload: currentDown
            )
        }
    }
    
    private func calculateRollingTotal(seconds: TimeInterval, currentUp: UInt64, currentDown: UInt64) -> (UInt64, UInt64) {
        let cutoff = Date().addingTimeInterval(-seconds)
        
        // Find the oldest entry within the window
        guard let oldest = history.first(where: { $0.0 >= cutoff }) ?? history.first else {
            return (0, 0)
        }
        
        let uploadDelta = currentUp > oldest.1 ? currentUp - oldest.1 : 0
        let downloadDelta = currentDown > oldest.2 ? currentDown - oldest.2 : 0
        
        return (uploadDelta, downloadDelta)
    }
    
    /// Get network interface statistics using getifaddrs()
    private func getNetworkBytes() -> (upload: UInt64, download: UInt64) {
        var uploadBytes: UInt64 = 0
        var downloadBytes: UInt64 = 0
        
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            LogManager.shared.log("getifaddrs() failed", level: .error, category: "Network")
            return (0, 0)
        }
        
        defer { freeifaddrs(ifaddr) }
        
        var cursor: UnsafeMutablePointer<ifaddrs>? = firstAddr
        
        while cursor != nil {
            if let addr = cursor {
                let name = String(cString: addr.pointee.ifa_name)
                
                // Check for Wi-Fi (en0, en1) and Cellular (pdp_ip0, pdp_ip1, etc.)
                if name.hasPrefix("en") || name.hasPrefix("pdp_ip") {
                    if let data = addr.pointee.ifa_data {
                        let networkData = data.assumingMemoryBound(to: if_data.self)
                        uploadBytes += UInt64(networkData.pointee.ifi_obytes)
                        downloadBytes += UInt64(networkData.pointee.ifi_ibytes)
                    }
                }
            }
            cursor = cursor?.pointee.ifa_next
        }
        
        return (uploadBytes, downloadBytes)
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        } else {
            return String(format: "%.2f GB", Double(bytes) / (1024 * 1024 * 1024))
        }
    }
}

// MARK: - C Interface Structure
fileprivate struct if_data {
    var ifi_type: UInt8
    var ifi_typelen: UInt8
    var ifi_physical: UInt8
    var ifi_addrlen: UInt8
    var ifi_hdrlen: UInt8
    var ifi_recvquota: UInt8
    var ifi_xmitquota: UInt8
    var ifi_unused1: UInt8
    var ifi_mtu: UInt32
    var ifi_metric: UInt32
    var ifi_baudrate: UInt32
    var ifi_ipackets: UInt32
    var ifi_ierrors: UInt32
    var ifi_opackets: UInt32
    var ifi_oerrors: UInt32
    var ifi_collisions: UInt32
    var ifi_ibytes: UInt32
    var ifi_obytes: UInt32
    var ifi_imcasts: UInt32
    var ifi_omcasts: UInt32
    var ifi_iqdrops: UInt32
    var ifi_noproto: UInt32
    var ifi_recvtiming: UInt32
    var ifi_xmittiming: UInt32
    var ifi_lastchange: timeval
    var ifi_unused2: UInt32
    var ifi_hwassist: UInt32
    var ifi_reserved1: UInt32
    var ifi_reserved2: UInt32
}
