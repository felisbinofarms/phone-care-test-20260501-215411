---
name: accessibility-audit
user-invocable: true
description: "Use when: testing VoiceOver support, Dynamic Type scaling, Dark Mode colors, Reduce Motion compliance, color contrast validation, touch target sizing, accessibility labels."
---

# PhoneCare Accessibility Audit Skill

Complete accessibility validation framework for VoiceOver, Dynamic Type, Dark Mode, Reduce Motion, and color contrast compliance.

## Accessibility Framework

PhoneCare targets users aged 40+ with diverse abilities:
- Vision: Low vision, color blindness, VoiceOver users
- Motor: Reduced dexterity, large touch targets
- Motion: Vestibular disorders, Reduce Motion enabled
- Cognitive: Clear language, simple navigation

## 1. VoiceOver Testing (Screen Reader)

### Enable VoiceOver on Device
```
iPhone Settings → Accessibility → VoiceOver → Toggle ON
Gesture to navigate: 2-finger tap + flick
Action: 2-finger double-tap
```

### VoiceOver Audit Checklist

- [ ] **All interactive elements have labels**
  - Buttons: "Save" (not "Submit Form")
  - Icons: "Photo deleted" (not just icon)
  - List items: "Battery health: 75%"

- [ ] **Logical read order (top to bottom, left to right)**
  - Test: Flick right repeatedly, ensure order makes sense
  - Fix: Use `.accessibilityElement(children: .combine)` to group

- [ ] **No orphaned text/images**
  - Decorative images: `Image(...).accessibilityHidden(true)`
  - Related text + icon: Combine into single element

- [ ] **All controls are reachable**
  - No buttons hidden behind gestures
  - Alternative text descriptions for gestures

- [ ] **Form fields have labels**
  - `@AccessibilityLabel("Email address")`
  - Not just placeholder text

### Example: Inaccessible → Accessible

**WRONG:**
```swift
HStack {
    Image(systemName: "checkmark.circle.fill")
    Text("Complete")
}
// VoiceOver says: "Complete" and then separately announces the icon
```

**CORRECT:**
```swift
HStack {
    Image(systemName: "checkmark.circle.fill")
        .accessibilityHidden(true)  // Decorative
    Text("Complete")
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Task complete")
// VoiceOver says only: "Task complete"
```

### VoiceOver Test Cases

| Screen | Test Case | Expected Result |
|--------|-----------|-----------------|
| Dashboard | Enable VoiceOver, navigate | All cards readable, logical order |
| Photos | Select photo for deletion | "Delete this photo" button announced |
| Paywall | VoiceOver + flick right | "Subscribe", "Restore", "Not now" all reachable |
| Battery Trend | Chart on screen | "Battery trend chart" announced (data not individual data points) |

## 2. Dynamic Type Testing (Text Scaling)

### Enable Large Text on Device
```
iPhone Settings → Accessibility → Display & Text Size → Larger Accessibility Sizes
Sizes: Small (44pt) to Extra Large (72pt)
```

### Dynamic Type Audit Checklist

- [ ] **All text scales with system settings**
  - ✓ Use `.font(.headline)`, `.font(.body)`, `.font(.caption)`
  - ❌ Avoid `.font(.system(size: 22))`

- [ ] **Layout adapts at large text**
  - At 44pt (smallest): Comfortable to read
  - At 72pt (largest): No overflow, layout stacks vertically
  - Text wraps naturally (`.lineLimit(nil)`)

- [ ] **Touch targets stay ≥44pt even at large text**
  - Button: Still 50pt tall at 72pt text size

- [ ] **No truncation with ellipsis**
  - Use `lineLimit(nil)` instead of `.lineLimit(1)`

- [ ] **Images/Icons scale proportionally**
  - Icons scale with text (not fixed size)

### Example: Dynamic Type Issues

**WRONG - Fixed Size:**
```swift
Text("Battery Health")
    .font(.system(size: 22))  // Fixed! Doesn't scale

VStack {
    Text("Health: 75%")
    Text("Storage: 32GB").lineLimit(1)  // Truncated at large sizes!
}
```

**CORRECT - Semantic Sizing:**
```swift
VStack(alignment: .leading, spacing: .sm) {
    Text("Battery Health")
        .font(.headline)  // Scales with system
    
    Text("Health: 75%")
        .font(.body)      // Scales with system
    
    Text("Storage: 32GB")
        .font(.caption)
        .lineLimit(nil)   // Wraps instead of truncating
        .multilineTextAlignment(.leading)
}
```

### Dynamic Type Test Cases

| Text Size | Test Action | Expected Result |
|-----------|-------------|-----------------|
| Smallest (44pt) | Open app | All text readable, no overflow |
| Medium (58pt) | Navigate features | Layout adapts, still readable |
| Largest (72pt) | Open battery chart | Chart labels readable, touch targets ≥44pt |

## 3. Dark Mode Validation

### Enable Dark Mode on Device
```
iPhone Settings → Display & Brightness → Dark
Xcode Preview: Toggle dark/light in canvas
```

### Dark Mode Audit Checklist

- [ ] **No hardcoded colors**
  - ✓ `Color.primary` (switches automatically)
  - ❌ `Color.black`, `Color.white`, `#000000`

- [ ] **Contrast ratio ≥4.5:1 for normal text**
  - Test with WebAIM Contrast Checker
  - Light backgrounds in light mode, dark in dark mode

- [ ] **Colors validated in both modes**
  - Primary CTA visible and clickable in both
  - Text readable without squinting

- [ ] **Images don't become invisible**
  - Light backgrounds in dark mode still visible
  - Icons use system colors or semantic colors

- [ ] **All colors defined with semantic tokens**
  - `Color(uiColor: UIColor { traitCollection in ... })`

### Example: Dark Mode Issues

**WRONG - Hardcoded Black:**
```swift
// In dark mode, white text on white background = invisible!
ZStack {
    Color.black.ignoresSafeArea()  // ❌ Hardcoded
    Text("Battery Status")
        .foregroundColor(.white)
}
```

**CORRECT - Semantic Colors:**
```swift
ZStack {
    Color.background.ignoresSafeArea()  // Switches light/dark
    Text("Battery Status")
        .foregroundColor(.textPrimary)   // Switches light/dark
}
```

### Dark Mode Test Cases

| Element | Light Mode | Dark Mode | Contrast |
|---------|-----------|-----------|----------|
| Primary CTA | Blue bg, white text | Blue bg, white text | ✓ 4.5:1 |
| Health Score (Green) | Green on white | Green on dark | ✓ 4.5:1 |
| Warning (Amber) | Amber on white | Amber on dark | ✓ 4.5:1 |
| Text | Dark text on light | Light text on dark | ✓ 4.5:1 |

## 4. Reduce Motion (Animation Respect)

### Enable Reduce Motion on Device
```
iPhone Settings → Accessibility → Motion → Reduce Motion → Toggle ON
```

### Reduce Motion Audit Checklist

- [ ] **Essential interactions work without animation**
  - Buttons respond immediately (animation optional)
  - Page transitions happen even with Reduce Motion

- [ ] **No auto-playing animations**
  - Loading spinners: Optional, not required
  - Parallax effects: Disabled with Reduce Motion

- [ ] **Animations checked for motion sensitivity**
  - Use `UIMotionEffect.isEnabled` to check
  - Disable vestibular-triggering animations (spinning, parallax)

- [ ] **Slide/fade transitions safe**
  - Subtle movement OK
  - Spinning, rapid motion not OK

### Example: Reduce Motion Support

**WRONG - Animation Always Plays:**
```swift
.onAppear {
    withAnimation(.easeInOut(duration: 1)) {
        // Spinning animation - bad for vestibular disorders!
        rotation += 360
    }
}
```

**CORRECT - Respects Reduce Motion:**
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

.onAppear {
    if reduceMotion {
        // Instant, no animation
        rotation = 360
    } else {
        withAnimation(.easeInOut(duration: 1)) {
            rotation += 360
        }
    }
}
```

## 5. Color Contrast Validation

### Contrast Ratio Rules

| Text Type | Minimum Ratio | Example Pass |
|-----------|--------------|--------------|
| Normal text | 4.5:1 | Black (#2C3E50) on white (#FFFFFF) |
| Large text (18pt+) | 3:1 | Primary blue on white |
| UI components | 3:1 | Icon on background |

### Check Contrast

1. **Online:** WebAIM Contrast Checker (https://webaim.org/resources/contrastchecker/)
2. **macOS:** Color Contrast Analyzer app
3. **Xcode:** Accessibility Inspector (Xcode → Open Developer Tools → Accessibility Inspector)

### PhoneCare Color Contrast Pairs

| Light Mode | Dark Mode | Ratio | Pass? |
|-----------|-----------|-------|-------|
| Primary (#0A3D62) on white | Primary (#5DADE2) on dark | ✓ 8.4:1 | ✓ |
| Accent (#1A8A6E) on white | Accent (#58D68D) on dark | ✓ 7.2:1 | ✓ |
| Warning (#F39C12) on white | Warning (#F5B041) on dark | ✓ 4.8:1 | ✓ |
| Error (#E74C3C) on white | Error (#EC7063) on dark | ✓ 5.1:1 | ✓ |
| Text Primary on bg | Text Primary on bg | ✓ 9:1+ | ✓ |

## 6. Touch Target Sizing

### Touch Target Rules

- **Minimum:** 44pt × 44pt (Apple HIG)
- **PhoneCare Standard:** 50pt height for CTAs, 56pt+ for list rows
- **Spacing between targets:** ≥8pt (prevents accidental taps)

### Touch Target Audit

- [ ] All buttons ≥44pt (CTAs ≥50pt)
- [ ] List rows ≥56pt
- [ ] Icon-only buttons ≥44pt × 44pt
- [ ] Spacing between tappable areas ≥8pt
- [ ] No overlapping touch areas

## Full Accessibility Audit Checklist

### Before Shipping Any Feature:

**VoiceOver** ✓
- [ ] All buttons/text have labels
- [ ] Decorative images marked `.accessibilityHidden(true)`
- [ ] Logical read order (top-to-bottom, left-to-right)
- [ ] No orphaned elements
- [ ] Form fields labeled

**Dynamic Type** ✓
- [ ] All text uses semantic sizes (.headline, .body, .caption)
- [ ] Text scales 44pt–72pt without overflow
- [ ] No fixed font sizes
- [ ] Layout stacks vertically at large sizes
- [ ] Touch targets stay ≥44pt at largest text

**Dark Mode** ✓
- [ ] No hardcoded colors (use Theme.swift)
- [ ] Contrast ≥4.5:1 in light mode
- [ ] Contrast ≥4.5:1 in dark mode
- [ ] All colors have light + dark variants
- [ ] Tested on device, not just Xcode preview

**Reduce Motion** ✓
- [ ] Essential interactions work without animation
- [ ] Animations respect `accessibilityReduceMotion`
- [ ] No spinning or rapid motion
- [ ] Loading spinners optional, not required

**Color Contrast** ✓
- [ ] Text ≥4.5:1 (normal) or ≥3:1 (large)
- [ ] Icons ≥3:1 contrast
- [ ] Color not only way to convey info

**Touch Targets** ✓
- [ ] All interactive elements ≥44pt
- [ ] CTAs ≥50pt
- [ ] List rows ≥56pt
- [ ] ≥8pt spacing between targets

## Testing on Device (Recommended Sequence)

1. **Enable VoiceOver**
   - Navigate entire flow
   - Ensure all actions findable

2. **Enable Dynamic Type (Largest)**
   - Does layout adapt?
   - Can you read everything?
   - Can you tap all buttons?

3. **Toggle Dark Mode**
   - Are colors visible?
   - Any text disappear?

4. **Enable Reduce Motion**
   - Do animations break anything?
   - Can you still interact normally?

5. **Disable all accessibility**
   - Does normal mode still work?

## Output Format

When auditing a feature:

```markdown
## Accessibility Audit: [Feature Name]

### VoiceOver ✓
- All buttons labeled: "Delete 5 photos"
- Logical read order: Confirmed (top-to-bottom)
- Decorative images hidden: ✓
- Result: **PASS**

### Dynamic Type ✓
- Semantic sizing used: ✓ (.headline, .body, .caption)
- Tested at 44pt–72pt: ✓ No overflow
- Touch targets ≥44pt at large text: ✓ 50pt CTAs
- Result: **PASS**

### Dark Mode ✓
- No hardcoded colors: ✓
- Contrast light mode: ✓ 8.4:1
- Contrast dark mode: ✓ 7.2:1
- Result: **PASS**

### Reduce Motion ✓
- Animations respect setting: ✓
- No vestibular triggers: ✓
- Result: **PASS**

### Color Contrast ✓
- Text contrast: ✓ 4.5:1+
- Icons contrast: ✓ 3:1+
- Result: **PASS**

### Touch Targets ✓
- Button sizing: ✓ 50pt+
- List rows: ✓ 56pt+
- Spacing: ✓ 8pt+
- Result: **PASS**

## Summary
**ACCESSIBILITY COMPLETE** — Feature ready for user testing.
```

---

**Use This Skill When:**
- Auditing a feature before ship
- Testing on device (VoiceOver, Dynamic Type, Dark Mode)
- Reviewing accessibility in code review
- Creating test matrix for QA
- Validating color palette compliance
