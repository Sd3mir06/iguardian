//
//  ExportSettingsView.swift
//  iguardian
//
//  Export settings and data export UI
//

import SwiftUI

struct ExportSettingsView: View {
    @StateObject private var store = StoreManager.shared
    @State private var selectedFormat: DataExporter.ExportFormat = .csv
    @State private var selectedDataType: DataExporter.ExportDataType = .incidents
    @State private var showPaywall = false
    @State private var showShareSheet = false
    @State private var exportData: Data?
    @State private var exportFilename = ""
    
    var body: some View {
        List {
            if store.isPremium {
                // Format Selection
                Section {
                    ForEach(DataExporter.ExportFormat.allCases, id: \.self) { format in
                        Button {
                            selectedFormat = format
                        } label: {
                            HStack {
                                Text(format.rawValue)
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                if selectedFormat == format {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.accentPrimary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Format")
                }
                
                // Data Type Selection
                Section {
                    ForEach(DataExporter.ExportDataType.allCases, id: \.self) { dataType in
                        Button {
                            selectedDataType = dataType
                        } label: {
                            HStack {
                                Image(systemName: dataType.icon)
                                    .foregroundStyle(Theme.accentPrimary)
                                    .frame(width: 24)
                                Text(dataType.rawValue)
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                if selectedDataType == dataType {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.accentPrimary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Data to Export")
                }
                
                // Export Button
                Section {
                    Button {
                        performExport()
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Data")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Theme.accentPrimary)
                    .foregroundStyle(.white)
                }
                
            } else {
                // Premium Required
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.premiumGradient)
                        
                        Text("Export Your Data")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        
                        Text("Export incidents, sleep sessions, and metrics history in CSV or JSON format.")
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
                    .padding(.vertical)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundPrimary)
        .navigationTitle("Export Data")
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = exportData {
                ShareSheet(items: [ExportFile(data: data, filename: exportFilename)])
            }
        }
    }
    
    private func performExport() {
        let exporter = DataExporter.shared
        exportFilename = exporter.generateFilename(for: selectedDataType, format: selectedFormat)
        
        switch selectedDataType {
        case .incidents:
            let incidents = IncidentManager.shared.recentIncidents
            exportData = exporter.exportIncidents(incidents, format: selectedFormat)
        case .sleepSessions:
            let sessions = SleepGuardManager.shared.getSessionHistory()
            exportData = exporter.exportSleepSessions(sessions, format: selectedFormat)
        case .metrics:
            // Would export metric history
            exportData = nil
        }
        
        if exportData != nil {
            showShareSheet = true
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Export File
class ExportFile: NSObject, UIActivityItemSource {
    let data: Data
    let filename: String
    
    init(data: Data, filename: String) {
        self.data = data
        self.filename = filename
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return data
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return data
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        if filename.hasSuffix(".csv") {
            return "public.comma-separated-values-text"
        } else {
            return "public.json"
        }
    }
}

#Preview {
    NavigationStack {
        ExportSettingsView()
    }
}
