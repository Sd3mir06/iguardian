# iGuardian Improvement Guide

## 🎯 Summary of Issues Fixed

### 1. ❌ Too Many False Alarms → ✅ Smart Idle Detection
**Problem:** App was triggering warnings even when user was actively using phone.
**Solution:** Now only monitors and alerts when device is **IDLE** (phone locked/unused for 60+ seconds).

### 2. ❌ No Notifications Working → ✅ Proper Notification System  
**Problem:** Notifications never sent.
**Solution:** Added proper `UNUserNotificationCenter` integration with permission request.

### 3. ❌ Dynamic Island Too Wide → ✅ Compact Design
**Problem:** Compact view showed too much text, taking space from other apps.
**Solution:** Compact view now shows only: Shield Icon (left) + Score Number (right).

### 4. ❌ Widget Not Updating → ✅ App Group Data Sync
**Problem:** Widget showed static/placeholder data.
**Solution:** Added `WidgetDataSync` helper that writes to App Group UserDefaults.

### 5. ❌ Unrealistic Thresholds → ✅ Smart Defaults
**Problem:** Thresholds were too sensitive (triggered on normal usage).
**Solution:** Increased defaults to realistic values:
- Total Upload: 100MB/hour (was 200MB)
- CPU While Idle: 50% (was 60%)
- Battery Drain: 10%/hour (was 8%)

---

## 📁 Files to Replace

| File | Location | Replace |
|------|----------|---------|
| `MonitoringManager.swift` | `iguardian/Services/` | ✅ Full replace |
| `AlertThreshold.swift` | `iguardian/Models/` | ✅ Full replace |
| `LiveActivityManager.swift` | `iguardian/LiveActivity/` | ✅ Full replace |
| `SentinelActivityAttributes.swift` | `iguardian/LiveActivity/` + `SentinelWidget/` | ✅ Both locations |
| `SentinelLiveActivity.swift` | `SentinelWidget/` | ✅ Full replace |
| `SentinelWidget.swift` | `SentinelWidget/` | ✅ Full replace |
| `WidgetDataSync.swift` | `iguardian/Services/` | ➕ NEW FILE |

---

## 🔧 Required Xcode Setup

### 1. App Groups (for Widget data sync)
1. Select **iguardian** target → Signing & Capabilities
2. Click **+ Capability** → **App Groups**
3. Add: `group.com.sukrudemir.iguardian`
4. **Repeat** for **SentinelWidget** target

### 2. Notification Permission
The new MonitoringManager automatically requests permission on init.
No additional setup needed.

### 3. Background Modes (optional, for future Sleep Guard)
1. Select **iguardian** target → Signing & Capabilities
2. Click **+ Capability** → **Background Modes**
3. Enable: ☑️ Background fetch, ☑️ Background processing

---

## 🧠 How the New Logic Works

### Idle Detection
```
Phone is IDLE when:
1. No user interaction for 60+ seconds
2. AND (CPU < 15% OR Network < 50 KB/s)

When IDLE → Check for anomalies
When ACTIVE → Score = 0, no alerts
```

### Threat Score Calculation (Only When Idle)
```
Factor                          Score
─────────────────────────────────────
Total Upload > 100MB/hr         +50
Upload at 80% limit             +20
Total Download > 300MB/hr       +30
High upload rate (5x baseline)  +25
CPU > 50% while idle            +25
Battery drain > 10%/hr          +20
Thermal serious/critical        +20
Screen mirror pattern           +20
─────────────────────────────────────
Max Score: 100

Levels:
0-19   = Normal (Green)
20-44  = Warning (Orange)  
45-69  = Alert (Red)
70-100 = Critical (Pulsing Red)
```

### Alert Cooldowns
- Same alert type: 5 minutes cooldown
- Level changes: 1 minute cooldown
- Prevents notification spam

---

## 📱 Dynamic Island Changes

### Before (Too Wide)
```
┌─────────────────────────────────────────┐
│ ↑ 1.2 KB/s              ↓ 3.4 KB/s      │
└─────────────────────────────────────────┘
```

### After (Compact)
```
┌───────────────────┐
│ 🛡️          12    │
└───────────────────┘
```

Expanded view (on tap) still shows all details.

---

## 🔔 Notifications

Notifications now work and are sent when:
1. Threat level reaches **Alert** or **Critical**
2. Device is in **IDLE** mode
3. Alert cooldown has passed (5 minutes)

Format:
```
🛡️ iGuardian
Security Alert
🚨 52MB uploaded while idle (limit: 100MB)
```

---

## ✅ Testing Checklist

After implementing changes:

- [ ] App shows "All Clear" when actively using phone
- [ ] App shows score/warnings only after 60+ seconds idle
- [ ] Dynamic Island is compact (icon + number only)
- [ ] Widget updates within 1 minute of app changes
- [ ] Notification appears when you exceed upload threshold
- [ ] No spam alerts during normal usage
- [ ] X-Ray view still shows detailed stats

---

## 🚀 Future Improvements

1. **Sleep Guard**: Background monitoring while phone locked overnight
2. **Baseline Learning**: Auto-adjust thresholds based on user's normal patterns
3. **Smart Notifications**: Group similar alerts, don't repeat same warning
4. **Community Compare**: See if your idle usage is normal vs other users

---

## ❓ FAQ

**Q: Why does the score stay at 0 when I'm using the phone?**
A: By design! iGuardian only monitors when idle. Active usage is normal.

**Q: The widget shows old data?**
A: Make sure App Groups is enabled on both targets. Check Xcode console for errors.

**Q: I never get notifications?**
A: 1) Check Settings → Notifications → iGuardian is enabled. 2) Must be idle AND exceed threshold.

**Q: What counts as "idle"?**
A: 60+ seconds since last touch AND (CPU < 15% OR network < 50 KB/s).

---

*iGuardian v1.0 - Your phone's silent security guardian* 🛡️
