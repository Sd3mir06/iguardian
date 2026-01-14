//
//  SettingsView.swift
//  iguardian
//
//  App settings view with working buttons
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var liveActivityManager = LiveActivityManager.shared
    @StateObject private var storeManager = StoreManager.shared
    @State private var showPaywall = false
    @State private var notificationsEnabled = true
    
    var body: some View {
        NavigationStack {
            List {
                // Live Activity Section (Dynamic Island)
                Section {
                    Toggle(isOn: $liveActivityManager.isActivityActive) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Theme.accentPrimary.opacity(0.2))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "circle.dotted.circle")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Theme.accentPrimary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Dynamic Island")
                                    .font(Theme.body)
                                    .foregroundColor(Theme.textPrimary)
                                
                                Text("Show live stats on Dynamic Island")
                                    .font(Theme.caption)
                                    .foregroundColor(Theme.textTertiary)
                            }
                        }
                    }
                    .tint(Theme.accentPrimary)
                    .onChange(of: liveActivityManager.isActivityActive) { _, newValue in
                        if newValue {
                            liveActivityManager.startActivity()
                        } else {
                            liveActivityManager.stopActivity()
                        }
                    }
                } header: {
                    Text("Live Activity")
                }
                .listRowBackground(Theme.backgroundSecondary)
                
                // Monitoring Section
                Section {
                    Toggle(isOn: $notificationsEnabled) {
                        SettingsRowContent(
                            icon: "bell.badge.fill",
                            title: "Notifications",
                            subtitle: "Receive security alerts",
                            color: Theme.accentPrimary
                        )
                    }
                    .tint(Theme.accentPrimary)
                    
                    if storeManager.isPremium {
                        NavigationLink {
                            ThresholdSettingsView()
                        } label: {
                            SettingsRowContent(
                                icon: "slider.horizontal.3",
                                title: "Thresholds",
                                subtitle: "Customize detection sensitivity",
                                color: Theme.statusWarning
                            )
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                SettingsRowContent(
                                    icon: "slider.horizontal.3",
                                    title: "Thresholds",
                                    subtitle: "Customize detection sensitivity",
                                    color: Theme.statusWarning,
                                    isPremium: true
                                )
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Theme.textTertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Monitoring")
                }
                .listRowBackground(Theme.backgroundSecondary)
                
                // Phase 3/4 Features Section
                Section {
                    NavigationLink {
                        SleepGuardView()
                    } label: {
                        SettingsRowContent(
                            icon: "moon.stars.fill",
                            title: "Sleep Guard",
                            subtitle: "Monitor while you sleep",
                            color: .purple,
                            isPremium: !storeManager.isPremium
                        )
                    }
                    
                    NavigationLink {
                        IncidentTimelineView()
                    } label: {
                        SettingsRowContent(
                            icon: "clock.arrow.circlepath",
                            title: "Incident Timeline",
                            subtitle: "Security event history",
                            color: .orange,
                            isPremium: !storeManager.isPremium
                        )
                    }
                    
                    NavigationLink {
                        ThemePickerView()
                    } label: {
                        SettingsRowContent(
                            icon: "paintpalette.fill",
                            title: "Themes",
                            subtitle: "Customize app appearance",
                            color: .pink,
                            isPremium: false
                        )
                    }
                    
                    NavigationLink {
                        ExportSettingsView()
                    } label: {
                        SettingsRowContent(
                            icon: "square.and.arrow.up",
                            title: "Export Data",
                            subtitle: "CSV or JSON export",
                            color: .cyan,
                            isPremium: !storeManager.isPremium
                        )
                    }
                } header: {
                    Text("Features")
                }
                .listRowBackground(Theme.backgroundSecondary)
                
                // Premium Section
                Section {
                    if storeManager.isPremium {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "F59E0B"), Color(hex: "EAB308")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            
                            Text("Premium Active")
                                .font(Theme.body)
                                .foregroundColor(Theme.textPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.statusSafe)
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            VStack(spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Upgrade to Premium")
                                            .font(Theme.title)
                                            .foregroundColor(Theme.textPrimary)
                                        
                                        Text("Dynamic Island, Sleep Guard & more")
                                            .font(Theme.caption)
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color(hex: "F59E0B"), Color(hex: "EAB308")],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                }
                                
                                Text("View Plans")
                                    .font(Theme.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall)
                                            .fill(Theme.premiumGradient)
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Premium")
                }
                .listRowBackground(Theme.backgroundSecondary)
                
                // About Section
                Section {
                    Button {
                        // Help action
                    } label: {
                        HStack {
                            SettingsRowContent(
                                icon: "questionmark.circle.fill",
                                title: "Help & FAQ",
                                subtitle: "Learn how iGuardian works",
                                color: Theme.accentSecondary
                            )
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        if let url = URL(string: "https://sukrudemir.org/privacy") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            SettingsRowContent(
                                icon: "lock.shield.fill",
                                title: "Privacy Policy",
                                subtitle: "Your data stays on device",
                                color: Theme.statusSafe
                            )
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        if let url = URL(string: "https://sukrudemir.org/terms") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            SettingsRowContent(
                                icon: "doc.text.fill",
                                title: "Terms of Service",
                                subtitle: "Legal information",
                                color: Theme.textTertiary
                            )
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("About")
                }
                .listRowBackground(Theme.backgroundSecondary)
                
                // App Info
                Section {
                    VStack(spacing: 8) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                        
                        Text("iGuardian")
                            .font(Theme.headline)
                            .foregroundColor(Theme.textPrimary)
                        
                        Text("Version 1.0.0")
                            .font(Theme.caption)
                            .foregroundColor(Theme.textTertiary)
                        
                        Text("Know when something suspicious is happening")
                            .font(Theme.caption)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
                .listRowBackground(Color.clear)
                
                // Debug Section (only in DEBUG builds)
                #if DEBUG
                Section {
                    Toggle(isOn: $storeManager.debugPremiumEnabled) {
                        SettingsRowContent(
                            icon: "ladybug.fill",
                            title: "Debug Premium",
                            subtitle: "Test premium features",
                            color: .red
                        )
                    }
                    .tint(Theme.accentPrimary)
                } header: {
                    Text("Debug")
                } footer: {
                    Text("This toggle only appears in debug builds")
                }
                .listRowBackground(Theme.backgroundSecondary)
                #endif
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundPrimary)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.accentPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .toolbarBackground(Theme.backgroundPrimary, for: .navigationBar)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Settings Row Content
struct SettingsRowContent: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var isPremium: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(Theme.body)
                        .foregroundColor(Theme.textPrimary)
                    
                    if isPremium {
                        Text("PRO")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Theme.premiumGradient)
                            )
                    }
                }
                
                Text(subtitle)
                    .font(Theme.caption)
                    .foregroundColor(Theme.textTertiary)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
