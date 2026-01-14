//
//  TrafficLog.swift
//  iguardian
//
//  Persistent storage for network traffic data
//  Separates WiFi and Cellular traffic
//

import Foundation
import SwiftData

@Model
class TrafficLog {
    var id: UUID
    var date: Date
    var intervalType: String  // "snapshot", "hourly", "daily"
    
    // WiFi traffic
    var wifiUploadBytes: Int64
    var wifiDownloadBytes: Int64
    
    // Cellular traffic
    var cellularUploadBytes: Int64
    var cellularDownloadBytes: Int64
    
    // Combined (for backwards compatibility)
    var uploadBytes: Int64
    var downloadBytes: Int64
    
    // System-level totals at this point (for delta calculation)
    var systemUploadTotal: UInt64
    var systemDownloadTotal: UInt64
    
    init(
        date: Date = Date(),
        wifiUploadBytes: Int64 = 0,
        wifiDownloadBytes: Int64 = 0,
        cellularUploadBytes: Int64 = 0,
        cellularDownloadBytes: Int64 = 0,
        intervalType: String = "snapshot",
        systemUploadTotal: UInt64 = 0,
        systemDownloadTotal: UInt64 = 0
    ) {
        self.id = UUID()
        self.date = date
        self.intervalType = intervalType
        self.wifiUploadBytes = wifiUploadBytes
        self.wifiDownloadBytes = wifiDownloadBytes
        self.cellularUploadBytes = cellularUploadBytes
        self.cellularDownloadBytes = cellularDownloadBytes
        self.uploadBytes = wifiUploadBytes + cellularUploadBytes
        self.downloadBytes = wifiDownloadBytes + cellularDownloadBytes
        self.systemUploadTotal = systemUploadTotal
        self.systemDownloadTotal = systemDownloadTotal
    }
}

// MARK: - Computed Properties
extension TrafficLog {
    // Combined
    var uploadMB: Double { Double(uploadBytes) / (1024 * 1024) }
    var downloadMB: Double { Double(downloadBytes) / (1024 * 1024) }
    var totalMB: Double { uploadMB + downloadMB }
    
    // WiFi
    var wifiUploadMB: Double { Double(wifiUploadBytes) / (1024 * 1024) }
    var wifiDownloadMB: Double { Double(wifiDownloadBytes) / (1024 * 1024) }
    var wifiTotalMB: Double { wifiUploadMB + wifiDownloadMB }
    
    // Cellular
    var cellularUploadMB: Double { Double(cellularUploadBytes) / (1024 * 1024) }
    var cellularDownloadMB: Double { Double(cellularDownloadBytes) / (1024 * 1024) }
    var cellularTotalMB: Double { cellularUploadMB + cellularDownloadMB }
    
    var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
