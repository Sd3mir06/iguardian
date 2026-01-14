//
//  TrafficSummaryView.swift
//  iguardian
//
//  Displays persistent traffic statistics (today, week, month, all-time)
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
                
                // Summary Cards
                todayCard
                weekCard
                monthCard
                allTimeCard
                
                // Daily Breakdown Chart (placeholder for future)
                dailyBreakdownCard
                
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
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(Theme.backgroundSecondary)
        )
    }
    
    // MARK: - Today Card
    private var todayCard: some View {
        TrafficStatCard(
            title: "Today",
            icon: "calendar",
            iconColor: .blue,
            uploadMB: trafficManager.todayUploadMB,
            downloadMB: trafficManager.todayDownloadMB
        )
    }
    
    // MARK: - Week Card
    private var weekCard: some View {
        TrafficStatCard(
            title: "This Week",
            icon: "calendar.badge.clock",
            iconColor: .green,
            uploadMB: trafficManager.weekUploadMB,
            downloadMB: trafficManager.weekDownloadMB
        )
    }
    
    // MARK: - Month Card
    private var monthCard: some View {
        TrafficStatCard(
            title: "This Month",
            icon: "calendar.circle",
            iconColor: .orange,
            uploadMB: trafficManager.monthUploadMB,
            downloadMB: trafficManager.monthDownloadMB
        )
    }
    
    // MARK: - All Time Card
    private var allTimeCard: some View {
        TrafficStatCard(
            title: "All Time",
            icon: "infinity",
            iconColor: Theme.accentPrimary,
            uploadMB: trafficManager.allTimeUploadMB,
            downloadMB: trafficManager.allTimeDownloadMB,
            isHighlighted: true
        )
    }
    
    // MARK: - Daily Breakdown
    private var dailyBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundColor(Theme.accentSecondary)
                Text("LAST 7 DAYS")
                    .font(Theme.micro)
                    .foregroundColor(Theme.textTertiary)
                    .kerning(1.2)
                Spacer()
            }
            
            let dailyData = trafficManager.getDailyBreakdown(days: 7)
            
            if dailyData.isEmpty {
                Text("No data yet. Keep the app running to collect traffic statistics.")
                    .font(Theme.caption)
                    .foregroundColor(Theme.textTertiary)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 8) {
                    ForEach(dailyData, id: \.date) { day in
                        DailyBreakdownRow(
                            date: day.date,
                            uploadMB: Double(day.upload) / (1024 * 1024),
                            downloadMB: Double(day.download) / (1024 * 1024)
                        )
                    }
                }
            }
        }
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
}

// MARK: - Traffic Stat Card
struct TrafficStatCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let uploadMB: Double
    let downloadMB: Double
    var isHighlighted: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
            }
            
            // Title and Total
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.body)
                    .foregroundColor(Theme.textPrimary)
                
                Text("Total: \(formatSize(uploadMB + downloadMB))")
                    .font(Theme.caption)
                    .foregroundColor(Theme.textTertiary)
            }
            
            Spacer()
            
            // Upload/Download
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.caption)
                        .foregroundColor(.cyan)
                    Text(formatSize(uploadMB))
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.textSecondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text(formatSize(downloadMB))
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.textSecondary)
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
        if mb < 1 {
            return String(format: "%.0f KB", mb * 1024)
        } else if mb < 1024 {
            return String(format: "%.1f MB", mb)
        } else {
            return String(format: "%.2f GB", mb / 1024)
        }
    }
}

// MARK: - Daily Breakdown Row
struct DailyBreakdownRow: View {
    let date: Date
    let uploadMB: Double
    let downloadMB: Double
    
    var body: some View {
        HStack {
            Text(dayString)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.textSecondary)
                .frame(width: 60, alignment: .leading)
            
            // Mini bar
            GeometryReader { geo in
                let maxMB = max(uploadMB + downloadMB, 1)
                let totalWidth = geo.size.width
                
                HStack(spacing: 2) {
                    // Upload portion
                    Rectangle()
                        .fill(Color.cyan)
                        .frame(width: max(2, totalWidth * CGFloat(uploadMB / maxMB) * 0.5))
                    
                    // Download portion
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: max(2, totalWidth * CGFloat(downloadMB / maxMB) * 0.5))
                }
                .frame(height: 8)
                .clipShape(Capsule())
            }
            .frame(height: 8)
            
            Text(formatSize(uploadMB + downloadMB))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(Theme.textTertiary)
                .frame(width: 60, alignment: .trailing)
        }
    }
    
    private var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func formatSize(_ mb: Double) -> String {
        if mb < 1 {
            return String(format: "%.0f KB", mb * 1024)
        } else if mb < 1024 {
            return String(format: "%.0f MB", mb)
        } else {
            return String(format: "%.1f GB", mb / 1024)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        TrafficSummaryView()
    }
    .preferredColorScheme(.dark)
}
