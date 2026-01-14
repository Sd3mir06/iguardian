//
//  ThemePickerView.swift
//  iguardian
//
//  Theme selection UI
//

import SwiftUI

struct ThemePickerView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var store = StoreManager.shared
    @State private var showPaywall = false
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(themeManager.availableThemes) { theme in
                    ThemeCard(
                        theme: theme,
                        isSelected: themeManager.currentTheme.id == theme.id,
                        isLocked: theme.isPremium && !store.isPremium
                    ) {
                        if theme.isPremium && !store.isPremium {
                            showPaywall = true
                        } else {
                            withAnimation {
                                themeManager.selectTheme(theme)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Theme.backgroundPrimary)
        .navigationTitle("Themes")
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Theme Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: theme.backgroundPrimary))
                        .frame(height: 100)
                    
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: theme.accentPrimary))
                                .frame(width: 24, height: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(hex: theme.textPrimary))
                                    .frame(width: 40, height: 6)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(hex: theme.textSecondary))
                                    .frame(width: 30, height: 4)
                            }
                        }
                        
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: theme.backgroundSecondary))
                                .frame(width: 30, height: 20)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: theme.backgroundSecondary))
                                .frame(width: 30, height: 20)
                        }
                    }
                    
                    if isLocked {
                        Color.black.opacity(0.5)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.white)
                    }
                }
                
                // Theme Info
                HStack {
                    Image(systemName: theme.icon)
                        .foregroundStyle(Color(hex: theme.accentPrimary))
                    
                    Text(theme.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.textPrimary)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(hex: theme.accentPrimary))
                    } else if theme.isPremium {
                        Text("PRO")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.premiumGradient)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding()
            .background(Theme.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(hex: theme.accentPrimary) : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ThemePickerView()
    }
}
