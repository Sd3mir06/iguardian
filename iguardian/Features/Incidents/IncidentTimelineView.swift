//
//  IncidentTimelineView.swift
//  iguardian
//
//  Timeline view for security incidents
//

import SwiftUI

struct IncidentTimelineView: View {
    @StateObject private var manager = IncidentManager.shared
    @StateObject private var store = StoreManager.shared
    @State private var selectedFilter: IncidentFilter = .all
    @State private var showPaywall = false
    
    enum IncidentFilter: String, CaseIterable {
        case all = "All"
        case critical = "Critical"
        case high = "High"
        case unresolved = "Unresolved"
    }
    
    var filteredIncidents: [Incident] {
        manager.recentIncidents.filter { incident in
            switch selectedFilter {
            case .all: return true
            case .critical: return incident.severity == .critical
            case .high: return incident.severity >= .high
            case .unresolved: return !incident.isResolved
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if store.isPremium {
                    // Filter Pills
                    filterPills
                    
                    // Timeline
                    if filteredIncidents.isEmpty {
                        emptyState
                    } else {
                        timelineList
                    }
                } else {
                    premiumPrompt
                }
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle("Incidents")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
    
    // MARK: - Filter Pills
    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(IncidentFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation { selectedFilter = filter }
                    } label: {
                        Text(filter.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedFilter == filter ? Theme.accentPrimary : Theme.backgroundSecondary)
                            .foregroundStyle(selectedFilter == filter ? .white : Theme.textSecondary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Timeline List
    private var timelineList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredIncidents, id: \.id) { incident in
                    IncidentRow(incident: incident)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 60))
                .foregroundStyle(Theme.statusSafe)
            
            Text("No Incidents")
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)
            
            Text("Your device is running normally with no security incidents detected.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Premium Prompt
    private var premiumPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundStyle(Theme.premiumGradient)
            
            Text("Incident Timeline")
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)
            
            Text("Track and analyze security incidents with full history and forensic details.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                showPaywall = true
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                    Text("Unlock Premium")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.premiumGradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Incident Row
struct IncidentRow: View {
    let incident: Incident
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline dot
            VStack {
                Circle()
                    .fill(incident.severity.color)
                    .frame(width: 12, height: 12)
                Rectangle()
                    .fill(Theme.backgroundTertiary)
                    .frame(width: 2)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: incident.type.icon)
                        .foregroundStyle(incident.type.color)
                    
                    Text(incident.type.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(Theme.textPrimary)
                    
                    Spacer()
                    
                    Text(incident.severity.label)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(incident.severity.color.opacity(0.2))
                        .foregroundStyle(incident.severity.color)
                        .clipShape(Capsule())
                }
                
                Text(incident.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
                
                if !incident.isResolved {
                    HStack {
                        Text("Duration: \(incident.durationFormatted)")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .padding()
            .background(Theme.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    IncidentTimelineView()
}
