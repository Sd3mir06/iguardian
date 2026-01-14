//
//  TrafficSummaryView.swift
//  iguardian
//
//  Displays persistent traffic statistics with WiFi vs Cellular breakdown
//

import SwiftUI

struct TrafficSummaryView: View {
    @StateObject private var trafficManager = TrafficLogManager.shared
    @State private var showResetConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                headerCard
                
                // Today Card with breakdown
                TrafficPeriodCard(
                    title: "Today",
                    icon: "calendar",
                    iconColor: .blue,
                    wifiUploadMB: trafficManager.todayWifiUploadMB,
                    wifiDownloadMB: trafficManager.todayWifiDownloadMB,
                    cellularUploadMB: trafficManager.todayCellularUploadMB,
                    cellularDownloadMB: trafficManager.todayCellularDownloadMB
                )
                
                // This Week
                TrafficPeriodCard(
                    title: "This Week",
                    icon: "calendar.badge.clock",
                    iconColor: .green,
                    wifiUploadMB: Double(trafficManager.weekWifiUploadBytes) / (1024 * 1024),
                    wifiDownloadMB: Double(trafficManager.weekWifiDownloadBytes) / (1024 * 1024),
                    cellularUploadMB: Double(trafficManager.weekCellularUploadBytes) / (1024 * 1024),
                    cellularDownloadMB: Double(trafficManager.weekCellularDownloadBytes) / (1024 * 1024)
                )
                
                // This Month
                TrafficPeriodCard(
                    title: "This Month",
                    icon: "calendar.circle",
                    iconColor: .orange,
                    wifiUploadMB: Double(trafficManager.monthWifiUploadBytes) / (1024 * 1024),
                    wifiDownloadMB: Double(trafficManager.monthWifiDownloadBytes) / (1024 * 1024),
                    cellularUploadMB: Double(trafficManager.monthCellularUploadBytes) / (1024 * 1024),
                    cellularDownloadMB: Double(trafficManager.monthCellularDownloadBytes) / (1024 * 1024)
                )
                
                // All Time
                TrafficPeriodCard(
                    title: "All Time",
                    icon: "infinity",
                    iconColor: Theme.accentPrimary,
                    wifiUploadMB: Double(trafficManager.allTimeWifiUploadBytes) / (1024 * 1024),
                    wifiDownloadMB: Double(trafficManager.allTimeWifiDownloadBytes) / (1024 * 1024),
                    cellularUploadMB: Double(trafficManager.allTimeCellularUploadBytes) / (1024 * 1024),
                    cellularDownloadMB: Double(trafficManager.allTimeCellularDownloadBytes) / (1024 * 1024),
                    isHighlighted: true
                )
                
                // Reset Button
                resetButton
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .background(Theme.backgroundPrimary)
        .navigationTitle("Traffic Summary")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reset All Traffic Stats?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                trafficManager.resetAllStats()
            }
        } message: {
            Text("This will permanently delete all traffic history. This cannot be undone.")
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 40))
                .foregroundColor(Theme.accentPrimary)
            
            Text("Network Traffic Log")
                .font(Theme.title)
                .foregroundColor(Theme.textPrimary)
            
            Text("Tracking since \(formattedStartDate)")
                .font(Theme.caption)
                .foregroundColor(Theme.textTertiary)
            
            // WiFi vs Cellular summary
            HStack(spacing: 24) {
                HStack(spacing: 6) {
                    Image(systemName: "wifi")
                        .foregroundColor(.blue)
                    Text(formatSize(trafficManager.allTimeWifiTotalMB))
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundColor(.orange)
                    Text(formatSize(trafficManager.allTimeCellularTotalMB))
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(Theme.backgroundSecondary)
        )
    }
    
    // MARK: - Reset Button
    private var resetButton: some View {
        Button {
            showResetConfirmation = true
        } label: {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                Text("Reset All Stats")
            }
            .font(Theme.body)
            .foregroundColor(Theme.statusDanger)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .fill(Theme.statusDanger.opacity(0.1))
            )
        }
    }
    
    // MARK: - Helpers
    private var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: trafficManager.trackingStartDate)
    }
    
    private func formatSize(_ mb: Double) -> String {
        if mb < 1 { return String(format: "%.0f KB", mb * 1024) }
        else if mb < 1024 { return String(format: "%.1f MB", mb) }
        else { return String(format: "%.2f GB", mb / 1024) }
    }
}

// MARK: - Traffic Period Card with WiFi/Cellular breakdown
struct TrafficPeriodCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let wifiUploadMB: Double
    let wifiDownloadMB: Double
    let cellularUploadMB: Double
    let cellularDownloadMB: Double
    var isHighlighted: Bool = false
    
    private var totalMB: Double {
        wifiUploadMB + wifiDownloadMB + cellularUploadMB + cellularDownloadMB
    }
    
    private var wifiTotalMB: Double { wifiUploadMB + wifiDownloadMB }
    private var cellularTotalMB: Double { cellularUploadMB + cellularDownloadMB }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.body)
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("Total: \(formatSize(totalMB))")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textTertiary)
                }
                
                Spacer()
            }
            
            // WiFi Row
            HStack {
                Image(systemName: "wifi")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Text("WiFi")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 55, alignment: .leading)
                
                Spacer()
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 10))
                            .foregroundColor(.cyan)
                        Text(formatSize(wifiUploadMB))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                        Text(formatSize(wifiDownloadMB))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    
                    Text(formatSize(wifiTotalMB))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                        .frame(width: 55, alignment: .trailing)
                }
            }
            
            // Cellular Row
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                    .frame(width: 20)
                
                Text("Cellular")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 55, alignment: .leading)
                
                Spacer()
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 10))
                            .foregroundColor(.cyan)
                        Text(formatSize(cellularUploadMB))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                        Text(formatSize(cellularDownloadMB))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    
                    Text(formatSize(cellularTotalMB))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                        .frame(width: 55, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(isHighlighted ? Theme.accentPrimary.opacity(0.1) : Theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                        .stroke(isHighlighted ? Theme.accentPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
    
    private func formatSize(_ mb: Double) -> String {
        if mb < 1 { return String(format: "%.0f KB", mb * 1024) }
        else if mb < 1024 { return String(format: "%.1f MB", mb) }
        else { return String(format: "%.2f GB", mb / 1024) }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        TrafficSummaryView()
    }
    .preferredColorScheme(.dark)
}
