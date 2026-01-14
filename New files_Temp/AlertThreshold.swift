//
//  AlertThreshold.swift
//  iguardian
//
//  IMPROVED: More realistic thresholds to prevent false alarms
//

import Foundation
import SwiftUI
import Combine

struct AlertThreshold: Codable, Identifiable {
    var id: String { metric.rawValue }
    var metric: ThresholdMetric
    var value: Double
    var isEnabled: Bool
    
    enum ThresholdMetric: String, Codable, CaseIterable {
        case uploadRate = "upload_rate"
        case downloadRate = "download_rate"
        case cpuUsage = "cpu_usage"
        case batteryDrain = "battery_drain"
        case totalUpload = "total_upload"
        case totalDownload = "total_download"
        
        var title: String {
            switch self {
            case .uploadRate: return "Sustained Upload Rate"
            case .downloadRate: return "Sustained Download Rate"
            case .cpuUsage: return "CPU While Idle"
            case .batteryDrain: return "Battery Drain While Idle"
            case .totalUpload: return "Total Upload (1 hour)"
            case .totalDownload: return "Total Download (1 hour)"
            }
        }
        
        var description: String {
            switch self {
            case .uploadRate: return "Alert when upload rate sustains above this"
            case .downloadRate: return "Alert when download rate sustains above this"
            case .cpuUsage: return "Alert when CPU stays high while phone is idle"
            case .batteryDrain: return "Alert when battery drains fast while idle"
            case .totalUpload: return "Alert when total data uploaded exceeds this in 1 hour"
            case .totalDownload: return "Alert when total data downloaded exceeds this in 1 hour"
            }
        }
        
        var icon: String {
            switch self {
            case .uploadRate: return "arrow.up.circle"
            case .downloadRate: return "arrow.down.circle"
            case .cpuUsage: return "cpu"
            case .batteryDrain: return "battery.50"
            case .totalUpload: return "arrow.up.doc.fill"
            case .totalDownload: return "arrow.down.doc.fill"
            }
        }
        
        var unit: String {
            switch self {
            case .uploadRate, .downloadRate: return "MB/h"
            case .cpuUsage: return "%"
            case .batteryDrain: return "%/h"
            case .totalUpload, .totalDownload: return "MB"
            }
        }
        
        // IMPROVED: More realistic defaults
        var defaultValue: Double {
            switch self {
            case .uploadRate: return 200     // 200 MB/h sustained = suspicious
            case .downloadRate: return 500   // 500 MB/h sustained = suspicious
            case .cpuUsage: return 50        // 50% CPU while idle = very suspicious
            case .batteryDrain: return 10    // 10%/h while idle = suspicious
            case .totalUpload: return 100    // 100 MB uploaded in 1h while idle = suspicious
            case .totalDownload: return 300  // 300 MB downloaded in 1h while idle
            }
        }
        
        var range: ClosedRange<Double> {
            switch self {
            case .uploadRate, .downloadRate: return 50...2000
            case .cpuUsage: return 20...90
            case .batteryDrain: return 5...30
            case .totalUpload: return 50...1000
            case .totalDownload: return 100...2000
            }
        }
        
        var step: Double {
            switch self {
            case .uploadRate, .downloadRate: return 50
            case .cpuUsage: return 5
            case .batteryDrain: return 1
            case .totalUpload, .totalDownload: return 50
            }
        }
    }
    
    static var defaults: [AlertThreshold] {
        ThresholdMetric.allCases.map { metric in
            AlertThreshold(
                metric: metric,
                value: metric.defaultValue,
                isEnabled: true
            )
        }
    }
}

// MARK: - Threshold Storage
class ThresholdManager: ObservableObject {
    static let shared = ThresholdManager()
    
    @Published var thresholds: [AlertThreshold] {
        didSet { save() }
    }
    
    private let key = "alert_thresholds_v2" // Changed key to reset to new defaults
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([AlertThreshold].self, from: data) {
            thresholds = decoded
        } else {
            thresholds = AlertThreshold.defaults
        }
    }
    
    func threshold(for metric: AlertThreshold.ThresholdMetric) -> AlertThreshold {
        thresholds.first { $0.metric == metric } ?? AlertThreshold(
            metric: metric,
            value: metric.defaultValue,
            isEnabled: true
        )
    }
    
    func update(_ threshold: AlertThreshold) {
        if let index = thresholds.firstIndex(where: { $0.metric == threshold.metric }) {
            thresholds[index] = threshold
        }
    }
    
    func reset() {
        thresholds = AlertThreshold.defaults
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(thresholds) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}
