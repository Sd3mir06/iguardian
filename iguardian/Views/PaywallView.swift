//
//  PaywallView.swift
//  iguardian
//
//  Created by Sukru Demir on 14.01.2026.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = StoreManager.shared
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Features
                    featuresSection
                    
                    // Products
                    productsSection
                    
                    // Restore
                    restoreButton
                    
                    // Terms
                    termsSection
                }
                .padding()
            }
            .background(Theme.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.textTertiary)
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Animated gradient icon
            // App logo
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .shadow(color: .purple.opacity(0.5), radius: 20)
            
            Text("iGuardian Premium")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Advanced security monitoring")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Features
    private var featuresSection: some View {
        VStack(spacing: 16) {
            FeatureRow(
                icon: "circle.dotted.circle",
                title: "Dynamic Island",
                description: "Live network stats always visible"
            )
            
            FeatureRow(
                icon: "moon.stars.fill",
                title: "Sleep Guard",
                description: "Monitor while you sleep"
            )
            
            FeatureRow(
                icon: "chart.xyaxis.line",
                title: "Unlimited History",
                description: "Full analytics & trends"
            )
            
            FeatureRow(
                icon: "bell.badge.fill",
                title: "Smart Alerts",
                description: "Threat signature detection"
            )
            
            FeatureRow(
                icon: "doc.text.fill",
                title: "Weekly Reports",
                description: "PDF security summaries"
            )
        }
        .padding()
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Products
    private var productsSection: some View {
        VStack(spacing: 12) {
            if store.isLoading {
                ProgressView()
                    .tint(Theme.accentPrimary)
            } else {
                ForEach(store.products, id: \.id) { product in
                    ProductCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        onSelect: { selectedProduct = product }
                    )
                }
                
                // Purchase Button
                Button {
                    Task { await purchase() }
                } label: {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Continue")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(selectedProduct == nil || isPurchasing)
                .opacity(selectedProduct == nil ? 0.6 : 1)
            }
        }
    }
    
    // MARK: - Restore Button
    private var restoreButton: some View {
        Button {
            Task {
                await store.restorePurchases()
                if store.isPremium {
                    dismiss()
                }
            }
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundStyle(Theme.accentPrimary)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Terms
    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("Recurring billing. Cancel anytime.")
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
            
            HStack(spacing: 16) {
                Link("Terms", destination: URL(string: "https://sukrudemir.org/terms")!)
                Link("Privacy", destination: URL(string: "https://sukrudemir.org/privacy")!)
            }
            .font(.caption)
            .foregroundStyle(Theme.textSecondary)
        }
    }
    
    // MARK: - Purchase Action
    private func purchase() async {
        guard let product = selectedProduct else { return }
        
        isPurchasing = true
        do {
            let success = try await store.purchase(product)
            if success {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isPurchasing = false
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Theme.accentPrimary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.textPrimary)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark")
                .foregroundStyle(.green)
        }
    }
}

// MARK: - Product Card
struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                        
                        if product.subscription?.subscriptionPeriod.unit == .year {
                            Text("SAVE 44%")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(product.displayPrice)
                        .font(.title3.bold())
                        .foregroundColor(Theme.textPrimary)
                    Text(product.periodFormatted)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding()
            .background(isSelected ? Theme.accentPrimary.opacity(0.15) : Theme.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Theme.accentPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView()
}
