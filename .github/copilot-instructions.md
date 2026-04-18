# PhoneCare Copilot Instructions

This repository has a non-standard iOS build workflow because local Xcode is not always available and private GitHub Actions minutes may be exhausted.

## IPA Build Rules

- Prefer the existing workflow in `.github/workflows/build.yml` for IPA generation.
- The current supported artifact is an **unsigned IPA** intended for Sideloadly.
- A valid IPA must contain:
  - `Payload/PhoneCare.app/Info.plist`
  - `Payload/PhoneCare.app/PhoneCare`
- If you change IPA packaging, preserve the `ditto`-based packaging flow used in `.github/workflows/build.yml`.

## When Private GitHub Actions Minutes Are Exhausted

- Do **not** block waiting for private-repo CI.
- Use a temporary **public** repository to consume free unlimited public Actions minutes.
- Standard fallback flow:
  1. Create a temporary public repo with `gh repo create`.
  2. Push `main` to that repo.
  3. Wait for `.github/workflows/build.yml` to complete.
  4. Download the `PhoneCare-unsigned` artifact.
  5. Place the resulting IPA at `~/Downloads/phonecare-ipa/PhoneCare.ipa`.
- Example pattern:

```bash
TEMP_REPO="phone-care-verify-$(date +%Y%m%d-%H%M%S)"
gh repo create "felisbinofarms/$TEMP_REPO" --public
git remote add temp-build "https://github.com/felisbinofarms/$TEMP_REPO.git"
git push -u temp-build main
gh run list --repo "felisbinofarms/$TEMP_REPO"
gh run download <RUN_ID> --repo "felisbinofarms/$TEMP_REPO" --name PhoneCare-unsigned --dir ~/Downloads/phonecare-ipa
```

## Important Project Caveat

- New Swift files are **not always automatically included** in the checked-in Xcode project.
- If you add a new file and CI cannot find the symbol, either:
  - update `PhoneCare.xcodeproj/project.pbxproj`, or
  - temporarily embed the new type in an already-included file until the project file is regenerated.
- Do not assume `project.yml` alone is enough at build time.

## CI Expectations

- `xcodebuild` commands in shell pipelines must use `set -eo pipefail` so failures are not masked.
- Build for device with:
  - `-sdk iphoneos`
  - `-destination 'generic/platform=iOS'`
  - `CODE_SIGNING_ALLOWED=NO`
- Packaging is for Sideloadly testing, not App Store distribution.

## Distribution Expectations

- For local device install, assume Sideloadly is the default path.
- If the user asks where the IPA is, the expected location is:

```text
~/Downloads/phonecare-ipa/PhoneCare.ipa
```

- If Sideloadly reports missing `Info.plist`, the IPA is malformed and must be rebuilt.

## Subscription / Paywall Testing

- Debug builds may include a test-user premium bypass in Settings.
- Preserve production StoreKit behavior unless the change is explicitly debug-only.

## Review / Merge Guidance

- Before approving PRs that add new Swift files, verify they are included in the Xcode project or CI will fail.
- Before merging build-related changes, ensure the generated IPA still contains a full app bundle and is not an empty shell.