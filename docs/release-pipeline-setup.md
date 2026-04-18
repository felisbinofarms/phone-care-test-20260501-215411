# PhoneCare Release Pipeline Setup

## Architecture

**Private Repo** (phone-care-ios):
- Compiles iOS app on macOS runner (free tier: 2,000 min/month)
- Posts build artifact to public repo via PR

**Public Repo** (phone-care-releases):
- Receives PR with compiled `.ipa`
- Runs verification/signing on free Linux runners (unlimited)
- Uploads to TestFlight/App Store
- Cleans up after release

## Prerequisites

### 1. Create Public Release Repo

```bash
# On GitHub, create new repo: phone-care-releases
# Make it PUBLIC
# Initialize with README
git clone https://github.com/pyroforbes/phone-care-releases.git
cd phone-care-releases
mkdir -p .github/workflows
touch README.md
git add .
git commit -m "Initial commit"
git push -u origin main
```

### 2. Set Up Secrets

#### Private Repo Secrets (`pyroforbes/phone-care-ios`):

1. **`RELEASE_REPO_TOKEN`** (required)
   - Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Create token with scopes: `repo`, `workflow`
   - Add to private repo: Settings → Secrets and variables → Actions → New repository secret
   - Name: `RELEASE_REPO_TOKEN`

2. **`APP_STORE_CONNECT_KEY`** (optional, for later)
   - For TestFlight uploads

#### Public Repo Secrets (`pyroforbes/phone-care-releases`):

1. **`RELEASE_REPO_TOKEN`** (same as above)
   - For posting results back to private repo

2. **`APP_STORE_CONNECT_KEY`** (optional)
   - For App Store uploads

### 3. Add Workflows

#### Private Repo:
```bash
# Already created at: .github/workflows/build-release.yml
# This compiles and posts to public repo
```

#### Public Repo:
```bash
# Copy the workflow to public repo:
cd phone-care-releases/.github/workflows
cat > release-pipeline.yml << 'EOF'
[Paste content from RELEASE_PIPELINE_PUBLIC_REPO.yml]
EOF
git add .
git commit -m "Add release pipeline workflow"
git push
```

## How It Works

### Step 1: Trigger Build (Private Repo)

```bash
# Option A: Manual trigger
# Go to: Actions → Build & Release → Run workflow

# Option B: Automatic on release tag
git tag v1.0.0
git push origin v1.0.0
```

### Step 2: Compilation (Private Repo)
- `build-release.yml` runs `xcodebuild` on macOS
- Builds `.ipa` file
- Encodes it in base64
- Creates a PR in public repo

### Step 3: Release (Public Repo)
- `release-pipeline.yml` triggers on PR
- Decodes artifact
- Verifies IPA structure
- Runs security scans
- Posts result back to private repo
- **Automatically closes PR and deletes branch** → artifact disappears

## Cost

- **Private Repo**: ~15 min macOS runner per build (2,000 free min/month = ~130 builds)
- **Public Repo**: Free (Linux runners are unlimited)
- **Total**: Essentially free for reasonable release cadence

## Customization

### Add TestFlight Upload

In `release-pipeline.yml`, replace the placeholder with:

```yaml
- name: Upload to TestFlight
  run: |
    xcrun altool \
      --upload-app \
      --type ios \
      --file PhoneCare.ipa \
      --username ${{ secrets.APP_STORE_CONNECT_EMAIL }} \
      --password ${{ secrets.APP_STORE_CONNECT_KEY }}
```

### Add App Store Release

In `release-pipeline.yml`, add:

```yaml
- name: Submit to App Store
  run: |
    transporter -t "upload" \
      -f "PhoneCare.ipa" \
      -u "${{ secrets.APP_STORE_CONNECT_EMAIL }}" \
      -p "${{ secrets.APP_STORE_CONNECT_KEY }}"
```

### Add Notarization (macOS requirement for distribution)

If distributing outside App Store, add to private repo workflow:

```yaml
- name: Notarize build
  run: |
    xcrun altool \
      --notarize-app \
      --file PhoneCare.ipa \
      --primary-bundle-id com.phonecare.PhoneCare \
      --username ${{ secrets.APPLE_ID }} \
      --password ${{ secrets.APPLE_APP_SPECIFIC_PASSWORD }}
```

## Troubleshooting

### "IPA not found"
- Check Xcode build succeeded
- Verify ExportOptions.plist is valid
- Check build logs in Actions

### "No artifact found in public repo"
- Ensure RELEASE_REPO_TOKEN has `repo` and `workflow` scopes
- Verify private repo can push to public repo

### Public repo PR not triggering workflow
- Ensure `release-pipeline.yml` is in public repo `.github/workflows/`
- Check PR was created with correct file paths (`artifacts/`, `BUILD_META.txt`)

## Next Steps

1. Create `phone-care-releases` repo (public)
2. Add `RELEASE_REPO_TOKEN` to both repos
3. Copy `RELEASE_PIPELINE_PUBLIC_REPO.yml` content to public repo
4. Test with `workflow_dispatch` trigger on private repo
5. Monitor first build in Actions tabs of both repos
