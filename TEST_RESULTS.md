# v0.2 Verification — 2026-11-02

Godot 4.6.3.stable.official.7d41c59c4, Linux x86_64.

Version remains **0.2.0 (code 2)** as requested; this is an in-version revision.

## Actual automated execution

- Original physics regression: **T01–T22 22/22 passed**, 74,237 assertions, zero failures. Baseline controller remains as a fixture for the explicitly superseded old time scale and three-button layout. Shared production Arena/Ball are tested unchanged by fixtures.
- New character/controller regression: **138 assertions, zero failures**, behavior labels C01–C42. Includes actual main-scene 1×/2×/3× equivalence across positions, HP, cooldowns and egg states; paused start and skill queuing. Normal 1/2/3 speed restored; restart/reset and gas-driven visual size regression added.
- 20 seeded battles: 17 puffer wins, 2 chicken wins, 1 time-limit draw. This is a functional smoke sample, **not evidence of balanced gameplay**.
- Godot headless import and gameplay initialization checked.
- Android v0.2 debug APK exported and v2/v3 signature verification passed. No signing private key included in repository.

## Not verified / limits

- T23 actual screen rendering and input: NOT RUN. An internal Web export was produced, but browser access to the preview server returned connection refused; this is not a passing visual test.
- T24 real Android installation/touch/background lifecycle: NOT RUN, no device attached.
- Sprite art is procedural placeholder art; collision bodies remain circles, including chicken.
- Physics remains floating point; no cross-device bit-exact determinism claim.
- APK verification is packaging/signature validation, not on-device execution.

Latest logs: tests/latest-run.txt and tests/character-latest-run.txt.
