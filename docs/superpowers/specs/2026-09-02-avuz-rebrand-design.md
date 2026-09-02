# Avuz Conecta visual rebrand — design

**Date:** 2026-09-02
**Branch:** avuz-customization-stable-34.1.1
**Status:** Approved, pending implementation
**Design source:** `~/AvuzConecta2/Plataforma Avuz Conecta/Identidade visual/App Drive.pdf` (9 mockup screens)

## Problem

The app carries the prior Avuz branding. A new visual identity (the "App Drive" PDF) defines the target: three-dot mark + wordmark, black primary buttons in the pre-login flow, a folder+dots launcher icon, refreshed splash/onboarding/login. This work brings the Android app to that identity. Same app identity (`com.avuz.conecta`, "Avuz Conecta") — visuals only.

## Decisions (locked)

| # | Decision |
|---|----------|
| 1 | Black primary button on **app pre-login screens only** (onboarding + app login form). The web grant-access flow is server-themed, not ours. Post-login stays blue. |
| 2 | Launcher label stays **Avuz Conecta** (PDF's "Drive" overridden). |
| 3 | **Palette unchanged** — `primary #2bb5e3`, `primary_dark #1e9bc7`, `accent #d2e314`, `bg_splash #f2f6fb`. |
| 4 | App font = current/system. Qestrial is web-only. |
| 5 | **Hide** the app-suite icon row on the login screen (if present in-app). |
| 6 | Web login pages (PDF screens 4/6/7) are server-side (Nextcloud theming on avuz-server) — out of scope. |
| 7 | Onboarding = **single slide** (as today): folder glyph + tagline + black button. |

## In-scope screens → files

| PDF screen | App file(s) |
|---|---|
| 1 Splash | `res/layout/activity_splash.xml`, `res/drawable/branded_splash_logo.xml`, `res/drawable-xxxhdpi/avuz_splash_logo.png` |
| 2 Onboarding | `com/nextcloud/client/onboarding/FirstRunActivity.kt`, `res/layout/first_run_activity.xml` |
| 3 Server-URL entry | `res/layout/account_setup.xml`, `com/owncloud/android/authentication/AuthenticatorActivity.java` |
| 5 Login form | login layout (identify: `account_setup.xml` vs alternate credentials layout), `res/drawable/branded_login_logo.xml` |
| 8 Files list | already blue-themed; brand-only verification |
| 9 Launcher icon | `res/drawable/ic_launcher_foreground.xml`, `ic_launcher_background.xml`, `ic_launcher_monochrome.xml`, `res/mipmap-*/ic_launcher.png`, `res/mipmap-anydpi/ic_launcher.xml` |

## Design details

### Launcher icon (screen 9)
Adaptive icon: folder + three-dot mark. Foreground = folder shape enclosing the three dots (blue/olive/grey); background = light. Rebuild `ic_launcher_foreground.xml` (currently dots only, no folder) as a vector, keep `ic_launcher_background.xml` light, provide `ic_launcher_monochrome.xml` (folder silhouette) for themed icons, regenerate legacy `mipmap-*/ic_launcher.png` at all densities.

### Black primary button — pre-login only (screens 2 & 5)
The auth-flow "Entrar" buttons render black; every button after login stays blue. **Technical risk (highest):** Nextcloud themes buttons from the primary color via `viewThemeUtils`/theme attributes, so a blunt color change would blacken post-login buttons too. Implementation must scope black to the auth screens — via an auth-only style or by setting the button treatment in `FirstRunActivity` / the login activity directly — and verify a post-login screen still shows blue. The exact mechanism is resolved in implementation, not assumed here.

### Splash (screen 1)
Three-dot + "Avuz Conecta" lockup on `#f2f6fb`. Update the splash logo asset to the dots+wordmark lockup (source: `assets/logo2.png`); keep background `bg_splash`.

### Onboarding (screen 2)
Single slide in `FirstRunActivity`: black open-folder glyph (vector), tagline "Armazene, organize e compartilhe arquivos no Drive", black "Entrar" button. Confirm the current single-slide structure and swap glyph + button treatment + copy.

### Login form (screen 5)
Dots+wordmark logo, grey rounded inputs, black button. **Hide the app-suite icon row** (folder/mail/video/chat/calendar). Note: this row was not found in `account_setup.xml`; it may be mockup-only. Implementation must locate it — if absent from the app, "hide" is a no-op and is recorded as such (do not invent the row).

### Server-URL entry (screen 3) & Files list (screen 8)
Brand-only. Verify the three-dot logo shows on the server-URL screen and that folders/FAB are already blue on the files list. No structural change expected.

## Assets

Build as vector drawables from the existing marks (crisper, theme-aware): launcher folder+dots, onboarding black-folder glyph. Splash/login lockup reuses `assets/logo2.png` (three dots + `avuzconecta` wordmark). `assets/logo.png` (interlocking chevron) is unused by these screens. If official SVGs are provided later, swap them in with no spec change.

## Verification

Definition of done (emulator, visual):
1. `./gradlew assembleGplayDebug` builds clean.
2. Launcher icon shows folder+dots; label "Avuz Conecta".
3. Splash shows dots+wordmark on `#f2f6fb`.
4. Onboarding: black folder + tagline + **black** button.
5. Login/server-URL screen: dots+wordmark; button black; app-suite icon row absent.
6. **Regression check:** a post-login screen (files list / a dialog button / FAB) still renders **blue**, proving black stayed scoped to auth.
7. No color regressions in light or dark theme.

## Out of scope

- Web login pages (server-side theming on avuz-server).
- Palette or font changes.
- The app-suite launcher row as a *feature* (links to other Avuz apps) — only its removal/hiding is in scope.
- Post-login UI restyle beyond verifying existing blue theme.

## Risks

- **Black-button isolation** (highest) — must not bleed into post-login buttons; verified by the regression check.
- **Login screen identity** — PDF screen 5 (credentials form + remember-me) may be a different auth path than the current server-URL entry; implementation maps which login screens the app actually renders before styling.
- **Adaptive icon densities** — regenerate all `mipmap-*` PNGs, not just the vector, or older launchers show a stale icon.
