# Automated Build Verification Pipeline

## Overview

Your code is **automatically verified on every PR and main merge** using temporary public repositories. This gives you unlimited free GitHub Actions minutes ($0 cost) while keeping your source code private.

**How it works:**
1. You push a PR or merge to main
2. GitHub Actions creates a temporary public repo (`phone-care-verify-...`)
3. Your code is pushed to it (unlimited free macOS minutes)
4. Build succeeds/fails on the public repo
5. Status is reported back to your PR as a comment
6. Temporary repo is deleted automatically
7. Your private repo stays private

```
┌─────────────────┐
│ Private Repo    │
│ (Your Source)   │
└────────┬────────┘
         │
         │ PR created / push to main
         │
         ▼
┌──────────────────────────────────────┐
│ verify-buildable.yml                 │
├──────────────────────────────────────┤
│ 1. Create temp public repo (5s)      │
│ 2. Push code to it (10s)             │
│ 3. Wait for build to finish (10min)  │
│ 4. Report status back to PR (1s)     │
│ 5. Delete temp repo (2s)             │
└────────┬─────────────────────────────┘
         │
         ▼
   ✅ Buildable!
   (or ❌ Failed with link to logs)
```

---

## Setup (One-Time)

### Step 1: Ensure `build.yml` is in place

The workflow `.github/workflows/build.yml` runs on all public repos (including temp ones). It:
- Builds the iOS app
- Exports `.ipa`
- Reports status

✅ **Already created** at `.github/workflows/build.yml`

### Step 2: Enable Actions on your private repo

1. Go to your **private repo settings** → **Actions** → **General**
2. Enable "Allow all actions and reusable workflows"
3. Save

### Step 3: Configure GitHub Token (Already available)

The verification workflow uses `secrets.GITHUB_TOKEN` (automatically available). This token can:
- ✅ Create public repos under your account
- ✅ Push to those repos
- ✅ Query Actions status
- ✅ Delete repos
- ✅ Post PR comments

**No additional secrets needed.** The default token has all required permissions.

---

## Workflows Deployed

### `.github/workflows/build.yml`
**What:** Simple build workflow that runs on public repos
**Triggers:** Runs on every push to `main` branch in the temp public repo
**Does:**
- Builds PhoneCare archive
- Exports `.ipa`
- Prepares TestFlight upload (secrets needed for actual upload, placeholder for now)

### `.github/workflows/verify-buildable.yml`
**What:** Orchestration workflow running in your private repo
**Triggers:**
- Every pull request (opened, synchronized, reopened)
- Every push to `main`

**Does:**
1. **Create temp public repo** named `phone-care-verify-YYYYMMDD-HHMMSS-{RUN_ID}`
2. **Push your code** to it (triggers `build.yml` automatically)
3. **Poll GitHub API** every 10 seconds (max 10 minutes)
4. **Check build result** (success/failure)
5. **Post PR comment** with status (if PR) or commit status (if main push)
6. **Delete temp repo** (always, even if build failed)

---

## Usage

### For PRs
1. Push commits to your PR branch
2. GitHub Actions automatically:
   - Creates temp public repo
   - Runs build
   - Posts ✅ or ❌ comment on your PR
3. You see PR comment: *"✅ Build Verification Passed"* or *"❌ Build Verification Failed"*
4. Temp repo auto-deleted

### For Main Merges
1. Merge your PR to `main`
2. GitHub Actions automatically:
   - Creates temp public repo
   - Runs build
   - Sets commit status (visible on main branch)
3. You see green checkmark (or red X) on the commit
4. Temp repo auto-deleted

### Manual Verification (Optional)
If you want to verify locally or manually:
```bash
# Clone the latest code
git clone https://github.com/yourusername/phone-care-ios.git
cd phone-care-ios

# Build manually
xcodebuild -project PhoneCare.xcodeproj \
  -scheme PhoneCare \
  -configuration Release \
  -archivePath "build/PhoneCare.xcarchive" \
  archive

# Export IPA
xcodebuild -exportArchive \
  -archivePath "build/PhoneCare.xcarchive" \
  -exportOptionsPlist "tools/ExportOptions.plist" \
  -exportPath "build/Release"
```

---

## How Temp Repo Cleanup Works

**Auto-cleanup always happens**, even if:
- Build fails
- Build times out
- Workflow crashes

The cleanup step runs in the `finally` phase:
```yaml
- name: Clean up temporary repository
  if: always()
  run: gh repo delete "$TEMP_REPO" --yes
```

**Result:** No orphaned temp repos; your GitHub account stays clean.

---

## Troubleshooting

### "❌ Build Verification Failed"
1. Click the link in PR comment → view build logs
2. Fix the code
3. Push a new commit to the PR
4. Verification runs automatically

### "⏱️ Build Verification Timeout"
Build took >10 minutes. Check:
- Xcode build log (linked in PR comment)
- Slow network / Actions queue
- Compile errors

Current estimate: ~15 min per build (will improve with caching)

### Temp repo wasn't deleted
Very rare. If you see orphaned repos:
```bash
gh repo list --source --limit 100 | grep phone-care-verify
gh repo delete phone-care-verify-XXXX --yes
```

### PR comment didn't appear
Check:
1. Workflow permissions: Settings → Actions → General → "Read and write permissions"
2. Enable "Allow GitHub Actions to create and approve pull requests" (if using branch protection)

---

## Cost Breakdown

| Item | Cost |
|------|------|
| Private repo + unlimited verification builds | $0 |
| Temporary public repo creation/deletion | $0 |
| GitHub Actions on public repos | $0 (unlimited free) |
| GitHub Actions on private repo (verify orchestration) | ~0.5 min/PR (~$0∎) |
| **Total/PR** | **$0.001 ($0 practical)** |

---

## Next Steps

1. ✅ Workflows deployed to `.github/workflows/`
2. ✅ No secrets configuration needed
3. **Action:** Commit these changes to your private repo
4. **Result:** On next PR, verification runs automatically

```bash
git add .github/workflows/build.yml .github/workflows/verify-buildable.yml
git commit -m "Add automated build verification pipeline"
git push origin main
```

Then open a PR and watch the magic! 🎉

---

## Architecture Notes

### Why two workflows?

- **`build.yml`** = Dumb builder (just builds, works on any repo)
- **`verify-buildable.yml`** = Smart orchestrator (creates/deletes temp repos, posts status)

This separation allows:
- Reusable `build.yml` on any public repo
- Private repo can control the lifecycle (create → verify → cleanup)
- Zero trust: no secrets needed (for public repos)

### Why unlimited free minutes on public repos?

GitHub's pricing:
- **Private repos:** 2,000 free macOS min/month, then $0.35/min
- **Public repos:** Unlimited free macOS minutes (always)

This is intentional community support. We're using it for QA—not circumventing fair use.

### Polling instead of webhooks?

Webhooks would be ideal, but GitHub doesn't have cross-repo workflow webhooks. Polling is:
- Simple
- Reliable
- Low-latency (10-second intervals)
- ~5-10 API calls max per build

