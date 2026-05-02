# PhoneCare Development War Room Guide

**Last Updated:** April 30, 2026

This guide explains how to effectively use the PhoneCare development team system for rapid, coordinated development.

## Quick Start: Calling Your Team

### Scenario 1: Start a Sprint
```
You: "PM, let's plan Q2. I need prioritization for F3, F4, and F5."

@phone-care-pm:
- Evaluates scope vs resources
- Creates sprint breakdown with story points
- Identifies dependencies and risks
- Provides timeline estimate

Output: Sprint plan with acceptance criteria and go/no-go decision
```

### Scenario 2: Design Review
```
You: "UX Lead, we have mockups for the battery trend chart. Red is used for low battery warning—is that OK?"

@phone-care-ux:
- Checks against anti-scareware rules
- ❌ RED FOR WARNINGS = BLOCKED (brand violation)
- ✓ Suggests AMBER instead
- Validates colors, spacing, accessibility

Output: Design approval (with revisions or rejection)
```

### Scenario 3: Feature Implementation
```
You: "Feature Dev, implement F3 (Duplicate Photo Finder). Sprint goal: ship by April 21."

@phone-care-feature-dev:
- Reviews design mockups from UX
- Implements PhotosViewModel + PhotosView
- Writes unit tests (80%+ coverage)
- Handles state (loading, success, error)
- Tests accessibility (VoiceOver, Dynamic Type)

Output: Feature complete + ready for QA
```

### Scenario 4: Test Before Ship
```
You: "QA, prep pre-release testing. We're shipping F1–F10 (MVP)."

@phone-care-qa:
- Creates test matrix for all features
- Documents edge cases
- Plans device testing (iPhone 11 + latest)
- Validates App Store compliance
- Defines go/no-go criteria

Output: Test cases + QA sign-off + blockers list
```

### Scenario 5: Build Fails
```
You: "DevOps, CI failed with 'Undefined symbol' error. Fix it."

@phone-care-devops:
- Diagnoses: New .swift file not in Xcode project
- Fixes: Updates project.pbxproj
- Re-runs build
- Adds lint check to prevent recurrence

Output: Build green ✓
```

## Full Team Sync: Pre-Launch War Room

**Participants:** PM, UX, Senior iOS, Feature Dev (x2), QA, DevOps
**Duration:** 1 hour
**Agenda:**

1. **MVP Feature Completeness** (10 min)
   - PM: "All 10 features complete?"
   - Each team: ✓ or ❌
   - Any blockers?

2. **Quality Gates** (15 min)
   - QA: "Test coverage met?"
   - QA: "Any P0 bugs?"
   - UX: "Anti-scareware compliance?"
   - DevOps: "Build reliable?"

3. **App Store Readiness** (10 min)
   - UX: "Screenshots and description ready?"
   - QA: "Privacy labels accurate?"
   - Senior iOS: "Any known issues?"
   - PM: "Go or No-go?"

4. **Launch Timeline** (10 min)
   - PM: "Submit Monday, expect review by Wed?"
   - DevOps: "Artifact ready?"
   - All: Action items for next 48 hours?

5. **Escalations & Risks** (15 min)
   - Any blocker that could delay launch?
   - Mitigation strategy?
   - Decision authority?

**Output:** Go/No-go decision + launch checklist

## Agent-Specific Workflows

### Product Manager (`@phone-care-pm`)

**Use When:**
- Sprint planning, backlog prioritization
- Feature kickoff (define acceptance criteria)
- Risk triage, blocker escalation
- Launch readiness review
- Stakeholder communication

**Sample Request:**
```
"Plan Q2 sprint with these constraints:
- 2 weeks, 2 FTE engineers available
- Features F3 (Duplicates), F4 (Contacts), F5 (Battery)
- All must have unit tests
- What's realistic?"
```

### UX/Product Lead (`@phone-care-ux`)

**Use When:**
- Design decisions, user flow validation
- Accessibility audit (VoiceOver, Dynamic Type)
- Anti-scareware enforcement (no red warnings)
- Paywall/onboarding design
- Screen mockup review

**Sample Request:**
```
"Review this battery warning design:
- 20% battery shows RED circle with 'URGENT CLEANUP'
Is this on-brand?"

Response: "❌ BLOCKED. Red violates anti-scareware rule. Use amber.
Change to: AMBER circle, 'Your battery needs attention.'"
```

### Senior iOS Engineer (`@phone-care-ios-engineer`)

**Use When:**
- Architecture review, design patterns
- Framework selection (StoreKit 2, PhotoKit, etc.)
- Complex algorithm design (hash, merge, scoring)
- Performance optimization, memory profiling
- Build configuration issues

**Sample Request:**
```
"Design the duplicate photo detection algorithm.
Library: 5000 photos. Time budget: <20 seconds. Memory: <100MB.
Which approach: Perceptual hash vs ML model?"

Response: "Start with PHASH:
- O(n log n), CPU-efficient
- 90% accuracy
- iOS 17+ support
- See skill: photokit-duplicate-detection"
```

### Feature Developer (`@phone-care-feature-dev`)

**Use When:**
- Feature implementation sprint
- ViewModel/View development
- Unit test writing
- Bug fixes and code reviews
- Design system validation

**Sample Request:**
```
"Implement F8: Onboarding (11 screens).
Deadline: April 10.
Show scan results BEFORE paywall.
Support Dynamic Type + VoiceOver."
```

### QA Lead (`@phone-care-qa`)

**Use When:**
- Test strategy design
- Edge case identification
- App Store compliance validation
- Device/iOS compatibility testing
- Sandbox subscription testing

**Sample Request:**
```
"QA F9 (Paywall). Key scenarios:
1. Trial grants access (test in sandbox)
2. Trial expires after 7 days
3. Renewal is transparent
4. Restore Purchases works
Create test matrix and sign-off."
```

### DevOps Engineer (`@phone-care-devops`)

**Use When:**
- CI/CD setup, build failures
- IPA generation and validation
- GitHub Actions workflow
- Public repo fallback procedures
- Artifact management, version bumping

**Sample Request:**
```
"Build failed: 'Undefined symbol'.
Logs: https://github.com/...
Fix the CI and add lint check to prevent this again."
```

## Skills Quick Reference

| Skill | Used By | When |
|-------|---------|------|
| `ux-design-system` | UX, Feature Dev | Color/spacing validation |
| `accessibility-audit` | UX, QA | VoiceOver, Dynamic Type, Dark Mode |
| `storekit2-integration` | Feature Dev, Senior iOS | Subscription, billing, sandbox testing |
| `photokit-duplicate-detection` | Senior iOS, Feature Dev | Duplicate photo algorithm |
| `contacts-merge-logic` | Senior iOS, Feature Dev | Contact deduplication, merge conflict resolution |
| `health-score-calculation` | Senior iOS, Feature Dev | Composite health score algorithm |
| `swift-unit-testing` | Feature Dev, QA | Unit test templates, mocking, coverage |
| `app-store-review` | QA, PM, UX | Submission prep, compliance, screenshots |
| `build-pipeline` | DevOps, Senior iOS | CI/CD, IPA generation, build troubleshooting |
| `performance-profiling` | Senior iOS, QA | CPU/memory profiling, optimization |

## Decision-Making Authority

**Who decides what?**

| Decision | Authority | Escalation |
|----------|-----------|-----------|
| Sprint scope | PM | CEO if timeline impacted |
| Feature design | UX + PM consensus | CEO if brand impacted |
| Architecture | Senior iOS | PM if timeline impacted |
| Quality gates | QA + Senior iOS consensus | PM if launch threatened |
| Launch readiness | PM (after QA sign-off) | CEO/Board |

## Red Flags: Escalate Immediately

- ❌ P0 bug (crash, data loss) found 3 days before launch
- ❌ App Store rejection reason found during QA
- ❌ Red color used for health warnings (brand violation)
- ❌ Paywall before delivering feature value
- ❌ VoiceOver completely broken
- ❌ Build fails consistently in CI
- ❌ Performance significantly worse than target

**Action:** PM convenes immediate war room with relevant agents.

## Communication Standards

### Chat Format
- **Clear:** State problem + context + deadline
- **Specific:** "F3 has red warning colors" (not "colors wrong")
- **Actionable:** "Fix by EOD Tuesday" (not "fix soon")

### Handoffs
- Always confirm understanding
- Share relevant files/links
- Set clear acceptance criteria
- Define done state

### Escalation
- If stuck >30 min, escalate to PM
- If depends on another team, flag dependencies
- If unsure, ask for clarification (don't guess)

## Sample Sprint: F3 Duplicate Photo Finder

### Day 1: Kickoff
```
PM: "F3 timeline: 5 days (by April 10). Budget: 1 FTE developer + review.
Acceptance: Scan 1000 photos in <5s, show results, free users see 3 groups."

UX: "Mockups ready. 3 screens:
- Scan progress spinner
- Results grid (2 photos per group)
- Batch delete confirmation
Colors: Green/amber only, no red. ✓ Anti-scareware compliant."

Senior iOS: "Algorithm: Perceptual hash (PHASH) for MVP.
Threshold 15 for comparison.
Edge case: handle rotated photos.
Memory: <100MB, Time: <5s for 1000."

Feature Dev: "Ready to start. Need: design mockups, algorithm details, unit test template."

QA: "Will test:
1. Happy path: 10 duplicates detected
2. No duplicates: Shows 'None found'
3. Free user: First 3 groups visible, paywall for more
4. Delete confirmation shows item count + size."
```

### Days 2–3: Implementation
```
Feature Dev:
- Day 2: Implement PhotosViewModel + PhotosView (screens 1–2)
- Day 2: Implement unit tests (PHASH algorithm)
- Day 3: Implement batch delete + confirmation (screen 3)
- Day 3: Accessibility audit (VoiceOver, Dynamic Type)

Senior iOS (review):
- Reviews ViewModel state management
- Confirms thread safety (scans on background queue)
- Validates PHASH performance
```

### Day 4: QA Testing
```
QA:
- ✓ Scan with 1000 test photos: Completes in 4.2 seconds
- ✓ Finds all 10 duplicate groups
- ✓ Free user sees 3 groups + paywall
- ✓ Delete shows confirmation: "Delete 5 photos? Freed 47 MB"
- ✓ Undo works for 24 hours
- ✓ VoiceOver: All buttons labeled, logical read order
- ✓ Dynamic Type: Readable at 44pt–72pt
- ✓ Dark Mode: All colors validated

Result: READY FOR SHIP ✓
```

### Day 5: Integration
```
Feature Dev: Merge to main via PR
DevOps: Build passes CI ✓
PM: Ship with F1, F2, F3 milestone
```

## Continuous Communication

### Daily Standup (15 min)
- Each agent: "What did I do? What's next? Any blockers?"
- PM: "On track for launch?"
- All: Red flags?

### Weekly War Room (1 hour)
- Sprint progress review
- Risks/blockers
- Next week priorities
- Launch readiness status

### Pre-Release (Final 48 hours)
- Daily syncs
- Bug triage
- Go/no-go decision
- Launch plan

## Tools & Access

- **GitHub:** Code, CI/CD, artifacts
- **App Store Connect:** Pricing, submissions, analytics
- **Xcode:** Build, test, profile
- **iPhone (device):** Real testing (required before ship)

## Victory Conditions

🎉 **MVP Launch:**
- [ ] All 10 features complete and tested
- [ ] Unit test coverage ≥80%
- [ ] VoiceOver, Dynamic Type, Dark Mode all pass
- [ ] No red/orange health warnings (anti-scareware ✓)
- [ ] App Store submission accepted
- [ ] Available on App Store May 15, 2026

---

**Questions? Ask the relevant agent in your chat. They have deep expertise in their domain and the PhoneCare project rules.**

**Ready to ship!** 🚀
