//
//  SystemInfoProvider.swift
//  iguardian
//
//  Gathers hardware, network, and system information for the System Report.
//

import Foundation
import UIKit
import Combine
import SystemConfiguration

struct SystemDetails {
    // Network
    var externalIP: String = "Fetching..."
    var localIP: String = "Unknown"
    var vpnStatus: String = "Inactive"
    var dnsServers: [String] = []
    
    // Hardware
    var model: String = "Unknown"
    var cpu: String = "Unknown"
    var ramTotal: String = "Unknown"
    var ramAvailable: String = "Unknown"
    var storageTotal: String = "Unknown"
    var storageFree: String = "Unknown"
    
    // System
    var uptime: String = "Unknown"
    var bootTime: String = "Unknown"
    var osVersion: String = "Unknown"
    var osBuild: String = "Unknown"
    var kernelVersion: String = "Unknown"
}

@MainActor
class SystemInfoProvider: ObservableObject {
    static let shared = SystemInfoProvider()
    
    @Published var details = SystemDetails()
    @Published var isFetchingExternalIP = false
    
    private init() {
        refreshAll()
    }
    
    func refreshAll() {
        fetchHardwareInfo()
        fetchNetworkInfo()
        fetchSystemUptime()
        fetchOSInfo()
        Task {
            await fetchExternalIP()
        }
    }
    
    // MARK: - Network Information
    
    private func fetchNetworkInfo() {
        details.localIP = getLocalIPAddress() ?? "Not Connected"
        details.vpnStatus = isVPNActive() ? "ACTIVE (TUNNEL)" : "INACTIVE"
        // In a real app, getting DNS requires more complex low-level code, 
        // using a placeholder or common system resolvers for now.
        details.dnsServers = ["System Default"]
    }
    
    private func fetchExternalIP() async {
        isFetchingExternalIP = true
        defer { isFetchingExternalIP = false }
        
        let url = URL(string: "https://api64.ipify.org?format=json")!
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
               let ip = json["ip"] {
                details.externalIP = ip
            } else {
                details.externalIP = "Unavailable"
            }
        } catch {
            details.externalIP = "Offline / Denied"
        }
    }
    
    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                guard let interface = ptr?.pointee else { continue }
                let flags = Int32(interface.ifa_flags)
                let addr = interface.ifa_addr.pointee
                
                if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                    if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                        let name = String(cString: interface.ifa_name)
                        if name == "en0" || name == "pdp_ip0" {
                            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                            if getnameinfo(interface.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                                address = String(cString: hostname)
                            }
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
    
    private func isVPNActive() -> Bool {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return false }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            let name = String(cString: ptr!.pointee.ifa_name)
            if name.contains("utun") || name.contains("tun") || name.contains("ppp") {
                return true
            }
            ptr = ptr?.pointee.ifa_next
        }
        return false
    }
    
    // MARK: - Hardware Information
    
    private func fetchHardwareInfo() {
        // Model
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        details.model = identifier // Simple identifier like iPhone16,1
        
        // Storage
        if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let totalSize = attributes[.systemSize] as? Int64,
           let freeSize = attributes[.systemFreeSize] as? Int64 {
            details.storageTotal = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .decimal)
            details.storageFree = ByteCountFormatter.string(fromByteCount: freeSize, countStyle: .decimal)
        }
        
        // Memory (RAM)
        let totalRAM = ProcessInfo.processInfo.physicalMemory
        details.ramTotal = ByteCountFormatter.string(fromByteCount: Int64(totalRAM), countStyle: .memory)
        
        // CPU (Architecture)
        #if arch(arm64)
        details.cpu = "Apple Silicon (ARM64)"
        #else
        details.cpu = "x86_64"
        #endif
    }
    
    // MARK: - System Uptime
    
    private func fetchSystemUptime() {
        let uptime = ProcessInfo.processInfo.systemUptime
        let days = Int(uptime) / 86400
        let hours = (Int(uptime) % 86400) / 3600
        let minutes = (Int(uptime) % 3600) / 60
        details.uptime = "\(days)d \(hours)h \(minutes)m"
        
        let bootDate = Date().addingTimeInterval(-uptime)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        details.bootTime = formatter.string(from: bootDate)
    }
    
    // MARK: - OS Info
    
    private func fetchOSInfo() {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        details.osVersion = "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        
        // Kernel version using uname
        var systemInfo = utsname()
        uname(&systemInfo)
        let releaseMirror = Mirror(reflecting: systemInfo.release)
        let release = releaseMirror.children.reduce("") { release, element in
            guard let value = element.value as? Int8, value != 0 else { return release }
            return release + String(UnicodeScalar(UInt8(value)))
        }
        details.kernelVersion = release // Current Darwin kernel version
        
        // OS Build (using direct system call)
        var size = 0
        sysctlbyname("kern.osversion", nil, &size, nil, 0)
        var build = [CChar](repeating: 0, count: size)
        sysctlbyname("kern.osversion", &build, &size, nil, 0)
        details.osBuild = String(cString: build)
    }
}
