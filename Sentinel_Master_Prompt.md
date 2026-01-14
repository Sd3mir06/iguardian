# SENTINEL - Master Development Prompt

## Project Identity

**App Name:** Sentinel  
**Tagline:** "Know when something suspicious is happening on your phone"  
**Platform:** iOS 17+  
**Language:** Swift / SwiftUI

---

## Core Concept

Sentinel is a security monitoring app that tracks device-wide metrics (network, CPU, battery, thermal) to detect suspicious background activity. It alerts users when patterns suggest potential threats like remote screen watching or unauthorized data exfiltration.

**Honest Value:** We can tell users WHEN something suspicious is happening, but NOT which app is responsible (iOS limitation).

---

## What We Monitor

| Metric | API/Method | What It Shows |
|--------|------------|---------------|
| **Network Traffic** | `getifaddrs()` | Total bytes up/down (Wi-Fi & Cellular) |
| **CPU Usage** | `host_processor_info()` | System-wide processor utilization |
| **Battery Drain** | `UIDevice.current.batteryLevel` | Rate of consumption |
| **Thermal State** | `ProcessInfo.processInfo.thermalState` | Device temperature level |

---

## Threat Detection Logic

### Remote Screen Watching Signature
```
Normal Idle:
- Upload: ~1 MB/hour (sporadic)
- CPU: 2-5%
- Battery: ~1%/hour
- Thermal: nominal

Screen Mirroring Active:
- Upload: 50-200 MB/hour (CONTINUOUS) 🚨
- CPU: 15-40%
- Battery: 5-10%/hour
- Thermal: elevated/serious
```

### Multi-Factor Anomaly Detection
When HIGH CPU + HIGH network + FAST battery drain occur simultaneously during idle = SUSPICIOUS

---

## Feature Tiers

### FREE TIER
- Basic real-time dashboard
- Network, CPU, battery, thermal monitoring
- Basic anomaly alerts
- 24-hour history only

### PREMIUM TIER ($14.99/month or $99.99/year)
Everything in Free, plus:
- **Dynamic Island Live Activity** (live upload/download stats)
- **Lock Screen Widget**
- **Unlimited History & Graphs**
- **Smart Threat Detection** (specific signatures like "possible screen mirroring")
- **Sleep Guard Mode** (scheduled monitoring windows)
- **Location-Based Alerts** (e.g., only alert when on home WiFi)
- **Custom Alert Thresholds**
- **Incident Timeline** (forensic view of suspicious events)
- **Daily Threat Score** (0-100 security rating)
- **Weekly Security Reports** (PDF export)
- **Community Comparison** (anonymous benchmarking)
- **Data Export** (CSV/JSON)
- **Custom Themes**

---

## Technical Requirements

### Frameworks
- **SwiftUI** - All UI
- **ActivityKit** - Dynamic Island & Live Activities
- **WidgetKit** - Lock screen widget
- **BackgroundTasks** - BGAppRefreshTask, BGProcessingTask
- **UserNotifications** - Alerts
- **Charts** - Data visualization
- **SwiftData/CoreData** - Local persistence
- **StoreKit 2** - In-app purchases

### Key Implementation Details

#### Network Monitoring
```swift
// Use getifaddrs() to get interface statistics
// Poll every 1-5 seconds
// Calculate delta between polls for rate
// Track Wi-Fi (en0) and Cellular (pdp_ip0) separately
```

#### Dynamic Island (Premium)
```swift
// ActivityKit Live Activity
// Compact: "↑ 1.2 MB/s  ↓ 340 KB/s"
// Expanded: Full stats + status indicator
// Update frequency: ~1 second
// Max duration: 8 hours (iOS limit)
```

#### Background Execution
- BGAppRefreshTask for periodic checks
- BGProcessingTask for extended analysis
- Live Activity updates bypass some background limits
- Consider silent push notifications for server-triggered refresh

#### Baseline Learning
- Store 7+ days of hourly averages
- Calculate user's "normal" idle patterns
- Adjust thresholds based on learned baseline
- Account for time of day, location, etc.

---

## UI Screens

### 1. Dashboard (Main)
- Threat Score gauge (0-100)
- Current metrics: Upload, Download, CPU, Battery, Thermal
- Status indicator (Normal / Warning / Alert)
- Quick access to alerts and history

### 2. Live Monitor
- Real-time graphs for all metrics
- Auto-scrolling timeline
- Current rates with visual indicators

### 3. History & Analytics
- Daily/Weekly/Monthly views
- Filter by metric type
- Incident markers on timeline
- Export button (Premium)

### 4. Incident Detail (Premium)
- Timeline of event
- All metrics at time of incident
- Duration and data volumes
- Suspicion level assessment

### 5. Sleep Guard (Premium)
- Set monitoring window (e.g., 11 PM - 7 AM)
- Morning report summary
- Overnight activity log

### 6. Settings
- Alert preferences
- Monitoring schedule
- Custom thresholds (Premium)
- Theme selection (Premium)
- Subscription management
- About & Help

---

## Alert Types

| Alert | Trigger | Message |
|-------|---------|---------|
| 🔴 Screen Surveillance | Continuous high upload + CPU while idle | "Possible remote screen viewing detected" |
| 🟠 Data Exfiltration | Large upload spike during idle | "Unusual upload: 127MB while idle" |
| 🟠 CPU Anomaly | Sustained high CPU with screen off | "High background CPU activity" |
| 🟡 Battery Alert | Drain rate > 3x normal idle | "Abnormal battery consumption" |
| 🟡 Thermal Warning | Elevated thermal with no active use | "Device heating up while idle" |

---

## Paywall Strategy

### Placement
- After onboarding, show premium benefits
- When user tries to access premium feature
- After 3 days of free use

### Conversion Hooks
- Dynamic Island is the hero feature (very visible, desirable)
- "See what your phone did last night" (Sleep Guard)
- "Your phone uses 2.5x more data than typical" (Community Compare)

---

## Messaging Guidelines

### DO Say:
- "Monitor your phone's background activity"
- "Get alerted when something unusual happens"
- "See patterns that might indicate surveillance"
- "Peace of mind monitoring"

### DON'T Say:
- "Detect Pegasus" (we can't guarantee this)
- "Complete security protection"
- "See which app is spying"
- "100% detection rate"

---

## Development Phases

### Phase 1: MVP
- [ ] Basic dashboard
- [ ] Network monitoring (getifaddrs)
- [ ] CPU monitoring
- [ ] Battery monitoring
- [ ] Thermal monitoring
- [ ] Basic alerts
- [ ] 24-hour history

### Phase 2: Premium Foundation
- [ ] Dynamic Island Live Activity
- [ ] Lock Screen widget
- [ ] Extended history storage
- [ ] Baseline learning algorithm
- [ ] StoreKit 2 integration
- [ ] Paywall UI

### Phase 3: Advanced
- [ ] Sleep Guard mode
- [ ] Threat scoring system
- [ ] Incident timeline
- [ ] Custom thresholds
- [ ] PDF report generation

### Phase 4: Polish
- [ ] Community benchmarking backend
- [ ] Data export
- [ ] Custom themes
- [ ] Onboarding flow
- [ ] Performance optimization

---

## Notes for Development

1. **Battery impact** - Our app must be efficient! Don't let a security app drain battery.

2. **Privacy** - We don't collect user data. All analysis is on-device. Community benchmarking uses anonymous aggregates only.

3. **App Store Review** - Be careful with marketing claims. Apple may scrutinize security-related apps.

4. **Testing** - Create test scenarios that simulate suspicious patterns to verify detection works.

5. **Accessibility** - Support VoiceOver, Dynamic Type, and color blindness considerations.

---

## Quick Reference: iOS Limits

| What We Want | iOS Reality |
|--------------|-------------|
| Per-app network usage | ❌ Not possible |
| Background monitoring | ⚠️ Limited (use BGTasks + LiveActivity) |
| Always-on monitoring | ❌ iOS kills background apps |
| Access to other apps | ❌ Sandbox prevents this |
| System-wide stats | ✅ getifaddrs, host_processor_info |

---

---

## UI/UX Design System

### Design Philosophy

**Aesthetic Direction:** Dark, premium, security-focused with a cyberpunk-meets-luxury feel. Think "high-end security operations center" - sophisticated, trustworthy, but not intimidating.

**Core Principles:**
- **Trust through clarity** - Users should instantly understand their security status
- **Calm confidence** - Not alarming by default, but unmistakably serious when threats detected
- **Premium feel** - Justify the $14.99/month through exceptional polish

---

### Color System

```swift
// Primary Palette
static let backgroundPrimary = Color(hex: "0A0E14")     // Deep space black
static let backgroundSecondary = Color(hex: "131920")   // Card backgrounds
static let backgroundTertiary = Color(hex: "1A2230")    // Elevated surfaces

// Accent Colors
static let accentPrimary = Color(hex: "00D9FF")         // Cyan glow - primary actions
static let accentSecondary = Color(hex: "6366F1")       // Indigo - secondary elements

// Status Colors
static let statusSafe = Color(hex: "10B981")            // Emerald green
static let statusWarning = Color(hex: "F59E0B")         // Amber
static let statusDanger = Color(hex: "EF4444")          // Red alert
static let statusCritical = Color(hex: "DC2626")        // Deep red - pulsing

// Text Colors
static let textPrimary = Color(hex: "F8FAFC")           // Primary text
static let textSecondary = Color(hex: "94A3B8")         // Secondary/muted
static let textTertiary = Color(hex: "64748B")          // Hints, timestamps

// Gradients
static let safeGradient = LinearGradient(
    colors: [Color(hex: "10B981"), Color(hex: "059669")],
    startPoint: .topLeading, endPoint: .bottomTrailing
)
static let dangerGradient = LinearGradient(
    colors: [Color(hex: "EF4444"), Color(hex: "DC2626")],
    startPoint: .topLeading, endPoint: .bottomTrailing
)
static let premiumGradient = LinearGradient(
    colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6"), Color(hex: "A855F7")],
    startPoint: .leading, endPoint: .trailing
)
```

---

### Typography

```swift
// Font Family: SF Pro (system) + custom display font
// Consider: "Geist" or "Satoshi" for a modern tech feel

// Hierarchy
static let displayLarge = Font.system(size: 48, weight: .bold, design: .rounded)    // Threat Score
static let displayMedium = Font.system(size: 34, weight: .bold, design: .rounded)   // Section headers
static let headline = Font.system(size: 22, weight: .semibold)                       // Card titles
static let title = Font.system(size: 17, weight: .semibold)                          // List headers
static let body = Font.system(size: 15, weight: .regular)                            // Body text
static let caption = Font.system(size: 13, weight: .medium)                          // Labels, timestamps
static let micro = Font.system(size: 11, weight: .medium)                            // Badges, tags

// Monospace for data
static let dataLarge = Font.system(size: 28, weight: .bold, design: .monospaced)    // Live stats
static let dataMedium = Font.system(size: 17, weight: .semibold, design: .monospaced)
static let dataSmall = Font.system(size: 13, weight: .medium, design: .monospaced)
```

---

### Component Library

#### 1. Threat Score Ring
```
┌─────────────────────────────────────┐
│                                     │
│         ╭─────────────╮             │
│       ╱       12       ╲            │  ← Large animated ring
│      │    ───────────   │           │     Glows based on status
│      │      /100        │           │     Smooth color transitions
│       ╲   All Clear    ╱            │
│         ╰─────────────╯             │
│                                     │
└─────────────────────────────────────┘
```
- Animated SVG ring with gradient stroke
- Pulses gently when safe (green glow)
- Pulses urgently when threat detected (red glow)
- Score number uses tabular figures (monospace numbers)

#### 2. Metric Cards
```
┌─────────────────────────────────────┐
│  ↑ UPLOAD                    1.2    │
│  ━━━━━━━━░░░░░░░░░░░░       MB/s   │  ← Mini sparkline
│                                     │
│  Status: Normal         vs avg: +0.3│
└─────────────────────────────────────┘
```
- Frosted glass effect (ultraThinMaterial)
- Subtle border glow matching status
- Embedded sparkline showing recent trend
- Comparison to baseline

#### 3. Alert Cards
```
┌─────────────────────────────────────┐
│ 🔴                           3:42 AM │
│                                      │
│ Possible Screen Surveillance         │
│                                      │
│ Continuous upload detected while     │
│ device was idle. 127MB sent.         │
│                                      │
│ ┌──────────┐  ┌──────────────────┐  │
│ │ Dismiss  │  │  View Details  → │  │
│ └──────────┘  └──────────────────┘  │
└─────────────────────────────────────┘
```
- Red left border/glow for critical
- Amber for warning
- Haptic feedback on appearance
- Swipe actions

#### 4. Live Graph
```
┌─────────────────────────────────────┐
│ Upload Rate                  Live 🔴│
│                                     │
│     ╭╮    ╭───╮                     │
│  ───╯╰────╯   ╰─────────────────    │  ← Smooth animated line
│                                     │
│ 0        15min        30min     Now │
└─────────────────────────────────────┘
```
- Real-time animated path
- Gradient fill under line
- Threshold line showing "normal" baseline
- Anomaly regions highlighted

#### 5. Dynamic Island Compact
```
┌─────────────────────────────────────┐
│  (  ↑ 1.2   ●   ↓ 340  )           │
│      MB/s       KB/s                │
└─────────────────────────────────────┘
```
- Green dot = normal
- Amber/Red dot = warning/alert
- Clean monospace numbers
- Updates smoothly

#### 6. Dynamic Island Expanded
```
┌─────────────────────────────────────┐
│         🛡️ SENTINEL ACTIVE          │
│                                     │
│   ↑ Upload      ↓ Download          │
│   1.2 MB/s       340 KB/s           │
│                                     │
│   CPU: 4%   Battery: -1%/hr         │
│                                     │
│         ✓ All Systems Normal        │
└─────────────────────────────────────┘
```

---

### Micro-Interactions & Animations

#### Loading & Transitions
- **Screen transitions**: Horizontal slide with subtle fade
- **Card appearance**: Staggered fade-up with spring animation
- **Data refresh**: Subtle pulse on updated values
- **Pull to refresh**: Custom shield animation

#### Status Changes
```swift
// When threat detected:
// 1. Haptic: .warning
// 2. Ring color transition (0.5s ease)
// 3. Subtle screen flash (red overlay, 0.1s)
// 4. Ring pulse animation begins

// When returning to safe:
// 1. Haptic: .success  
// 2. Ring color transition (1s ease - slower, calming)
// 3. Subtle green ripple from center
```

#### Data Visualizations
- Numbers count up/down smoothly (no jumping)
- Graphs animate path drawing
- Percentage rings fill with spring physics

---

### Screen Layouts

#### Dashboard (Main)
```
┌─────────────────────────────────────┐
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░  9:41  │  ← Status bar
├─────────────────────────────────────┤
│                                     │
│  SENTINEL                    ⚙️     │  ← Header
│                                     │
│         ╭─────────────╮             │
│       ╱       12       ╲            │
│      │                  │           │  ← Threat Score
│       ╲    All Clear   ╱            │
│         ╰─────────────╯             │
│                                     │
│  ┌─────────────┐ ┌─────────────┐   │
│  │ ↑ Upload    │ │ ↓ Download  │   │  ← Metric Grid
│  │ 1.2 MB/s    │ │ 340 KB/s    │   │     (2x2)
│  └─────────────┘ └─────────────┘   │
│  ┌─────────────┐ ┌─────────────┐   │
│  │ 🔥 CPU      │ │ 🔋 Battery  │   │
│  │ 4%          │ │ -1%/hr      │   │
│  └─────────────┘ └─────────────┘   │
│                                     │
│  Recent Activity                    │
│  ┌─────────────────────────────┐   │
│  │ ✓ 2:30 PM - All normal      │   │  ← Activity Feed
│  │ ✓ 1:15 PM - All normal      │   │
│  │ ⚠️ 3:42 AM - Upload spike    │   │
│  └─────────────────────────────┘   │
│                                     │
├─────────────────────────────────────┤
│  🏠      📊      🌙      ⚙️        │  ← Tab Bar
│ Home   History  Sleep  Settings     │
└─────────────────────────────────────┘
```

#### Live Monitor
```
┌─────────────────────────────────────┐
│  ← Back        Live Monitor    🔴   │
├─────────────────────────────────────┤
│                                     │
│  Network Activity                   │
│  ┌─────────────────────────────┐   │
│  │     ╭╮    ╭───╮             │   │
│  │  ───╯╰────╯   ╰──────────   │   │  ← Real-time graph
│  │                              │   │
│  │  ↑ 1.2 MB/s    ↓ 340 KB/s  │   │
│  └─────────────────────────────┘   │
│                                     │
│  System Resources                   │
│  ┌─────────────────────────────┐   │
│  │  CPU  ████░░░░░░  4%        │   │
│  │  RAM  ██████░░░░  62%       │   │  ← Resource bars
│  │  Temp ███░░░░░░░  Normal    │   │
│  └─────────────────────────────┘   │
│                                     │
│  Baseline Comparison                │
│  ┌─────────────────────────────┐   │
│  │  Your idle: 1.2 MB/hr       │   │
│  │  Normal:    0.8 MB/hr       │   │
│  │  Status:    Slightly High   │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

#### Sleep Guard Report (Premium)
```
┌─────────────────────────────────────┐
│  ☀️ Good Morning                    │
├─────────────────────────────────────┤
│                                     │
│  SLEEP GUARD REPORT                 │
│  11:00 PM → 7:00 AM                 │
│                                     │
│         ╭─────────────╮             │
│       ╱       ✓        ╲            │
│      │    No Issues    │            │
│       ╲    Detected   ╱             │
│         ╰─────────────╯             │
│                                     │
│  Overnight Summary                  │
│  ┌─────────────────────────────┐   │
│  │  Total Upload:      4.2 MB  │   │
│  │  Total Download:   12.8 MB  │   │
│  │  Peak CPU:            8%    │   │
│  │  Battery Used:       12%    │   │
│  └─────────────────────────────┘   │
│                                     │
│  Activity Timeline                  │
│  ┌─────────────────────────────┐   │
│  │  11PM ░░░░░░░░░░░░░░░ 7AM  │   │
│  │       ▲              ▲      │   │
│  │    small spike    normal    │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │      View Full Details →    │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

---

### Special Effects

#### Threat Detected State
When threat is active, the entire UI shifts:
- Background gets subtle red vignette
- Threat score ring pulses with red glow
- Affected metric cards have red border glow
- Tab bar shows alert badge
- Haptic every 30 seconds if unacknowledged

#### Premium Upsell Moments
- Frosted blur over premium features
- Gradient "PRO" badge with shimmer animation
- Smooth paywall sheet with feature carousel

#### Empty States
- Custom illustrations (shield character)
- Helpful onboarding tips
- "Your phone is being watched" placeholder with friendly tone

---

### Accessibility

- **VoiceOver**: All elements properly labeled with security context
- **Dynamic Type**: Scales gracefully up to XXXL
- **Reduce Motion**: Disable animations, use fades instead
- **Color Blind**: Status also indicated by icons, not just color
- **High Contrast**: Alternative high contrast theme available

---

### Sound Design (Optional)

- **Alert sound**: Short, distinctive "security ping" - not alarming but attention-getting
- **All clear**: Gentle chime when returning to safe status
- **Haptics over sounds**: Prefer haptic feedback, sounds optional

---

**Let's build this! 🛡️**
