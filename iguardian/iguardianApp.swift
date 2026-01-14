//
//  iguardianApp.swift
//  iguardian
//
//  Created by Sukru Demir on 13.01.2026.
//

import SwiftUI
import SwiftData

@main
struct iguardianApp: App {
    let modelContainer: ModelContainer
    
    init() {
        // Configure navigation bar appearance globally
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Theme.backgroundPrimary)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.textPrimary),
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Theme.textPrimary)
        ]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        
        // Configure SwiftData with migration fallback
        let schema = Schema([
            SleepSession.self,
            Incident.self,
            TrafficLog.self
        ])
        
        // First try with normal configuration
        do {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Migration failed - delete old store and try again
            print("⚠️ SwiftData migration failed: \(error)")
            print("⚠️ Deleting old database and starting fresh...")
            
            // Delete the old store files
            let storeURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("default.store")
            let storePaths = [
                storeURL,
                storeURL.appendingPathExtension("shm"),
                storeURL.appendingPathExtension("wal")
            ]
            for path in storePaths {
                try? FileManager.default.removeItem(at: path)
            }
            
            // Retry with fresh store
            do {
                let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                modelContainer = try ModelContainer(for: schema, configurations: [config])
                print("✅ Fresh database created successfully")
            } catch {
                fatalError("Failed to create ModelContainer after cleanup: \(error)")
            }
        }
        
        // Configure managers with model context
        let context = modelContainer.mainContext
        Task { @MainActor in
            SleepGuardManager.shared.configure(modelContext: context)
            IncidentManager.shared.configure(modelContext: context)
            TrafficLogManager.shared.configure(modelContext: context)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
                .modelContainer(modelContainer)
        }
    }
}
