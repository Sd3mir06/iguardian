//
//  iguardianApp.swift
//  iguardian
//
//  IMPROVED: Added onboarding flow and proper initialization
//

import SwiftUI
import SwiftData

@main
struct iguardianApp: App {
    let modelContainer: ModelContainer
    
    // Onboarding state
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
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
        
        // Configure tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(Theme.backgroundSecondary)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        
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
            RootView(hasCompletedOnboarding: hasCompletedOnboarding)
                .preferredColorScheme(.dark)
                .modelContainer(modelContainer)
        }
    }
}

// MARK: - Root View (Handles Onboarding vs Main App)
struct RootView: View {
    let hasCompletedOnboarding: Bool
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if !hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showSplash)
        .animation(.easeInOut(duration: 0.5), value: hasCompletedOnboarding)
        .onAppear {
            // Show splash for 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Splash View
struct SplashView: View {
    @State private var isAnimating = false
    @State private var showTagline = false
    
    var body: some View {
        ZStack {
            // Background
            Theme.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Animated Shield
                ZStack {
                    // Outer pulsing ring
                    Circle()
                        .stroke(Theme.accentPrimary.opacity(0.3), lineWidth: 2)
                        .frame(width: 160, height: 160)
                        .scaleEffect(isAnimating ? 1.3 : 1)
                        .opacity(isAnimating ? 0 : 0.5)
                    
                    // Middle ring
                    Circle()
                        .stroke(Theme.accentPrimary.opacity(0.5), lineWidth: 2)
                        .frame(width: 140, height: 140)
                        .scaleEffect(isAnimating ? 1.2 : 1)
                        .opacity(isAnimating ? 0.3 : 0.7)
                    
                    // Inner glow
                    Circle()
                        .fill(Theme.accentPrimary.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    // App logo image
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .shadow(color: Theme.accentPrimary.opacity(0.5), radius: 20)
                }
                
                // App name
                VStack(spacing: 8) {
                    Text("iGUARDIAN")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .kerning(4)
                    
                    if showTagline {
                        Text("Your Silent Security Partner")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }
        }
        .onAppear {
            // Start animations
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
            
            // Show tagline after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn(duration: 0.5)) {
                    showTagline = true
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Splash") {
    SplashView()
}

#Preview("Root - Onboarding") {
    RootView(hasCompletedOnboarding: false)
}

#Preview("Root - Main") {
    RootView(hasCompletedOnboarding: true)
}
