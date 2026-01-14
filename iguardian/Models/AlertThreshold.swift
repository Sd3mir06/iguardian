//
//  AlertThreshold.swift
//  iguardian
//
//  Custom alert threshold settings
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
            case .uploadRate: return "Instant Upload Rate"
            case .downloadRate: return "Instant Download Rate"
            case .cpuUsage: return "CPU Usage"
            case .batteryDrain: return "Battery Drain"
            case .totalUpload: return "Last 1h Total Upload"
            case .totalDownload: return "Last 1h Total Download"
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
            case .uploadRate, .downloadRate: return "MB/h (rate)"
            case .cpuUsage: return "%"
            case .batteryDrain: return "%/h"
            case .totalUpload, .totalDownload: return "MB (limit)"
            }
        }
        
        var defaultValue: Double {
            switch self {
            case .uploadRate: return 100     // 100 MB/h rate equiv
            case .downloadRate: return 200    // 200 MB/h rate equiv
            case .cpuUsage: return 60         // 60%
            case .batteryDrain: return 8      // 8%/h
            case .totalUpload: return 200     // 200 MB in 1h
            case .totalDownload: return 500    // 500 MB in 1h
            }
        }
        
        var range: ClosedRange<Double> {
            switch self {
            case .uploadRate, .downloadRate: return 10...1000
            case .cpuUsage: return 10...95
            case .batteryDrain: return 2...50
            case .totalUpload: return 50...2000
            case .totalDownload: return 100...5000
            }
        }
        
        var step: Double {
            switch self {
            case .uploadRate, .downloadRate: return 50
            case .cpuUsage: return 5
            case .batteryDrain: return 1
            case .totalUpload, .totalDownload: return 100
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
    
    private let key = "alert_thresholds"
    
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
