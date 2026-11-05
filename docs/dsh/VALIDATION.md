# 本次准备与验证记录

记录时间：2026-11-05，准备完成时的状态：**本地待审，未提交、未推送、未部署**。按用户本次要求，先展示所有拟上传文件及完整内容，获得对这批内容的确认后再上传到 Balls。后续发布状态以可核实的远端提交为准。

## 变更范围

基于 `Gankkiii/balls` 的 `main`，基准提交 `9b995fbfe3c15f71ba1ba577b9938397bb62c939`，本地分支 `docs/dsh-webpage-setup`。

仅新增以下 9 个文件：

1. `docs/dsh/README.md`：总指挥在自己环境安装、检查、人工交接与可选 headless 说明。
2. `docs/dsh/package.example.json`：DSH 固定版本安装清单。
3. `docs/dsh/config/webpage-worker.patch.yml`：真实 Web preset 的可迁移版本。
4. `docs/dsh/config/headless-webpage-worker.patch.yml`：单独的 headless persona 与禁止再分派配置。
5. `docs/dsh/config/privacy.patch.yml`：两个额外会话上传通道的关闭配置。
6. `docs/dsh/skills/ball-art-review/SKILL.md`：网页辅助制作 skill，含文案确认与最新网页覆盖规则。
7. `docs/dsh/TASK.template.md`：单轮材料、文案、授权及验收交接模板。
8. `docs/dsh/check-config.mjs`：不启动服务或模型任务的配置检查器。
9. `docs/dsh/VALIDATION.md`：本记录。

未改游戏代码、既有测试、根 `AGENTS.md`、`art-team/`、`.codex/agents/` 或 GitHub Actions。没有运行团队，没有创建自动桥接、计划任务或公开服务，没有安装到总指挥环境，也没有调用付费模型。原有临时测试 launcher 未被纳入交付。

## DSH 离线检查：通过

环境：Linux，Node `24.22.1`，实际安装的 DSH `0.2.1-rc.5`。

- 安装清单 JSON、三份 YAML patch、skill frontmatter、检查器 JavaScript 语法通过。
- 使用 DSH 自带 `--dump-config`，在无凭据的临时 HOME、DSH_HOME、DSH_AGENTS_HOME 中分别组合 Web 与 headless 配置。
- Web 组合含 `webpage-worker`，所需插件可从实际安装解析；该 preset 未注册子角色工具。
- headless 组合含独立网页 persona 与 skill 支持，四个子角色工具关闭；未将 Web preset 错当成 headless 可选 preset，默认持久凭据存储仍关闭。
- 两种组合均确认 `session-log-deepseek.enabled: false` 及 `session-telemetry-otel.mode: DISABLED`。这不阻止正常模型请求，也不等于对全部网络行为完成审计。
- 检查器及配置位于含空格路径时通过；故意改为开启 Session Log 的临时测试副本被拒绝；缺少 runtime 参数返回退出码 2。
- 对拟新增文件做常见 API token、GitHub token、JWT、私钥、明文凭据赋值和私有机器路径模式检查，未发现命中。没有读取或比对实际密钥文件；静态扫描不是对任意秘密泄露的数学保证。

## 仓库回归：通过

按仓库真实工作流运行 Godot `4.6.3`，使用临时用户数据目录，不改测试预期：

```bash
godot --headless --editor --import --quit
godot --headless --script tests/run_tests.gd
godot --headless --script tests/test_characters.gd
godot --headless --script tests/independent_gameplay_cases.gd
```

- 导入成功，退出码 0。
- 基础/控制器：22/22 自动用例通过，74,247 次断言，0 失败；2 个手工用例未运行。
- 角色及关联套件：11,849 次断言，0 失败；该输出不提供统一独立用例总数，不把断言数当用例数。
- 独立玩法：25/25 用例通过，49 次断言，0 失败。
- 合计 86,145 次断言，不是 86,145 个独立用例；三个套件退出码均为 0，日志未发现 ERROR、SCRIPT ERROR、Parse Error 或 FAIL。
- 导入新生成的未跟踪 `.import`/`.uid` 文件已经清理，不包含在拟上传内容中。

## 明确未运行或尚未验证

- 未重新安装 npm 依赖，使用的是已有实际安装；另一台机器的新安装仍需在当地验证。
- 未启动 Web UI、进行真实 skill 加载对话或调用模型；配置组合成功不等于实际会话已经工作。
- 未验证目标环境的权限强制执行、网络/费用限制、超时中止与产物搬运。
- 未验证总指挥自动发任务、读取结果或重复任务防护；headless 是可选配置示例，不是完整桥接实现。
- 未进行网页视觉/听觉验收、手机触控、Android 真机或公开网址部署检查。

## 批准后的建议发布方式

确认拟上传的就是上述 9 个文件后，先复查远端 `main` 是否变化，保留用户其他改动；仅提交 `docs/dsh/`。目标、分支与是否需要草稿 PR 以用户确认的发布方式为准，不从本次准备任务推定可以合并或部署。不强推、不重写历史、不上传配置状态目录、日志、凭据、node_modules 或旧测试 launcher。

推送后核实远端确有对应提交和 9 个文件，再向用户提供仓库链接；不能仅凭本地成功就声称已上线。更换目标、扩大文件清单或改变已审内容前，重新说明差异并取得适用确认。本记录保留准备阶段的实际结果，不冒充未来验证。
