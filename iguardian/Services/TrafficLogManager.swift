//
//  TrafficLogManager.swift
//  iguardian
//
//  Manages persistent traffic logging and aggregation
//

import Foundation
import SwiftData
import Combine

@MainActor
class TrafficLogManager: ObservableObject {
    static let shared = TrafficLogManager()
    
    // MARK: - Published Properties
    @Published var todayUploadBytes: Int64 = 0
    @Published var todayDownloadBytes: Int64 = 0
    @Published var weekUploadBytes: Int64 = 0
    @Published var weekDownloadBytes: Int64 = 0
    @Published var monthUploadBytes: Int64 = 0
    @Published var monthDownloadBytes: Int64 = 0
    @Published var allTimeUploadBytes: Int64 = 0
    @Published var allTimeDownloadBytes: Int64 = 0
    
    // MARK: - Private Properties
    private var modelContext: ModelContext?
    private var lastSystemUpload: UInt64 = 0
    private var lastSystemDownload: UInt64 = 0
    private var lastRecordTime: Date?
    
    // UserDefaults keys for persistence between launches
    private let kLastSystemUpload = "traffic_last_system_upload"
    private let kLastSystemDownload = "traffic_last_system_download"
    private let kAllTimeUpload = "traffic_all_time_upload"
    private let kAllTimeDownload = "traffic_all_time_download"
    private let kTrackingStartDate = "traffic_tracking_start_date"
    
    private init() {
        loadPersistedValues()
    }
    
    // MARK: - Configuration
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadAggregates()
        
        // Set tracking start date if not set
        if UserDefaults.standard.object(forKey: kTrackingStartDate) == nil {
            UserDefaults.standard.set(Date(), forKey: kTrackingStartDate)
        }
        
        LogManager.shared.log("TrafficLogManager configured. All-time: Up=\(formatMB(allTimeUploadBytes)), Down=\(formatMB(allTimeDownloadBytes))", level: .info, category: "Traffic")
    }
    
    // MARK: - Public Methods
    
    /// Called by NetworkMonitor to record current system totals
    /// This calculates the delta since last reading and persists it
    func recordTraffic(systemUpload: UInt64, systemDownload: UInt64) {
        let now = Date()
        
        // If this is the first reading, just store the baseline
        if lastSystemUpload == 0 && lastSystemDownload == 0 {
            lastSystemUpload = systemUpload
            lastSystemDownload = systemDownload
            lastRecordTime = now
            savePersistedValues()
            return
        }
        
        // Calculate delta (handle counter reset after device reboot)
        let uploadDelta: Int64
        let downloadDelta: Int64
        
        if systemUpload >= lastSystemUpload {
            uploadDelta = Int64(systemUpload - lastSystemUpload)
        } else {
            // Counter was reset (device rebooted), treat current as the new delta
            uploadDelta = Int64(systemUpload)
        }
        
        if systemDownload >= lastSystemDownload {
            downloadDelta = Int64(systemDownload - lastSystemDownload)
        } else {
            downloadDelta = Int64(systemDownload)
        }
        
        // Only record if there's meaningful traffic (> 1KB)
        if uploadDelta > 1024 || downloadDelta > 1024 {
            // Create snapshot log entry
            let log = TrafficLog(
                date: now,
                uploadBytes: uploadDelta,
                downloadBytes: downloadDelta,
                intervalType: "snapshot",
                systemUploadTotal: systemUpload,
                systemDownloadTotal: systemDownload
            )
            
            modelContext?.insert(log)
            try? modelContext?.save()
            
            // Update aggregates
            todayUploadBytes += uploadDelta
            todayDownloadBytes += downloadDelta
            weekUploadBytes += uploadDelta
            weekDownloadBytes += downloadDelta
            monthUploadBytes += uploadDelta
            monthDownloadBytes += downloadDelta
            allTimeUploadBytes += uploadDelta
            allTimeDownloadBytes += downloadDelta
            
            LogManager.shared.log(
                "Traffic recorded: Up=+\(formatMB(uploadDelta)), Down=+\(formatMB(downloadDelta))",
                level: .debug,
                category: "Traffic"
            )
        }
        
        // Update baseline
        lastSystemUpload = systemUpload
        lastSystemDownload = systemDownload
        lastRecordTime = now
        savePersistedValues()
    }
    
    /// Reset all traffic stats
    func resetAllStats() {
        todayUploadBytes = 0
        todayDownloadBytes = 0
        weekUploadBytes = 0
        weekDownloadBytes = 0
        monthUploadBytes = 0
        monthDownloadBytes = 0
        allTimeUploadBytes = 0
        allTimeDownloadBytes = 0
        
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
        UserDefaults.standard.set(0, forKey: kAllTimeUpload)
        UserDefaults.standard.set(0, forKey: kAllTimeDownload)
        UserDefaults.standard.set(Date(), forKey: kTrackingStartDate)
        
        LogManager.shared.log("All traffic stats reset", level: .info, category: "Traffic")
    }
    
    /// Get tracking start date
    var trackingStartDate: Date {
        UserDefaults.standard.object(forKey: kTrackingStartDate) as? Date ?? Date()
    }
    
    /// Get daily breakdown for chart
    func getDailyBreakdown(days: Int = 7) -> [(date: Date, upload: Int64, download: Int64)] {
        guard let context = modelContext else { return [] }
        
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let predicate = #Predicate<TrafficLog> { log in
            log.date >= startDate
        }
        
        var descriptor = FetchDescriptor<TrafficLog>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.date)]
        
        guard let logs = try? context.fetch(descriptor) else { return [] }
        
        // Group by day
        var dailyTotals: [String: (upload: Int64, download: Int64)] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        for log in logs {
            let key = formatter.string(from: log.date)
            let existing = dailyTotals[key] ?? (0, 0)
            dailyTotals[key] = (existing.upload + log.uploadBytes, existing.download + log.downloadBytes)
        }
        
        // Convert to array sorted by date
        return dailyTotals.map { key, value in
            (date: formatter.date(from: key)!, upload: value.upload, download: value.download)
        }.sorted { $0.date < $1.date }
    }
    
    // MARK: - Computed Properties
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
    
    // MARK: - Private Methods
    private func loadPersistedValues() {
        lastSystemUpload = UInt64(UserDefaults.standard.integer(forKey: kLastSystemUpload))
        lastSystemDownload = UInt64(UserDefaults.standard.integer(forKey: kLastSystemDownload))
        allTimeUploadBytes = Int64(UserDefaults.standard.integer(forKey: kAllTimeUpload))
        allTimeDownloadBytes = Int64(UserDefaults.standard.integer(forKey: kAllTimeDownload))
    }
    
    private func savePersistedValues() {
        UserDefaults.standard.set(Int(lastSystemUpload), forKey: kLastSystemUpload)
        UserDefaults.standard.set(Int(lastSystemDownload), forKey: kLastSystemDownload)
        UserDefaults.standard.set(Int(allTimeUploadBytes), forKey: kAllTimeUpload)
        UserDefaults.standard.set(Int(allTimeDownloadBytes), forKey: kAllTimeDownload)
    }
    
    private func loadAggregates() {
        guard let context = modelContext else { return }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Start of today
        let startOfToday = calendar.startOfDay(for: now)
        
        // Start of week (Sunday)
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        
        // Start of month
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        // Fetch and aggregate
        do {
            let allLogs = try context.fetch(FetchDescriptor<TrafficLog>())
            
            todayUploadBytes = 0
            todayDownloadBytes = 0
            weekUploadBytes = 0
            weekDownloadBytes = 0
            monthUploadBytes = 0
            monthDownloadBytes = 0
            
            for log in allLogs {
                if log.date >= startOfToday {
                    todayUploadBytes += log.uploadBytes
                    todayDownloadBytes += log.downloadBytes
                }
                if log.date >= startOfWeek {
                    weekUploadBytes += log.uploadBytes
                    weekDownloadBytes += log.downloadBytes
                }
                if log.date >= startOfMonth {
                    monthUploadBytes += log.uploadBytes
                    monthDownloadBytes += log.downloadBytes
                }
            }
            
            // All-time comes from UserDefaults (persisted across sessions)
            allTimeUploadBytes = Int64(UserDefaults.standard.integer(forKey: kAllTimeUpload))
            allTimeDownloadBytes = Int64(UserDefaults.standard.integer(forKey: kAllTimeDownload))
            
        } catch {
            LogManager.shared.log("Failed to load traffic aggregates: \(error)", level: .error, category: "Traffic")
        }
    }
    
    private func formatMB(_ bytes: Int64) -> String {
        let mb = Double(bytes) / (1024 * 1024)
        if mb < 1 {
            return String(format: "%.0f KB", Double(bytes) / 1024)
        } else if mb < 1024 {
            return String(format: "%.1f MB", mb)
        } else {
            return String(format: "%.2f GB", mb / 1024)
        }
    }
}
