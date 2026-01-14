//
//  LogManager.swift
//  iguardian
//
//  Centralized logging system for debugging and monitoring background activity.
//

import Foundation
import Combine

enum LogLevel: String, Codable {
    case info = "ℹ️ INFO"
    case warning = "⚠️ WARN"
    case error = "❌ ERROR"
    case debug = "🔍 DEBG"
    
    var color: String {
        switch self {
        case .info: return "blue"
        case .warning: return "orange"
        case .error: return "red"
        case .debug: return "gray"
        }
    }
}

struct LogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let level: LogLevel
    let category: String
    let message: String
    
    init(level: LogLevel, category: String, message: String) {
        self.id = UUID()
        self.timestamp = Date()
        self.level = level
        self.category = category
        self.message = message
    }
}

@MainActor
class LogManager: ObservableObject {
    static let shared = LogManager()
    
    @Published var entries: [LogEntry] = []
    private let maxEntries = 500
    
    private init() {}
    
    func log(_ message: String, level: LogLevel = .info, category: String = "System") {
        let entry = LogEntry(level: level, category: category, message: message)
        
        // Print to console for Xcode debugging
        print("[\(entry.level.rawValue)] [\(entry.category)] \(entry.message)")
        
        // Add to buffer for live console
        entries.insert(entry, at: 0)
        
        // Trim if needed
        if entries.count > maxEntries {
            entries.removeLast()
        }
    }
    
    func clear() {
        entries.removeAll()
    }
    
    func exportLogs() -> String {
        return entries.map { entry in
            "\(entry.timestamp) [\(entry.level.rawValue)] [\(entry.category)] \(entry.message)"
        }.joined(separator: "\n")
    }
}
