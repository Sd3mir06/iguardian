//
//  SystemReportView.swift
//  iguardian
//
//  Display the comprehensive system report
//

import SwiftUI

struct SystemReportView: View {
    @StateObject private var generator = SystemReportGenerator.shared
    @ObservedObject var monitoringManager: MonitoringManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var report: SystemReport?
    @State private var reportText: String = ""
    @State private var showShareSheet = false
    @State private var showCopiedToast = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if generator.isGenerating {
                    loadingView
                } else if let report = report {
                    reportContentView(report)
                } else {
                    generateButton
                }
                
                // Copied Toast
                if showCopiedToast {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Copied to clipboard")
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.9))
                        .cornerRadius(10)
                        .padding(.bottom, 50)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(100)
                }
            }
            .navigationTitle("System Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Theme.accentPrimary)
                }
                
                if report != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                copyToClipboard()
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            
                            Button {
                                showShareSheet = true
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            
                            Button {
                                Task {
                                    await regenerateReport()
                                }
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(Theme.accentPrimary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [reportText])
            }
        }
        .task {
            await generateReport()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Theme.accentPrimary)
            
            Text("Generating Report...")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Gathering system information")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Generate Button
    private var generateButton: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Theme.accentPrimary)
            
            Text("System Report")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("Generate a comprehensive report of your device")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button {
                Task {
                    await generateReport()
                }
            } label: {
                Text("Generate Report")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Theme.accentPrimary)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
    
    // MARK: - Report Content View
    private func reportContentView(_ report: SystemReport) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                reportHeader(report)
                
                // Sections
                networkSection(report)
                powerSection(report)
                hardwareSection(report)
                systemSection(report)
                securitySection(report)
                sessionSection(report)
                
                // Footer
                reportFooter
            }
            .padding()
        }
    }
    
    // MARK: - Report Header
    private func reportHeader(_ report: SystemReport) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "shield.checkered")
                    .font(.title)
                    .foregroundColor(Theme.accentPrimary)
                
                Text("GUARDIAN SYSTEM REPORT")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .kerning(2)
            }
            
            Text(report.generatedAt, style: .date)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
            
            Text(report.generatedAt, style: .time)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.accentPrimary.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.bottom, 12)
    }
    
    // MARK: - Section Views
    private func networkSection(_ report: SystemReport) -> some View {
        ReportSection(title: "NETWORK", icon: "antenna.radiowaves.left.and.right", color: .cyan) {
            ReportRow(label: "Type", value: report.networkType)
            if let ssid = report.wifiSSID {
                ReportRow(label: "SSID", value: ssid)
            }
            ReportRow(label: "External IP", value: report.externalIP ?? "Unavailable")
            ReportRow(label: "Internal IP", value: report.internalIP ?? "Unavailable")
            ReportRow(label: "VPN", value: report.isVPNActive ? "● ACTIVE (\(report.vpnProtocol ?? ""))" : "○ Inactive", 
                     valueColor: report.isVPNActive ? .green : .gray)
            if let carrier = report.carrierName {
                ReportRow(label: "Carrier", value: carrier)
            }
            if let tech = report.cellularTechnology {
                ReportRow(label: "Network", value: tech)
            }
        }
    }
    
    private func powerSection(_ report: SystemReport) -> some View {
        ReportSection(title: "POWER", icon: "battery.100", color: .yellow) {
            ReportRow(label: "Battery", value: "\(report.batteryLevel)% (\(report.batteryState))",
                     valueColor: report.batteryLevel < 20 ? .red : .white)
            ReportRow(label: "Thermal", value: "\(thermalEmoji(report.thermalState)) \(report.thermalState)")
            ReportRow(label: "Low Power", value: report.isLowPowerMode ? "ON" : "OFF",
                     valueColor: report.isLowPowerMode ? .orange : .gray)
        }
    }
    
    private func hardwareSection(_ report: SystemReport) -> some View {
        ReportSection(title: "HARDWARE", icon: "cpu", color: .orange) {
            ReportRow(label: "Model", value: report.deviceModelName)
            ReportRow(label: "Chip", value: report.cpuArchitecture)
            ReportRow(label: "Cores", value: "\(report.cpuCoreCount) cores")
            ReportRow(label: "RAM", value: formatBytes(report.totalRAM))
            ReportRow(label: "Storage", value: "\(formatBytes(report.usedStorage)) / \(formatBytes(report.totalStorage))")
            ReportRow(label: "Screen", value: "\(report.screenSize) @\(Int(report.screenScale))x")
            ReportRow(label: "Brightness", value: "\(Int(report.screenBrightness * 100))%")
        }
    }
    
    private func systemSection(_ report: SystemReport) -> some View {
        ReportSection(title: "SYSTEM", icon: "gear", color: .purple) {
            ReportRow(label: "iOS", value: "\(report.osVersion) (\(report.osBuild))")
            ReportRow(label: "Kernel", value: report.kernelVersion)
            ReportRow(label: "Uptime", value: formatUptime(report.uptime))
            if let boot = report.bootTime {
                ReportRow(label: "Boot", value: formatDate(boot))
            }
            ReportRow(label: "Locale", value: report.locale)
            ReportRow(label: "Timezone", value: report.timezone)
        }
    }
    
    private func securitySection(_ report: SystemReport) -> some View {
        ReportSection(title: "SECURITY", icon: "lock.shield", color: .green) {
            ReportRow(label: "Passcode", value: report.isPasscodeEnabled ? "● Enabled" : "○ Disabled",
                     valueColor: report.isPasscodeEnabled ? .green : .red)
            ReportRow(label: "Biometric", value: report.biometricType)
            ReportRow(label: "Jailbreak", value: report.isJailbroken ? "⚠️ DETECTED" : "✓ Not Detected",
                     valueColor: report.isJailbroken ? .red : .green)
            ReportRow(label: "MDM", value: report.isMDMEnrolled ? "Enrolled" : "Not Enrolled")
        }
    }
    
    private func sessionSection(_ report: SystemReport) -> some View {
        ReportSection(title: "SESSION", icon: "chart.line.uptrend.xyaxis", color: .blue) {
            ReportRow(label: "Duration", value: formatUptime(report.sessionDuration))
            ReportRow(label: "Upload", value: String(format: "%.1f MB", report.sessionUploadMB))
            ReportRow(label: "Download", value: String(format: "%.1f MB", report.sessionDownloadMB))
            ReportRow(label: "Alerts", value: "\(report.alertCount)",
                     valueColor: report.alertCount > 0 ? .orange : .green)
        }
    }
    
    private var reportFooter: some View {
        Text("SECURE • PRIVATE • PROTECTED")
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(.gray)
            .kerning(2)
            .padding(.top, 20)
    }
    
    // MARK: - Actions
    private func generateReport() async {
        let newReport = await generator.generateReport()
        report = newReport
        reportText = generator.formatReportAsText(newReport)
    }
    
    private func regenerateReport() async {
        report = nil
        await generateReport()
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = reportText
        withAnimation {
            showCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedToast = false
            }
        }
    }
    
    // MARK: - Helpers
    private func formatUptime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        } else {
            return "\(minutes)m \(seconds)s"
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / (1024 * 1024 * 1024)
        if gb >= 1 {
            return String(format: "%.2f GB", gb)
        } else {
            let mb = Double(bytes) / (1024 * 1024)
            return String(format: "%.0f MB", mb)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        return formatter.string(from: date)
    }
    
    private func thermalEmoji(_ state: String) -> String {
        switch state {
        case "Nominal": return "🟢"
        case "Fair": return "🟡"
        case "Serious": return "🟠"
        case "Critical": return "🔴"
        default: return "⚪"
        }
    }
}

// MARK: - Report Section
struct ReportSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                    .kerning(2)
                Spacer()
            }
            .padding(.bottom, 4)
            
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.bottom, 8)
    }
}

// MARK: - Report Row
struct ReportRow: View {
    let label: String
    let value: String
    var valueColor: Color = .white
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(valueColor)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
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

// MARK: - Preview
#Preview {
    SystemReportView(monitoringManager: MonitoringManager.shared)
        .preferredColorScheme(.dark)
}
