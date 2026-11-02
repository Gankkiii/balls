# Verification report

Engine: Godot 4.6.3.stable.official.7d41c59c4, Linux x86_64.

## Executed

- Headless editor import: scripts and scenes load.
- Native GDScript suite: **22 named automated cases, 74,237 assertions, 0 failures; T23–T24 manual cases NOT RUN**.
- Uniform motion, four walls, corner, head-on velocity exchange, oblique tangent preservation, pair momentum and energy, separating contact.
- High-speed opposing disks: analytic CCD, no remaining overlap and conserved energy.
- 20 seeds × 72,000 fixed steps = 20 independent ten-minute simulations. Checked finite values, bounds, separation and event safety limit. Worst final relative energy drift **0.000000834** (0.0000834%), below predefined 0.1% tolerance.
- Actual main scene: 1× for ten seconds matches 2× for five seconds, pause/background preserve state, repeated controls leave exactly two balls.

## Not yet verified

- Native desktop visual inspection and manual clicking.
- Real Android installation, touch input, hardware-specific rendering, background/resume and screen scaling.


No claims of Android device compatibility beyond the selected arm64 export target. Automated physics assertions do not constitute full visual or mobile QA.

## Android artifact verified

- APK build completed with Godot 4.6.3 prebuilt debug template (no Gradle).
- OpenJDK 21.0.12.1; Android Build Tools 35.0.0 used as exporter fallback for the template target SDK 36. Export completed successfully despite fallback warning.
- `apksigner verify --verbose`: verified v2 and v3 signatures, one signer.
- Package: `com.gankkiii.smootharena`, version 0.1.0 (1), min SDK 24 / Android 7.0, target SDK 36, arm64-v8a.
- File: `build/smooth-arena.apk`, approximately 27 MiB.
- SHA-256: `a836a7421f3085563d450c40ba745a745cf3c49f1ea55f9ab80426f6eca84bda`.
- No attached Android device or emulator: installation and actual on-device gameplay remain untested. ADB daemon warning did not prevent packaging/signature verification.

## Expanded regression suite (2026-11-02)

Baseline suite passed before edits (60,081 assertions). Expanded T01–T22 passed on the same production source. Added independent registration/removal, seed reproducibility, near-miss, overlap, real button signals, lifecycle notifications and render-rate comparisons. Test definitions and fixed tolerances are in `tests/TEST_CASES.md`. Final output is in `tests/latest-run.txt`. No gameplay or APK changes in this test-only update.
