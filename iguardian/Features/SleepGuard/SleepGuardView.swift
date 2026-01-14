//
//  SleepGuardView.swift
//  iguardian
//
//  Sleep Guard UI for overnight monitoring
//

import SwiftUI

struct SleepGuardView: View {
    @StateObject private var manager = SleepGuardManager.shared
    @StateObject private var store = StoreManager.shared
    @State private var showPaywall = false
    
    // Timer for updating elapsed time
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Status Card with Timer
                    statusCard
                    
                    // Schedule Settings
                    if store.isPremium {
                        scheduleCard
                        
                        // Quick Actions
                        actionsCard
                        
                        // Last Report Preview
                        if let lastReport = manager.lastReport {
                            lastReportCard(lastReport)
                        }
                        
                        // History
                        historySection
                    } else {
                        premiumPrompt
                    }
                }
                .padding()
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle("Sleep Guard")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onAppear {
                if manager.isMonitoring {
                    startTimer()
                }
            }
            .onDisappear {
                stopTimer()
            }
            .onChange(of: manager.isMonitoring) { _, isMonitoring in
                if isMonitoring {
                    startTimer()
                } else {
                    stopTimer()
                }
            }
        }
    }
    
    // MARK: - Timer Control
    private func startTimer() {
        timer?.invalidate()
        updateElapsedTime()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateElapsedTime()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        elapsedTime = 0
    }
    
    private func updateElapsedTime() {
        if let session = manager.currentSession {
            elapsedTime = Date().timeIntervalSince(session.startTime)
        }
    }
    
    private var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // MARK: - Status Card
    private var statusCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(manager.isMonitoring ? Theme.statusSafe.opacity(0.2) : Theme.backgroundTertiary)
                    .frame(width: 120, height: 120)
                
                if manager.isMonitoring {
                    // Pulsing animation
                    Circle()
                        .stroke(Theme.statusSafe.opacity(0.5), lineWidth: 2)
                        .frame(width: 130, height: 130)
                        .scaleEffect(manager.isMonitoring ? 1.1 : 1.0)
                        .opacity(manager.isMonitoring ? 0 : 1)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: manager.isMonitoring)
                }
                
                Image(systemName: manager.isMonitoring ? "moon.stars.fill" : "moon.zzz")
                    .font(.system(size: 48))
                    .foregroundStyle(manager.isMonitoring ? Theme.statusSafe : Theme.textTertiary)
            }
            
            Text(manager.isMonitoring ? "Monitoring Active" : "Sleep Guard Off")
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)
            
            // Live Timer
            if manager.isMonitoring {
                VStack(spacing: 4) {
                    Text(formattedElapsedTime)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.accentPrimary)
                    
                    Text("Session Duration")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.top, 8)
            }
            
            if manager.isEnabled && !manager.isMonitoring {
                Text("Scheduled: \(manager.scheduleDescription)")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Schedule Card
    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(Theme.accentPrimary)
                Text("Schedule")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }
            
            Toggle(isOn: $manager.isEnabled) {
                Text("Auto-start at bedtime")
                    .foregroundStyle(Theme.textPrimary)
            }
            .tint(Theme.accentPrimary)
            
            if manager.isEnabled {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Start")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        Text("\(manager.startHour):\(String(format: "%02d", manager.startMinute))")
                            .font(.title3.bold())
                            .foregroundStyle(Theme.textPrimary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .foregroundStyle(Theme.textTertiary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("End")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        Text("\(manager.endHour):\(String(format: "%02d", manager.endMinute))")
                            .font(.title3.bold())
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
            }
        }
        .padding()
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Actions Card
    private var actionsCard: some View {
        VStack(spacing: 12) {
            if manager.isMonitoring {
                Button {
                    manager.endSession()
                } label: {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("End Session")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.statusDanger)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    manager.startSession()
                } label: {
                    HStack {
                        Image(systemName: "moon.stars.fill")
                        Text("Start Sleep Guard Now")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accentPrimary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Last Report Card
    private func lastReportCard(_ session: SleepSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundStyle(Theme.accentPrimary)
                Text("Last Night")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(session.statusSummary)
                    .font(.caption)
            }
            
            HStack(spacing: 24) {
                VStack {
                    Text(session.durationFormatted)
                        .font(.title3.bold())
                        .foregroundStyle(Theme.textPrimary)
                    Text("Duration")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                
                VStack {
                    Text("\(String(format: "%.1f", session.batteryUsed))%")
                        .font(.title3.bold())
                        .foregroundStyle(Theme.textPrimary)
                    Text("Battery Used")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                
                VStack {
                    Text(session.totalUploadFormatted)
                        .font(.title3.bold())
                        .foregroundStyle(Theme.textPrimary)
                    Text("Uploaded")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding()
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - History Section
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("History")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                
                Text("\(manager.sessionHistory.count) sessions")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            
            if manager.sessionHistory.isEmpty {
                Text("Your sleep monitoring sessions will appear here after you complete them.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                ForEach(manager.sessionHistory.prefix(5), id: \.id) { session in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(session.startTime, style: .date)
                                .font(.subheadline)
                                .foregroundStyle(Theme.textPrimary)
                            Text(session.durationFormatted)
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Text(session.statusSummary)
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Premium Prompt
    private var premiumPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.premiumGradient)
            
            Text("Sleep Guard")
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)
            
            Text("Monitor your device overnight and get a detailed security report in the morning.")
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
        .padding()
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    SleepGuardView()
}
