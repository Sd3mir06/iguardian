//
//  HistoryView.swift
//  iguardian
//
//  Shows historical activity and events
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var monitoringManager: MonitoringManager
    @State private var selectedFilter: HistoryFilter = .all
    
    enum HistoryFilter: String, CaseIterable {
        case all = "All"
        case alerts = "Alerts"
        case warnings = "Warnings"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Pills
                filterBar
                
                // Content
                if filteredEntries.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Theme.backgroundPrimary, for: .navigationBar)
        }
    }
    
    // MARK: - Filter Bar
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HistoryFilter.allCases, id: \.self) { filter in
                    FilterPill(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Theme.backgroundSecondary)
    }
    
    // MARK: - History List
    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredEntries) { entry in
                    HistoryCard(entry: entry)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 60))
                .foregroundStyle(Theme.statusSafe.opacity(0.5))
            
            Text("No Activity Yet")
                .font(Theme.headline)
                .foregroundColor(Theme.textPrimary)
            
            Text("Activity will appear here as\nyour device is monitored.")
                .font(Theme.body)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Filtered Entries
    private var filteredEntries: [ActivityEntry] {
        switch selectedFilter {
        case .all:
            return monitoringManager.recentActivity
        case .alerts:
            return monitoringManager.recentActivity.filter { 
                $0.type == .alert || $0.type == .critical 
            }
        case .warnings:
            return monitoringManager.recentActivity.filter { 
                $0.type == .warning 
            }
        }
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.accentPrimary : Theme.backgroundTertiary)
                .foregroundColor(isSelected ? .white : Theme.textSecondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - History Card
struct HistoryCard: View {
    let entry: ActivityEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(entry.type.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: entry.type.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(entry.type.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(Theme.body)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.textPrimary)
                
                Text(entry.description)
                    .font(Theme.caption)
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Time
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.timeFormatted)
                    .font(Theme.caption)
                    .foregroundColor(Theme.textTertiary)
                
                Text(entry.timestamp, style: .date)
                    .font(Theme.micro)
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(Theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                        .stroke(entry.type.color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview
#Preview {
    HistoryView(monitoringManager: MonitoringManager.shared)
        .preferredColorScheme(.dark)
}
