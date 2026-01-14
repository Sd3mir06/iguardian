//
//  SystemReportView.swift
//  iguardian
//
//  Digital Receipt style System Report for iGuardian.
//

import SwiftUI

struct SystemReportView: View {
    @StateObject private var provider = SystemInfoProvider.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showCopySuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        Text("GUARDIAN SYSTEM REPORT")
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.black)
                            .padding(.top, 40)
                        
                        Text("================================")
                            .font(.system(size: 14, design: .monospaced))
                        
                        HStack {
                            Text("ID: IGUARDIAN-\(currentMonthYear)")
                            Spacer()
                            Text("VER: 2.0.1")
                        }
                        .font(.system(size: 12, design: .monospaced))
                        .padding(.vertical, 8)
                        
                        Text("DATE: \(currentDateTime)")
                            .font(.system(size: 12, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("--------------------------------")
                            .font(.system(size: 14, design: .monospaced))
                            .padding(.vertical, 4)
                        
                        // Sections
                        ReceiptSection(title: "NETWORK IDENTITY", entries: [
                            ("EXT IP", provider.details.externalIP),
                            ("INT IP", provider.details.localIP),
                            ("VPN", provider.details.vpnStatus)
                        ])
                        
                        ReceiptSection(title: "HARDWARE SPECS", entries: [
                            ("MODEL", provider.details.model),
                            ("CPU", provider.details.cpu),
                            ("RAM", "\(provider.details.ramTotal)"),
                            ("STORAGE", "\(provider.details.storageFree) FREE / \(provider.details.storageTotal)")
                        ])
                        
                        ReceiptSection(title: "SYSTEM UPTIME", entries: [
                            ("UPTIME", provider.details.uptime),
                            ("BOOT", provider.details.bootTime)
                        ])
                        
                         ReceiptSection(title: "OS / KERNEL", entries: [
                            ("OS", "IOS \(provider.details.osVersion) (\(provider.details.osBuild))"),
                            ("DARWIN", provider.details.kernelVersion)
                        ])
                        
                        Text("================================")
                            .font(.system(size: 14, design: .monospaced))
                            .padding(.top, 20)
                        
                        Text("SECURE. PRIVATE. PROTECTED.")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .padding(.vertical, 10)
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: copyToClipboard) {
                                HStack {
                                    Image(systemName: "doc.on.clipboard")
                                    Text("COPY TO CLIPBOARD")
                                }
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.white)
                            
                            Button(action: { provider.refreshAll() }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("REFRESH REPORT")
                                }
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.white)
                        }
                        .padding(.top, 30)
                        .padding(.bottom, 50)
                    }
                    .padding(.horizontal, 24)
                    .foregroundColor(.white)
                }
                
                // Success Overlay
                if showCopySuccess {
                    VStack {
                        Spacer()
                        Text("COPIED TO CLIPBOARD")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.black)
                            .cornerRadius(4)
                            .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date()).uppercased()
    }
    
    private var currentDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: Date())
    }
    
    private func copyToClipboard() {
        let report = """
        GUARDIAN SYSTEM REPORT
        ================================
        DATE: \(currentDateTime)
        --------------------------------
        NETWORK:
        EXT IP: \(provider.details.externalIP)
        INT IP: \(provider.details.localIP)
        VPN: \(provider.details.vpnStatus)
        --------------------------------
        HARDWARE:
        MODEL: \(provider.details.model)
        CPU: \(provider.details.cpu)
        RAM: \(provider.details.ramTotal)
        STORAGE: \(provider.details.storageFree) / \(provider.details.storageTotal)
        --------------------------------
        SYSTEM:
        UPTIME: \(provider.details.uptime)
        BOOT: \(provider.details.bootTime)
        OS: \(provider.details.osVersion) (\(provider.details.osBuild))
        DARWIN: \(provider.details.kernelVersion)
        ================================
        SECURE. PRIVATE. PROTECTED.
        """
        UIPasteboard.general.string = report
        withAnimation {
            showCopySuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopySuccess = false
            }
        }
    }
}

struct ReceiptSection: View {
    let title: String
    let entries: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("[\(title)]")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .padding(.bottom, 2)
            
            ForEach(entries, id: \.0) { key, value in
                HStack(alignment: .top) {
                    Text(key + ":")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                        .frame(width: 80, alignment: .leading)
                    
                    Text(value.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .lineLimit(2)
                }
            }
            
            Text("--------------------------------")
                .font(.system(size: 14, design: .monospaced))
                .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SystemReportView()
        .preferredColorScheme(.dark)
}
