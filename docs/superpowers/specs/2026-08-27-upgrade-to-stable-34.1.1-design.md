# Upgrade Avuz Conecta base: stable-3.35.0 → stable-34.1.1 — design

**Date:** 2026-08-27
**Branch (current):** avuz-customization-stable-3.35.0
**Branch (new):** avuz-customization-stable-34.1.1
**Status:** Approved, pending implementation

## Problem

The fork's upstream baseline is `stable-3.35.0` (Nextcloud android, 2026-01-19). Upstream has since shipped a newer stable line topping out at `stable-34.1.1` (2026-08-27) — a separate, newer release line (34.x does not contain the 3.x line). Starting new feature work on a ~7-month-old base means building on stale platform/toolchain and re-hitting already-fixed upstream issues.

The recent download outage was itself upstream drift: a hand-bump of `android-library` past the app's API baseline dropped the `OwnCloudClient` download path the 3.35.0 app still called (`UnsupportedOperationException: Not used anymore`). Moving to a coherent newer stable removes that class of mismatch — at `stable-34.1.1`, the app code and `android-library 2.25.0` ship matched.

## Goal

`avuz-customization-stable-34.1.1` builds cleanly on `stable-34.1.1` with Avuz branding intact, all core file-sync flows verified on an emulator. New feature work (including the planned rebrand) starts from this modern base.

## Key facts (established during scoping)

- **True Avuz customization vs `stable-3.35.0` = branding only, zero custom code.** The large file-diff seen against `merge-base(branch, upstream/master)` was upstream's own 33→3.35 release-line drift, not Avuz changes.
- Avuz branding currently lives as **uncommitted working-tree changes** (fragile — one `git checkout .` wipes it).
- `android-library` at `stable-34.1.1` = **`2.25.0`** (a git tag → durable on jitpack; no snapshot-GC risk). No hand-pin needed.
- Toolchain jump: **AGP 8.13.1 → 9.2.1** (major), Kotlin 2.2.21 → 2.4.0, Gradle wrapper 9.2.1 → 9.6.1.

## Decisions

| Decision | Choice |
|----------|--------|
| Carry strategy | Fresh branch off tag `stable-34.1.1`, re-apply branding (no 2733-commit merge) |
| Version identity | Adopt upstream **34.1.x** versionName/Code (versionCode 30M → 340M — monotonic, valid update, one-way door) |
| Branding scope | **Apply all** branding (visual + structural) now; the later rebrand swaps only what changes |
| Registry | **Consolidate**: merge this spec's per-file merge checklist *and* `customizations.json` metadata into one registry — neither dropped. Keeping it current is a hard acceptance criterion |
| Flavor scope | **gplay only** for this upgrade. `generic`/`huawei`/`versionDev`/`qa` explicitly out of scope (untested, not claimed) |
| Rebrand | Separate future feature — visuals-only, same app identity (`com.avuz.conecta`, "Avuz Conecta") |
| Verification bar | Full core-flow test on emulator, against a **33.0.8** server (prod-equivalent) |

## Server compatibility (grilled, cleared)

- Prod + homologation servers both run **Nextcloud 33.0.8**; the emulator test hits `conectahml.avuz.app` (= prod version), so results are representative.
- Client 34.1.1 vs server 33.0.8 = **client newer than server**, the safe direction: the client feature-detects via OCS capabilities and degrades, not crashes. One major apart, server not EOL → no "unsupported server" wall.
- **E2E encryption is OFF** (`occ app:list` shows `end_to_end_encryption` not enabled; no client build flag either side). E2E is the one feature that could hard-break on a client/server crypto-version gap — N/A here.

## Branding re-apply checklist (27 files)

Split by upstream churn `stable-3.35.0..stable-34.1.1` (higher churn = hand-merge, not verbatim):

**Hand-merge (upstream changed the file):**
- `app/build.gradle.kts` — 39 commits. The real work: app-id `com.avuz.conecta`, flavors (generic/gplay/huawei/versionDev/qa), versionName/Code → 34.1.x. Re-apply Avuz identity **onto** 34.1.1's file; do not port 34.1.1 changes into the old file.
  - **CRITICAL — signing block.** Upstream 34.1.1 has **no signing config**. The entire mechanism is Avuz-only: `keystore.properties` loading + `signingConfigs { release }` + `signingConfig = signingConfigs.getByName("release")` on the release buildType. Miss it → every release build is unsigned/uninstallable. `keystore.properties` and `keystore/avuz-conecta.jks` are git-ignored (local-only) and persist in the working tree across the branch switch — the *secrets* survive; the *build-file block* must be re-applied by hand. Verified at Phase 5 step 2 (apksigner → CN=Avuz Conecta).
- `app/src/main/res/values/dims.xml` — 14 commits (drawer header dims).
- `app/src/main/res/values/styles.xml` — 7 commits.
- `app/src/main/res/values/setup.xml` — 2 commits (central branding config).

**Churn-check at implementation, then verbatim or quick-merge:**
- `notification_icon.xml`, `deep_link_login.xml`, `activity_preview_media.xml`, `ic_launcher_background.xml`, `mipmap-anydpi/ic_launcher.xml`, `.gitignore`.

**Verbatim (0 upstream churn / new files not in upstream):**
- `FirstRunActivity.kt`, `drawer_header.xml`, `activity_splash.xml`, `account_setup.xml`, `ic_launcher_foreground.xml`
- `branded_splash_logo.xml`, `branded_drawer_logo.xml`, `branded_login_logo.xml`, `ic_launcher_monochrome.xml`
- `avuz_splash_logo.png`, `avuz_drawer_logo.png`, `avuz_logo.png`, all `mipmap-*/ic_launcher.png`
- `proguard-rules.pro`, `customizations.json`, `CLAUDE.md`

Consistency rule: any layout that references a `branded_*`/`avuz_*` drawable must be carried together with that drawable (avoid dangling references). Since we apply everything, this holds by default.

## Phases

**Phase 0 — Preserve (safety).** Commit the current uncommitted branding on `avuz-customization-stable-3.35.0` (includes new rebrand source images under `assets/`). Nothing is lost; the old branch becomes a clean reference of the 3.35.0 branding.

**Phase 1 — Branch.** Create `avuz-customization-stable-34.1.1` from tag `stable-34.1.1`.

**Phase 2 — Apply branding.** Re-apply the 27 files per the checklist. Verbatim files: copy from the committed 3.35.0 branding. Hand-merge files: apply Avuz deltas onto 34.1.1's versions.

**Phase 3 — Deps & version.** Confirm `android-library = 2.25.0` (upstream default — leave as-is). Set versionName/Code to the chosen 34.1.x value.

**Phase 4 — Build.** `./gradlew clean assembleGplayRelease` (no flags). Fix toolchain fallout — expect AGP 9 DSL/deprecation breakage concentrated in `build.gradle.kts`, plus Kotlin 2.4 changes. Iterate until BUILD SUCCESSFUL.

**Phase 5 — Verify (done bar).** Install on emulator, log into a **33.0.8** Avuz server (`conectahml.avuz.app`, prod-equivalent), run the adb-logcat loop over: login, folder browse, **download**, **upload**, **auto-upload**, **sync-conflict**, and confirm branding renders. Green build + all flows pass = done. gplay flavor only.

## Verification

Definition of done:

1. `./gradlew clean assembleGplayRelease` — no flags — BUILD SUCCESSFUL. (gplay only; other flavors out of scope.)
2. APK installs on emulator; `apksigner verify` → CN=Avuz Conecta, v2 scheme true. (Proves the Avuz signing block survived the `build.gradle.kts` re-apply.)
3. adb-logcat confirms, against the 33.0.8 server, with no `UnsupportedOperationException`/error results: login, browse, download (HTTP 200 + file on disk), upload, auto-upload, sync-conflict dialog.
4. Branding visible: app name, launcher icon, splash, drawer header.
5. Consolidated registry (`customizations.json` + merged checklist) lists every carried customization and reflects the 34.1.1 base (`android-library 2.25.0`, no `264573e3`/`827db94` references).

## Risks & mitigations

- **AGP 8→9 breakage in `build.gradle.kts`** (highest). Mitigation: re-apply Avuz identity onto 34.1.1's build file rather than porting upstream into the old one; consult upstream's 34.1.1 `build.gradle.kts` as the correct AGP-9 shape.
- **Signing config drift.** The Avuz keystore/signing block must survive the build-file re-apply, or release APKs won't sign. Verify in Phase 5 step 2.
- **Branding drift in `dims.xml`/`styles.xml`.** Upstream churn may have renamed/removed keys Avuz overrides. Reconcile during hand-merge.
- **minSdk/targetSdk shift** (SDK levels moved out of the version catalog upstream — not chased during scoping). Low risk; confirm at implementation whether the min bumped and whether it drops any device tier Avuz cares about.

## Rollback

The old branch `avuz-customization-stable-3.35.0` (with branding committed in Phase 0) is untouched and buildable. Abandoning the new branch reverts fully.

## Out of scope

- New features and the visual rebrand (separate follow-up on this new base).
- **Flavors other than gplay** (`generic`/`huawei`/`versionDev`/`qa`) — not built or verified in this upgrade; do not claim they work.
- Further `android-library` bumps beyond upstream's `2.25.0`.
- CI / multi-machine reproducibility.
- Config-cache: `stable-3.35.0` release built clean without flags; re-confirm on 34.1.1, address only if it regresses.
