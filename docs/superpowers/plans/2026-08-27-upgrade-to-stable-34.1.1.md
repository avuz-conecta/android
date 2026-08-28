# Upgrade to stable-34.1.1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the Avuz Conecta fork from upstream base `stable-3.35.0` to `stable-34.1.1`, carrying all Avuz branding, with the gplay release building, signing, and passing core file-sync flows on an emulator.

**Architecture:** Fresh branch off the upstream `stable-34.1.1` tag. Avuz's customization is branding only (zero custom code), currently uncommitted. Commit it as one commit, then `git cherry-pick` it onto the new branch — clean files apply automatically, the four upstream-churned files conflict and are hand-resolved. Then fix AGP-9/Kotlin-2.4 build fallout and verify.

**Tech Stack:** Gradle (Kotlin DSL), AGP 9.2.1, Kotlin 2.4.0, Gradle wrapper 9.6.1, android-library 2.25.0 (upstream default), adb.

## Global Constraints

- Base tag: `stable-34.1.1`. New branch: `avuz-customization-stable-34.1.1`.
- Version identity: **keep upstream 34/1/1** (`versionMajor=34, versionMinor=1, versionPatch=1`). Do NOT revert to Avuz's old 3/35/0. versionCode must stay ≥ current prod (30350095 → 34.x computes ~340,010,1xx, satisfied).
- App identity (must survive every merge): `applicationId = "com.avuz.conecta"` (qa → `com.avuz.conecta.qa`, versionDev → `com.avuz.conecta.beta`). `namespace` stays `com.owncloud.android`.
- Signing: upstream has **no** signing block. Avuz's `keystore.properties` loader + `signingConfigs { release }` + release-buildType `signingConfig` must be re-applied by hand. Secrets `keystore.properties` + `keystore/avuz-conecta.jks` are git-ignored, already present in the working tree, and persist across the branch switch.
- android-library: leave at upstream default `2.25.0`. No hand-pin.
- Scope: **gplay flavor only**. Do not build/claim generic/huawei/versionDev/qa.
- Verify against a **33.0.8** server (`conectahml.avuz.app`). E2E is off (N/A).
- No credentials typed by the agent — the user logs into the server on the emulator.

---

### Task 0: Preserve current branding as one commit (safety net + cherry-pick source)

**Files:**
- Modify (commit): all tracked-modified branding + untracked branding assets on `avuz-customization-stable-3.35.0`.

**Interfaces:**
- Produces: a single commit `<BRANDING_SHA>` on the old branch containing every Avuz branding change, cherry-pickable in Task 2.

- [ ] **Step 1: Confirm on the old branch with the download fix present**

Run: `git -C /Users/patrickrezende/work/avuz/android branch --show-current && git log --oneline -1`
Expected: `avuz-customization-stable-3.35.0`, tip is the hardened-spec commit.

- [ ] **Step 2: Stage all branding (tracked + untracked), excluding git-ignored secrets**

```bash
cd /Users/patrickrezende/work/avuz/android
git add -A
git status --short | head -40   # review: no keystore.properties / *.jks (they're ignored)
```
Expected: staged list includes `app/build.gradle.kts`, `res/values/setup.xml`, icons, layouts, `customizations.json`, `CLAUDE.md`, `assets/`, `app/proguard-rules.pro`; NO `keystore.properties` or `*.jks`.

- [ ] **Step 3: Commit the branding**

```bash
git commit -m "chore: Avuz Conecta branding customization (baseline for 34.1.1 rebase)"
git rev-parse HEAD   # record this as <BRANDING_SHA>
```
Expected: one commit created; working tree clean (`git status` shows only ignored files).

- [ ] **Step 4: Push the old branch (preserve off-machine)**

```bash
git push origin avuz-customization-stable-3.35.0
```
Expected: branch updated on origin. This is the rollback point.

---

### Task 1: Create the new branch off stable-34.1.1

**Files:** none (branch operation).

**Interfaces:**
- Consumes: tag `stable-34.1.1`.
- Produces: branch `avuz-customization-stable-34.1.1` at pristine upstream 34.1.1.

- [ ] **Step 1: Verify the tag exists locally**

Run: `git -C /Users/patrickrezende/work/avuz/android show -s --format="%ci %h" stable-34.1.1^{commit}`
Expected: dated 2026-08-27, resolves to a commit. (If missing: `git fetch upstream --tags`.)

- [ ] **Step 2: Create and switch to the new branch**

```bash
cd /Users/patrickrezende/work/avuz/android
git switch -c avuz-customization-stable-34.1.1 stable-34.1.1
```
Expected: `Switched to a new branch 'avuz-customization-stable-34.1.1'`.

- [ ] **Step 3: Confirm pristine upstream state + secrets still present**

```bash
grep -n 'applicationId' app/build.gradle.kts | head -1   # expect com.nextcloud.client
test -f keystore.properties && test -f keystore/avuz-conecta.jks && echo "secrets present"
```
Expected: applicationId is `com.nextcloud.client`; `secrets present` (working-tree files persisted).

---

### Task 2: Cherry-pick branding and resolve the churned files

**Files:**
- Modify (resolve conflicts): `app/build.gradle.kts`, `app/src/main/res/values/setup.xml`, `app/src/main/res/values/dims.xml`, `app/src/main/res/values/styles.xml` (and any of `notification_icon.xml`, `deep_link_login.xml`, `activity_preview_media.xml`, `ic_launcher_background.xml`, `mipmap-anydpi/ic_launcher.xml`, `.gitignore` that report conflicts).
- Apply cleanly (no action): all 0-churn files and new branding assets.

**Interfaces:**
- Consumes: `<BRANDING_SHA>` from Task 0.
- Produces: new branch carrying Avuz branding on the 34.1.1 base, `com.avuz.conecta` app-id, Avuz signing block, upstream 34/1/1 version.

- [ ] **Step 1: Start the cherry-pick**

```bash
cd /Users/patrickrezende/work/avuz/android
git cherry-pick <BRANDING_SHA>
```
Expected: conflicts reported in `build.gradle.kts` and likely `setup.xml`, `dims.xml`, `styles.xml`. Clean files (icons, layouts, PNGs, FirstRunActivity.kt, customizations.json, CLAUDE.md, proguard, assets) apply automatically.

- [ ] **Step 2: List conflicts**

Run: `git diff --name-only --diff-filter=U`
Expected: the churned files only.

- [ ] **Step 3: Resolve `app/build.gradle.kts` — the critical one**

Keep **upstream's** structure and version, graft **Avuz's** identity + signing. Concretely, the resolved file must have:

```kotlin
// version: KEEP UPSTREAM
val versionMajor = 34
val versionMinor = 1
val versionPatch = 1

// keystore loader (Avuz — re-add above android { }):
val keystoreProps = Properties().apply {
    val file = rootProject.file("keystore.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    // signing (Avuz — re-add):
    signingConfigs {
        create("release") {
            val keystoreFile = rootProject.file(keystoreProps["storeFile"] as? String ?: "")
            if (keystoreFile.exists()) {
                storeFile = keystoreFile
                storePassword = keystoreProps["storePassword"] as? String
                keyAlias = keystoreProps["keyAlias"] as? String
                keyPassword = keystoreProps["keyPassword"] as? String
            }
        }
    }
    defaultConfig {
        applicationId = "com.avuz.conecta"   // was com.nextcloud.client
    }
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
    productFlavors {
        // each flavor's applicationId → Avuz, matching upstream's per-flavor overrides:
        // generic/gplay/huawei → "com.avuz.conecta"
        // versionDev           → "com.avuz.conecta.beta"   (was com.nextcloud.android.beta)
        // qa                   → "com.avuz.conecta.qa"
    }
}
```

Cross-check every `applicationId = "com.nextcloud.*"` occurrence in the resolved file and confirm none remain (next step verifies).

- [ ] **Step 4: Verify no upstream app-id leaked**

Run: `grep -nE 'applicationId' app/build.gradle.kts`
Expected: only `com.avuz.conecta`, `com.avuz.conecta.beta`, `com.avuz.conecta.qa`. Zero `com.nextcloud.*`.

- [ ] **Step 5: Resolve `setup.xml` / `dims.xml` / `styles.xml`**

Take Avuz's values (app_name "Avuz Conecta", account_type "avuzconecta", authority "com.avuz.conecta", `help_enabled/sourcecode_enabled/participate_enabled=false`, `privacy_url`, brand colors, drawer dims). Where upstream added new keys, keep the new upstream key AND Avuz's overridden value. Delete all conflict markers.

- [ ] **Step 6: Confirm no conflict markers remain anywhere**

Run: `git diff --check && ! grep -rn '<<<<<<<\|>>>>>>>\|=======' app/build.gradle.kts app/src/main/res/values/ && echo CLEAN`
Expected: `CLEAN`.

- [ ] **Step 7: Finish the cherry-pick**

```bash
git add -A
git cherry-pick --continue
```
Expected: commit completes on `avuz-customization-stable-34.1.1`.

---

### Task 3: Build gplay release, fix AGP-9/Kotlin-2.4 fallout, verify signing

**Files:** whatever the build errors point to (expect `app/build.gradle.kts`, occasionally a Kotlin source touched by a 2.4 change).

**Interfaces:**
- Consumes: the branded branch from Task 2.
- Produces: a signed `gplay-release-*.apk` (CN=Avuz Conecta).

- [ ] **Step 1: Clean release build, no flags (this is the failing "test")**

```bash
cd /Users/patrickrezende/work/avuz/android
( ./gradlew clean assembleGplayRelease > /tmp/agp.log 2>&1; echo "EXIT=$?" >> /tmp/agp.log ); grep -E "BUILD SUCCESSFUL|BUILD FAILED|EXIT=" /tmp/agp.log
```
Expected initially: may `BUILD FAILED` on AGP-9 DSL/deprecation or Kotlin-2.4 changes.

- [ ] **Step 2: Read the first real error**

Run: `grep -nE "e: |FAILURE|What went wrong|> " /tmp/agp.log | head -20`
Expected: a concrete error (removed/renamed AGP DSL, a deprecated Kotlin API). Cross-reference upstream 34.1.1's own `build.gradle.kts` (`git show stable-34.1.1:app/build.gradle.kts`) for the AGP-9-correct shape.

- [ ] **Step 3: Fix one error, rebuild, repeat**

Apply the minimal fix, then re-run Step 1's command. Iterate until `BUILD SUCCESSFUL`. Do not silence errors with `--no-configuration-cache` unless config-cache specifically regresses (spec says it built clean on 3.35.0; only address if it reappears, and note it).

- [ ] **Step 4: Locate + signature-verify the APK**

```bash
APK=$(ls app/build/outputs/apk/gplay/release/gplay-release-*.apk | head -1); echo "$APK"
SDK=${ANDROID_HOME:-$HOME/Library/Android/sdk}; APKSIGNER=$(ls "$SDK"/build-tools/*/apksigner | sort -V | tail -1)
"$APKSIGNER" verify --print-certs "$APK" | grep -iE "certificate DN|Signer #1"
```
Expected: `CN=Avuz Conecta` present. (If unsigned → the Task 2 Step 3 signing block was dropped; fix and rebuild.)

- [ ] **Step 5: Commit the build fixes**

```bash
git add -A
git commit -m "build: fix AGP 9 / Kotlin 2.4 fallout for gplay release on 34.1.1 base"
```
Expected: commit created.

---

### Task 4: Consolidate the customizations registry

**Files:**
- Modify: `customizations.json`

**Interfaces:**
- Consumes: the spec's per-file merge checklist + the existing `customizations.json`.
- Produces: one registry listing every carried customization, current for the 34.1.1 base.

- [ ] **Step 1: Read the current registry**

Run: `cat customizations.json`
Expected: existing structured entries (may predate this upgrade).

- [ ] **Step 2: Merge — do not replace**

Fold the spec's file list into `customizations.json` so every carried customization has an entry, each with: file path, category (identity vs visual), merge-risk (verbatim / hand-merge), and any code side-effect note (e.g. the `build.gradle.kts` signing block is `critical`). Keep all existing metadata; add what's missing. Update any version references to the 34.1.1 base: `android-library = 2.25.0`; remove any `264573e3` / `827db94` / `3.35.0` base references.

- [ ] **Step 3: Validate JSON**

Run: `python3 -c "import json; json.load(open('customizations.json')); print('valid')"`
Expected: `valid`.

- [ ] **Step 4: Commit**

```bash
git add customizations.json
git commit -m "docs: consolidate customizations registry for 34.1.1 base"
```
Expected: commit created.

---

### Task 5: Full core-flow verification on emulator (done bar)

**Files:** none (verification).

**Interfaces:**
- Consumes: the signed APK from Task 3.

- [ ] **Step 1: Confirm an emulator is booted**

Run: `adb devices -l`
Expected: one `emulator-*` line as `device`. (If none: user boots it in Android Studio.)

- [ ] **Step 2: Reinstall the APK fresh (signature changed vs old install)**

```bash
adb uninstall com.avuz.conecta 2>/dev/null; adb install -r "$APK"
```
Expected: `Success`.

- [ ] **Step 3: Start log capture**

```bash
adb logcat -c; adb logcat -v time > /tmp/verify.txt 2>&1 &
```
Expected: capture running (background).

- [ ] **Step 4: Hand to user for the guided flows**

Ask the user to, on the emulator: log into `conectahml.avuz.app` (33.0.8), then browse a folder, **download** a file, **upload** a file, trigger **auto-upload** (add a photo), and force a **sync-conflict** (edit same file both sides). The agent never types credentials.

- [ ] **Step 5: Assert each flow succeeded in logs**

```bash
grep -aE "🗄️|FileDownloadWorker|DownloadFileRemoteOperation|UploadFileOperation|FileUploadWorker|AutoUpload|SyncConflict|Not used anymore|status code 200" /tmp/verify.txt | grep -avE "Capabilities" | tail -40
```
Expected: `status code 200 (success)` for download/upload, auto-upload worker success, sync-conflict handled; **zero** `UnsupportedOperationException: Not used anymore`.

- [ ] **Step 6: Branding visual check**

Confirm on the emulator: launcher icon, app name "Avuz Conecta", splash logo, drawer header logo render.

- [ ] **Step 7: Push the upgraded branch**

```bash
pkill -f "adb.*logcat"; git push -u origin avuz-customization-stable-34.1.1
```
Expected: branch pushed. Upgrade done.

---

## Rollback

`avuz-customization-stable-3.35.0` (branding committed in Task 0, pushed) is untouched and buildable. `git switch avuz-customization-stable-3.35.0` reverts fully; delete the new branch to abandon.
