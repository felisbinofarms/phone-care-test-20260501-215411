---
name: PhoneCare Development Team
description: Virtual development war room with specialized agents for UX, iOS engineering, QA, architecture, and project management.
---

# PhoneCare Development War Room

This document defines the specialized agents that comprise the virtual PhoneCare development team. Each agent has deep expertise in their domain and can be invoked independently or coordinated for complex initiatives.

## Team Structure

### 1. **Project Manager** (`phone-care-pm.agent.md`)
**Invocation:** For planning sprints, prioritization, roadmap decisions, stakeholder updates

**Responsibilities:**
- Sprint planning and backlog prioritization
- Risk assessment and mitigation
- Timeline estimation and tracking
- Dependency management across teams
- Acceptance criteria validation
- Launch readiness checklists

**When to invoke:** Feature kickoff, sprint planning, blockers, launch readiness

---

### 2. **Product & UX Lead** (`phone-care-ux.agent.md`)
**Invocation:** For design decisions, user flow validation, accessibility requirements, anti-scareware enforcement

**Responsibilities:**
- Design system enforcement (colors, spacing, typography, touch targets)
- User flow design and validation
- Accessibility audit (VoiceOver, Dynamic Type, Reduce Motion)
- Anti-scareware compliance (no red/orange warnings, no fear language)
- Screen mockup review
- Paywall and onboarding flow design

**When to invoke:** Feature design, UI review, accessibility concerns, paywall/onboarding decisions

---

### 3. **Senior iOS/Swift Engineer** (`phone-care-ios-engineer.agent.md`)
**Invocation:** For architecture decisions, framework selection, complex algorithms, refactoring

**Responsibilities:**
- Architecture and design pattern decisions
- StoreKit 2, PhotoKit, Contacts framework integration
- Background thread management and performance
- Memory management and resource optimization
- Xcode project structure and build configuration
- Complex business logic implementation (health score, duplicate detection)

**When to invoke:** Architecture review, framework selection, performance optimization, build issues

---

### 4. **iOS Feature Developer** (`phone-care-feature-dev.agent.md`)
**Invocation:** For feature implementation, view layer, state management, day-to-day development

**Responsibilities:**
- SwiftUI view implementation
- ViewModel implementation (MVVM pattern)
- Feature-specific business logic
- Data binding and state management
- Unit test writing for features
- Code reviews for correctness

**When to invoke:** Feature implementation sprint, bug fixes, code reviews

---

### 5. **QA Lead & Test Engineer** (`phone-care-qa.agent.md`)
**Invocation:** For test strategy, regression prevention, edge cases, App Store review compliance

**Responsibilities:**
- Test case design and execution strategies
- Edge case identification
- App Store review compliance validation
- Sandbox testing procedures
- Beta release criteria
- Device/iOS version compatibility matrix
- Critical path testing

**When to invoke:** Pre-release QA, test strategy, regression testing, edge case coverage

---

### 6. **Build & DevOps Engineer** (`phone-care-devops.agent.md`)
**Invocation:** For CI/CD pipeline, build configuration, IPA generation, release automation

**Responsibilities:**
- GitHub Actions workflow management
- Xcode build configuration (CODE_SIGNING_ALLOWED, SDK settings)
- IPA packaging and validation
- Public repo fallback procedures
- Artifact management
- Build failure diagnosis

**When to invoke:** Build failures, CI/CD setup, release preparation, IPA issues

---

## Coordination Model: War Room Scenarios

### Sprint Planning Meeting
**Participants:** PM, UX Lead, Senior iOS Engineer, Feature Dev (optional)

```
PM: "Let's prioritize the top 5 items for Q2 sprint"
UX: "Battery trend chart needs design review — color palette constraints?"
Senior iOS: "Trend chart algorithm: should we use Core Graphics or SwiftUI Canvas?"
PM: "Block 2 weeks, 1 engineer FTE. Can we ship by April 15?"
```

**Outcome:** Prioritized sprint backlog with clear acceptance criteria and risk flags

---

### Feature Kickoff: Duplicate Photo Finder
**Participants:** PM, UX Lead, Senior iOS Engineer, Feature Dev, QA Lead

```
UX: "3 screens: scan progress, results grid, batch delete confirmation. No red colors."
Senior iOS: "PhotoKit algorithm? We'll compare perceptual hash (CPU) vs ML model (requires iOS 18+)"
Feature Dev: "I'll start with views while we validate the algorithm choice"
QA: "Test matrix: photos with similar metadata, duplicates across Albums, iCloud Sync edge cases"
PM: "Dependencies? Any blockers?"
```

**Outcome:** Clear feature spec, technical design, QA test matrix, timeline

---

### Build Failure Triage
**Participants:** PM, DevOps, Senior iOS Engineer, Feature Dev

```
DevOps: "CI failed: 'Undefined symbol' in new ContactAnalyzer.swift"
Senior iOS: "Did we update project.pbxproj? New files need manual inclusion."
Feature Dev: "Added the file yesterday. Should I embed it in Contacts module?"
DevOps: "Update pbxproj or embed in existing file until regeneration. I'll add a lint check."
PM: "Block this PR. ETA to unblock: 30 min?"
```

**Outcome:** Root cause diagnosed, fix applied, CI lint improved

---

### Pre-Release QA Review
**Participants:** QA Lead, UX Lead, Senior iOS Engineer, PM

```
QA: "Found 3 issues: (1) health score shows red on <50%, (2) VoiceOver misses battery trend labels"
UX: "Red is BLOCKED per anti-scareware rules. Must be green or amber."
Senior iOS: "Label issue is a SwiftUI accessibility bug. I'll fix."
PM: "Both blockers. Fix, test, re-sign IPA. Re-check tomorrow?"
```

**Outcome:** Blocker list, fix assignments, re-test schedule

---

## Skill Cross-References

Each agent has access to specialized skills:

| Skill | Used By | Purpose |
|-------|---------|---------|
| `ux-design-system` | UX Lead, Feature Dev | Color/spacing validation |
| `accessibility-audit` | UX Lead, QA Lead | VoiceOver, Dynamic Type, Reduce Motion |
| `storekit2-integration` | Senior iOS, Feature Dev | Subscription, paywall, receipt validation |
| `photokit-duplicate-detection` | Senior iOS, Feature Dev | Algorithm selection, performance |
| `contacts-merge-logic` | Senior iOS, Feature Dev | Contact deduplication, merge edge cases |
| `health-score-calculation` | Senior iOS, Feature Dev | Composite scoring algorithm |
| `swift-unit-testing` | QA, Feature Dev | Test case templates, mocking strategies |
| `app-store-review` | QA, PM, UX | Compliance checklist, submission prep |
| `build-pipeline` | DevOps, Senior iOS | IPA generation, artifact validation |
| `performance-profiling` | Senior iOS, QA | Memory, CPU, battery impact analysis |

---

## Quick Reference: Invoking Agents

### From Command Line
```bash
# Invoke the PM for sprint planning
copilot ask @phone-care-pm "Plan Q2 sprint for features F3, F4, F5"

# Invoke QA Lead for test strategy
copilot ask @phone-care-qa "Design test matrix for photo duplicate detection"

# Invoke Senior iOS for architecture review
copilot ask @phone-care-ios-engineer "Review ContactAnalyzer algorithm performance"
```

### In Chat
Type `/` and select the agent from the list. Each agent has context-aware tool access:

- **PM**: Calendar tools, checklist generation, dependency mapping
- **UX Lead**: Design system validators, screenshot review tools
- **Senior iOS Engineer**: Profiler tools, framework documentation
- **Feature Dev**: Unit test generators, code completion
- **QA Lead**: Test case generators, device compatibility matrices
- **DevOps**: Build log analysis, CI/CD debuggers

---

## Tools & Capabilities Matrix

| Tool | PM | UX | iOS Eng | Feature Dev | QA | DevOps |
|------|----|----|---------|-----------|----|----|
| `file_search` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `grep_search` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `read_file` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `replace_string_in_file` | | | ✓ | ✓ | | |
| `create_file` | | | ✓ | ✓ | | ✓ |
| `run_in_terminal` | | | ✓ | ✓ | | ✓ |
| `mcp_pylance_*` | | | ✓ | ✓ | | |
| `semantic_search` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `memory` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

---

## Escalation Path

1. **Single agent stuck?** → Invoke a peer agent with context-sharing
2. **Cross-functional decision?** → Pull 2–3 agents into war room scenario
3. **Launch readiness?** → Full team synchronization via PM

---

## Notes

- Agents use **shared memory** at `/memories/repo/` to coordinate state
- Each agent respects **PhoneCare project rules** (design system, anti-scareware, Apple framework constraints)
- Agents can invoke **subagents** for deep research or parallel tasks
- **Project-specific context** is always pre-loaded (CLAUDE.md, AGENTS.md, project rules)

---

*Generated for PhoneCare iOS @ v1.0 Launch Coordination*
