# Avuz Conecta Visual Rebrand Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the Android app's visuals to the "App Drive" identity — folder+dots launcher icon, dots+wordmark splash, light-themed auth screens with a black primary button — without changing the palette or app identity.

**Architecture:** Pure resource work. Rewrite two vector drawables (launcher), swap one splash bitmap, and re-theme the pre-login screens via the already-isolated `@style/Button.Login` style plus `setup.xml` login colors. Verification is a visual pass on an emulator, including a regression check that post-login stays blue.

**Tech Stack:** Android resource XML (vector/adaptive-icon/styles), Gradle, adb. minSdk 28 (adaptive icons always used → legacy mipmap PNGs are not rendered on any supported device).

## Global Constraints

- Palette unchanged: `primary #2bb5e3`, `primary_dark #1e9bc7`, `accent #d2e314`, `bg_splash #f2f6fb`, dots grey `#d9d9d9`.
- App identity unchanged: `com.avuz.conecta`, app_name "Avuz Conecta".
- Black scoped to **pre-login only**. A post-login screen MUST still render blue (regression check).
- `@style/Button.Login` (styles.xml:187) is used ONLY in `first_run_activity.xml` and `account_setup.xml` — both pre-login. This is the isolation mechanism; do not add new usages elsewhere.
- No new strings/colors as magic values — add named resources.
- Match the PDF (`~/AvuzConecta2/Plataforma Avuz Conecta/Identidade visual/App Drive.pdf`) screens: 1 splash, 2 onboarding, 3 server-URL, 9 launcher icon.
- Build/verify the **gplay** variant only.

---

### Task 1: Launcher icon — folder + three dots

**Files:**
- Modify: `app/src/main/res/drawable/ic_launcher_foreground.xml` (currently three dots, no folder)
- Modify: `app/src/main/res/drawable/ic_launcher_monochrome.xml`
- Reference (no change): `app/src/main/res/mipmap-anydpi/ic_launcher.xml` (adaptive-icon wiring)

**Interfaces:**
- Produces: an adaptive foreground showing a folder enclosing the three-dot mark, matching PDF screen 9 (white folder, blue/olive/grey dots).

- [ ] **Step 1: Rewrite the foreground vector**

Replace the whole file `ic_launcher_foreground.xml` with a folder + three dots, keeping the SPDX header. Dots keep brand hex; folder is white with a subtle brand-blue base so it reads on the light `ic_launcher_background`. Adaptive safe zone is the centre ~66×66 of the 108 viewport.

```xml
<!--
  ~ Avuz Conecta - Android Client
  ~
  ~ SPDX-FileCopyrightText: 2026 Avuz
  ~ SPDX-License-Identifier: AGPL-3.0-or-later OR GPL-2.0-only
-->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">

    <!-- Folder back tab -->
    <path
        android:fillColor="#2bb5e3"
        android:pathData="M32,40 h16 l6,6 h22 a4,4 0 0 1 4,4 v4 h-52 v-10 a4,4 0 0 1 4,-4 z"/>
    <!-- Folder body -->
    <path
        android:fillColor="#FFFFFF"
        android:pathData="M30,50 h48 a4,4 0 0 1 4,4 v18 a4,4 0 0 1 -4,4 h-48 a4,4 0 0 1 -4,-4 v-18 a4,4 0 0 1 4,-4 z"/>
    <!-- Three dots inside the folder -->
    <path android:fillColor="#2bb5e3"
        android:pathData="M45,63 m-5,0 a5,5 0 1 1 10,0 a5,5 0 1 1 -10,0"/>
    <path android:fillColor="#d2e314"
        android:pathData="M59,63 m-5,0 a5,5 0 1 1 10,0 a5,5 0 1 1 -10,0"/>
    <path android:fillColor="#d9d9d9"
        android:pathData="M73,63 m-5,0 a5,5 0 1 1 10,0 a5,5 0 1 1 -10,0"/>
</vector>
```

- [ ] **Step 2: Update the monochrome variant to a folder silhouette**

Replace `ic_launcher_monochrome.xml`'s path(s) with a single-colour folder outline (themed-icon tint is applied by the system, so use a solid fill; the dots are omitted in monochrome). Keep the SPDX header and 108 viewport. Body path may reuse the folder body+tab paths from Step 1 merged into one `<path android:fillColor="#000000" .../>`.

- [ ] **Step 3: Build and eyeball the icon**

Run: `./gradlew :app:assembleGplayDebug`
Expected: BUILD SUCCESSFUL. (Visual confirm happens in Task 5 on the emulator; here just confirm the vectors compile — a malformed pathData fails the build.)

- [ ] **Step 4: Commit**

```bash
git add app/src/main/res/drawable/ic_launcher_foreground.xml app/src/main/res/drawable/ic_launcher_monochrome.xml
git commit -m "feat(branding): folder + three-dot launcher icon"
```

Note: minSdk 28 → the legacy `mipmap-*/ic_launcher.png` are never rendered; leave them (out of scope).

---

### Task 2: Splash — dots + wordmark lockup

**Files:**
- Replace (binary): `app/src/main/res/drawable-xxxhdpi/avuz_splash_logo.png`
- Reference (no change): `res/drawable/branded_splash_logo.xml` (bitmap → `avuz_splash_logo`), `res/layout/activity_splash.xml`

**Interfaces:**
- Produces: splash showing the three-dot + "avuzconecta" lockup centred on `bg_splash`.

- [ ] **Step 1: Replace the splash logo with the lockup**

The splash `ImageView` already points (via `branded_splash_logo` alias) at `avuz_splash_logo.png`, and the splash background is already light (`bg_drawer_header` → `bg_splash`). Swap the asset:

```bash
cp "assets/logo2.png" app/src/main/res/drawable-xxxhdpi/avuz_splash_logo.png
```

(`logo2.png` is the dots + `avuzconecta` lockup on transparent — correct for centring on the light splash. No layout change needed.)

- [ ] **Step 2: Build**

Run: `./gradlew :app:assembleGplayDebug`
Expected: BUILD SUCCESSFUL.

- [ ] **Step 3: Commit**

```bash
git add app/src/main/res/drawable-xxxhdpi/avuz_splash_logo.png
git commit -m "feat(branding): dots+wordmark splash lockup"
```

---

### Task 3: Auth screens — light theme + black button + colored logo

Currently the pre-login screens use a **white** logo/text (`login_text_color #ffffff`) on a dark ground; the PDF flips this to a light ground with a black button and the colored dots logo.

**Files:**
- Modify: `app/src/main/res/values/styles.xml:187` (`Button.Login`)
- Modify: `app/src/main/res/values/setup.xml` (`login_text_color`, add `login_background`, add `login_btn_background`)
- Modify: `app/src/main/res/drawable/branded_login_logo.xml` (remove white tint)
- Investigate + modify: the pre-login background (AuthenticatorActivity / FirstRunActivity theme)

**Interfaces:**
- Consumes: `@style/Button.Login` isolation (Global Constraints).
- Produces: onboarding + server-URL screens on a light ground, black "Entrar" button, colored dots+wordmark logo, dark text.

- [ ] **Step 1: Add named colors in `setup.xml`**

Add (near the existing `login_text_color`):

```xml
<color name="login_text_color">#1a1a1a</color>   <!-- was #ffffff -->
<color name="login_background">@color/bg_splash</color>
<color name="login_btn_background">#000000</color>
<color name="login_btn_text">#ffffff</color>
```

- [ ] **Step 2: Make `Button.Login` black**

In `styles.xml`, set the `Button.Login` style (line ~187) background/tint to `@color/login_btn_background` and text to `@color/login_btn_text`. Show the resolved style, e.g.:

```xml
<style name="Button.Login" parent="Button">
    <item name="backgroundTint">@color/login_btn_background</item>
    <item name="android:textColor">@color/login_btn_text</item>
</style>
```

(Confirm the parent `Button` doesn't force a different tint that overrides this; if it does, add `android:backgroundTint` too.)

- [ ] **Step 3: Un-tint the login logo**

`branded_login_logo.xml` currently tints `avuz_logo` white. Replace it so the colored dots+wordmark show on the light ground — point it at the lockup and drop the tint:

```xml
<?xml version="1.0" encoding="utf-8"?>
<bitmap xmlns:android="http://schemas.android.com/apk/res/android"
    android:src="@drawable/avuz_splash_logo"
    android:gravity="center" />
```

(Reuses the Task 2 lockup asset `avuz_splash_logo`. If a login-specific mark is preferred later, swap the `src`.)

- [ ] **Step 4: Flip the pre-login background to light**

Find where the pre-login background is set. Run:
`grep -rnE "login_background|windowBackground|@color/primary" app/src/main/res/values*/themes*.xml app/src/main/res/values*/styles.xml | grep -i login`
and inspect the `AuthenticatorActivity` / `FirstRunActivity` theme (`grep -rn "android:theme" app/src/main/AndroidManifest.xml | grep -iE "Authenticator|FirstRun"`). Set that theme's `android:windowBackground`/`colorbackground` to `@color/login_background`. Show the exact edit you made.

- [ ] **Step 5: Onboarding slide — black folder glyph + tagline**

Create `app/src/main/res/drawable/ic_onboarding_folder.xml` (black open-folder, matching PDF screen 2):

```xml
<!--
  ~ Avuz Conecta - Android Client
  ~
  ~ SPDX-FileCopyrightText: 2026 Avuz
  ~ SPDX-License-Identifier: AGPL-3.0-or-later OR GPL-2.0-only
-->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="96dp" android:height="96dp"
    android:viewportWidth="24" android:viewportHeight="24"
    android:tint="#1a1a1a">
    <path android:fillColor="#000000"
        android:pathData="M20,6h-8l-2,-2H4C2.9,4 2,4.9 2,6v12c0,1.1 0.9,2 2,2h16c1.1,0 2,-0.9 2,-2V8c0,-1.1 -0.9,-2 -2,-2z"/>
</vector>
```

Then wire the single onboarding slide. Read `com/nextcloud/client/onboarding/FirstRunActivity.kt`, find where it builds its `FeatureItem`/slide list (the collapsed single slide). Set that slide's image to `R.drawable.ic_onboarding_folder` and its text to the tagline. Add the string to `res/values/strings.xml` if absent:

```xml
<string name="first_run_1_text">Armazene, organize e compartilhe arquivos no Drive</string>
```

Show the exact `FirstRunActivity.kt` edit (old → new lines). Do not add slides — keep it single.

- [ ] **Step 6: Build**

Run: `./gradlew :app:assembleGplayDebug`
Expected: BUILD SUCCESSFUL.

- [ ] **Step 7: Commit**

```bash
git add app/src/main/res/values/setup.xml app/src/main/res/values/styles.xml app/src/main/res/drawable/branded_login_logo.xml app/src/main/res/drawable/ic_onboarding_folder.xml app/src/main/res/values/strings.xml app/src/main/res/values*/themes*.xml app/src/main/java/com/nextcloud/client/onboarding/FirstRunActivity.kt
git commit -m "feat(branding): light auth screens, black button, onboarding folder glyph"
```

---

### Task 4: App-suite icon row + files/server-URL verification

**Files:**
- Investigate: `res/layout/account_setup.xml` (already read — no icon row), `res/layout/deep_link_login.xml`, any `login_*` layout.

**Interfaces:**
- Produces: confirmation the PDF's app-suite icon row is mockup-only (or, if found in-app, it is hidden).

- [ ] **Step 1: Locate the app-suite icon row**

Run: `grep -rnE "ic_mail|ic_video|ic_chat|ic_calendar|talk|deck|calendar" app/src/main/res/layout/*login* app/src/main/res/layout/account_setup*.xml app/src/main/res/layout/deep_link_login.xml`
Expected: likely no match → the row is mockup-only. Record this in the report.

- [ ] **Step 2: If found, hide it**

Only if Step 1 finds a real icon-row container: set that container `android:visibility="gone"`. If nothing is found, this task is a no-op verification — state that explicitly; do NOT invent the row.

- [ ] **Step 3: Commit (only if a change was made)**

```bash
git add -A && git commit -m "feat(branding): hide app-suite icon row on login"
```

If no change: no commit; note "icon row is mockup-only, no-op" in the report.

---

### Task 5: Emulator visual verification (done bar)

**Files:** none (verification).

- [ ] **Step 1: Build + install**

```bash
./gradlew :app:assembleGplayDebug
adb install -r app/build/outputs/apk/gplay/debug/*.apk
```
Expected: `Success`.

- [ ] **Step 2: Launcher icon**

Confirm on the emulator home/app drawer: folder + three-dot icon, label "Avuz Conecta".

- [ ] **Step 3: Splash + onboarding + login (pre-login, must be LIGHT + BLACK button)**

Launch the app. Confirm: splash = dots+wordmark on light; onboarding/login = light ground, colored dots logo, dark text, **black** "Entrar" button. Screenshot via `adb exec-out screencap -p > /tmp/rebrand_login.png` and Read it.

- [ ] **Step 4: Regression — post-login stays BLUE**

Log in (user drives) and confirm a post-login control (files FAB / a primary dialog button) is still **blue**, proving black stayed scoped to auth. Screenshot and Read it.

- [ ] **Step 5: Dark theme sanity**

Toggle dark theme; confirm no unreadable white-on-white or black-on-black on the auth screens.

- [ ] **Step 6: Push**

```bash
git push origin avuz-customization-stable-34.1.1
```

---

## Rollback

Each task is its own commit on `avuz-customization-stable-34.1.1`. Revert any task's commit independently; the branch built and ran before these commits (verified in the upgrade work).
