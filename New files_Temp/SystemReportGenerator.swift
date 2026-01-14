//
//  SystemReportGenerator.swift
//  iguardian
//
//  Comprehensive system report with all available iOS information
//

import Foundation
import UIKit
import Network
import CoreTelephony
import SystemConfiguration.CaptiveNetwork
import LocalAuthentication

// MARK: - System Report Model
struct SystemReport {
    let generatedAt: Date
    
    // Network
    var networkType: String = "Unknown"
    var wifiSSID: String?
    var wifiBSSID: String?
    var externalIP: String?
    var internalIP: String?
    var isVPNActive: Bool = false
    var vpnProtocol: String?
    var carrierName: String?
    var carrierCountry: String?
    var cellularTechnology: String?
    
    // Power
    var batteryLevel: Int = 0
    var batteryState: String = "Unknown"
    var isLowPowerMode: Bool = false
    var thermalState: String = "Nominal"
    
    // Hardware
    var deviceModel: String = "Unknown"
    var deviceModelName: String = "Unknown"
    var cpuArchitecture: String = "Unknown"
    var cpuCoreCount: Int = 0
    var totalRAM: UInt64 = 0
    var usedRAM: UInt64 = 0
    var totalStorage: UInt64 = 0
    var usedStorage: UInt64 = 0
    var screenSize: String = "Unknown"
    var screenScale: CGFloat = 1.0
    var screenBrightness: CGFloat = 0.5
    
    // System
    var osVersion: String = "Unknown"
    var osBuild: String = "Unknown"
    var kernelVersion: String = "Unknown"
    var uptime: TimeInterval = 0
    var bootTime: Date?
    var locale: String = "Unknown"
    var timezone: String = "Unknown"
    var deviceName: String = "Unknown"
    var identifierForVendor: String?
    
    // Security
    var isPasscodeEnabled: Bool = false
    var biometricType: String = "None"
    var isJailbroken: Bool = false
    var isMDMEnrolled: Bool = false
    
    // Session (from MonitoringManager)
    var sessionDuration: TimeInterval = 0
    var sessionUploadMB: Double = 0
    var sessionDownloadMB: Double = 0
    var alertCount: Int = 0
}

// MARK: - System Report Generator
@MainActor
class SystemReportGenerator: ObservableObject {
    static let shared = SystemReportGenerator()
    
    @Published var currentReport: SystemReport?
    @Published var isGenerating: Bool = false
    
    private init() {}
    
    // MARK: - Generate Full Report
    func generateReport() async -> SystemReport {
        isGenerating = true
        
        var report = SystemReport(generatedAt: Date())
        
        // Gather all information
        await gatherNetworkInfo(&report)
        gatherPowerInfo(&report)
        gatherHardwareInfo(&report)
        gatherSystemInfo(&report)
        gatherSecurityInfo(&report)
        gatherSessionInfo(&report)
        
        currentReport = report
        isGenerating = false
        
        return report
    }
    
    // MARK: - Network Information
    private func gatherNetworkInfo(_ report: inout SystemReport) async {
        // Network type detection
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        
        await withCheckedContinuation { continuation in
            monitor.pathUpdateHandler = { path in
                if path.usesInterfaceType(.wifi) {
                    report.networkType = "WiFi"
                } else if path.usesInterfaceType(.cellular) {
                    report.networkType = "Cellular"
                } else if path.usesInterfaceType(.wiredEthernet) {
                    report.networkType = "Ethernet"
                } else {
                    report.networkType = "None"
                }
                monitor.cancel()
                continuation.resume()
            }
            monitor.start(queue: queue)
        }
        
        // WiFi SSID (requires location permission or entitlement)
        if let interfaces = CNCopySupportedInterfaces() as? [String] {
            for interface in interfaces {
                if let info = CNCopyCurrentNetworkInfo(interface as CFString) as NSDictionary? {
                    report.wifiSSID = info[kCNNetworkInfoKeySSID as String] as? String
                    report.wifiBSSID = info[kCNNetworkInfoKeyBSSID as String] as? String
                }
            }
        }
        
        // Internal IP
        report.internalIP = getInternalIP()
        
        // External IP (async fetch)
        report.externalIP = await fetchExternalIP()
        
        // VPN Detection
        let (isVPN, vpnProto) = detectVPN()
        report.isVPNActive = isVPN
        report.vpnProtocol = vpnProto
        
        // Carrier Info
        let carrierInfo = getCarrierInfo()
        report.carrierName = carrierInfo.name
        report.carrierCountry = carrierInfo.country
        report.cellularTechnology = carrierInfo.technology
    }
    
    private func getInternalIP() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = firstAddr
        while true {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) { // IPv4
                let name = String(cString: interface.ifa_name)
                if name == "en0" { // WiFi
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                               &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
            
            guard let next = interface.ifa_next else { break }
            ptr = next
        }
        
        return address
    }
    
    private func fetchExternalIP() async -> String? {
        // Try multiple services
        let services = [
            "https://api.ipify.org",
            "https://icanhazip.com",
            "https://api64.ipify.org"
        ]
        
        for service in services {
            guard let url = URL(string: service) else { continue }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let ip = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    return ip
                }
            } catch {
                continue
            }
        }
        
        return nil
    }
    
    private func detectVPN() -> (isActive: Bool, protocol: String?) {
        guard let cfDict = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any],
              let scoped = cfDict["__SCOPED__"] as? [String: Any] else {
            return (false, nil)
        }
        
        // Check for VPN interfaces
        for key in scoped.keys {
            if key.contains("tap") || key.contains("tun") || key.contains("ppp") || 
               key.contains("ipsec") || key.contains("utun") {
                
                var vpnProtocol = "Unknown"
                if key.contains("ipsec") {
                    vpnProtocol = "IPSec"
                } else if key.contains("utun") {
                    vpnProtocol = "WireGuard/IKEv2"
                } else if key.contains("ppp") {
                    vpnProtocol = "PPTP/L2TP"
                } else if key.contains("tun") || key.contains("tap") {
                    vpnProtocol = "OpenVPN"
                }
                
                return (true, vpnProtocol)
            }
        }
        
        return (false, nil)
    }
    
    private func getCarrierInfo() -> (name: String?, country: String?, technology: String?) {
        let networkInfo = CTTelephonyNetworkInfo()
        
        var carrierName: String?
        var countryCode: String?
        var technology: String?
        
        if let carriers = networkInfo.serviceSubscriberCellularProviders {
            for (_, carrier) in carriers {
                carrierName = carrier.carrierName
                countryCode = carrier.isoCountryCode?.uppercased()
                break
            }
        }
        
        if let radioTech = networkInfo.serviceCurrentRadioAccessTechnology?.values.first {
            switch radioTech {
            case CTRadioAccessTechnologyLTE:
                technology = "4G LTE"
            case CTRadioAccessTechnologyNRNSA, CTRadioAccessTechnologyNR:
                technology = "5G"
            case CTRadioAccessTechnologyWCDMA, CTRadioAccessTechnologyHSDPA, CTRadioAccessTechnologyHSUPA:
                technology = "3G"
            case CTRadioAccessTechnologyEdge, CTRadioAccessTechnologyGPRS:
                technology = "2G"
            default:
                technology = "Unknown"
            }
        }
        
        return (carrierName, countryCode, technology)
    }
    
    // MARK: - Power Information
    private func gatherPowerInfo(_ report: inout SystemReport) {
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        // Battery Level
        let level = UIDevice.current.batteryLevel
        report.batteryLevel = level >= 0 ? Int(level * 100) : -1
        
        // Battery State
        switch UIDevice.current.batteryState {
        case .charging:
            report.batteryState = "Charging"
        case .full:
            report.batteryState = "Full"
        case .unplugged:
            report.batteryState = "Discharging"
        case .unknown:
            report.batteryState = "Unknown"
        @unknown default:
            report.batteryState = "Unknown"
        }
        
        // Low Power Mode
        report.isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        // Thermal State
        switch ProcessInfo.processInfo.thermalState {
        case .nominal:
            report.thermalState = "Nominal"
        case .fair:
            report.thermalState = "Fair"
        case .serious:
            report.thermalState = "Serious"
        case .critical:
            report.thermalState = "Critical"
        @unknown default:
            report.thermalState = "Unknown"
        }
    }
    
    // MARK: - Hardware Information
    private func gatherHardwareInfo(_ report: inout SystemReport) {
        // Device Model
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }
        report.deviceModel = modelCode
        report.deviceModelName = getDeviceName(from: modelCode)
        
        // CPU
        report.cpuArchitecture = "Apple Silicon (ARM64)"
        report.cpuCoreCount = ProcessInfo.processInfo.processorCount
        
        // RAM
        report.totalRAM = ProcessInfo.processInfo.physicalMemory
        report.usedRAM = getUsedMemory()
        
        // Storage
        let (total, used) = getStorageInfo()
        report.totalStorage = total
        report.usedStorage = used
        
        // Screen
        let screen = UIScreen.main
        report.screenSize = String(format: "%.1f\"", getScreenDiagonal())
        report.screenScale = screen.scale
        report.screenBrightness = screen.brightness
    }
    
    private func getDeviceName(from modelCode: String) -> String {
        let deviceMap: [String: String] = [
            // iPhone 15 Series
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",
            "iPhone15,4": "iPhone 15",
            "iPhone15,5": "iPhone 15 Plus",
            // iPhone 14 Series
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone14,7": "iPhone 14",
            "iPhone14,8": "iPhone 14 Plus",
            // iPhone 13 Series
            "iPhone14,2": "iPhone 13 Pro",
            "iPhone14,3": "iPhone 13 Pro Max",
            "iPhone14,4": "iPhone 13 mini",
            "iPhone14,5": "iPhone 13",
            // iPhone 12 Series
            "iPhone13,1": "iPhone 12 mini",
            "iPhone13,2": "iPhone 12",
            "iPhone13,3": "iPhone 12 Pro",
            "iPhone13,4": "iPhone 12 Pro Max",
            // iPhone SE
            "iPhone14,6": "iPhone SE (3rd gen)",
            "iPhone12,8": "iPhone SE (2nd gen)",
            // Simulator
            "x86_64": "Simulator",
            "arm64": "Simulator"
        ]
        
        return deviceMap[modelCode] ?? modelCode
    }
    
    private func getUsedMemory() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? info.resident_size : 0
    }
    
    private func getStorageInfo() -> (total: UInt64, used: UInt64) {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) else {
            return (0, 0)
        }
        
        let total = (attrs[.systemSize] as? UInt64) ?? 0
        let free = (attrs[.systemFreeSize] as? UInt64) ?? 0
        let used = total - free
        
        return (total, used)
    }
    
    private func getScreenDiagonal() -> Double {
        let screen = UIScreen.main
        let bounds = screen.nativeBounds
        let scale = screen.nativeScale
        
        // Points per inch varies by device, approximate
        let ppi: Double = 460 // Average for modern iPhones
        
        let widthInches = Double(bounds.width) / scale / ppi
        let heightInches = Double(bounds.height) / scale / ppi
        
        return sqrt(widthInches * widthInches + heightInches * heightInches)
    }
    
    // MARK: - System Information
    private func gatherSystemInfo(_ report: inout SystemReport) {
        // iOS Version
        report.osVersion = UIDevice.current.systemVersion
        
        // Build Number
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            // Get actual OS build
            var size = 0
            sysctlbyname("kern.osversion", nil, &size, nil, 0)
            var osBuild = [CChar](repeating: 0, count: size)
            sysctlbyname("kern.osversion", &osBuild, &size, nil, 0)
            report.osBuild = String(cString: osBuild)
        }
        
        // Kernel Version
        var size = 0
        sysctlbyname("kern.osrelease", nil, &size, nil, 0)
        var kernelVersion = [CChar](repeating: 0, count: size)
        sysctlbyname("kern.osrelease", &kernelVersion, &size, nil, 0)
        report.kernelVersion = "Darwin " + String(cString: kernelVersion)
        
        // Uptime
        report.uptime = ProcessInfo.processInfo.systemUptime
        report.bootTime = Date(timeIntervalSinceNow: -report.uptime)
        
        // Locale & Timezone
        report.locale = Locale.current.identifier
        report.timezone = TimeZone.current.identifier
        
        // Device Name
        report.deviceName = UIDevice.current.name
        
        // Vendor ID
        report.identifierForVendor = UIDevice.current.identifierForVendor?.uuidString
    }
    
    // MARK: - Security Information
    private func gatherSecurityInfo(_ report: inout SystemReport) {
        // Biometric Type
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID:
                report.biometricType = "Face ID"
            case .touchID:
                report.biometricType = "Touch ID"
            case .opticID:
                report.biometricType = "Optic ID"
            case .none:
                report.biometricType = "None"
            @unknown default:
                report.biometricType = "Unknown"
            }
            report.isPasscodeEnabled = true
        } else {
            report.biometricType = "None"
            // Check if passcode is enabled without biometrics
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                report.isPasscodeEnabled = true
            }
        }
        
        // Jailbreak Detection
        report.isJailbroken = checkJailbreak()
        
        // MDM Check (basic)
        report.isMDMEnrolled = checkMDM()
    }
    
    private func checkJailbreak() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        // Check for common jailbreak files
        let paths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/usr/bin/ssh",
            "/var/cache/apt",
            "/var/lib/cydia",
            "/var/tmp/cydia.log",
            "/Applications/Sileo.app",
            "/var/jb"
        ]
        
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // Check if app can write outside sandbox
        let testPath = "/private/jailbreak_test.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            // Expected behavior - can't write
        }
        
        // Check for suspicious URL schemes
        if let url = URL(string: "cydia://package/com.test") {
            if UIApplication.shared.canOpenURL(url) {
                return true
            }
        }
        
        return false
        #endif
    }
    
    private func checkMDM() -> Bool {
        // Check for MDM profiles
        let profilePaths = [
            "/var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles/ProfileMeta.plist"
        ]
        
        for path in profilePaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Session Information
    private func gatherSessionInfo(_ report: inout SystemReport) {
        let manager = MonitoringManager.shared
        
        report.sessionDuration = manager.networkMonitor.sessionDuration
        report.sessionUploadMB = manager.networkMonitor.sessionUploadMB
        report.sessionDownloadMB = manager.networkMonitor.sessionDownloadMB
        report.alertCount = manager.recentActivity.filter { 
            $0.type == .alert || $0.type == .critical || $0.type == .warning 
        }.count
    }
    
    // MARK: - Format Report as Text
    func formatReportAsText(_ report: SystemReport) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let uptimeFormatted = formatUptime(report.uptime)
        let bootFormatted: String
        if let boot = report.bootTime {
            let bootFormatter = DateFormatter()
            bootFormatter.dateFormat = "dd MMM yyyy, HH:mm"
            bootFormatted = bootFormatter.string(from: boot)
        } else {
            bootFormatted = "Unknown"
        }
        
        return """
╔══════════════════════════════════════════╗
║       🛡️ GUARDIAN SYSTEM REPORT          ║
╠══════════════════════════════════════════╣
║ DATE: \(dateFormatter.string(from: report.generatedAt).padding(toLength: 32, withPad: " ", startingAt: 0))║
╠══════════════════════════════════════════╣
║ 📡 NETWORK                               ║
├──────────────────────────────────────────┤
║ Type:      \(report.networkType.padding(toLength: 28, withPad: " ", startingAt: 0))║
\(report.wifiSSID != nil ? "║ SSID:      \(report.wifiSSID!.padding(toLength: 28, withPad: " ", startingAt: 0))║\n" : "")\
║ Ext IP:    \((report.externalIP ?? "Unavailable").prefix(28).padding(toLength: 28, withPad: " ", startingAt: 0))║
║ Int IP:    \((report.internalIP ?? "Unavailable").padding(toLength: 28, withPad: " ", startingAt: 0))║
║ VPN:       \((report.isVPNActive ? "● ACTIVE (\(report.vpnProtocol ?? "Unknown"))" : "○ Inactive").padding(toLength: 28, withPad: " ", startingAt: 0))║
\(report.carrierName != nil ? "║ Carrier:   \(report.carrierName!.padding(toLength: 28, withPad: " ", startingAt: 0))║\n" : "")\
\(report.cellularTechnology != nil ? "║ Network:   \(report.cellularTechnology!.padding(toLength: 28, withPad: " ", startingAt: 0))║\n" : "")\
╠══════════════════════════════════════════╣
║ 🔋 POWER                                 ║
├──────────────────────────────────────────┤
║ Battery:   \("\(report.batteryLevel)% (\(report.batteryState))".padding(toLength: 28, withPad: " ", startingAt: 0))║
║ Thermal:   \(thermalEmoji(report.thermalState)) \(report.thermalState.padding(toLength: 25, withPad: " ", startingAt: 0))║
║ Low Power: \((report.isLowPowerMode ? "ON" : "OFF").padding(toLength: 28, withPad: " ", startingAt: 0))║
╠══════════════════════════════════════════╣
║ 💾 HARDWARE                              ║
├──────────────────────────────────────────┤
║ Model:     \(report.deviceModelName.padding(toLength: 28, withPad: " ", startingAt: 0))║
║ Chip:      \("\(report.cpuArchitecture)".padding(toLength: 28, withPad: " ", startingAt: 0))║
║ Cores:     \("\(report.cpuCoreCount) cores".padding(toLength: 28, withPad: " ", startingAt: 0))║
║ RAM:       \(formatBytes(report.totalRAM).padding(toLength: 28, withPad: " ", startingAt: 0))║
║ Storage:   \("\(formatBytes(report.usedStorage)) / \(formatBytes(report.totalStorage))".padding(toLength: 28, withPad: " ", startingAt: 0))║
║ Screen:    \("\(report.screenSize) @\(Int(report.screenScale))x".padding(toLength: 28, withPad: " ", startingAt: 0))║
║ Brightness:\("\(Int(report.screenBrightness * 100))%".padding(toLength: 28, withPad: " ", startingAt: 0))║
╠══════════════════════════════════════════╣
║ ⚙️ SYSTEM                                ║
├──────────────────────────────────────────┤
║ iOS:       \("\(report.osVersion) (\(report.osBuild))".padding(toLength: 28, withPad: " ", startingAt: 0))║
║ Kernel:    \(report.kernelVersion.prefix(28).padding(toLength: 28, withPad: " ", startingAt: 0))║
║ Uptime:    \(uptimeFormatted.padding(toLength: 28, withPad: " ", startingAt: 0))║
║ Boot:      \(bootFormatted.padding(toLength: 28, withPad: " ", startingAt: 0))║
║ Locale:    \(report.locale.padding(toLength: 28, withPad: " ", startingAt: 0))║
║ Timezone:  \(report.timezone.prefix(28).padding(toLength: 28, withPad: " ", startingAt: 0))║
╠══════════════════════════════════════════╣
║ 🔒 SECURITY                              ║
├──────────────────────────────────────────┤
║ Passcode:  \((report.isPasscodeEnabled ? "● Enabled" : "○ Disabled").padding(toLength: 28, withPad: " ", startingAt: 0))║
║ Biometric: \(report.biometricType.padding(toLength: 28, withPad: " ", startingAt: 0))║
║ Jailbreak: \((report.isJailbroken ? "⚠️ DETECTED" : "✓ Not Detected").padding(toLength: 28, withPad: " ", startingAt: 0))║
║ MDM:       \((report.isMDMEnrolled ? "Enrolled" : "Not Enrolled").padding(toLength: 28, withPad: " ", startingAt: 0))║
╠══════════════════════════════════════════╣
║ 📊 CURRENT SESSION                       ║
├──────────────────────────────────────────┤
║ Monitoring:\(formatUptime(report.sessionDuration).padding(toLength: 28, withPad: " ", startingAt: 0))║
║ Upload:    \(String(format: "%.1f MB (session)", report.sessionUploadMB).padding(toLength: 28, withPad: " ", startingAt: 0))║
║ Download:  \(String(format: "%.1f MB (session)", report.sessionDownloadMB).padding(toLength: 28, withPad: " ", startingAt: 0))║
║ Alerts:    \("\(report.alertCount)".padding(toLength: 28, withPad: " ", startingAt: 0))║
╚══════════════════════════════════════════╝
        SECURE • PRIVATE • PROTECTED
"""
    }
    
    // MARK: - Helpers
    private func formatUptime(_ interval: TimeInterval) -> String {
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        
        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
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
