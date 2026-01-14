//
//  OnboardingView.swift
//  iguardian
//
//  IMPROVED: Beautiful animations, permission flow, professional design
//

import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var showPermissions = false
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "shield.checkered",
            iconColor: .cyan,
            title: "Welcome to iGuardian",
            subtitle: "Your Silent Security Partner",
            description: "iGuardian monitors your device for suspicious background activity that could indicate surveillance or data theft.",
            features: [],
            useAppLogo: true
        ),
        OnboardingPage(
            icon: "eye.slash.fill",
            iconColor: .green,
            title: "Idle Mode Protection",
            subtitle: "Watching When You're Not",
            description: "We only alert you when something suspicious happens while your phone is idle - no annoying false alarms.",
            features: [
                OnboardingFeature(icon: "moon.fill", text: "Monitors when phone is unused"),
                OnboardingFeature(icon: "bell.slash.fill", text: "Zero alerts during active use"),
                OnboardingFeature(icon: "brain.head.profile", text: "Learns your normal patterns")
            ]
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            iconColor: .orange,
            title: "What We Monitor",
            subtitle: "Multi-Factor Detection",
            description: "We track multiple indicators simultaneously to detect potential threats.",
            features: [
                OnboardingFeature(icon: "arrow.up.arrow.down", text: "Network traffic patterns"),
                OnboardingFeature(icon: "cpu", text: "CPU usage anomalies"),
                OnboardingFeature(icon: "battery.50", text: "Unusual battery drain"),
                OnboardingFeature(icon: "thermometer.medium", text: "Device temperature")
            ]
        ),
        OnboardingPage(
            icon: "exclamationmark.triangle.fill",
            iconColor: .red,
            title: "Threat Detection",
            subtitle: "Know When It Matters",
            description: "Get notified when we detect patterns consistent with screen mirroring, data exfiltration, or spyware activity.",
            features: [
                OnboardingFeature(icon: "display", text: "Screen surveillance detection"),
                OnboardingFeature(icon: "doc.fill.badge.plus", text: "Unusual data uploads"),
                OnboardingFeature(icon: "antenna.radiowaves.left.and.right", text: "Suspicious network activity")
            ]
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            iconColor: .purple,
            title: "100% Private",
            subtitle: "Your Data Stays Yours",
            description: "All monitoring happens locally on your device. We never collect, upload, or share your data. Period.",
            features: [
                OnboardingFeature(icon: "iphone", text: "All processing on-device"),
                OnboardingFeature(icon: "xmark.icloud", text: "No cloud uploads"),
                OnboardingFeature(icon: "hand.raised.fill", text: "No data collection")
            ]
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "0A0E14"),
                    Color(hex: "0F1419"),
                    Color(hex: "0A0E14")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Animated background particles
            ParticleView()
                .opacity(0.3)
            
            VStack(spacing: 0) {
                // Skip button (top right)
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button {
                            showPermissions = true
                        } label: {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textTertiary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Bottom section
                VStack(spacing: 20) {
                    // Page indicator
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { index in
                            Capsule()
                                .fill(currentPage == index ? Theme.accentPrimary : Theme.textTertiary.opacity(0.3))
                                .frame(width: currentPage == index ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    
                    // Continue/Get Started button
                    Button {
                        if currentPage == pages.count - 1 {
                            showPermissions = true
                        } else {
                            withAnimation(.spring(response: 0.4)) {
                                currentPage += 1
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                                .fontWeight(.semibold)
                            
                            Image(systemName: currentPage == pages.count - 1 ? "checkmark" : "arrow.right")
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Theme.accentPrimary, Theme.accentPrimary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Theme.accentPrimary.opacity(0.3), radius: 10, y: 5)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showPermissions) {
            PermissionsView(onComplete: {
                hasCompletedOnboarding = true
            })
        }
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let description: String
    let features: [OnboardingFeature]
    var useAppLogo: Bool = false
}

struct OnboardingFeature: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var isAnimated = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Animated Icon
            ZStack {
                // Outer glow
                Circle()
                    .fill(page.iconColor.opacity(0.1))
                    .frame(width: 180, height: 180)
                    .scaleEffect(isAnimated ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimated)
                
                // Inner circle
                Circle()
                    .fill(page.iconColor.opacity(0.15))
                    .frame(width: 140, height: 140)
                
                // Icon or App Logo
                if page.useAppLogo {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .shadow(color: page.iconColor.opacity(0.5), radius: 20)
                } else {
                    Image(systemName: page.icon)
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [page.iconColor, page.iconColor.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: page.iconColor.opacity(0.5), radius: 20)
                }
            }
            .onAppear {
                isAnimated = true
            }
            
            // Text content
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.headline)
                    .foregroundStyle(page.iconColor)
                
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Features list
            if !page.features.isEmpty {
                VStack(spacing: 12) {
                    ForEach(page.features) { feature in
                        HStack(spacing: 12) {
                            Image(systemName: feature.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(page.iconColor)
                                .frame(width: 24)
                            
                            Text(feature.text)
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 48)
                    }
                }
                .padding(.top, 8)
            }
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Permissions View
struct PermissionsView: View {
    let onComplete: () -> Void
    
    @State private var notificationStatus: PermissionStatus = .notDetermined
    @State private var isRequestingNotification = false
    
    enum PermissionStatus {
        case notDetermined, granted, denied
    }
    
    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Theme.accentPrimary.opacity(0.15))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Theme.accentPrimary)
                }
                
                // Title
                VStack(spacing: 8) {
                    Text("Enable Notifications")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Stay informed about security threats")
                        .font(.body)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                // Permission explanation
                VStack(alignment: .leading, spacing: 16) {
                    PermissionRow(
                        icon: "exclamationmark.shield.fill",
                        title: "Security Alerts",
                        description: "Get notified when suspicious activity is detected"
                    )
                    
                    PermissionRow(
                        icon: "moon.stars.fill",
                        title: "Sleep Guard Reports",
                        description: "Receive overnight monitoring summaries"
                    )
                    
                    PermissionRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Threshold Warnings",
                        description: "Know when data usage exceeds your limits"
                    )
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    Button {
                        requestNotificationPermission()
                    } label: {
                        HStack {
                            if isRequestingNotification {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: statusIcon)
                                Text(statusText)
                            }
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(statusColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .disabled(notificationStatus == .granted)
                    
                    Button {
                        onComplete()
                    } label: {
                        Text(notificationStatus == .notDetermined ? "Maybe Later" : "Continue")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            checkNotificationStatus()
        }
    }
    
    private var statusIcon: String {
        switch notificationStatus {
        case .notDetermined: return "bell.fill"
        case .granted: return "checkmark.circle.fill"
        case .denied: return "gear"
        }
    }
    
    private var statusText: String {
        switch notificationStatus {
        case .notDetermined: return "Enable Notifications"
        case .granted: return "Notifications Enabled"
        case .denied: return "Open Settings"
        }
    }
    
    private var statusColor: Color {
        switch notificationStatus {
        case .notDetermined: return Theme.accentPrimary
        case .granted: return Theme.statusSafe
        case .denied: return Theme.statusWarning
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    notificationStatus = .granted
                case .denied:
                    notificationStatus = .denied
                default:
                    notificationStatus = .notDetermined
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        if notificationStatus == .denied {
            // Open settings
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            return
        }
        
        isRequestingNotification = true
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                isRequestingNotification = false
                notificationStatus = granted ? .granted : .denied
            }
        }
    }
}

// MARK: - Permission Row
struct PermissionRow: View {
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
                    .foregroundStyle(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }
}

// MARK: - Particle View (Background Animation)
struct ParticleView: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geo.size)
                animateParticles(in: geo.size)
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        particles = (0..<20).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 2...6),
                color: [Color.cyan, Color.purple, Color.blue].randomElement()!.opacity(0.3),
                opacity: Double.random(in: 0.1...0.4)
            )
        }
    }
    
    private func animateParticles(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            for i in particles.indices {
                particles[i].position.y -= CGFloat.random(in: 0.5...1.5)
                particles[i].position.x += CGFloat.random(in: -0.5...0.5)
                
                if particles[i].position.y < -10 {
                    particles[i].position.y = size.height + 10
                    particles[i].position.x = CGFloat.random(in: 0...size.width)
                }
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var color: Color
    var opacity: Double
}

// MARK: - Preview
#Preview {
    OnboardingView()
}
