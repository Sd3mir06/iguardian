//
//  CommunityManager.swift
//  iguardian
//
//  Anonymous community benchmarking
//

import Foundation
import Combine
import Combine
import SwiftUI

// MARK: - Community Statistics
struct CommunityStats: Codable {
    let averageIdleUpload: Double      // MB/hour
    let averageIdleDownload: Double    // MB/hour
    let averageIdleCPU: Double         // percentage
    let averageBatteryDrain: Double    // %/hour
    let averageThreatScore: Double     // 0-100
    let totalUsers: Int
    let lastUpdated: Date
    
    // Percentiles for comparison
    let uploadPercentiles: Percentiles
    let downloadPercentiles: Percentiles
    let cpuPercentiles: Percentiles
    let batteryPercentiles: Percentiles
    
    struct Percentiles: Codable {
        let p25: Double
        let p50: Double
        let p75: Double
        let p90: Double
    }
}

// MARK: - User's Stats for Comparison
struct UserDeviceStats {
    var averageIdleUpload: Double = 0
    var averageIdleDownload: Double = 0
    var averageIdleCPU: Double = 0
    var averageBatteryDrain: Double = 0
    var averageThreatScore: Double = 0
}

// MARK: - Comparison Result
struct ComparisonResult {
    let metric: String
    let userValue: Double
    let communityAverage: Double
    let percentile: Int  // Which percentile the user falls into
    let status: ComparisonStatus
    
    enum ComparisonStatus {
        case excellent  // Better than 75% of users
        case good       // Better than 50%
        case average    // 25-50%
        case high       // Higher than 75%
        case concerning // Higher than 90%
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .cyan
            case .average: return .gray
            case .high: return .orange
            case .concerning: return .red
            }
        }
        
        var label: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .average: return "Average"
            case .high: return "High"
            case .concerning: return "Concerning"
            }
        }
    }
}

// MARK: - Community Manager
@MainActor
class CommunityManager: ObservableObject {
    static let shared = CommunityManager()
    
    @Published var communityStats: CommunityStats?
    @Published var userStats: UserDeviceStats = UserDeviceStats()
    @Published var comparisons: [ComparisonResult] = []
    @Published var isLoading = false
    @Published var lastSyncDate: Date?
    
    // Privacy: User must opt-in
    @AppStorage("community_optIn") var isOptedIn = false
    
    private init() {}
    
    // MARK: - Fetch Community Stats
    func fetchCommunityStats() async {
        guard isOptedIn else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        // In production, this would fetch from your backend
        // For now, use mock data
        communityStats = mockCommunityStats()
        lastSyncDate = Date()
        
        calculateComparisons()
    }
    
    // MARK: - Calculate Comparisons
    private func calculateComparisons() {
        guard let stats = communityStats else { return }
        
        comparisons = [
            ComparisonResult(
                metric: "Upload (Idle)",
                userValue: userStats.averageIdleUpload,
                communityAverage: stats.averageIdleUpload,
                percentile: calculatePercentile(userStats.averageIdleUpload, stats.uploadPercentiles),
                status: determineStatus(userStats.averageIdleUpload, stats.uploadPercentiles, higherIsBad: true)
            ),
            ComparisonResult(
                metric: "Download (Idle)",
                userValue: userStats.averageIdleDownload,
                communityAverage: stats.averageIdleDownload,
                percentile: calculatePercentile(userStats.averageIdleDownload, stats.downloadPercentiles),
                status: determineStatus(userStats.averageIdleDownload, stats.downloadPercentiles, higherIsBad: true)
            ),
            ComparisonResult(
                metric: "CPU (Idle)",
                userValue: userStats.averageIdleCPU,
                communityAverage: stats.averageIdleCPU,
                percentile: calculatePercentile(userStats.averageIdleCPU, stats.cpuPercentiles),
                status: determineStatus(userStats.averageIdleCPU, stats.cpuPercentiles, higherIsBad: true)
            ),
            ComparisonResult(
                metric: "Battery Drain",
                userValue: userStats.averageBatteryDrain,
                communityAverage: stats.averageBatteryDrain,
                percentile: calculatePercentile(userStats.averageBatteryDrain, stats.batteryPercentiles),
                status: determineStatus(userStats.averageBatteryDrain, stats.batteryPercentiles, higherIsBad: true)
            )
        ]
    }
    
    private func calculatePercentile(_ value: Double, _ percentiles: CommunityStats.Percentiles) -> Int {
        if value <= percentiles.p25 { return 25 }
        if value <= percentiles.p50 { return 50 }
        if value <= percentiles.p75 { return 75 }
        if value <= percentiles.p90 { return 90 }
        return 95
    }
    
    private func determineStatus(_ value: Double, _ percentiles: CommunityStats.Percentiles, higherIsBad: Bool) -> ComparisonResult.ComparisonStatus {
        let percentile = calculatePercentile(value, percentiles)
        
        if higherIsBad {
            switch percentile {
            case 0...25: return .excellent
            case 26...50: return .good
            case 51...75: return .average
            case 76...90: return .high
            default: return .concerning
            }
        } else {
            switch percentile {
            case 0...25: return .concerning
            case 26...50: return .high
            case 51...75: return .average
            case 76...90: return .good
            default: return .excellent
            }
        }
    }
    
    // MARK: - Mock Data
    private func mockCommunityStats() -> CommunityStats {
        CommunityStats(
            averageIdleUpload: 3.2,
            averageIdleDownload: 8.5,
            averageIdleCPU: 4.5,
            averageBatteryDrain: 1.2,
            averageThreatScore: 8,
            totalUsers: 12847,
            lastUpdated: Date(),
            uploadPercentiles: .init(p25: 1.5, p50: 3.0, p75: 6.0, p90: 15.0),
            downloadPercentiles: .init(p25: 4.0, p50: 8.0, p75: 15.0, p90: 30.0),
            cpuPercentiles: .init(p25: 2.0, p50: 4.0, p75: 8.0, p90: 15.0),
            batteryPercentiles: .init(p25: 0.5, p50: 1.0, p75: 2.0, p90: 4.0)
        )
    }
}
