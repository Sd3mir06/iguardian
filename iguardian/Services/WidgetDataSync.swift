//
//  WidgetDataSync.swift
//  iguardian
//
//  Helper class to sync data to widgets via App Group
//  Add this file to the MAIN APP target
//

import Foundation
import WidgetKit

class WidgetDataSync {
    static let shared = WidgetDataSync()
    
    private let appGroupID = "group.com.sukrudemir.iguardian"
    private var defaults: UserDefaults?
    
    private init() {
        defaults = UserDefaults(suiteName: appGroupID)
    }
    
    /// Call this whenever monitoring data updates
    func syncToWidget(
        uploadSpeed: Double,
        downloadSpeed: Double,
        threatScore: Int,
        threatLevel: Int,
        isIdle: Bool
    ) {
        guard let defaults = defaults else {
            print("WidgetDataSync: Failed to access App Group")
            return
        }
        
        defaults.set(uploadSpeed, forKey: "widget_uploadSpeed")
        defaults.set(downloadSpeed, forKey: "widget_downloadSpeed")
        defaults.set(threatScore, forKey: "widget_threatScore")
        defaults.set(threatLevel, forKey: "widget_threatLevel")
        defaults.set(isIdle, forKey: "widget_isIdle")
        defaults.set(Date(), forKey: "widget_lastUpdate")
        
        // Request widget refresh
        WidgetCenter.shared.reloadTimelines(ofKind: "iGuardianWidget")
    }
    
    /// Call this when monitoring starts
    func notifyMonitoringStarted() {
        syncToWidget(uploadSpeed: 0, downloadSpeed: 0, threatScore: 0, threatLevel: 0, isIdle: false)
    }
    
    /// Call this when monitoring stops
    func notifyMonitoringStopped() {
        guard let defaults = defaults else { return }
        defaults.removeObject(forKey: "widget_lastUpdate")
        WidgetCenter.shared.reloadTimelines(ofKind: "iGuardianWidget")
    }
}

/*
 SETUP INSTRUCTIONS:
 
 1. Enable App Groups in Xcode:
    - Select your main app target → Signing & Capabilities → + Capability → App Groups
    - Add: group.com.sukrudemir.iguardian
    
 2. Do the same for your Widget Extension target
 
 3. In MonitoringManager.swift, add this call in updateLiveActivity():
 
    // Sync to widget
    WidgetDataSync.shared.syncToWidget(
        uploadSpeed: networkMonitor.uploadBytesPerSecond,
        downloadSpeed: networkMonitor.downloadBytesPerSecond,
        threatScore: threatScore,
        threatLevel: threatLevelInt,
        isIdle: isDeviceIdle
    )
 
 4. In startMonitoring(), add:
    WidgetDataSync.shared.notifyMonitoringStarted()
 
 5. In stopMonitoring(), add:
    WidgetDataSync.shared.notifyMonitoringStopped()
*/
