# Project rules

- The user requires a complete regression run after every development change and before GitHub submission. Do not push changes whose automated regression suite fails.
- Run the actual Godot tests, not a translated substitute. Inspect errors as well as exit status.
- Do not delete, skip, or relax existing tests to hide regressions. Intentional gameplay changes need confirmation and updated acceptance criteria.
- Report automated pass/fail counts separately from individual assertion counts and manual/device NOT RUN cases.
- No claims of real Android QA without actual installation and execution evidence.
- Preserve the manual-only workflow trigger; do not add automatic or recurring CI without explicit authorization.
- Never commit signing keys or credentials.
