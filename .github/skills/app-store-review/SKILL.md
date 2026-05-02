---
name: app-store-review
user-invocable: true
description: "Use when: preparing for App Store submission, validating compliance, creating submission screenshots, writing app description, testing in production environment, understanding Apple's review guidelines."
---

# PhoneCare App Store Submission Skill

Complete checklist and workflow for successful App Store submission and review.

## Pre-Submission Checklist (7 Days Before)

### Code Quality
- [ ] **No crashes on latest iOS** (compile with latest Xcode SDK)
- [ ] **No hardcoded test data** (all placeholder content removed)
- [ ] **No "Coming Soon" screens** (every screen must be functional)
- [ ] **All links work** (no dead links to external websites)
- [ ] **No debug logs in production build** (remove print statements)
- [ ] **Unit test coverage ≥80%** for business logic

### Compliance & Privacy
- [ ] **Privacy policy public** and linked in App Store
- [ ] **Terms of Service public** (if applicable)
- [ ] **Privacy Nutrition Label accurate:**
  - [ ] We collect ZERO user data ✓
  - [ ] No tracking ✓
  - [ ] No device identifiers collected ✓
  - [ ] No health info transmitted ✓
- [ ] **No private/undocumented APIs**
  - ✓ Battery health accessed via Settings link (not private API)
  - ✓ All frameworks from Apple public SDK
- [ ] **Data collection disclosure (if any)**
  - ✓ We collect NO user data

### Permissions & NSUsageDescriptions
- [ ] **Photos:** `NSPhotoLibraryUsageDescription` — "Needed to scan for duplicate photos"
- [ ] **Contacts:** `NSContactsUsageDescription` — "Needed to find duplicate contacts"
- [ ] **Storage:** No special permission needed (app-scoped access)
- [ ] **Other:** All permission descriptions clear and user-friendly (6th-grade reading level)

### Features & Functionality
- [ ] **All 10 MVP features complete** (no partial features)
  - [ ] F1: Health Dashboard
  - [ ] F2: Storage Analyzer
  - [ ] F3: Photo Duplicates
  - [ ] F4: Contact Merger
  - [ ] F5: Battery Monitor
  - [ ] F6: Privacy Audit
  - [ ] F7: Guided Flows
  - [ ] F8: Onboarding
  - [ ] F9: Paywall/Subscription
  - [ ] F10: Settings

- [ ] **Free vs Premium tiers clear**
  - [ ] Free users see all data (first 3 groups limited)
  - [ ] Premium unlocks actions + full features
  - [ ] Paywall doesn't show before scan results

### Accessibility (Required by Apple)
- [ ] **VoiceOver:** All interactive elements labeled
- [ ] **Dynamic Type:** Text scales 44pt–72pt, layout adapts
- [ ] **Dark Mode:** All colors validated in light + dark
- [ ] **Color Contrast:** ≥4.5:1 for normal text
- [ ] **Reduce Motion:** Essential interactions work without animation

### Design & User Experience
- [ ] **No red/orange health warnings** (anti-scareware brand rule)
- [ ] **No fake threat alerts** (no "virus detected" or "device at risk")
- [ ] **Paywall close button visible** (user can always dismiss)
- [ ] **No misleading pricing** (all renewal terms clear)
- [ ] **Screenshots match real app** (no Photoshop mockups)
- [ ] **Consistent branding** (colors, fonts, tone)

### Subscription & Billing (Critical for Apple Review)
- [ ] **Clear pricing** displayed in paywall
  - [ ] $0.99/week, $2.99/month, $19.99/year all shown
- [ ] **Trial terms prominent:** "7-day free trial"
- [ ] **Renewal disclosure:** "Renews automatically"
- [ ] **Cancellation info:** "Cancel anytime in Settings"
- [ ] **Restore Purchases button** in Settings
- [ ] **Sandbox testing passed** (with sandbox account)
- [ ] **No recurring charge surprise** (trial-to-paid transition transparent)

### Build Configuration
- [ ] **Latest SDK:** Built with Xcode 16+
- [ ] **Min iOS 17+** (no older versions)
- [ ] **App version bumped:** e.g., 1.0.0
- [ ] **Build number incremented** (e.g., 1)
- [ ] **No test code or configuration flags**
- [ ] **Signed with Apple Developer certificate**

## Submission Workflow

### Step 1: Prepare App Store Connect Entry

1. **App Name:** "PhoneCare" (or "PhoneCare - Phone Cleaner")
2. **Subtitle:** "Honest phone maintenance" (if using subtitles)
3. **Category:** Utilities
4. **Content Rating:** Fill questionnaire (health data: No, privacy: No data collected)
5. **Copyright:** © 2026 PhoneCare (or your company)

### Step 2: Write App Description

**Keyword Rules:**
- "Phone cleaner" - Yes, accurate
- "Duplicate detector" - Yes, feature description
- "Spam cleaner" - Avoid (too scammy)
- "Battery saver" - Only if you actually optimize battery (we don't)
- "Junk cleaner" - Avoid (scamware language)

**Example App Store Description:**

```
PhoneCare is honest phone maintenance for iPhone users who are tired of predatory cleaner apps.

What PhoneCare Does:
• Storage Analyzer: See what's using your phone's space
• Duplicate Photo Finder: Find and delete similar-looking photos safely
• Duplicate Contact Merger: Combine duplicate contacts with one tap
• Battery Health Monitor: Track your battery's health over time
• Privacy Audit: See which apps have access to your data
• Guided Cleanup Flows: Step-by-step guidance to free up space

What PhoneCare Does NOT Do:
• We don't use scary alerts or fake threats
• We don't collect your data
• We don't track you
• We don't require a monthly subscription to access basic features
• All cleanup actions are reversible for 24 hours

PhoneCare costs $19.99/year (or $0.99/week). Free users can view all data and use basic features. Premium users unlock batch cleanup, full duplicate lists, and undo support.

Your phone, taken care of. Honestly.
```

### Step 3: Create Screenshots

**Requirements:**
- 6–8 screenshots per device type
- Real app UI (not mockups)
- Text overlay allowed (tell story)
- No app store rating stars
- Devices: iPhone 6.7" and 5.5" (covers most users)

**Screenshot Flow:**
1. Dashboard (health score, no red colors)
2. Storage breakdown (charts, no scary language)
3. Photo duplicates (groups, batch selection)
4. Delete confirmation (shows item count + size)
5. Battery trend (chart, not scary alerts)
6. Privacy audit (permission list, Settings links)
7. Paywall (pricing, "Not now" button visible)
8. Settings (subscription status, Restore Purchases)

**Text Overlay Examples:**
```
Screenshot 1: "Your phone at a glance"
Screenshot 2: "See what's using your space"
Screenshot 3: "Find photos that look the same"
Screenshot 4: "Safe deletion with undo"
Screenshot 5: "Track battery health over time"
Screenshot 6: "See which apps have access"
Screenshot 7: "Unlock full cleanup power"
Screenshot 8: "Manage your subscription anytime"
```

### Step 4: Review Notes for Apple

**Required in Review Notes:**

```
## PhoneCare Submission Notes

### Overview
PhoneCare is an honest phone maintenance app for users aged 40+. 
It provides storage cleanup, duplicate detection, battery monitoring, 
and privacy audits — all on-device, no data collection.

### How to Review

#### F1: Health Dashboard (Home tab)
1. Tap Home tab
2. View composite health score (green/amber, never red)
3. Tap any card to drill into details

#### F3: Duplicate Photo Finder (Photos tab)
1. Tap Photos tab
2. Tap "Scan for Duplicates"
3. Wait ~10 seconds for scan
4. View results in grid
5. Free users: Can view first 3 groups (paywall for more)
6. Premium users: See all groups + can batch delete
7. Tap "Delete" → Confirmation dialog with item count + size
8. After deletion: "Undo" button available for 24 hours

#### F9: Paywall (Try premium action as free user)
1. Tap Photos tab
2. With free account, try to batch delete
3. Paywall appears
4. Verify: Pricing clear, trial terms visible, "Not now" button prominent

#### Sandbox Testing
Test account: [PROVIDE SANDBOX EMAIL + PASSWORD]
1. First launch: Signs out of any App Store account
2. Tap paywall "Start Free Trial"
3. Sign in with sandbox account
4. 7-day trial granted immediately
5. Full access during trial
6. After 7 days: Automatic conversion to $19.99/year

### Tech Details
- Language: Swift, SwiftUI
- Frameworks: PhotoKit, Contacts, StoreKit 2 (no third-party SDKs)
- Data: 100% on-device, no cloud sync or external backend
- Analytics: None (no third-party analytics)
- Privacy: Zero user data collected

### Anti-Scareware Commitments
- No red/orange health warnings (brand rule)
- No fake threat alerts
- No paywall before delivering scan value
- All destructive actions require confirmation + undo
- Content written at 6th-grade reading level
- Tone: Calm, trustworthy, never manipulative

### Known Limitations
- Battery health max capacity requires link to Settings (private API restriction)
- All storage cleanup is photo/contact focused (not system cache clearing)
- Subscription management: Edit/cancel only in Settings (Apple requirement)
```

### Step 5: Submit to App Store

1. **Final build:** Archive in Xcode
2. **Validate:** Xcode → Product → Validate
3. **Upload:** Xcode → Product → Upload to App Store
4. **Verify:** App Store Connect → Build appears (may take 5–10 min)
5. **Submit for Review:**
   - App Store Connect → Version on App Store
   - Scroll to Build section → Select your build
   - Add review notes
   - Check all required info filled
   - Submit for Review

**Average Review Time:** 24–48 hours (sometimes faster)

## Common Rejection Reasons & Fixes

| Rejection | Root Cause | Fix |
|-----------|-----------|-----|
| "Incomplete app" | Broken link / missing screenshots | Test all features, add complete screenshots |
| "Privacy violation" | Too many permissions, no usage explanation | Update NSUsageDescription strings |
| "Misleading pricing" | Trial terms not clear | Ensure "7-day free, then $19.99/year" visible |
| "Inaccurate preview" | Screenshots don't match real app | Update screenshots to match current build |
| "Uses private API" | Tried to access battery max capacity | Link to Settings instead |
| "Scareware alert" | Red health warning or fake threat | Change to green/amber, remove fear language |
| "Doesn't function" | App crashes on app reviewer's device | Test on iPhone 11, add crash logs to review notes |

## Post-Approval: Maintenance

### Version Numbering
```
1.0.0 — Initial release (10 MVP features)
1.0.1 — Hotfix (critical bug fix)
1.1.0 — Minor release (1–2 new features or improvements)
2.0.0 — Major release (significant redesign or many new features)
```

### Bug Fix Submission
1. Fix bug in code
2. Increment build number (1.0.0 build 2 → 1.0.0 build 3)
3. Test thoroughly
4. Upload new build
5. Submit for Review with notes: "Fixed: [bug description]"

### Feature Update Submission
1. Implement feature
2. Increment version (1.0.0 → 1.1.0)
3. Increment build number to 1
4. Update App Store description / screenshots if needed
5. Submit with release notes highlighting new features

## Red Flags (Instant Rejection)

- ❌ Red color for health warnings
- ❌ "Virus detected" or "Your device is infected"
- ❌ Trial terms hidden or unclear
- ❌ Paywall before showing any value
- ❌ No "Not now" button on paywall
- ❌ Collect data without privacy disclosure
- ❌ App crashes on launch
- ❌ Same screenshots as competitor (copied assets)
- ❌ Offensive or misleading app name
- ❌ Uses private/undocumented APIs

## Submission Checklist

```
PRE-SUBMISSION (7 days before)
- [ ] Code: No crashes, no placeholder content, no debug logs
- [ ] Privacy: Policy written, nutrition label accurate
- [ ] Permissions: NSUsageDescription strings clear
- [ ] Accessibility: VoiceOver, Dynamic Type, Dark Mode, Reduce Motion
- [ ] Design: No red health warnings, paywall close button visible
- [ ] Subscription: Trial terms clear, Restore button present
- [ ] Build: Latest SDK, version bumped, signed correctly

SUBMISSION
- [ ] App Store Connect: All fields filled (name, description, category)
- [ ] Description: Clear, no scamware language, 6th-grade reading level
- [ ] Screenshots: 6–8 per device type, real app UI, text overlay
- [ ] Review Notes: Include sandbox test account + submission notes
- [ ] Final Build: Uploaded and validated
- [ ] Submit for Review: All required info confirmed

APPROVED
- [ ] Release on App Store
- [ ] Pin v1.0.0 release notes
- [ ] Monitor crash reports
- [ ] Plan next version features
```

---

**Use This Skill When:**
- Planning App Store submission
- Preparing review notes
- Creating screenshots and description
- Validating compliance
- Handling rejections
- Planning version updates
