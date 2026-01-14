# Sentinel App - Phase 2 Implementation

## Overview
Phase 2 adds premium features: Dynamic Island Live Activity, Lock Screen Widget, and StoreKit 2 subscription.

---

## 🚨 XCODE SETUP REQUIRED FIRST

Before adding any code, you must configure Xcode:

### Step 1: Add Widget Extension Target

1. In Xcode: **File → New → Target**
2. Search for **"Widget Extension"**
3. Name it: `SentinelWidget`
4. **Uncheck** "Include Live Activity" (we'll add it manually for more control)
5. **Uncheck** "Include Configuration App Intent"
6. Click **Finish**
7. When asked "Activate scheme?", click **Activate**

### Step 2: Add Live Activity Capability

1. Select your **main app target** (iguardian)
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Search and add **"Push Notifications"** (required for Live Activities)
5. In **Info.plist**, add:
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

### Step 3: Add App Groups (for sharing data)

1. Select **main app target** → Signing & Capabilities → **+ Capability** → **App Groups**
2. Add group: `group.com.yourteam.sentinel`
3. Select **SentinelWidget target** → same steps → select SAME group

### Step 4: Add StoreKit Capability

1. Select **main app target**
2. Signing & Capabilities → **+ Capability** → **In-App Purchase**

---

## 📁 New Files to Create

### In Main App (iguardian folder):

```
iguardian/
├── LiveActivity/
│   ├── SentinelActivityAttributes.swift    ← Shared with widget
│   └── LiveActivityManager.swift           ← Controls Live Activity
├── Store/
│   ├── StoreManager.swift                  ← StoreKit 2 purchases
│   └── SubscriptionView.swift              ← Paywall UI
└── Views/
    └── PaywallView.swift                   ← Premium upsell screen
```

### In Widget Extension (SentinelWidget folder):

```
SentinelWidget/
├── SentinelWidget.swift                    ← Home screen widget
├── SentinelLiveActivity.swift              ← Dynamic Island UI
└── SentinelWidgetBundle.swift              ← Widget bundle
```

---

## 📄 FILE 1: SentinelActivityAttributes.swift
**Location:** `iguardian/LiveActivity/SentinelActivityAttributes.swift`

```swift
import ActivityKit
import Foundation

struct SentinelActivityAttributes: ActivityAttributes {
    // Static data that doesn't change during the activity
    public struct ContentState: Codable, Hashable {
        // Dynamic data that updates
        var uploadSpeed: Double      // bytes per second
        var downloadSpeed: Double    // bytes per second
        var cpuUsage: Double         // percentage
        var threatLevel: Int         // 0 = normal, 1 = warning, 2 = alert
        var threatScore: Int         // 0-100
    }
    
    // Static attributes (set when activity starts)
    var startTime: Date
}

// Helper extension for formatting
extension SentinelActivityAttributes.ContentState {
    var uploadFormatted: String {
        formatSpeed(uploadSpeed)
    }
    
    var downloadFormatted: String {
        formatSpeed(downloadSpeed)
    }
    
    var statusColor: String {
        switch threatLevel {
        case 0: return "green"
        case 1: return "orange"
        default: return "red"
        }
    }
    
    var statusText: String {
        switch threatLevel {
        case 0: return "Normal"
        case 1: return "Warning"
        default: return "Alert"
        }
    }
    
    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1024 {
            return String(format: "%.0f B/s", bytesPerSecond)
        } else if bytesPerSecond < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytesPerSecond / 1024)
        } else {
            return String(format: "%.1f MB/s", bytesPerSecond / (1024 * 1024))
        }
    }
}
```

---

## 📄 FILE 2: LiveActivityManager.swift
**Location:** `iguardian/LiveActivity/LiveActivityManager.swift`

```swift
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
```

---

## 📄 FILE 3: SentinelLiveActivity.swift
**Location:** `SentinelWidget/SentinelLiveActivity.swift`

```swift
import ActivityKit
import WidgetKit
import SwiftUI

struct SentinelLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SentinelActivityAttributes.self) { context in
            // LOCK SCREEN BANNER
            LockScreenView(state: context.state)
                .activityBackgroundTint(.black.opacity(0.8))
                .activitySystemActionForegroundColor(.white)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // EXPANDED VIEW
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Label {
                            Text(context.state.uploadFormatted)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.semibold)
                        } icon: {
                            Image(systemName: "arrow.up")
                                .foregroundStyle(.cyan)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Label {
                            Text(context.state.downloadFormatted)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.semibold)
                        } icon: {
                            Image(systemName: "arrow.down")
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Image(systemName: "shield.checkered")
                            .font(.title2)
                            .foregroundStyle(statusColor(context.state.threatLevel))
                        Text(context.state.statusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Label("\(context.state.cpuUsage, specifier: "%.0f")% CPU", systemImage: "cpu")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("Score: \(context.state.threatScore)")
                            .font(.caption.bold())
                            .foregroundStyle(statusColor(context.state.threatLevel))
                    }
                    .padding(.horizontal, 4)
                }
                
            } compactLeading: {
                // COMPACT LEFT
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .foregroundStyle(.cyan)
                        .font(.caption2)
                    Text(context.state.uploadFormatted)
                        .font(.system(.caption2, design: .monospaced))
                        .fontWeight(.medium)
                }
                
            } compactTrailing: {
                // COMPACT RIGHT
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .foregroundStyle(.green)
                        .font(.caption2)
                    Text(context.state.downloadFormatted)
                        .font(.system(.caption2, design: .monospaced))
                        .fontWeight(.medium)
                }
                
            } minimal: {
                // MINIMAL (just icon)
                Image(systemName: "shield.checkered")
                    .foregroundStyle(statusColor(context.state.threatLevel))
            }
        }
    }
    
    private func statusColor(_ level: Int) -> Color {
        switch level {
        case 0: return .green
        case 1: return .orange
        default: return .red
        }
    }
}

// MARK: - Lock Screen Banner View
struct LockScreenView: View {
    let state: SentinelActivityAttributes.ContentState
    
    var body: some View {
        HStack(spacing: 16) {
            // Shield icon
            Image(systemName: "shield.checkered")
                .font(.title)
                .foregroundStyle(statusColor)
            
            // Stats
            VStack(alignment: .leading, spacing: 4) {
                Text("SENTINEL")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 16) {
                    Label(state.uploadFormatted, systemImage: "arrow.up")
                        .foregroundStyle(.cyan)
                    Label(state.downloadFormatted, systemImage: "arrow.down")
                        .foregroundStyle(.green)
                }
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.semibold)
            }
            
            Spacer()
            
            // Threat Score
            VStack {
                Text("\(state.threatScore)")
                    .font(.title2.bold())
                    .foregroundStyle(statusColor)
                Text("Score")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
    
    private var statusColor: Color {
        switch state.threatLevel {
        case 0: return .green
        case 1: return .orange
        default: return .red
        }
    }
}
```

---

## 📄 FILE 4: SentinelWidget.swift (Home Screen Widget)
**Location:** `SentinelWidget/SentinelWidget.swift`

```swift
import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct SentinelEntry: TimelineEntry {
    let date: Date
    let uploadSpeed: Double
    let downloadSpeed: Double
    let threatScore: Int
    let threatLevel: Int
}

// MARK: - Timeline Provider
struct SentinelProvider: TimelineProvider {
    func placeholder(in context: Context) -> SentinelEntry {
        SentinelEntry(
            date: Date(),
            uploadSpeed: 1024,
            downloadSpeed: 2048,
            threatScore: 12,
            threatLevel: 0
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SentinelEntry) -> Void) {
        let entry = SentinelEntry(
            date: Date(),
            uploadSpeed: 1024,
            downloadSpeed: 2048,
            threatScore: 12,
            threatLevel: 0
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SentinelEntry>) -> Void) {
        // In real implementation, read from App Group shared storage
        let entry = SentinelEntry(
            date: Date(),
            uploadSpeed: 1536,
            downloadSpeed: 3072,
            threatScore: 8,
            threatLevel: 0
        )
        
        // Update every 5 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View
struct SentinelWidgetView: View {
    var entry: SentinelEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .accessoryCircular:
            CircularWidgetView(entry: entry)
        case .accessoryRectangular:
            RectangularWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: SentinelEntry
    
    var body: some View {
        VStack(spacing: 8) {
            // Shield with score
            ZStack {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 40))
                    .foregroundStyle(statusColor.gradient)
            }
            
            Text("\(entry.threatScore)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(statusColor)
            
            Text(statusText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            Color.black
        }
    }
    
    private var statusColor: Color {
        switch entry.threatLevel {
        case 0: return .green
        case 1: return .orange
        default: return .red
        }
    }
    
    private var statusText: String {
        switch entry.threatLevel {
        case 0: return "All Clear"
        case 1: return "Warning"
        default: return "Alert!"
        }
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: SentinelEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left - Shield & Score
            VStack(spacing: 4) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 32))
                    .foregroundStyle(statusColor.gradient)
                
                Text("\(entry.threatScore)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(statusColor)
                
                Text(statusText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80)
            
            // Right - Stats
            VStack(alignment: .leading, spacing: 8) {
                StatRow(
                    icon: "arrow.up",
                    label: "Upload",
                    value: formatSpeed(entry.uploadSpeed),
                    color: .cyan
                )
                
                StatRow(
                    icon: "arrow.down",
                    label: "Download",
                    value: formatSpeed(entry.downloadSpeed),
                    color: .green
                )
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(for: .widget) {
            Color.black
        }
    }
    
    private var statusColor: Color {
        switch entry.threatLevel {
        case 0: return .green
        case 1: return .orange
        default: return .red
        }
    }
    
    private var statusText: String {
        switch entry.threatLevel {
        case 0: return "All Clear"
        case 1: return "Warning"
        default: return "Alert!"
        }
    }
    
    private func formatSpeed(_ bytes: Double) -> String {
        if bytes < 1024 {
            return String(format: "%.0f B/s", bytes)
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytes / 1024)
        } else {
            return String(format: "%.1f MB/s", bytes / (1024 * 1024))
        }
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Lock Screen Circular Widget
struct CircularWidgetView: View {
    let entry: SentinelEntry
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            VStack(spacing: 2) {
                Image(systemName: "shield.checkered")
                    .font(.title3)
                Text("\(entry.threatScore)")
                    .font(.system(.body, design: .rounded, weight: .bold))
            }
        }
    }
}

// MARK: - Lock Screen Rectangular Widget
struct RectangularWidgetView: View {
    let entry: SentinelEntry
    
    var body: some View {
        HStack {
            Image(systemName: "shield.checkered")
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text("Sentinel")
                    .font(.caption.bold())
                HStack(spacing: 8) {
                    Label(formatSpeed(entry.uploadSpeed), systemImage: "arrow.up")
                    Label(formatSpeed(entry.downloadSpeed), systemImage: "arrow.down")
                }
                .font(.system(.caption2, design: .monospaced))
            }
        }
    }
    
    private func formatSpeed(_ bytes: Double) -> String {
        if bytes < 1024 {
            return String(format: "%.0f", bytes)
        } else if bytes < 1024 * 1024 {
            return String(format: "%.0fK", bytes / 1024)
        } else {
            return String(format: "%.1fM", bytes / (1024 * 1024))
        }
    }
}

// MARK: - Widget Configuration
struct SentinelHomeWidget: Widget {
    let kind: String = "SentinelWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SentinelProvider()) { entry in
            SentinelWidgetView(entry: entry)
        }
        .configurationDisplayName("Sentinel")
        .description("Monitor your device security")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}
```

---

## 📄 FILE 5: SentinelWidgetBundle.swift
**Location:** `SentinelWidget/SentinelWidgetBundle.swift`

```swift
import WidgetKit
import SwiftUI

@main
struct SentinelWidgetBundle: WidgetBundle {
    var body: some Widget {
        SentinelHomeWidget()      // Home screen widget
        SentinelLiveActivity()    // Dynamic Island
    }
}
```

---

## 📄 FILE 6: StoreManager.swift
**Location:** `iguardian/Store/StoreManager.swift`

```swift
import StoreKit
import SwiftUI

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    // Product IDs - configure these in App Store Connect
    private let productIds = [
        "com.sentinel.premium.monthly",
        "com.sentinel.premium.yearly"
    ]
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    
    var isPremium: Bool {
        !purchasedProductIDs.isEmpty
    }
    
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: productIds)
            products.sort { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
        isLoading = false
    }
    
    // MARK: - Purchase
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return true
            
        case .userCancelled:
            return false
            
        case .pending:
            return false
            
        @unknown default:
            return false
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            print("Failed to restore: \(error)")
        }
    }
    
    // MARK: - Check Purchased Status
    func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchased.insert(transaction.productID)
            }
        }
        
        purchasedProductIDs = purchased
    }
    
    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                }
            }
        }
    }
    
    // MARK: - Verify Transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}

// MARK: - Product Extension
extension Product {
    var priceFormatted: String {
        displayPrice
    }
    
    var periodFormatted: String {
        guard let subscription = subscription else { return "" }
        let unit = subscription.subscriptionPeriod.unit
        switch unit {
        case .month: return "/month"
        case .year: return "/year"
        case .week: return "/week"
        case .day: return "/day"
        @unknown default: return ""
        }
    }
}
```

---

## 📄 FILE 7: PaywallView.swift
**Location:** `iguardian/Views/PaywallView.swift`

```swift
import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = StoreManager.shared
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Features
                    featuresSection
                    
                    // Products
                    productsSection
                    
                    // Restore
                    restoreButton
                    
                    // Terms
                    termsSection
                }
                .padding()
            }
            .background(Theme.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.textTertiary)
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Animated gradient icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple, Color.blue, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "shield.checkered")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
            }
            
            Text("Sentinel Premium")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Advanced security monitoring")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Features
    private var featuresSection: some View {
        VStack(spacing: 16) {
            FeatureRow(
                icon: "circle.dotted.circle",
                title: "Dynamic Island",
                description: "Live network stats always visible"
            )
            
            FeatureRow(
                icon: "moon.stars.fill",
                title: "Sleep Guard",
                description: "Monitor while you sleep"
            )
            
            FeatureRow(
                icon: "chart.xyaxis.line",
                title: "Unlimited History",
                description: "Full analytics & trends"
            )
            
            FeatureRow(
                icon: "bell.badge.fill",
                title: "Smart Alerts",
                description: "Threat signature detection"
            )
            
            FeatureRow(
                icon: "doc.text.fill",
                title: "Weekly Reports",
                description: "PDF security summaries"
            )
        }
        .padding()
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Products
    private var productsSection: some View {
        VStack(spacing: 12) {
            if store.isLoading {
                ProgressView()
                    .tint(Theme.accentPrimary)
            } else {
                ForEach(store.products, id: \.id) { product in
                    ProductCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        onSelect: { selectedProduct = product }
                    )
                }
                
                // Purchase Button
                Button {
                    Task { await purchase() }
                } label: {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Continue")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(selectedProduct == nil || isPurchasing)
                .opacity(selectedProduct == nil ? 0.6 : 1)
            }
        }
    }
    
    // MARK: - Restore Button
    private var restoreButton: some View {
        Button {
            Task {
                await store.restorePurchases()
                if store.isPremium {
                    dismiss()
                }
            }
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundStyle(Theme.accentPrimary)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Terms
    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("Recurring billing. Cancel anytime.")
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
            
            HStack(spacing: 16) {
                Link("Terms", destination: URL(string: "https://sukrudemir.org/terms")!)
                Link("Privacy", destination: URL(string: "https://sukrudemir.org/privacy")!)
            }
            .font(.caption)
            .foregroundStyle(Theme.textSecondary)
        }
    }
    
    // MARK: - Purchase Action
    private func purchase() async {
        guard let product = selectedProduct else { return }
        
        isPurchasing = true
        do {
            let success = try await store.purchase(product)
            if success {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isPurchasing = false
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
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
                    .foregroundStyle(Theme.textPrimary)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark")
                .foregroundStyle(.green)
        }
    }
}

// MARK: - Product Card
struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                        
                        if product.subscription?.subscriptionPeriod.unit == .year {
                            Text("SAVE 44%")
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(product.displayPrice)
                        .font(.title3.bold())
                    Text(product.periodFormatted)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding()
            .background(isSelected ? Theme.accentPrimary.opacity(0.15) : Theme.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Theme.accentPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView()
}
```

---

## 📄 FILE 8: Update MonitoringManager.swift

Add this method to connect with Live Activity:

```swift
// Add to MonitoringManager class:

private var liveActivityManager = LiveActivityManager.shared

// Call this in your update loop:
func updateLiveActivity() {
    let threatLevel: Int
    switch currentThreatLevel {
    case .normal: threatLevel = 0
    case .warning: threatLevel = 1
    case .alert, .critical: threatLevel = 2
    }
    
    liveActivityManager.updateActivity(
        uploadSpeed: networkMonitor.uploadBytesPerSecond,
        downloadSpeed: networkMonitor.downloadBytesPerSecond,
        cpuUsage: cpuMonitor.usage,
        threatLevel: threatLevel,
        threatScore: threatScore
    )
}
```

---

## 📄 FILE 9: Update DashboardView.swift

Add Dynamic Island toggle:

```swift
// Add to DashboardView:

@StateObject private var liveActivity = LiveActivityManager.shared
@StateObject private var store = StoreManager.shared
@State private var showPaywall = false

// Add in the view body, perhaps in a "Quick Actions" section:
if store.isPremium {
    Toggle(isOn: $liveActivity.isActivityActive) {
        Label("Dynamic Island", systemImage: "circle.dotted.circle")
    }
    .onChange(of: liveActivity.isActivityActive) { _, newValue in
        if newValue {
            liveActivity.startActivity()
        } else {
            liveActivity.stopActivity()
        }
    }
} else {
    Button {
        showPaywall = true
    } label: {
        HStack {
            Label("Dynamic Island", systemImage: "circle.dotted.circle")
            Spacer()
            Text("PRO")
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.premiumGradient)
                .clipShape(Capsule())
        }
    }
}

// Add sheet:
.sheet(isPresented: $showPaywall) {
    PaywallView()
}
```

---

## 🧪 Testing Checklist

### StoreKit Testing (Xcode)
1. In Xcode: **Product → Scheme → Edit Scheme**
2. Under **Run → Options → StoreKit Configuration**
3. Create a new **StoreKit Configuration File**
4. Add products:
   - `com.sentinel.premium.monthly` - $14.99/month
   - `com.sentinel.premium.yearly` - $99.99/year

### Live Activity Testing
1. Run on **physical device** (iPhone 14+ for Dynamic Island)
2. Dynamic Island won't show in simulator
3. Lock screen widget works in simulator

### Widget Testing
1. After building, long-press home screen
2. Tap **+** to add widget
3. Search "Sentinel"
4. Add small or medium widget

---

## 📋 App Store Connect Setup

### Create Subscriptions
1. Go to App Store Connect → Your App → Subscriptions
2. Create subscription group: "Sentinel Premium"
3. Add subscriptions:
   - Monthly: $14.99
   - Yearly: $99.99 (saves ~44%)

### Required Screenshots
- Dynamic Island (expanded)
- Lock Screen widget
- Dashboard with Premium badge
- Paywall screen

---

## Summary

| Feature | File | Status |
|---------|------|--------|
| Dynamic Island | SentinelLiveActivity.swift | Ready to implement |
| Lock Screen Widget | SentinelWidget.swift | Ready to implement |
| Home Screen Widget | SentinelWidget.swift | Ready to implement |
| StoreKit 2 | StoreManager.swift | Ready to implement |
| Paywall UI | PaywallView.swift | Ready to implement |
| Live Activity Manager | LiveActivityManager.swift | Ready to implement |

---

**Next: Phase 3 will add Sleep Guard mode, Incident Timeline, and PDF Reports!** 🛡️
