//
//  DashboardView.swift
//  iguardian
//
//  Main dashboard screen showing threat score and all metrics
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var monitoringManager: MonitoringManager
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Threat Score Ring
                    ThreatScoreRing(
                        score: monitoringManager.threatScore,
                        threatLevel: monitoringManager.threatLevel
                    )
                    .frame(width: 200, height: 200)
                    .padding(.top, 20)
                    
                    // Status indicator
                    StatusBadge(
                        isMonitoring: monitoringManager.isMonitoring,
                        threatLevel: monitoringManager.threatLevel
                    )
                    
                    // Metric Cards Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        UploadMetricCard(
                            bytesPerSecond: monitoringManager.currentSnapshot.uploadBytesPerSecond,
                            status: getUploadStatus()
                        )
                        
                        DownloadMetricCard(
                            bytesPerSecond: monitoringManager.currentSnapshot.downloadBytesPerSecond
                        )
                        
                        CPUMetricCard(
                            usagePercent: monitoringManager.currentSnapshot.cpuUsagePercent,
                            status: getCPUStatus()
                        )
                        
                        BatteryMetricCard(
                            drainRatePerHour: monitoringManager.currentSnapshot.batteryDrainPerHour,
                            status: getBatteryStatus()
                        )
                    }
                    .padding(.horizontal)
                    
                    // Thermal State
                    ThermalStatusCard(state: monitoringManager.currentSnapshot.thermalState)
                        .padding(.horizontal)
                    
                    // Activity Feed
                    ActivityFeed(entries: monitoringManager.recentActivity)
                        .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle("iGUARDIAN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        // Shield icon tapped - could show app info
                    } label: {
                        Image(systemName: "shield.checkered")
                            .font(.title2)
                            .foregroundColor(Theme.accentPrimary)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
            }
            .toolbarBackground(Theme.backgroundPrimary, for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .onAppear {
            if !monitoringManager.isMonitoring {
                monitoringManager.startMonitoring()
            }
        }
    }
    
    // MARK: - Status Helpers
    private func getUploadStatus() -> ThreatLevel {
        let bytes = monitoringManager.currentSnapshot.uploadBytesPerSecond
        if bytes > 2_000_000 { return .alert }
        if bytes > 500_000 { return .warning }
        return .normal
    }
    
    private func getCPUStatus() -> ThreatLevel {
        let cpu = monitoringManager.currentSnapshot.cpuUsagePercent
        if cpu > 60 { return .alert }
        if cpu > 30 { return .warning }
        return .normal
    }
    
    private func getBatteryStatus() -> ThreatLevel {
        let drain = monitoringManager.currentSnapshot.batteryDrainPerHour
        if drain > 10 { return .alert }
        if drain > 5 { return .warning }
        return .normal
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let isMonitoring: Bool
    let threatLevel: ThreatLevel
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isMonitoring ? threatLevel.color : Theme.textTertiary)
                .frame(width: 8, height: 8)
            
            Text(isMonitoring ? "Monitoring Active" : "Monitoring Paused")
                .font(Theme.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Theme.backgroundSecondary)
                .overlay(
                    Capsule()
                        .stroke(threatLevel.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Thermal Status Card
struct ThermalStatusCard: View {
    let state: ThermalState
    
    var body: some View {
        HStack {
            Image(systemName: "thermometer.medium")
                .font(.system(size: 20))
                .foregroundColor(state.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("THERMAL STATE")
                    .font(Theme.micro)
                    .foregroundColor(Theme.textTertiary)
                    .kerning(1.2)
                
                Text(state.rawValue)
                    .font(Theme.body)
                    .foregroundColor(state.color)
            }
            
            Spacer()
            
            // Visual indicator
            HStack(spacing: 4) {
                ForEach(0..<4) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index < thermalLevel ? state.color : Theme.backgroundTertiary)
                        .frame(width: 6, height: 16)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(Theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                        .stroke(state.color.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var thermalLevel: Int {
        switch state {
        case .nominal: return 1
        case .fair: return 2
        case .serious: return 3
        case .critical: return 4
        }
    }
}

// MARK: - Preview
#Preview {
    DashboardView(monitoringManager: MonitoringManager.shared)
        .preferredColorScheme(.dark)
}
