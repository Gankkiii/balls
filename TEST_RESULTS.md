# v0.2 Verification — 2026-11-02

Godot 4.6.3.stable.official.7d41c59c4, Linux x86_64.

Version remains **0.2.0 (code 2)** as requested; this is an in-version revision.

## Actual automated execution

- Original physics regression: **T01–T22 22/22 passed**, 74,247 assertions, zero failures. T01 and T15–T19 now load the current main scene and five-control UI; obsolete baseline-controller assertions were replaced, not skipped. Isolated production Arena/Ball physics coverage and tolerances are unchanged.
- New character/controller regression: **1,256 assertions, zero failures**, behavior labels C01–C63. Includes actual main-scene 1×/2×/3× equivalence across positions, HP, cooldowns and egg states; paused start and skill queuing. Includes six restart states, actual queued-node destruction, repeated restarts, every quarter gas size, per-step growth/shrink, full-state 1/2/3 speed × 10/30/60/144 fps equivalence, actual button signals, background/focus notifications and frame clamp.
- 20 seeded battles: 17 puffer wins, 2 chicken wins, 1 time-limit draw. This is a functional smoke sample, **not evidence of balanced gameplay**.
- Godot headless import and gameplay initialization checked.
- Previous gameplay revision Android v0.2 debug APK exported and v2/v3 signature verification passed; this revision changes tests/documentation only, no new APK export performed. No signing private key included in repository.

## Not verified / limits

- T23 actual screen rendering and input: NOT RUN. An internal Web export was produced, but browser access to the preview server returned connection refused; this is not a passing visual test.
- T24 real Android installation/touch/background lifecycle: NOT RUN, no device attached.
- Sprite art is procedural placeholder art; collision bodies remain circles, including chicken.
- Physics remains floating point; no cross-device bit-exact determinism claim.
- APK verification is packaging/signature validation, not on-device execution.

Latest logs: tests/latest-run.txt and tests/character-latest-run.txt.
