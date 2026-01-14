//
//  MainTabView.swift
//  iguardian
//
//  Created by Sukru Demir on 13.01.2026.
//

import SwiftUI

/// Main tab navigation for the app
struct MainTabView: View {
    @StateObject private var monitoringManager = MonitoringManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(monitoringManager: monitoringManager)
                .tabItem {
                    Label("Home", systemImage: "shield.fill")
                }
                .tag(0)
            
            HistoryView(monitoringManager: monitoringManager)
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(1)
        }
        .tint(Theme.accentPrimary)
        .onAppear {
            // Configure tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Theme.backgroundSecondary)
            
            // Unselected state
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Theme.textTertiary)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(Theme.textTertiary)
            ]
            
            // Selected state
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Theme.accentPrimary)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(Theme.accentPrimary)
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}
