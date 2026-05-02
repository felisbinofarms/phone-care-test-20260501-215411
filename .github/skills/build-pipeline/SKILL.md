---
name: build-pipeline
user-invocable: true
description: "Use when: setting up CI/CD, debugging build failures, configuring Xcode settings, generating IPAs, managing artifacts, troubleshooting swift file inclusion, using public repo fallback."
---

# PhoneCare Build Pipeline Skill

Complete guide to CI/CD setup, build configuration, IPA generation, and troubleshooting.

## GitHub Actions Workflow: `.github/workflows/build.yml`

**Minimal Working Example:**

```yaml
name: Build PhoneCare

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build:
    runs-on: macos-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Select Xcode version
        run: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
      
      - name: Verify build environment
        run: |
          xcode-select -p
          xcodebuild -version
      
      - name: Build for iOS Device
        run: |
          set -eo pipefail
          xcodebuild -scheme PhoneCare \
            -sdk iphoneos \
            -destination 'generic/platform=iOS' \
            -configuration Release \
            CODE_SIGNING_ALLOWED=NO \
            build 2>&1 | tee build.log
      
      - name: Package IPA
        run: |
          # Create IPA from .app bundle
          ditto -c -k --sequesterRsrc --keepParent \
            build/Release-iphoneos/PhoneCare.app \
            PhoneCare.ipa
          
          # Verify IPA structure
          echo "IPA Contents:"
          unzip -l PhoneCare.ipa | head -20
          
          # Validate required files
          unzip -t PhoneCare.ipa | grep -E "(Info.plist|PhoneCare$)" || {
            echo "ERROR: IPA missing required files"
            exit 1
          }
          
          echo "IPA validation passed"
      
      - name: Upload IPA artifact
        uses: actions/upload-artifact@v3
        with:
          name: PhoneCare-unsigned
          path: PhoneCare.ipa
          retention-days: 30
      
      - name: Build status check
        if: always()
        run: |
          if [ -f build.log ]; then
            echo "Build log available:"
            tail -50 build.log
          fi
```

## Build Settings Reference

**Critical Xcode Settings for iOS Device Build:**

| Setting | Value | Why |
|---------|-------|-----|
| `-sdk iphoneos` | iOS device SDK | Build for physical devices, not simulator |
| `-destination 'generic/platform=iOS'` | Generic platform | Works with any iOS device (iPhone 11, 12, 15, etc.) |
| `CODE_SIGNING_ALLOWED=NO` | Disabled | No code signing in CI (produces unsigned IPA for Sideloadly) |
| `-configuration Release` | Release build | Optimized, minified, production-ready |
| Build Destination | Device, not simulator | CI environment can't run simulator |

## Xcode Project File Issues

### Issue 1: New .swift File Not Found (Undefined Symbol)

**Symptoms:**
```
ld: symbol not found in flat namespace: _$s9PhoneCare...
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```

**Root Cause:**
Added new `.swift` file to repo but didn't add to `PhoneCare.xcodeproj/project.pbxproj`

**Solution A: Manual Fix (Recommended)**
```bash
# 1. Open Xcode locally
open PhoneCare.xcworkspace

# 2. Go to: PhoneCare target → Build Phases → Compile Sources
# 3. Click + and add the missing .swift file(s)
# 4. Commit project.pbxproj changes

git add PhoneCare.xcodeproj/project.pbxproj
git commit -m "Add ContactAnalyzer.swift to project"
git push
```

**Solution B: Temporary Workaround**
```bash
# Embed new type in existing file until project regeneration
# Example: Add ContactAnalyzer inside Contacts.swift

cat >> PhoneCare/Features/Contacts/Contacts.swift << 'EOF'

// TEMPORARY: Move to separate file after project regeneration
struct ContactAnalyzer {
    // ... implementation
}
EOF
```

**Solution C: Add CI Lint Check (Prevention)**

Add to `.github/workflows/build.yml`:

```yaml
      - name: Verify all .swift files in project
        run: |
          echo "Checking for .swift files not in project.pbxproj..."
          
          # Find all .swift files in PhoneCare/
          REPO_FILES=$(find PhoneCare -name "*.swift" -type f | sort)
          
          # Extract filenames from project.pbxproj
          PROJECT_FILES=$(grep -o '[A-Za-z0-9_]*\.swift' \
            PhoneCare.xcodeproj/project.pbxproj | sort -u)
          
          # Check each file
          MISSING=0
          for file in $REPO_FILES; do
            filename=$(basename "$file")
            if ! echo "$PROJECT_FILES" | grep -q "$filename"; then
              echo "❌ MISSING in project.pbxproj: $file"
              MISSING=$((MISSING + 1))
            fi
          done
          
          if [ $MISSING -gt 0 ]; then
            echo "❌ $MISSING file(s) missing from project"
            exit 1
          fi
          echo "✓ All .swift files found in project"
```

### Issue 2: Build Timeout or Hangs

**Symptoms:**
- Build runs for >30 minutes
- Xcode processes use 100% CPU
- Stuck at linking phase

**Solution:**

```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Fresh build
xcodebuild clean -scheme PhoneCare -sdk iphoneos
xcodebuild build -scheme PhoneCare -sdk iphoneos -configuration Release
```

## IPA Validation

**After packaging IPA, always validate structure:**

```bash
# List IPA contents
unzip -l PhoneCare.ipa

# Should show:
#   Payload/PhoneCare.app/Info.plist
#   Payload/PhoneCare.app/PhoneCare (executable)
#   Payload/PhoneCare.app/Assets.car (or similar resources)

# Quick validation check
unzip -t PhoneCare.ipa > /dev/null && echo "IPA valid"

# Check executable is present
unzip -l PhoneCare.ipa | grep "PhoneCare$" || {
  echo "ERROR: PhoneCare executable missing from IPA"
  exit 1
}

# Check Info.plist
unzip -l PhoneCare.ipa | grep "Info.plist" || {
  echo "ERROR: Info.plist missing from IPA"
  exit 1
}

echo "✓ IPA structure valid"
```

## Downloading IPA from GitHub Actions

**From private repo:**
```bash
# List recent runs
gh run list --limit 10

# Download artifact from specific run
gh run download <RUN_ID> \
  --name PhoneCare-unsigned \
  --dir ~/Downloads/phonecare-ipa

# Verify
ls -lh ~/Downloads/phonecare-ipa/PhoneCare.ipa
```

**From public repo fallback:**
```bash
TEMP_REPO="phone-care-$(date +%Y%m%d-%H%M%S)"
gh repo create "felisbinofarms/$TEMP_REPO" --public
git remote add temp-build "https://github.com/felisbinofarms/$TEMP_REPO.git"
git push -u temp-build main

# Wait for build to complete
gh run list --repo "felisbinofarms/$TEMP_REPO"
gh run download <RUN_ID> --repo "felisbinofarms/$TEMP_REPO" \
  --name PhoneCare-unsigned --dir ~/Downloads/phonecare-ipa

# Cleanup
git remote remove temp-build
```

## Version Management

**Automatic version bumping in CI:**

```yaml
      - name: Bump build number
        run: |
          # Get current build number
          BUILD_NUMBER=$(agvtool what-build -terse)
          echo "Current build: $BUILD_NUMBER"
          
          # Increment
          NEW_BUILD=$((BUILD_NUMBER + 1))
          agvtool new-build -all "$NEW_BUILD"
          
          echo "New build number: $NEW_BUILD"
          
          git add PhoneCare.xcodeproj/project.pbxproj
          git commit -m "Bump build to $NEW_BUILD"
          git push
```

## Local Build Testing

**Before pushing, always test locally:**

```bash
# Clean build
xcodebuild clean -scheme PhoneCare -sdk iphoneos

# Build for device
xcodebuild -scheme PhoneCare \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -configuration Release \
  CODE_SIGNING_ALLOWED=NO \
  build

# Verify no errors
echo $?  # Should be 0

# Package IPA
ditto -c -k --sequesterRsrc --keepParent \
  build/Release-iphoneos/PhoneCare.app \
  PhoneCare.ipa

# Validate
unzip -t PhoneCare.ipa
```

## Troubleshooting Build Logs

**Common error patterns:**

```bash
# Error: "Undefined symbol"
# → New .swift file not in project.pbxproj
grep "Undefined symbol" build.log && echo "Need to add file to project"

# Error: "Provisioning profile"
# → CODE_SIGNING_ALLOWED not set
grep -i "provisioning profile" build.log && \
  echo "Check CODE_SIGNING_ALLOWED=NO is set"

# Error: "Framework not found"
# → Framework issue (import vs linking)
grep "Framework not found" build.log && \
  echo "Check framework imports and build phases"

# Warning: "Redundant conformance"
# → Swift type double-confirming protocol (usually OK)
grep "Redundant conformance" build.log && \
  echo "Usually harmless, check if intentional"
```

## Artifact Retention

**GitHub Actions retention policy:**

```yaml
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: PhoneCare-unsigned
          path: PhoneCare.ipa
          retention-days: 30  # Free tier: 90 days max
```

**To keep artifacts longer or download after retention expires:**
- Manual download within retention window
- Use another storage (S3, GitHub Releases, etc.)
- Re-run failed CI builds (creates new artifacts)

## Deployment to TestFlight (Post-MVP)

**For future releases to QA testers:**

```yaml
      - name: Upload to TestFlight
        run: |
          # Requires API key and team ID from App Store Connect
          xcrun altool --upload-app \
            --file PhoneCare.ipa \
            --type ios \
            --apiKey ${{ secrets.APP_STORE_API_KEY }} \
            --apiIssuer ${{ secrets.APP_STORE_ISSUER_ID }}
```

---

**Use This Skill When:**
- Setting up or fixing CI/CD pipeline
- Debugging build failures
- Generating IPAs for testing
- Managing artifact lifecycle
- Troubleshooting Xcode project issues
