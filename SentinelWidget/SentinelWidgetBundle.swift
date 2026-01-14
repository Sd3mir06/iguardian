//
//  SentinelWidgetBundle.swift
//  SentinelWidget
//
//  Created by Sukru Demir on 14.01.2026.
//

import WidgetKit
import SwiftUI

@main
struct SentinelWidgetBundle: WidgetBundle {
    var body: some Widget {
        SentinelHomeWidget()      // Home screen widget
        SentinelLiveActivity()    // Dynamic Island
    }
}
