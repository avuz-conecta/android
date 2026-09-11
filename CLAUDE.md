@AGENTS.md

# Avuz Conecta - Android Client

## What is this?

**Avuz Conecta** is a branded Android client based on the [Nextcloud](https://nextcloud.com) open-source project. It provides file sync and share functionality, allowing users to access, sync, and manage files stored on Nextcloud servers.

## Branding

This is a white-labeled version of the Nextcloud Android app with **Avuz Conecta** branding.

### Brand Colors
- **Primary**: `#2bb5e3` (Azul/Blue)
- **Primary Dark**: `#1e9bc7`
- **Accent**: `#d2e314` (Verde oliva/Olive green)
- **Background Light**: `#f2f6fb` (Cinza claro/Light gray)

### Key Branding Files

All branding is centralized in `setup.xml` where possible to minimize merge conflicts:

| File | Purpose |
|------|---------|
| `app/src/main/res/values/setup.xml` | **Main branding config** - colors, flags, URLs, dimensions |
| `app/src/main/res/drawable/branded_splash_logo.xml` | Alias pointing to splash logo |
| `app/src/main/res/drawable/branded_drawer_logo.xml` | Alias pointing to drawer logo |
| `app/src/main/res/drawable-xxxhdpi/avuz_splash_logo.png` | Splash screen logo image |
| `app/src/main/res/drawable-xxxhdpi/avuz_drawer_logo.png` | Drawer header logo image |
| `app/src/main/res/drawable/ic_launcher_foreground.xml` | App icon (three dots) |
| `app/src/main/res/drawable/ic_launcher_background.xml` | App icon background |
| `app/src/main/res/drawable/ic_launcher_monochrome.xml` | Monochrome icon for Android 13+ |
| `app/src/main/res/mipmap-*/ic_launcher.png` | Legacy launcher icons |
| `app/build.gradle.kts` | Application ID (`com.avuz.conecta`) |

### Branding Settings in setup.xml

#### App Identity
```xml
<string name="app_name">Avuz Conecta</string>
<string name="account_type">avuzconecta</string>
<string name="authority">com.avuz.conecta</string>
```

#### Colors
```xml
<color name="primary">#2bb5e3</color>
<color name="primary_dark">#1e9bc7</color>
<color name="color_accent">#d2e314</color>
<color name="bg_splash">#f2f6fb</color>
<color name="bg_drawer_header">@color/bg_splash</color>
<color name="drawer_header_icon_tint">@color/primary</color>
<color name="drawer_header_text_color">@color/primary_dark</color>
```

#### Drawer Header Dimensions
```xml
<dimen name="drawer_header_height">120dp</dimen>
<dimen name="drawer_header_logo_max_width">180dp</dimen>
```

#### Feature Flags (Disabled)
```xml
<bool name="help_enabled">false</bool>
<bool name="sourcecode_enabled">false</bool>
<bool name="participate_enabled">false</bool>  <!-- Hides Community menu -->
```

#### URLs
```xml
<string name="privacy_url">https://avuz.cloud/politica-de-privacidade/</string>
```

### How to Update Branding

1. **Change colors**: Edit color values in `setup.xml`
2. **Change logos**: Replace PNG files in `assets/` folder, then copy to drawable folders
3. **Change app icon**: Edit `ic_launcher_foreground.xml` and regenerate PNGs
4. **Hide/show features**: Toggle boolean flags in `setup.xml`

### Merge Strategy for Upstream Updates

When merging from Nextcloud upstream:

```bash
git fetch origin
git merge origin/master
```

**Low conflict risk** (changes in setup.xml):
- Colors, URLs, feature flags, dimensions

**Medium conflict risk** (layout changes):
- `drawer_header.xml` - uses references to setup.xml values
- `activity_splash.xml` - uses references to setup.xml values

**Files to watch**:
- If Nextcloud adds new drawable references, update the `branded_*.xml` aliases
- If Nextcloud adds new menu items, they may need hiding via flags

## Tech Stack

- **Language**: Kotlin (primary) + Java (legacy)
- **Min SDK**: 28 (Android 9)
- **Target SDK**: 36 (Android 16)
- **Build System**: Gradle with Kotlin DSL
- **UI**: Jetpack Compose + Android Views (XML with Data Binding/View Binding)
- **DI**: Dagger 2
- **Database**: Room
- **Image Loading**: Glide + Coil
- **Networking**: Nextcloud Android Library (custom)
- **Background Work**: WorkManager

## Project Structure

```
android/
├── app/                          # Main application module
│   ├── src/
│   │   ├── main/java/
│   │   │   ├── com/nextcloud/    # Main codebase
│   │   │   │   ├── client/       # Core app logic (DI, database, preferences, workers)
│   │   │   │   ├── ui/           # UI components (Compose, behaviors)
│   │   │   │   ├── utils/        # Utility classes
│   │   │   │   ├── model/        # Data models
│   │   │   │   └── repository/   # Data repositories
│   │   │   ├── com/owncloud/     # Legacy ownCloud code
│   │   │   └── third_parties/    # Vendored libraries
│   │   ├── androidTest/          # Instrumented tests
│   │   ├── test/                 # Unit tests
│   │   ├── gplay/                # Google Play flavor code
│   │   ├── generic/              # F-Droid flavor code
│   │   ├── huawei/               # Huawei AppGallery flavor code
│   │   └── versionDev/           # Development/beta flavor code
│   └── build.gradle.kts
├── appscan/                      # Document scanner module (OpenCV-based)
├── gradle/                       # Gradle wrapper and version catalog
├── scripts/                      # Build and CI scripts
└── doc/                          # Documentation assets
```

## Build Flavors

| Flavor     | App ID                  | Description                              |
|------------|-------------------------|------------------------------------------|
| generic    | com.avuz.conecta        | F-Droid release (no Google services)     |
| gplay      | com.avuz.conecta        | Google Play release (with push notifs)   |
| huawei     | com.avuz.conecta        | Huawei AppGallery release                |
| versionDev | com.avuz.conecta.beta   | Beta/development builds                  |
| qa         | com.avuz.conecta.qa     | QA testing builds                        |

## Key Dependencies

- `com.github.nextcloud:android-library` - Nextcloud API client
- `androidx.room` - Database
- `com.google.dagger` - Dependency injection
- `androidx.work` - Background task scheduling
- `io.coil-kt:coil` - Image loading (Compose)
- `com.github.bumptech.glide:glide` - Image loading (Views)
- `androidx.media3` - Media playback
- `org.osmdroid:osmdroid-android` - Maps

## Build Commands

```bash
# Build debug APK
./gradlew assembleGplayDebug

# Run unit tests
./gradlew testGplayDebugUnitTest

# Run lint
./gradlew lintGplayDebug

# Run all checks (lint, checkstyle, spotbugs, pmd, detekt)
./gradlew check

# Clean build
./gradlew clean assembleGplayDebug
```

## Code Style

- Kotlin: ktlint (via Spotless plugin)
- Java: Checkstyle
- Static analysis: SpotBugs, PMD, Detekt

## Testing

- **Unit tests**: JUnit 5, Mockito, MockK
- **UI tests**: Espresso
- **Screenshot tests**: Shot (Karumi)

## Current Version

- Version: 34.1.2
- Version Code: 340010290

## License

- GPL v2 (original code)
- AGPL v3+ (contributions after June 16, 2016)

## Key Files

- `app/build.gradle.kts` - App module configuration
- `gradle/libs.versions.toml` - Dependency version catalog
- `app/src/main/AndroidManifest.xml` - Android manifest
- `app/src/main/java/com/nextcloud/client/di/` - Dagger modules
- `app/src/main/res/values/setup.xml` - Branding configuration

## Branch Info

This is a fork/customization branch: `avuz-customization-stable-34.1.1`
Main upstream branch: `master`
