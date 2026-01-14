//
//  NetworkMonitor.swift
//  iguardian
//
//  Monitors network traffic using getifaddrs()
//  Tracks both instant rates AND cumulative totals
//  Separates WiFi and Cellular traffic
//

import Foundation
import Combine

// MARK: - Network Traffic Data Structure
struct NetworkTraffic {
    var wifiUpload: UInt64 = 0
    var wifiDownload: UInt64 = 0
    var cellularUpload: UInt64 = 0
    var cellularDownload: UInt64 = 0
    
    var totalUpload: UInt64 { wifiUpload + cellularUpload }
    var totalDownload: UInt64 { wifiDownload + cellularDownload }
}

class NetworkMonitor: ObservableObject {
    
    // MARK: - Total Instant Rate (combined)
    @Published var uploadBytesPerSecond: Double = 0
    @Published var downloadBytesPerSecond: Double = 0
    
    // MARK: - WiFi Rates
    @Published var wifiUploadBytesPerSecond: Double = 0
    @Published var wifiDownloadBytesPerSecond: Double = 0
    
    // MARK: - Cellular Rates
    @Published var cellularUploadBytesPerSecond: Double = 0
    @Published var cellularDownloadBytesPerSecond: Double = 0
    
    // MARK: - Cumulative Totals (since device boot)
    @Published var totalUploadBytes: UInt64 = 0
    @Published var totalDownloadBytes: UInt64 = 0
    
    // MARK: - WiFi Totals (session)
    @Published var sessionWifiUploadBytes: UInt64 = 0
    @Published var sessionWifiDownloadBytes: UInt64 = 0
    
    // MARK: - Cellular Totals (session)
    @Published var sessionCellularUploadBytes: UInt64 = 0
    @Published var sessionCellularDownloadBytes: UInt64 = 0
    
    // MARK: - Session Totals (combined, since monitoring started)
    @Published var sessionUploadBytes: UInt64 = 0
    @Published var sessionDownloadBytes: UInt64 = 0
    
    // MARK: - Rolling Window Totals (last N minutes)
    @Published var lastHourUploadBytes: UInt64 = 0
    @Published var lastHourDownloadBytes: UInt64 = 0
    @Published var last5MinUploadBytes: UInt64 = 0
    @Published var last5MinDownloadBytes: UInt64 = 0
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var lastTraffic = NetworkTraffic()
    private var lastUpdateTime: Date?
    
    // Session baseline (values when monitoring started)
    private var sessionStartTraffic = NetworkTraffic()
    private var sessionStartTime: Date?
    
    // Rolling window history: (timestamp, totalUp, totalDown)
    private var history: [(Date, UInt64, UInt64)] = []
    
    private let updateInterval: TimeInterval = 1.0
    private let historyRetentionSeconds: TimeInterval = 3600 // Keep 1 hour of data
    
    // MARK: - Computed Properties (Formatted in MB)
    var sessionUploadMB: Double { Double(sessionUploadBytes) / (1024 * 1024) }
    var sessionDownloadMB: Double { Double(sessionDownloadBytes) / (1024 * 1024) }
    var sessionWifiUploadMB: Double { Double(sessionWifiUploadBytes) / (1024 * 1024) }
    var sessionWifiDownloadMB: Double { Double(sessionWifiDownloadBytes) / (1024 * 1024) }
    var sessionCellularUploadMB: Double { Double(sessionCellularUploadBytes) / (1024 * 1024) }
    var sessionCellularDownloadMB: Double { Double(sessionCellularDownloadBytes) / (1024 * 1024) }
    var lastHourUploadMB: Double { Double(lastHourUploadBytes) / (1024 * 1024) }
    var lastHourDownloadMB: Double { Double(lastHourDownloadBytes) / (1024 * 1024) }
    var last5MinUploadMB: Double { Double(last5MinUploadBytes) / (1024 * 1024) }
    var last5MinDownloadMB: Double { Double(last5MinDownloadBytes) / (1024 * 1024) }
    
    var sessionDuration: TimeInterval {
        guard let start = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(start)
    }
    
    // Total session for WiFi vs Cellular
    var sessionWifiTotalMB: Double { sessionWifiUploadMB + sessionWifiDownloadMB }
    var sessionCellularTotalMB: Double { sessionCellularUploadMB + sessionCellularDownloadMB }
    
    // MARK: - Public Methods
    func startMonitoring() {
        let traffic = getNetworkBytes()
        lastTraffic = traffic
        lastUpdateTime = Date()
        
        // Set session baseline
        sessionStartTraffic = traffic
        sessionStartTime = Date()
        sessionUploadBytes = 0
        sessionDownloadBytes = 0
        sessionWifiUploadBytes = 0
        sessionWifiDownloadBytes = 0
        sessionCellularUploadBytes = 0
        sessionCellularDownloadBytes = 0
        
        // Clear history
        history.removeAll()
        history.append((Date(), traffic.totalUpload, traffic.totalDownload))
        
        LogManager.shared.log(
            "Network monitoring started. WiFi: Up=\(formatBytes(traffic.wifiUpload)), Down=\(formatBytes(traffic.wifiDownload)). Cellular: Up=\(formatBytes(traffic.cellularUpload)), Down=\(formatBytes(traffic.cellularDownload))",
            level: .info,
            category: "Network"
        )
        
        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateNetworkStats()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        
        LogManager.shared.log(
            "Network monitoring stopped. Session: WiFi=\(String(format: "%.1f", sessionWifiTotalMB))MB, Cellular=\(String(format: "%.1f", sessionCellularTotalMB))MB",
            level: .info,
            category: "Network"
        )
    }
    
    func resetSessionTotals() {
        let traffic = getNetworkBytes()
        sessionStartTraffic = traffic
        sessionStartTime = Date()
        sessionUploadBytes = 0
        sessionDownloadBytes = 0
        sessionWifiUploadBytes = 0
        sessionWifiDownloadBytes = 0
        sessionCellularUploadBytes = 0
        sessionCellularDownloadBytes = 0
        history.removeAll()
        history.append((Date(), traffic.totalUpload, traffic.totalDownload))
        
        LogManager.shared.log("Session totals reset", level: .info, category: "Network")
    }
    
    // MARK: - Private Methods
    private func updateNetworkStats() {
        let currentTraffic = getNetworkBytes()
        let now = Date()
        
        if let lastTime = lastUpdateTime {
            let elapsed = now.timeIntervalSince(lastTime)
            
            if elapsed > 0 {
                // Calculate WiFi deltas
                let wifiUpDelta = currentTraffic.wifiUpload > lastTraffic.wifiUpload ? currentTraffic.wifiUpload - lastTraffic.wifiUpload : 0
                let wifiDownDelta = currentTraffic.wifiDownload > lastTraffic.wifiDownload ? currentTraffic.wifiDownload - lastTraffic.wifiDownload : 0
                
                // Calculate Cellular deltas
                let cellularUpDelta = currentTraffic.cellularUpload > lastTraffic.cellularUpload ? currentTraffic.cellularUpload - lastTraffic.cellularUpload : 0
                let cellularDownDelta = currentTraffic.cellularDownload > lastTraffic.cellularDownload ? currentTraffic.cellularDownload - lastTraffic.cellularDownload : 0
                
                // Calculate session WiFi totals
                let sessionWifiUp = currentTraffic.wifiUpload > sessionStartTraffic.wifiUpload ? currentTraffic.wifiUpload - sessionStartTraffic.wifiUpload : 0
                let sessionWifiDown = currentTraffic.wifiDownload > sessionStartTraffic.wifiDownload ? currentTraffic.wifiDownload - sessionStartTraffic.wifiDownload : 0
                
                // Calculate session Cellular totals
                let sessionCellularUp = currentTraffic.cellularUpload > sessionStartTraffic.cellularUpload ? currentTraffic.cellularUpload - sessionStartTraffic.cellularUpload : 0
                let sessionCellularDown = currentTraffic.cellularDownload > sessionStartTraffic.cellularDownload ? currentTraffic.cellularDownload - sessionStartTraffic.cellularDownload : 0
                
                // Add to history
                history.append((now, currentTraffic.totalUpload, currentTraffic.totalDownload))
                
                // Remove old history entries
                let cutoff = now.addingTimeInterval(-historyRetentionSeconds)
                history.removeAll { $0.0 < cutoff }
                
                // Calculate rolling window totals
                let (hourUp, hourDown) = calculateRollingTotal(seconds: 3600, currentUp: currentTraffic.totalUpload, currentDown: currentTraffic.totalDownload)
                let (fiveMinUp, fiveMinDown) = calculateRollingTotal(seconds: 300, currentUp: currentTraffic.totalUpload, currentDown: currentTraffic.totalDownload)
                
                DispatchQueue.main.async {
                    // WiFi rates
                    self.wifiUploadBytesPerSecond = Double(wifiUpDelta) / elapsed
                    self.wifiDownloadBytesPerSecond = Double(wifiDownDelta) / elapsed
                    
                    // Cellular rates
                    self.cellularUploadBytesPerSecond = Double(cellularUpDelta) / elapsed
                    self.cellularDownloadBytesPerSecond = Double(cellularDownDelta) / elapsed
                    
                    // Total rates (combined)
                    self.uploadBytesPerSecond = Double(wifiUpDelta + cellularUpDelta) / elapsed
                    self.downloadBytesPerSecond = Double(wifiDownDelta + cellularDownDelta) / elapsed
                    
                    // Cumulative totals
                    self.totalUploadBytes = currentTraffic.totalUpload
                    self.totalDownloadBytes = currentTraffic.totalDownload
                    
                    // Session WiFi totals
                    self.sessionWifiUploadBytes = sessionWifiUp
                    self.sessionWifiDownloadBytes = sessionWifiDown
                    
                    // Session Cellular totals
                    self.sessionCellularUploadBytes = sessionCellularUp
                    self.sessionCellularDownloadBytes = sessionCellularDown
                    
                    // Session combined totals
                    self.sessionUploadBytes = sessionWifiUp + sessionCellularUp
                    self.sessionDownloadBytes = sessionWifiDown + sessionCellularDown
                    
                    // Rolling window totals
                    self.lastHourUploadBytes = hourUp
                    self.lastHourDownloadBytes = hourDown
                    self.last5MinUploadBytes = fiveMinUp
                    self.last5MinDownloadBytes = fiveMinDown
                }
            }
        }
        
        lastTraffic = currentTraffic
        lastUpdateTime = now
        
        // Record to persistent storage with WiFi/Cellular breakdown
        Task { @MainActor in
            TrafficLogManager.shared.recordTraffic(
                wifiUpload: currentTraffic.wifiUpload,
                wifiDownload: currentTraffic.wifiDownload,
                cellularUpload: currentTraffic.cellularUpload,
                cellularDownload: currentTraffic.cellularDownload
            )
        }
    }
    
    private func calculateRollingTotal(seconds: TimeInterval, currentUp: UInt64, currentDown: UInt64) -> (UInt64, UInt64) {
        let cutoff = Date().addingTimeInterval(-seconds)
        
        guard let oldest = history.first(where: { $0.0 >= cutoff }) ?? history.first else {
            return (0, 0)
        }
        
        let uploadDelta = currentUp > oldest.1 ? currentUp - oldest.1 : 0
        let downloadDelta = currentDown > oldest.2 ? currentDown - oldest.2 : 0
        
        return (uploadDelta, downloadDelta)
    }
    
    /// Get network interface statistics using getifaddrs()
    /// Returns separate values for WiFi and Cellular
    private func getNetworkBytes() -> NetworkTraffic {
        var traffic = NetworkTraffic()
        
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            LogManager.shared.log("getifaddrs() failed", level: .error, category: "Network")
            return traffic
        }
        
        defer { freeifaddrs(ifaddr) }
        
        var cursor: UnsafeMutablePointer<ifaddrs>? = firstAddr
        
        while cursor != nil {
            if let addr = cursor {
                let name = String(cString: addr.pointee.ifa_name)
                
                if let data = addr.pointee.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self)
                    let upload = UInt64(networkData.pointee.ifi_obytes)
                    let download = UInt64(networkData.pointee.ifi_ibytes)
                    
                    // WiFi interfaces: en0, en1, en2, etc.
                    if name.hasPrefix("en") {
                        traffic.wifiUpload += upload
                        traffic.wifiDownload += download
                    }
                    // Cellular interfaces: pdp_ip0, pdp_ip1, etc.
                    else if name.hasPrefix("pdp_ip") {
                        traffic.cellularUpload += upload
                        traffic.cellularDownload += download
                    }
                }
            }
            cursor = cursor?.pointee.ifa_next
        }
        
        return traffic
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
