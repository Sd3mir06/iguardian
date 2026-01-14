//
//  DashboardView.swift
//  iguardian
//
//  Main dashboard - IMPROVED with total data tracking
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var monitoringManager: MonitoringManager
    @State private var showSettings = false
    @State private var showDebug = false
    
    // Get threshold values
    @ObservedObject private var thresholds = ThresholdManager.shared
    
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
                    
                    // OPTION 1: Full-width Network Summary Card
                    NetworkSummaryCard(
                        uploadRate: monitoringManager.networkMonitor.uploadBytesPerSecond,
                        downloadRate: monitoringManager.networkMonitor.downloadBytesPerSecond,
                        uploadTotalMB: monitoringManager.networkMonitor.lastHourUploadMB,
                        downloadTotalMB: monitoringManager.networkMonitor.lastHourDownloadMB,
                        uploadThresholdMB: thresholds.threshold(for: .totalUpload).value,
                        downloadThresholdMB: thresholds.threshold(for: .totalDownload).value,
                        status: getNetworkStatus()
                    )
                    .padding(.horizontal)
                    
                    // CPU & Battery Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
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
                    
                    // Session Stats Card
                    SessionStatsCard(networkMonitor: monitoringManager.networkMonitor)
                        .padding(.horizontal)
                    
                    // Activity Feed
                    ActivityFeed(entries: monitoringManager.recentActivity)
                        .padding(.horizontal)
                    
                    // Sleep Guard Widget
                    SleepGuardDashboardWidget()
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
                        showDebug = true
                        LogManager.shared.log("Opening Debug Console", level: .debug, category: "UI")
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
            .sheet(isPresented: $showDebug) {
                DebugConsoleView()
            }
        }
        .onAppear {
            if !monitoringManager.isMonitoring {
                monitoringManager.startMonitoring()
                LogManager.shared.log("Started monitoring from Dashboard", level: .info, category: "Monitoring")
            }
        }
    }
    
    // MARK: - Status Helpers
    private func getNetworkStatus() -> ThreatLevel {
        let uploadMB = monitoringManager.networkMonitor.lastHourUploadMB
        let downloadMB = monitoringManager.networkMonitor.lastHourDownloadMB
        let uploadThreshold = thresholds.threshold(for: .totalUpload).value
        let downloadThreshold = thresholds.threshold(for: .totalDownload).value
        
        // Check if either exceeds threshold
        if uploadMB > uploadThreshold || downloadMB > downloadThreshold {
            return .alert
        }
        
        // Check if approaching threshold (70%)
        if uploadMB > uploadThreshold * 0.7 || downloadMB > downloadThreshold * 0.7 {
            return .warning
        }
        
        return .normal
    }
    
    private func getUploadStatus() -> ThreatLevel {
        let totalMB = monitoringManager.networkMonitor.lastHourUploadMB
        let threshold = thresholds.threshold(for: .totalUpload).value
        if totalMB > threshold { return .alert }
        if totalMB > threshold * 0.7 { return .warning }
        return .normal
    }
    
    private func getDownloadStatus() -> ThreatLevel {
        let totalMB = monitoringManager.networkMonitor.lastHourDownloadMB
        let threshold = thresholds.threshold(for: .totalDownload).value
        if totalMB > threshold { return .alert }
        if totalMB > threshold * 0.7 { return .warning }
        return .normal
    }
    
    private func getCPUStatus() -> ThreatLevel {
        let cpu = monitoringManager.currentSnapshot.cpuUsagePercent
        let threshold = thresholds.threshold(for: .cpuUsage).value
        if cpu > threshold { return .alert }
        if cpu > threshold * 0.7 { return .warning }
        return .normal
    }
    
    private func getBatteryStatus() -> ThreatLevel {
        let drain = Double(monitoringManager.currentSnapshot.batteryDrainPerHour)
        let threshold = thresholds.threshold(for: .batteryDrain).value
        if drain > threshold { return .alert }
        if drain > threshold * 0.7 { return .warning }
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

// MARK: - Session Stats Card
struct SessionStatsCard: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.accentSecondary)
                
                Text("SESSION STATS")
                    .font(Theme.micro)
                    .foregroundColor(Theme.textTertiary)
                    .kerning(1.2)
                
                Spacer()
                
                Button {
                    networkMonitor.resetSessionTotals()
                } label: {
                    Text("Reset")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.accentPrimary)
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 20) {
                // Session Duration
                VStack(alignment: .leading, spacing: 2) {
                    Text("Duration")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textTertiary)
                    Text(formatDuration(networkMonitor.sessionDuration))
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                }
                
                Divider()
                    .frame(height: 30)
                    .background(Theme.backgroundTertiary)
                
                // Session Upload
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upload")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textTertiary)
                    Text(formatMB(networkMonitor.sessionUploadMB))
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.cyan)
                }
                
                // Session Download
                VStack(alignment: .leading, spacing: 2) {
                    Text("Download")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textTertiary)
                    Text(formatMB(networkMonitor.sessionDownloadMB))
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.green)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(Theme.backgroundSecondary)
        )
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%dm %02ds", minutes, secs)
        }
    }
    
    private func formatMB(_ mb: Double) -> String {
        if mb < 1 {
            return String(format: "%.0f KB", mb * 1024)
        } else if mb < 1024 {
            return String(format: "%.1f MB", mb)
        } else {
            return String(format: "%.2f GB", mb / 1024)
        }
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

// MARK: - Sleep Guard Dashboard Widget (keep existing)
struct SleepGuardDashboardWidget: View {
    @StateObject private var manager = SleepGuardManager.shared
    @StateObject private var store = StoreManager.shared
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        NavigationLink {
            SleepGuardView()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(manager.isMonitoring ? Theme.statusSafe.opacity(0.2) : Theme.backgroundTertiary)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: manager.isMonitoring ? "moon.stars.fill" : "moon.zzz")
                        .font(.title2)
                        .foregroundStyle(manager.isMonitoring ? Theme.statusSafe : Theme.textTertiary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sleep Guard")
                        .font(Theme.body)
                        .foregroundStyle(Theme.textPrimary)
                    
                    if manager.isMonitoring {
                        Text(formattedElapsedTime)
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.accentPrimary)
                    } else if let lastReport = manager.lastReport {
                        Text(lastReport.statusSummary)
                            .font(Theme.caption)
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        Text(store.isPremium ? "Tap to start" : "Premium Feature")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                
                Spacer()
                
                if manager.isMonitoring {
                    Circle()
                        .fill(Theme.statusSafe)
                        .frame(width: 10, height: 10)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .fill(Theme.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                            .stroke(manager.isMonitoring ? Theme.statusSafe.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            if manager.isMonitoring { startTimer() }
        }
        .onDisappear { stopTimer() }
        .onChange(of: manager.isMonitoring) { _, isMonitoring in
            if isMonitoring { startTimer() } else { stopTimer() }
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        updateElapsedTime()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateElapsedTime()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        elapsedTime = 0
    }
    
    private func updateElapsedTime() {
        if let session = manager.currentSession {
            elapsedTime = Date().timeIntervalSince(session.startTime)
        }
    }
    
    private var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - Preview
#Preview {
    DashboardView(monitoringManager: MonitoringManager.shared)
        .preferredColorScheme(.dark)
}
