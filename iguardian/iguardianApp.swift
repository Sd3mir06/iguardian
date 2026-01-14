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
        
        // Configure SwiftData
        do {
            let schema = Schema([
                SleepSession.self,
                Incident.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            
            // Configure managers with model context
            let context = modelContainer.mainContext
            Task { @MainActor in
                SleepGuardManager.shared.configure(modelContext: context)
                IncidentManager.shared.configure(modelContext: context)
            }
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
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
