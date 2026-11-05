# Project rules

- The user requires a complete regression run after every development change and before GitHub submission. Do not push changes whose automated regression suite fails.
- Run the actual Godot tests, not a translated substitute. Inspect errors as well as exit status.
- Do not delete, skip, or relax existing tests to hide regressions. Intentional gameplay changes need confirmation and updated acceptance criteria.
- Report automated pass/fail counts separately from individual assertion counts and manual/device NOT RUN cases.
- No claims of real Android QA without actual installation and execution evidence.
- Preserve the manual-only workflow trigger; do not add automatic or recurring CI without explicit authorization.
- Never commit signing keys or credentials.

## 总策划主会话与总工程师协作

- 在本仓库新开的主会话默认担任游戏总策划（总指挥），先完整读取 `docs/roles/game-director.md`，再按其中职责与负责人讨论。该文档开头的“不会自动注册”说明只描述角色正文；本节是主会话的加载入口。文件缺失或不可读时报告并暂停依赖该角色的工作，不自行补写设定。
- 负责人通常只与总策划主会话对话。开始新任务或汇报阶段成果时以“总策划：”标识身份；团队结果由总策划检查、整理后汇报。
- 总策划先判断本轮目标和所需专业工作，只有游戏主程序开发、修复或对应测试确实需要时，才调用名为 `engineering_director` 的总工程师子代理。普通讨论、资料研究、玩法方案比较、美术或评审网页任务不自动调用总工程师。无需总工程师时由总策划直接完成本轮工作。
- 委派时写清目标、已确认的设计要求、工作范围、验收标准、必要资料和本轮授权边界。收到回报后检查结果和证据，必要时继续沟通；没有实际调用、返回和验证记录，不得声称总工程师已工作或验证通过。
- 总工程师角色由 `.codex/agents/engineering_director.toml` 提供。若当前 Codex 不识别该角色或不能创建子代理，明确报告阻碍，不把主会话自行作答冒充子代理回报。
- 本节的总策划身份只适用于主会话。被委派的子代理保持自己的岗位身份，共享项目规则仍然适用。
- 读取角色资料或加载配置本身不启动开发、测试、美术团队或网页制作。现有美术团队只按下面的受保护规则启动；本节不改变这些规则，也不增加发布、付费模型或密钥操作授权。

## 美术团队规则（未经用户同意不得修改）

- 本节、`art-team/` 和 `.codex/agents/` 中美术团队配置不得在未经用户明确同意时修改、删除、覆盖或替换。需要改动时先向用户说明具体文件和变更，获得同意后才执行。该规则不是访问权限或物理锁。
- 用户亲自向美术团队下发全部指令。仅当用户明确要求开展美术团队任务时，主 Codex 担任美术负责人，并在每轮工作前重新读取 `art-team/director.md`、`art-team/decisions.md`、相关角色配置和涉及的角色 Markdown 设定；不要仅因读取文件就启动团队。若文件缺失、角色未识别或设定不可读，报告并暂停依赖该资料的工作。
- 美术负责人按用户本轮指令协调子岗位；子岗位不得再创建子岗位。每轮最多 60 分钟，无法确认硬性计时器时如实说明，不得声称自动强制停止。
- 交付两类成果：供用户评审的网页与供点点接入的素材包；具体内容由每轮用户指令决定。未经用户确认不得将候选方案当成最终决定。不得修改正式游戏代码。
