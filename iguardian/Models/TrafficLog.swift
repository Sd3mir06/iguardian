//
//  TrafficLog.swift
//  iguardian
//
//  Persistent storage for network traffic data
//

import Foundation
import SwiftData

@Model
class TrafficLog {
    var id: UUID
    var date: Date
    var uploadBytes: Int64
    var downloadBytes: Int64
    var intervalType: String  // "snapshot", "hourly", "daily"
    
    // For tracking deltas
    var systemUploadTotal: UInt64  // System-level total at this point
    var systemDownloadTotal: UInt64
    
    init(
        date: Date = Date(),
        uploadBytes: Int64 = 0,
        downloadBytes: Int64 = 0,
        intervalType: String = "snapshot",
        systemUploadTotal: UInt64 = 0,
        systemDownloadTotal: UInt64 = 0
    ) {
        self.id = UUID()
        self.date = date
        self.uploadBytes = uploadBytes
        self.downloadBytes = downloadBytes
        self.intervalType = intervalType
        self.systemUploadTotal = systemUploadTotal
        self.systemDownloadTotal = systemDownloadTotal
    }
}

// MARK: - Computed Properties
extension TrafficLog {
    var uploadMB: Double {
        Double(uploadBytes) / (1024 * 1024)
    }
    
    var downloadMB: Double {
        Double(downloadBytes) / (1024 * 1024)
    }
    
    var totalMB: Double {
        uploadMB + downloadMB
    }
    
    var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
