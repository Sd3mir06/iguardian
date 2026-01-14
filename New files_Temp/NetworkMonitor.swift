//
//  NetworkMonitor.swift
//  iguardian
//
//  Monitors network traffic using getifaddrs()
//

import Foundation
import Combine

class NetworkMonitor: ObservableObject {
    
    @Published var uploadBytesPerSecond: Double = 0
    @Published var downloadBytesPerSecond: Double = 0
    @Published var totalUploadBytes: UInt64 = 0
    @Published var totalDownloadBytes: UInt64 = 0
    
    private var timer: Timer?
    private var lastUploadBytes: UInt64 = 0
    private var lastDownloadBytes: UInt64 = 0
    private var lastUpdateTime: Date?
    
    private let updateInterval: TimeInterval = 1.0
    
    // MARK: - Public Methods
    func startMonitoring() {
        // Get initial values
        let (up, down) = getNetworkBytes()
        lastUploadBytes = up
        lastDownloadBytes = down
        lastUpdateTime = Date()
        
        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateNetworkStats()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Private Methods
    private func updateNetworkStats() {
        let (currentUp, currentDown) = getNetworkBytes()
        let now = Date()
        
        if let lastTime = lastUpdateTime {
            let elapsed = now.timeIntervalSince(lastTime)
            
            if elapsed > 0 {
                // Calculate bytes per second
                let uploadDelta = currentUp > lastUploadBytes ? currentUp - lastUploadBytes : 0
                let downloadDelta = currentDown > lastDownloadBytes ? currentDown - lastDownloadBytes : 0
                
                DispatchQueue.main.async {
                    self.uploadBytesPerSecond = Double(uploadDelta) / elapsed
                    self.downloadBytesPerSecond = Double(downloadDelta) / elapsed
                    self.totalUploadBytes = currentUp
                    self.totalDownloadBytes = currentDown
                }
            }
        }
        
        lastUploadBytes = currentUp
        lastDownloadBytes = currentDown
        lastUpdateTime = now
    }
    
    /// Get network interface statistics using getifaddrs()
    private func getNetworkBytes() -> (upload: UInt64, download: UInt64) {
        var uploadBytes: UInt64 = 0
        var downloadBytes: UInt64 = 0
        
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return (0, 0)
        }
        
        defer { freeifaddrs(ifaddr) }
        
        var cursor: UnsafeMutablePointer<ifaddrs>? = firstAddr
        
        while cursor != nil {
            if let addr = cursor {
                let name = String(cString: addr.pointee.ifa_name)
                
                // Check for Wi-Fi (en0) and Cellular (pdp_ip0, pdp_ip1, etc.)
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
}

// MARK: - C Interface Structure
// This is needed for getifaddrs to work properly
// The if_data structure from <net/if_var.h>
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
