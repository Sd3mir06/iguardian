//
//  LiveActivityManager.swift
//  iguardian
//
//  Created by Sukru Demir on 14.01.2026.
//

import ActivityKit
import Foundation
import Combine

@MainActor
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published var isActivityActive = false
    private var currentActivity: Activity<SentinelActivityAttributes>?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Start Live Activity
    func startActivity() {
        // Check if Live Activities are supported
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities not enabled")
            return
        }
        
        // Don't start if already running
        guard currentActivity == nil else {
            print("Activity already running")
            return
        }
        
        let attributes = SentinelActivityAttributes(startTime: Date())
        let initialState = SentinelActivityAttributes.ContentState(
            uploadSpeed: 0,
            downloadSpeed: 0,
            cpuUsage: 0,
            threatLevel: 0,
            threatScore: 0
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            isActivityActive = true
            print("Live Activity started: \(activity.id)")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    // MARK: - Update Live Activity
    func updateActivity(
        uploadSpeed: Double,
        downloadSpeed: Double,
        cpuUsage: Double,
        threatLevel: Int,
        threatScore: Int
    ) {
        guard let activity = currentActivity else { return }
        
        let updatedState = SentinelActivityAttributes.ContentState(
            uploadSpeed: uploadSpeed,
            downloadSpeed: downloadSpeed,
            cpuUsage: cpuUsage,
            threatLevel: threatLevel,
            threatScore: threatScore
        )
        
        Task {
            await activity.update(
                ActivityContent(state: updatedState, staleDate: nil)
            )
        }
    }
    
    // MARK: - Stop Live Activity
    func stopActivity() {
        guard let activity = currentActivity else { return }
        
        let finalState = SentinelActivityAttributes.ContentState(
            uploadSpeed: 0,
            downloadSpeed: 0,
            cpuUsage: 0,
            threatLevel: 0,
            threatScore: 0
        )
        
        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
            currentActivity = nil
            isActivityActive = false
            print("Live Activity stopped")
        }
    }
    
    // MARK: - Check for existing activities on app launch
    func resumeActivityIfNeeded() {
        // Check for any running activities
        for activity in Activity<SentinelActivityAttributes>.activities {
            currentActivity = activity
            isActivityActive = true
            print("Resumed activity: \(activity.id)")
            break
        }
    }
}
