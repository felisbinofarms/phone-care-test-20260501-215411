---
name: ux-design-system
user-invocable: true
description: "Use when: validating colors, spacing, typography, touch targets against PhoneCare design system; reviewing mockups for design compliance; ensuring anti-scareware brand rules; enforcing Dark Mode, Dynamic Type support."
---

# PhoneCare UX Design System Skill

This skill provides design system validation, color compliance, spacing grids, and anti-scareware enforcement for PhoneCare iOS.

## Quick Color Reference

### Brand Colors (Semantic)

| Token | Light | Dark | Usage | Anti-Scareware |
|-------|-------|------|-------|---|
| **primary** | #0A3D62 | #5DADE2 | Brand blue, nav bars | ✓ Safe |
| **accent** | #1A8A6E | #58D68D | CTAs, success, health | ✓ Safe for health |
| **warning** | #F39C12 | #F5B041 | Genuine warnings only | ⚠️ Use sparingly |
| **error** | #E74C3C | #EC7063 | True errors only | ⚠️ Never for warnings |
| **background** | #F8F9FA | #1C1C1E | Screen backgrounds | ✓ Safe |
| **surface** | #FFFFFF | #2C2C2E | Cards | ✓ Safe |
| **textPrimary** | #2C3E50 | #F2F2F7 | Body text | ✓ Safe |
| **textSecondary** | #95A5A6 | #8E8E93 | Metadata | ✓ Safe |

### Health Score Colors (CRITICAL ANTI-SCAREWARE RULE)

**NEVER RED for health warnings!**

| Score Range | Color | Reason |
|-----------|-------|--------|
| **51-100%** | **Green** (.accent) | Healthy state |
| **0-50%** | **Amber** (.warning) | Needs attention |
| **NEVER** | ❌ **Red** | Predatory scareware pattern - brand violation |

## Spacing Grid (8pt Base)

All spacing must be multiples of 8pt:

| Token | Size | Usage |
|-------|------|-------|
| xs | 4pt | Micro spacing (between icons + text) |
| sm | 8pt | Small gaps (list item padding) |
| md | 16pt | Standard gaps (section padding) |
| lg | 24pt | Large gaps (screen sections) |
| xl | 32pt | Extra large (major sections) |
| xxl | 48pt | Full spacing (vertical separation) |

**Grid Rules:**
- All padding/margins must be multiples of 8pt
- No arbitrary numbers like 12pt, 15pt, 20pt
- Button padding: sm (8pt) left/right, md (16pt) top/bottom minimum

## Typography

### Font (SF Pro Only)

| Element | Font | Size (Base) | Weight | Dynamic Type | Usage |
|---------|------|------------|--------|---|---|
| Headline | SF Pro | 22pt | Bold | Large Title | Screen titles, cards |
| Body | SF Pro | 17pt | Regular | Body | Content text |
| Metadata | SF Pro | 13pt | Regular | Caption | Secondary info, labels |
| Small | SF Pro | 11pt | Regular | Small Caption | Tiny labels |

**Dynamic Type Support (MANDATORY):**
- All text must scale from **44pt (Accessibility: Large Text)** to **72pt (Accessibility: Extra Large)**
- Never lock font sizes — use semantic sizes (.headline, .body, .caption)
- Test at minimum (44pt) and maximum (72pt) sizes
- Layout must adapt (stack vertically instead of horizontal) at largest sizes

### Example: Safe Typography

```swift
// ✓ CORRECT - Scales with system
Text("Battery Health")
    .font(.headline)  // Scales 44pt → 72pt
    .lineLimit(nil)   // Allow wrapping

// ❌ WRONG - Fixed size, doesn't scale
Text("Battery Health")
    .font(.system(size: 22))  // Fixed 22pt!
```

## Touch Targets

**Apple HIG Minimum:** 44pt × 44pt

**PhoneCare Standard:**
- Primary CTAs: **50pt minimum** height
- List rows: **56pt minimum**, **64pt for interactive rows**
- Icon-only buttons: **44pt × 44pt minimum**

**Layout Spacing:**
- Button to button: 8pt (sm)
- Button to adjacent text: 8pt (sm)
- Row to row: 8pt (sm)

## Button Styles

### Primary CTA (Most Important Action)
```
Background: #1A8A6E (.accent)
Text: White
Height: 50pt
Corner Radius: 12pt
```

### Secondary CTA (Alternative Action)
```
Background: #E8F8F5 (light teal)
Text: #1A8A6E (.accent)
Height: 50pt
Corner Radius: 12pt
```

### Destructive CTA (Delete, Cancel Subscription)
```
Background: White
Text: #E74C3C (.error) - RED ONLY HERE
Height: 50pt
Corner Radius: 12pt
Always pair with: Confirmation dialog
```

**Rule:** Red text ONLY for destructive actions with confirmation dialog. Never for warnings or passive info.

## Anti-Scareware Color Validation

**Validation Checklist:**

- [ ] Health score uses GREEN (51-100%) or AMBER (0-50%), NEVER RED
- [ ] Storage warnings use AMBER (.warning), NOT RED
- [ ] Battery warnings use AMBER (.warning), NOT RED
- [ ] No "danger" red colors on any warning or status indicator
- [ ] Red (.error) only used for:
  - [ ] Destructive CTAs (delete, clear all) with confirmation dialog
  - [ ] Critical system errors (e.g., permission denied)
- [ ] All warning text is calm, not scary ("needs attention" not "at RISK")
- [ ] No red icons or badges used for non-critical info

**Example: WRONG Health Score UI (Predatory)**

```
❌ BLOCKED:
Health Score: 35%    [RED circle]   "⚠️ Your device is at RISK! URGENT cleanup needed NOW!"
               ↑ RED violates  ↑ Fear language    ↑ Predatory
               anti-scareware
```

**Example: CORRECT Health Score UI**

```
✓ APPROVED:
Health Score: 35%    [AMBER circle]   "Your device needs attention. Start with photos?"
               ↑ Amber OK         ↑ Calm tone
```

## Dark Mode Validation

**Requirements:**
- All colors must be defined with light + dark variants
- No hardcoded black (#000000) or white (#FFFFFF)
- Use UIColor with semantic init

**Correct Pattern:**
```swift
Color(uiColor: UIColor { traitCollection in
    if traitCollection.userInterfaceStyle == .dark {
        return UIColor(red: 0.36, green: 0.68, blue: 0.88, alpha: 1)  // #5DADE2
    } else {
        return UIColor(red: 0.04, green: 0.24, blue: 0.38, alpha: 1)  // #0A3D62
    }
})

// Or use Theme.swift
Color.primary  // Automatically switches light/dark
```

**Validation Checklist:**
- [ ] All text readable in light mode (≥4.5:1 contrast)
- [ ] All text readable in dark mode (≥4.5:1 contrast)
- [ ] No hardcoded colors — all from Theme.swift
- [ ] Tested with Dark Mode toggle on device
- [ ] Images/SF Symbols render correctly in both modes

## Design Review Checklist

When reviewing a screen mockup or implemented feature:

### Colors
- [ ] No red/orange used for warnings or health indicators ← ANTI-SCAREWARE
- [ ] Health scores: Green (51-100%) or Amber (0-50%)
- [ ] All colors use Theme.swift tokens
- [ ] Dark Mode validated (both light + dark colors visible)
- [ ] Text contrast ≥4.5:1 for normal, ≥3:1 for large text

### Spacing & Layout
- [ ] All padding/margins are 8pt multiples (4, 8, 16, 24, 32, 48)
- [ ] Button padding: sm (8pt) horizontally, md (16pt) vertically minimum
- [ ] Primary CTAs: 50pt height
- [ ] List rows: 56pt+ height
- [ ] No arbitrary pixel values

### Typography
- [ ] All text uses semantic sizes (.headline, .body, .caption)
- [ ] Support Dynamic Type (scales 44pt–72pt)
- [ ] Line limits allow wrapping at large text sizes
- [ ] Font is SF Pro only (no custom fonts)

### Touch Targets
- [ ] All interactive elements ≥44pt
- [ ] CTAs: 50pt height
- [ ] Spacing between tappable areas: ≥8pt
- [ ] No nested touch targets

### Accessibility
- [ ] VoiceOver labels on all interactive elements
- [ ] Color not only way to convey info (text + color)
- [ ] Logical read order (top-to-bottom, left-to-right)
- [ ] Support Dark Mode + Reduce Motion

## Common Design Issues & Fixes

| Issue | Wrong | Correct |
|-------|-------|---------|
| Health warning red | Red circle with "⚠️ At Risk!" | Amber circle with "Needs attention" |
| Fixed text size | `font(.system(size: 22))` | `font(.headline)` |
| Hardcoded color | `Color(.sRGB, red: 1, green: 0, blue: 0)` | `Color.primary` or `Color.error` |
| Random spacing | `.padding(12)` | `.padding(.sm)` (8pt) |
| Small button | 40pt height CTA | 50pt height minimum |
| Text doesn't wrap | `lineLimit(1)` on large text | `lineLimit(nil)` + multilineTextAlignment |

## Assets & Reference Files

**Theme.swift (Source of Truth)**
- All semantic colors defined here
- Light/dark mode variants
- Spacing tokens
- Typography scales

**Implementation Pattern:**
```swift
// PhoneCare/Core/DesignSystem/Theme.swift
import SwiftUI

struct PhoneCareTheme {
    static let colors = PhoneCareColors()
    static let spacing = PhoneCareSpacing()
    static let typography = PhoneCareTypography()
}

struct PhoneCareColors {
    let primary = Color(uiColor: /* light #0A3D62, dark #5DADE2 */)
    let accent = Color(uiColor: /* light #1A8A6E, dark #58D68D */)
    let warning = Color(uiColor: /* light #F39C12, dark #F5B041 */)
    let error = Color(uiColor: /* light #E74C3C, dark #EC7063 */)
    // ... more colors
}

struct PhoneCareSpacing {
    let xs: CGFloat = 4
    let sm: CGFloat = 8
    let md: CGFloat = 16
    let lg: CGFloat = 24
    let xl: CGFloat = 32
    let xxl: CGFloat = 48
}

// Usage in Views:
Text("Button").padding(.md).foregroundColor(.primary)
```

## Questions to Ask During Design Review

1. **Colors:** Are any health warnings or storage indicators red or orange? (Should be GREEN or AMBER only)
2. **Spacing:** Are all spacing values multiples of 8pt?
3. **Typography:** Does all text scale with Dynamic Type (44pt–72pt)?
4. **Touch Targets:** Are all interactive elements ≥44pt? CTAs ≥50pt?
5. **Dark Mode:** Have you tested both light and dark modes on device?
6. **Brand:** Does this feel calm and trustworthy, or scary and manipulative?

---

**Use This Skill When:**
- Reviewing feature mockups or implementations
- Validating colors and spacing
- Auditing anti-scareware compliance
- Testing Dynamic Type and Dark Mode
- Onboarding new designers to the brand system
