# Durable android-library dependency — design

**Date:** 2026-07-15
**Branch:** avuz-customization-stable-3.35.0
**Status:** Approved, pending implementation

## Problem

Release builds fail to resolve `com.github.nextcloud:android-library:264573e3017279162c511ed1e7ccf83b45be957b`:

```
Could not find com.github.nextcloud:android-library:264573e3...
Searched: maven central, jitpack — all artifacts 404
```

The version is a **jitpack snapshot** (raw master commit hash, not a tag). Jitpack garbage-collects snapshot builds; the commit build was evicted (API reports `status: ok` but `modules: []`, all artifacts 404). Tag builds persist, snapshot builds do not.

Debug builds still worked only because the resolved artifacts sat in the gradle cache and their tasks were up-to-date. A fresh release resolve (`checkGplayReleaseDuplicateClasses` → `gplayReleaseRuntimeClasspath`) forced re-resolution and hit the dead jitpack artifact.

Upstream Nextcloud pins android-library by master commit hash via `scripts/updateLibraryHash.sh`, recording checksums in `gradle/verification-metadata.xml`. This fork inherits that fragility: any pinned commit can be GC'd by jitpack at any time.

## Goal

`./gradlew assembleGplayRelease` builds cleanly on the developer's machine with **no special flags**, permanently immune to jitpack evicting the snapshot build, using the **byte-exact library the current 3.35.0 APK was validated against**.

Scope: local machine only (single developer producing tester/release APKs). Not CI, not multi-machine.

## Constraints

- Must use the exact `264573e3` artifact — the shipped APKs were built and validated against it. No code drift.
- Must not require typing `--dependency-verification off` or `--no-configuration-cache`.
- Must survive a full `~/.gradle` cache wipe AND jitpack death.
- Minimal merge-conflict surface against upstream (this is a long-lived fork).

## Approaches considered

| Approach | Durable vs jitpack | Byte-exact | Self-sufficient after cache wipe | Binary in git | Verdict |
|----------|-------------------|-----------|----------------------------------|---------------|---------|
| A. Harden mavenLocal + recovery script | Yes | Yes | Only if aar committed | Yes | Folded into C |
| B. Repin to jitpack tag `rc-2.24.1-1` | Yes | **No — +97 commits drift** | Yes | No | Rejected: API/behavior risk, forces recompile+retest |
| C. In-repo maven repo (committed aar+pom) | Yes | Yes | Yes | Yes | **Chosen** |

Approach C is A with the aar committed in-repo — which makes the `~/.m2` install and recovery script redundant (gradle reads the committed artifacts directly). Chosen for being strictly simpler and more robust than A while meeting every constraint.

## Design

Serve the exact `264573e3` artifacts from a committed in-repo maven repository. This dependency never touches jitpack again; all other dependencies resolve normally.

### Change 1 — `gradle/localrepo/` (new)

Maven layout under version control:

```
gradle/localrepo/com/github/nextcloud/android-library/264573e3017279162c511ed1e7ccf83b45be957b/
  android-library-264573e3017279162c511ed1e7ccf83b45be957b.aar   (byte-exact, copied from gradle cache)
  android-library-264573e3017279162c511ed1e7ccf83b45be957b.pom
```

The aar is copied from
`~/.gradle/caches/modules-2/files-2.1/com.github.nextcloud/android-library/264573e3.../<sha1>/android-library-264573e3....aar`
(sha256 `d20a65e1dd339d3fd7db0692b67d98408fb8e07aab9e9a24cc52596d1c750d04`).

The `.pom` declares android-library's transitive runtime dependencies, recovered from the parsed Gradle Module Metadata in the gradle cache descriptor:

- `com.squareup.okhttp3:okhttp:5.3.2`
- `org.jetbrains.kotlin:kotlin-parcelize-runtime:2.3.21`
- `org.jetbrains.kotlin:kotlin-stdlib-jdk8:2.3.21`
- `org.jetbrains.kotlinx:kotlinx-serialization-json:1.11.0`
- `org.apache.jackrabbit:jackrabbit-webdav:2.13.5`
- `com.google.code.gson:gson:2.14.0`
- `androidx.annotation:annotation:1.10.0`
- `androidx.core:core-ktx:1.18.0`
- `com.google.guava:guava:33.6.0-jre`

Note: the app module already declares okhttp/gson/guava/kotlin directly, so those transitives are covered by the app graph regardless; the pom's job is to make gradle accept the module and pull the android-library-only deps (jackrabbit-webdav, kotlinx-serialization-json).

### Change 2 — `settings.gradle.kts`

Replace the temporary `mavenLocal()` line (added during triage) in the `dependencyResolutionManagement.repositories` block with a scoped local maven repo:

```kotlin
maven {
    url = uri("$rootDir/gradle/localrepo")
    content { includeModule("com.github.nextcloud", "android-library") }
}
```

`content { includeModule(...) }` restricts this repo to the single artifact, so every other dependency still resolves via google/mavenCentral/jitpack unchanged. Placed first so it wins for android-library.

### Change 3 — `gradle/verification-metadata.xml`

The aar for `264573e3` is already trusted (`.aar` + `.module` checksums present). The in-repo maven repo serves a hand-authored `.pom` that has no recorded checksum and no PGP signature, so with `verify-metadata=true` and `verify-signatures=true` it is rejected. Add one line to `<trusted-artifacts>`:

```xml
<trust group="com.github.nextcloud" name="android-library" file=".*[.]pom" regex="true"
       reason="in-repo localrepo pom for pinned snapshot; jitpack GC'd the snapshot build"/>
```

This trusts only android-library pom files. Removes the need for `--dependency-verification off`.

### Change 4 — config cache (conditional)

The original `--no-configuration-cache` need came from an AGP bug: `MergeNativeLibsTask` fails to serialize a `ResolutionBackedFileCollection` into the configuration cache. This is independent of the resolution failure.

Implementation must **test a plain `./gradlew assembleGplayRelease`** (no flags) after Changes 1–3. If it still trips the config-cache bug, scope config cache off for the release path only (keeping it on for debug), so no flag is ever required. If the plain build succeeds, no change is needed here. Decision is empirical, not assumed.

### Change 5 — cleanup

Remove the throwaway artifacts installed under `~/.m2/repository/com/github/nextcloud/android-library/264573e3.../` during triage. No longer referenced once Change 2 points at the in-repo repo.

## Verification

Definition of done:

1. `rm -rf ~/.m2/repository/com/github/nextcloud` (prove mavenLocal is not involved).
2. `./gradlew assembleGplayRelease` — no flags — **BUILD SUCCESSFUL**.
3. Output `app/build/outputs/apk/gplay/release/gplay-release-*.apk` exists, `apksigner verify` reports `CN=Avuz Conecta`, v2 scheme true.
4. Optional stronger proof: temporarily move the gradle cache entry for android-library aside, confirm the build still resolves from `gradle/localrepo/`.

## Tradeoffs and future maintenance

- **774 KB aar committed to git** — accepted; the cost of a fully self-sufficient local build.
- **Diverges from `scripts/updateLibraryHash.sh`** — that script rewrites `androidLibraryVersion` and regenerates verification metadata against jitpack. It will not update the in-repo copy.
- **Updating android-library later:** either (a) re-vendor — drop the new aar+pom into `gradle/localrepo/` and bump `androidLibraryVersion`, or (b) if the new pin is a jitpack *tag* (persistent), point back at jitpack and delete the localrepo entry. Prefer pinning tags over master commits going forward to avoid recurrence.

## Out of scope

- CI / multi-machine reproducibility (would argue for a hosted artifact or fork; not needed here).
- Changing the upstream hash-pinning workflow or `updateLibraryHash.sh`.
- Upgrading android-library to a newer version.
