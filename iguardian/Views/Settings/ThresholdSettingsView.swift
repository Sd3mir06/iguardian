//
//  ThresholdSettingsView.swift
//  iguardian
//
//  Custom alert threshold settings UI
//

import SwiftUI

struct ThresholdSettingsView: View {
    @StateObject private var thresholdManager = ThresholdManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(thresholdManager.thresholds) { threshold in
                    ThresholdRow(threshold: binding(for: threshold))
                }
                
                Section {
                    Button(role: .destructive) {
                        thresholdManager.reset()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Reset to Defaults")
                            Spacer()
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundPrimary)
            .navigationTitle("Alert Thresholds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.accentPrimary)
                }
            }
        }
    }
    
    private func binding(for threshold: AlertThreshold) -> Binding<AlertThreshold> {
        Binding(
            get: { threshold },
            set: { thresholdManager.update($0) }
        )
    }
}

struct ThresholdRow: View {
    @Binding var threshold: AlertThreshold
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: threshold.metric.icon)
                    .foregroundStyle(Theme.accentPrimary)
                    .frame(width: 24)
                
                Text(threshold.metric.title)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                
                Spacer()
                
                Toggle("", isOn: $threshold.isEnabled)
                    .tint(Theme.accentPrimary)
                    .labelsHidden()
            }
            
            if threshold.isEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Alert when above:")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        
                        Spacer()
                        
                        Text("\(Int(threshold.value)) \(threshold.metric.unit)")
                            .font(.subheadline.bold())
                            .foregroundStyle(Theme.accentPrimary)
                    }
                    
                    Slider(
                        value: $threshold.value,
                        in: threshold.metric.range,
                        step: threshold.metric.step
                    )
                    .tint(Theme.accentPrimary)
                }
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Theme.backgroundSecondary)
    }
}

#Preview {
    ThresholdSettingsView()
}
