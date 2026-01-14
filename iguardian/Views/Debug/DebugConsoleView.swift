//
//  DebugConsoleView.swift
//  iguardian
//
//  Developer console for viewing real-time logs and system status.
//

import SwiftUI

struct DebugConsoleView: View {
    @StateObject private var logManager = LogManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLevel: LogLevel? = nil
    
    var filteredEntries: [LogEntry] {
        if let level = selectedLevel {
            return logManager.entries.filter { $0.level == level }
        }
        return logManager.entries
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Header
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterButton(title: "ALL", isSelected: selectedLevel == nil) {
                            selectedLevel = nil
                        }
                        
                        FilterButton(title: "INFO", isSelected: selectedLevel == .info, color: .blue) {
                            selectedLevel = .info
                        }
                        
                        FilterButton(title: "WARN", isSelected: selectedLevel == .warning, color: .orange) {
                            selectedLevel = .warning
                        }
                        
                        FilterButton(title: "ERROR", isSelected: selectedLevel == .error, color: .red) {
                            selectedLevel = .error
                        }
                        
                        FilterButton(title: "DEBUG", isSelected: selectedLevel == .debug, color: .gray) {
                            selectedLevel = .debug
                        }
                    }
                    .padding()
                }
                .background(Theme.backgroundSecondary)
                
                // Log List
                List(filteredEntries) { entry in
                    LogEntryRow(entry: entry)
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        .listRowBackground(Theme.backgroundPrimary)
                }
                .listStyle(.plain)
                .background(Theme.backgroundPrimary)
            }
            .navigationTitle("Debug Console")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        logManager.clear()
                    }
                    .foregroundColor(Theme.statusDanger)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        ShareLink(item: logManager.exportLogs()) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        
                        Button("Done") {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                    .foregroundColor(Theme.accentPrimary)
                }
            }
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    var color: Color = .gray
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption2.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? (color == .gray ? Theme.textPrimary : color) : Theme.backgroundTertiary)
                .foregroundColor(isSelected ? .black : Theme.textSecondary)
                .cornerRadius(8)
        }
    }
}

struct LogEntryRow: View {
    let entry: LogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.level.rawValue)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(levelColor.opacity(0.2))
                    .foregroundColor(levelColor)
                    .cornerRadius(4)
                
                Text(entry.category.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
                
                Spacer()
                
                Text(entry.timestamp, style: .time)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Theme.textTertiary)
            }
            
            Text(entry.message)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
    
    private var levelColor: Color {
        switch entry.level {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .debug: return .gray
        }
    }
}

#Preview {
    DebugConsoleView()
        .preferredColorScheme(.dark)
}
