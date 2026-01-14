//
//  OnboardingView.swift
//  iguardian
//
//  Welcome and onboarding flow
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "shield.checkered",
            iconColor: .cyan,
            title: "Welcome to iGuardian",
            subtitle: "Your personal security monitor",
            description: "iGuardian watches for suspicious background activity that could indicate your device is being monitored."
        ),
        OnboardingPage(
            icon: "chart.bar.xaxis",
            iconColor: .green,
            title: "Real-Time Monitoring",
            subtitle: "Know what's happening",
            description: "Track network traffic, CPU usage, battery drain, and thermal state in real-time."
        ),
        OnboardingPage(
            icon: "exclamationmark.triangle.fill",
            iconColor: .orange,
            title: "Threat Detection",
            subtitle: "Stay informed",
            description: "Get alerts when patterns suggest possible screen surveillance or data exfiltration."
        ),
        OnboardingPage(
            icon: "moon.stars.fill",
            iconColor: .purple,
            title: "Sleep Guard",
            subtitle: "Protection while you rest",
            description: "Monitor your device overnight and receive a security report in the morning."
        )
    ]
    
    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Theme.accentPrimary : Theme.textTertiary)
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentPage == index ? 1.2 : 1)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.bottom, 32)
                
                // Buttons
                VStack(spacing: 12) {
                    if currentPage == pages.count - 1 {
                        Button {
                            hasCompletedOnboarding = true
                        } label: {
                            Text("Get Started")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.accentPrimary)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            withAnimation { currentPage += 1 }
                        } label: {
                            Text("Continue")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.accentPrimary)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if currentPage < pages.count - 1 {
                        Button {
                            hasCompletedOnboarding = true
                        } label: {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let description: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.15))
                    .frame(width: 140, height: 140)
                
                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(page.iconColor)
            }
            
            // Text
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.title3)
                    .foregroundStyle(Theme.accentPrimary)
                
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
