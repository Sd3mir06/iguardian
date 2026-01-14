//
//  TrafficLogManager.swift
//  iguardian
//
//  Manages persistent traffic logging and aggregation
//  Separates WiFi and Cellular traffic
//

import Foundation
import SwiftData
import Combine

@MainActor
class TrafficLogManager: ObservableObject {
    static let shared = TrafficLogManager()
    
    // MARK: - Published Properties (Combined)
    @Published var todayUploadBytes: Int64 = 0
    @Published var todayDownloadBytes: Int64 = 0
    @Published var weekUploadBytes: Int64 = 0
    @Published var weekDownloadBytes: Int64 = 0
    @Published var monthUploadBytes: Int64 = 0
    @Published var monthDownloadBytes: Int64 = 0
    @Published var allTimeUploadBytes: Int64 = 0
    @Published var allTimeDownloadBytes: Int64 = 0
    
    // MARK: - Published Properties (WiFi)
    @Published var todayWifiUploadBytes: Int64 = 0
    @Published var todayWifiDownloadBytes: Int64 = 0
    @Published var weekWifiUploadBytes: Int64 = 0
    @Published var weekWifiDownloadBytes: Int64 = 0
    @Published var monthWifiUploadBytes: Int64 = 0
    @Published var monthWifiDownloadBytes: Int64 = 0
    @Published var allTimeWifiUploadBytes: Int64 = 0
    @Published var allTimeWifiDownloadBytes: Int64 = 0
    
    // MARK: - Published Properties (Cellular)
    @Published var todayCellularUploadBytes: Int64 = 0
    @Published var todayCellularDownloadBytes: Int64 = 0
    @Published var weekCellularUploadBytes: Int64 = 0
    @Published var weekCellularDownloadBytes: Int64 = 0
    @Published var monthCellularUploadBytes: Int64 = 0
    @Published var monthCellularDownloadBytes: Int64 = 0
    @Published var allTimeCellularUploadBytes: Int64 = 0
    @Published var allTimeCellularDownloadBytes: Int64 = 0
    
    // MARK: - Private Properties
    private var modelContext: ModelContext?
    private var lastWifiUpload: UInt64 = 0
    private var lastWifiDownload: UInt64 = 0
    private var lastCellularUpload: UInt64 = 0
    private var lastCellularDownload: UInt64 = 0
    private var lastRecordTime: Date?
    
    // UserDefaults keys
    private let kLastWifiUpload = "traffic_last_wifi_upload"
    private let kLastWifiDownload = "traffic_last_wifi_download"
    private let kLastCellularUpload = "traffic_last_cellular_upload"
    private let kLastCellularDownload = "traffic_last_cellular_download"
    private let kAllTimeUpload = "traffic_all_time_upload"
    private let kAllTimeDownload = "traffic_all_time_download"
    private let kAllTimeWifiUpload = "traffic_all_time_wifi_upload"
    private let kAllTimeWifiDownload = "traffic_all_time_wifi_download"
    private let kAllTimeCellularUpload = "traffic_all_time_cellular_upload"
    private let kAllTimeCellularDownload = "traffic_all_time_cellular_download"
    private let kTrackingStartDate = "traffic_tracking_start_date"
    
    private init() {
        loadPersistedValues()
    }
    
    // MARK: - Configuration
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadAggregates()
        
        if UserDefaults.standard.object(forKey: kTrackingStartDate) == nil {
            UserDefaults.standard.set(Date(), forKey: kTrackingStartDate)
        }
        
        LogManager.shared.log(
            "TrafficLogManager configured. WiFi: \(formatMB(allTimeWifiUploadBytes + allTimeWifiDownloadBytes)), Cellular: \(formatMB(allTimeCellularUploadBytes + allTimeCellularDownloadBytes))",
            level: .info,
            category: "Traffic"
        )
    }
    
    // MARK: - Public Methods
    
    /// Called by NetworkMonitor to record traffic with WiFi/Cellular breakdown
    func recordTraffic(
        wifiUpload: UInt64,
        wifiDownload: UInt64,
        cellularUpload: UInt64,
        cellularDownload: UInt64
    ) {
        let now = Date()
        
        // First reading - just store baseline
        if lastWifiUpload == 0 && lastWifiDownload == 0 && lastCellularUpload == 0 && lastCellularDownload == 0 {
            lastWifiUpload = wifiUpload
            lastWifiDownload = wifiDownload
            lastCellularUpload = cellularUpload
            lastCellularDownload = cellularDownload
            lastRecordTime = now
            savePersistedValues()
            return
        }
        
        // Calculate deltas (handle counter reset after device reboot)
        let wifiUpDelta = wifiUpload >= lastWifiUpload ? Int64(wifiUpload - lastWifiUpload) : Int64(wifiUpload)
        let wifiDownDelta = wifiDownload >= lastWifiDownload ? Int64(wifiDownload - lastWifiDownload) : Int64(wifiDownload)
        let cellularUpDelta = cellularUpload >= lastCellularUpload ? Int64(cellularUpload - lastCellularUpload) : Int64(cellularUpload)
        let cellularDownDelta = cellularDownload >= lastCellularDownload ? Int64(cellularDownload - lastCellularDownload) : Int64(cellularDownload)
        
        let totalUpDelta = wifiUpDelta + cellularUpDelta
        let totalDownDelta = wifiDownDelta + cellularDownDelta
        
        // Only record if there's meaningful traffic (> 1KB total)
        if totalUpDelta > 1024 || totalDownDelta > 1024 {
            let log = TrafficLog(
                date: now,
                wifiUploadBytes: wifiUpDelta,
                wifiDownloadBytes: wifiDownDelta,
                cellularUploadBytes: cellularUpDelta,
                cellularDownloadBytes: cellularDownDelta,
                intervalType: "snapshot",
                systemUploadTotal: wifiUpload + cellularUpload,
                systemDownloadTotal: wifiDownload + cellularDownload
            )
            
            modelContext?.insert(log)
            try? modelContext?.save()
            
            // Update WiFi aggregates
            todayWifiUploadBytes += wifiUpDelta
            todayWifiDownloadBytes += wifiDownDelta
            weekWifiUploadBytes += wifiUpDelta
            weekWifiDownloadBytes += wifiDownDelta
            monthWifiUploadBytes += wifiUpDelta
            monthWifiDownloadBytes += wifiDownDelta
            allTimeWifiUploadBytes += wifiUpDelta
            allTimeWifiDownloadBytes += wifiDownDelta
            
            // Update Cellular aggregates
            todayCellularUploadBytes += cellularUpDelta
            todayCellularDownloadBytes += cellularDownDelta
            weekCellularUploadBytes += cellularUpDelta
            weekCellularDownloadBytes += cellularDownDelta
            monthCellularUploadBytes += cellularUpDelta
            monthCellularDownloadBytes += cellularDownDelta
            allTimeCellularUploadBytes += cellularUpDelta
            allTimeCellularDownloadBytes += cellularDownDelta
            
            // Update combined aggregates
            todayUploadBytes += totalUpDelta
            todayDownloadBytes += totalDownDelta
            weekUploadBytes += totalUpDelta
            weekDownloadBytes += totalDownDelta
            monthUploadBytes += totalUpDelta
            monthDownloadBytes += totalDownDelta
            allTimeUploadBytes += totalUpDelta
            allTimeDownloadBytes += totalDownDelta
            
            LogManager.shared.log(
                "Traffic: WiFi +\(formatMB(wifiUpDelta + wifiDownDelta)), Cellular +\(formatMB(cellularUpDelta + cellularDownDelta))",
                level: .debug,
                category: "Traffic"
            )
        }
        
        // Update baseline
        lastWifiUpload = wifiUpload
        lastWifiDownload = wifiDownload
        lastCellularUpload = cellularUpload
        lastCellularDownload = cellularDownload
        lastRecordTime = now
        savePersistedValues()
    }
    
    /// Legacy method for backwards compatibility
    func recordTraffic(systemUpload: UInt64, systemDownload: UInt64) {
        // Call the new method with combined values (treat as WiFi for legacy calls)
        recordTraffic(wifiUpload: systemUpload, wifiDownload: systemDownload, cellularUpload: 0, cellularDownload: 0)
    }
    
    /// Reset all traffic stats
    func resetAllStats() {
        // Combined
        todayUploadBytes = 0
        todayDownloadBytes = 0
        weekUploadBytes = 0
        weekDownloadBytes = 0
        monthUploadBytes = 0
        monthDownloadBytes = 0
        allTimeUploadBytes = 0
        allTimeDownloadBytes = 0
        
        // WiFi
        todayWifiUploadBytes = 0
        todayWifiDownloadBytes = 0
        weekWifiUploadBytes = 0
        weekWifiDownloadBytes = 0
        monthWifiUploadBytes = 0
        monthWifiDownloadBytes = 0
        allTimeWifiUploadBytes = 0
        allTimeWifiDownloadBytes = 0
        
        // Cellular
        todayCellularUploadBytes = 0
        todayCellularDownloadBytes = 0
        weekCellularUploadBytes = 0
        weekCellularDownloadBytes = 0
        monthCellularUploadBytes = 0
        monthCellularDownloadBytes = 0
        allTimeCellularUploadBytes = 0
        allTimeCellularDownloadBytes = 0
        
        // Delete all logs
        if let context = modelContext {
            do {
                try context.delete(model: TrafficLog.self)
                try context.save()
            } catch {
                LogManager.shared.log("Failed to delete traffic logs: \(error)", level: .error, category: "Traffic")
            }
        }
        
        // Reset UserDefaults
        let defaults = UserDefaults.standard
        defaults.set(0, forKey: kAllTimeUpload)
        defaults.set(0, forKey: kAllTimeDownload)
        defaults.set(0, forKey: kAllTimeWifiUpload)
        defaults.set(0, forKey: kAllTimeWifiDownload)
        defaults.set(0, forKey: kAllTimeCellularUpload)
        defaults.set(0, forKey: kAllTimeCellularDownload)
        defaults.set(Date(), forKey: kTrackingStartDate)
        
        LogManager.shared.log("All traffic stats reset", level: .info, category: "Traffic")
    }
    
    var trackingStartDate: Date {
        UserDefaults.standard.object(forKey: kTrackingStartDate) as? Date ?? Date()
    }
    
    // MARK: - Computed Properties (MB)
    // Combined
    var todayUploadMB: Double { Double(todayUploadBytes) / (1024 * 1024) }
    var todayDownloadMB: Double { Double(todayDownloadBytes) / (1024 * 1024) }
    var weekUploadMB: Double { Double(weekUploadBytes) / (1024 * 1024) }
    var weekDownloadMB: Double { Double(weekDownloadBytes) / (1024 * 1024) }
    var monthUploadMB: Double { Double(monthUploadBytes) / (1024 * 1024) }
    var monthDownloadMB: Double { Double(monthDownloadBytes) / (1024 * 1024) }
    var allTimeUploadMB: Double { Double(allTimeUploadBytes) / (1024 * 1024) }
    var allTimeDownloadMB: Double { Double(allTimeDownloadBytes) / (1024 * 1024) }
    
    var todayTotalMB: Double { todayUploadMB + todayDownloadMB }
    var weekTotalMB: Double { weekUploadMB + weekDownloadMB }
    var monthTotalMB: Double { monthUploadMB + monthDownloadMB }
    var allTimeTotalMB: Double { allTimeUploadMB + allTimeDownloadMB }
    
    // WiFi
    var todayWifiUploadMB: Double { Double(todayWifiUploadBytes) / (1024 * 1024) }
    var todayWifiDownloadMB: Double { Double(todayWifiDownloadBytes) / (1024 * 1024) }
    var todayWifiTotalMB: Double { todayWifiUploadMB + todayWifiDownloadMB }
    var allTimeWifiTotalMB: Double { Double(allTimeWifiUploadBytes + allTimeWifiDownloadBytes) / (1024 * 1024) }
    
    // Cellular
    var todayCellularUploadMB: Double { Double(todayCellularUploadBytes) / (1024 * 1024) }
    var todayCellularDownloadMB: Double { Double(todayCellularDownloadBytes) / (1024 * 1024) }
    var todayCellularTotalMB: Double { todayCellularUploadMB + todayCellularDownloadMB }
    var allTimeCellularTotalMB: Double { Double(allTimeCellularUploadBytes + allTimeCellularDownloadBytes) / (1024 * 1024) }
    
    // MARK: - Private Methods
    private func loadPersistedValues() {
        let defaults = UserDefaults.standard
        lastWifiUpload = UInt64(defaults.integer(forKey: kLastWifiUpload))
        lastWifiDownload = UInt64(defaults.integer(forKey: kLastWifiDownload))
        lastCellularUpload = UInt64(defaults.integer(forKey: kLastCellularUpload))
        lastCellularDownload = UInt64(defaults.integer(forKey: kLastCellularDownload))
        
        allTimeUploadBytes = Int64(defaults.integer(forKey: kAllTimeUpload))
        allTimeDownloadBytes = Int64(defaults.integer(forKey: kAllTimeDownload))
        allTimeWifiUploadBytes = Int64(defaults.integer(forKey: kAllTimeWifiUpload))
        allTimeWifiDownloadBytes = Int64(defaults.integer(forKey: kAllTimeWifiDownload))
        allTimeCellularUploadBytes = Int64(defaults.integer(forKey: kAllTimeCellularUpload))
        allTimeCellularDownloadBytes = Int64(defaults.integer(forKey: kAllTimeCellularDownload))
    }
    
    private func savePersistedValues() {
        let defaults = UserDefaults.standard
        defaults.set(Int(lastWifiUpload), forKey: kLastWifiUpload)
        defaults.set(Int(lastWifiDownload), forKey: kLastWifiDownload)
        defaults.set(Int(lastCellularUpload), forKey: kLastCellularUpload)
        defaults.set(Int(lastCellularDownload), forKey: kLastCellularDownload)
        
        defaults.set(Int(allTimeUploadBytes), forKey: kAllTimeUpload)
        defaults.set(Int(allTimeDownloadBytes), forKey: kAllTimeDownload)
        defaults.set(Int(allTimeWifiUploadBytes), forKey: kAllTimeWifiUpload)
        defaults.set(Int(allTimeWifiDownloadBytes), forKey: kAllTimeWifiDownload)
        defaults.set(Int(allTimeCellularUploadBytes), forKey: kAllTimeCellularUpload)
        defaults.set(Int(allTimeCellularDownloadBytes), forKey: kAllTimeCellularDownload)
    }
    
    private func loadAggregates() {
        guard let context = modelContext else { return }
        
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        do {
            let allLogs = try context.fetch(FetchDescriptor<TrafficLog>())
            
            // Reset
            todayUploadBytes = 0; todayDownloadBytes = 0
            weekUploadBytes = 0; weekDownloadBytes = 0
            monthUploadBytes = 0; monthDownloadBytes = 0
            todayWifiUploadBytes = 0; todayWifiDownloadBytes = 0
            weekWifiUploadBytes = 0; weekWifiDownloadBytes = 0
            monthWifiUploadBytes = 0; monthWifiDownloadBytes = 0
            todayCellularUploadBytes = 0; todayCellularDownloadBytes = 0
            weekCellularUploadBytes = 0; weekCellularDownloadBytes = 0
            monthCellularUploadBytes = 0; monthCellularDownloadBytes = 0
            
            for log in allLogs {
                if log.date >= startOfToday {
                    todayUploadBytes += log.uploadBytes
                    todayDownloadBytes += log.downloadBytes
                    todayWifiUploadBytes += log.wifiUploadBytes
                    todayWifiDownloadBytes += log.wifiDownloadBytes
                    todayCellularUploadBytes += log.cellularUploadBytes
                    todayCellularDownloadBytes += log.cellularDownloadBytes
                }
                if log.date >= startOfWeek {
                    weekUploadBytes += log.uploadBytes
                    weekDownloadBytes += log.downloadBytes
                    weekWifiUploadBytes += log.wifiUploadBytes
                    weekWifiDownloadBytes += log.wifiDownloadBytes
                    weekCellularUploadBytes += log.cellularUploadBytes
                    weekCellularDownloadBytes += log.cellularDownloadBytes
                }
                if log.date >= startOfMonth {
                    monthUploadBytes += log.uploadBytes
                    monthDownloadBytes += log.downloadBytes
                    monthWifiUploadBytes += log.wifiUploadBytes
                    monthWifiDownloadBytes += log.wifiDownloadBytes
                    monthCellularUploadBytes += log.cellularUploadBytes
                    monthCellularDownloadBytes += log.cellularDownloadBytes
                }
            }
            
            // All-time from UserDefaults
            let defaults = UserDefaults.standard
            allTimeUploadBytes = Int64(defaults.integer(forKey: kAllTimeUpload))
            allTimeDownloadBytes = Int64(defaults.integer(forKey: kAllTimeDownload))
            allTimeWifiUploadBytes = Int64(defaults.integer(forKey: kAllTimeWifiUpload))
            allTimeWifiDownloadBytes = Int64(defaults.integer(forKey: kAllTimeWifiDownload))
            allTimeCellularUploadBytes = Int64(defaults.integer(forKey: kAllTimeCellularUpload))
            allTimeCellularDownloadBytes = Int64(defaults.integer(forKey: kAllTimeCellularDownload))
            
        } catch {
            LogManager.shared.log("Failed to load traffic aggregates: \(error)", level: .error, category: "Traffic")
        }
    }
    
    private func formatMB(_ bytes: Int64) -> String {
        let mb = Double(bytes) / (1024 * 1024)
        if mb < 1 { return String(format: "%.0f KB", Double(bytes) / 1024) }
        else if mb < 1024 { return String(format: "%.1f MB", mb) }
        else { return String(format: "%.2f GB", mb / 1024) }
    }
}
