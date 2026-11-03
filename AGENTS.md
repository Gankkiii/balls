# Project rules

- The user requires a complete regression run after every development change and before GitHub submission. Do not push changes whose automated regression suite fails.
- Run the actual Godot tests, not a translated substitute. Inspect errors as well as exit status.
- Do not delete, skip, or relax existing tests to hide regressions. Intentional gameplay changes need confirmation and updated acceptance criteria.
- Report automated pass/fail counts separately from individual assertion counts and manual/device NOT RUN cases.
- No claims of real Android QA without actual installation and execution evidence.
- Preserve the manual-only workflow trigger; do not add automatic or recurring CI without explicit authorization.
- Never commit signing keys or credentials.

## 美术团队规则（未经用户同意不得修改）

- 本节、`art-team/` 和 `.codex/agents/` 中美术团队配置不得在未经用户明确同意时修改、删除、覆盖或替换。需要改动时先向用户说明具体文件和变更，获得同意后才执行。该规则不是访问权限或物理锁。
- 用户亲自向美术团队下发全部指令。仅当用户明确要求开展美术团队任务时，主 Codex 担任美术负责人，并在每轮工作前重新读取 `art-team/director.md`、`art-team/decisions.md`、相关角色配置和涉及的角色 Markdown 设定；不要仅因读取文件就启动团队。若文件缺失、角色未识别或设定不可读，报告并暂停依赖该资料的工作。
- 美术负责人按用户本轮指令协调子岗位；子岗位不得再创建子岗位。每轮最多 60 分钟，无法确认硬性计时器时如实说明，不得声称自动强制停止。
- 交付两类成果：供用户评审的网页与供点点接入的素材包；具体内容由每轮用户指令决定。未经用户确认不得将候选方案当成最终决定。不得修改正式游戏代码。
