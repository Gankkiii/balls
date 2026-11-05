# 游戏总指挥与 DSH 修订验证记录

记录日期：2026-11-05。本次范围：**用户已确认仅上传以下 7 个 DSH 文件，完整总指挥角色提示词暂不上传、未启用**。下述检查记录在提交前完成；实际上传结果以远端提交为准。本次没有部署网页。文档存在不代表安装、真实调用或自动桥接已经完成。

## 基准与变更范围

原 9 文件已上传至 `Gankkiii/balls` 的 `main`：[4e86f896af9abff9136c3895cd79b82ece63a6ab](https://github.com/Gankkiii/balls/commit/4e86f896af9abff9136c3895cd79b82ece63a6ab)。本次逐一读取远端文件并留存基线。该提交只增加 DSH 文档，游戏及既有团队仍沿用父版本 `9b995fbfe3c15f71ba1ba577b9938397bb62c939`。

修改原 7 个文件：

1. `docs/dsh/README.md`：统一服务游戏总指挥，说明安装状态与外部工具属性，更新工作流；注明完整角色提示词单独审阅、本次不上传。
2. `docs/dsh/config/webpage-worker.patch.yml`：改正 Web 网页制作员服务的指挥角色。
3. `docs/dsh/config/headless-webpage-worker.patch.yml`：改正 headless 网页制作员服务的指挥角色。
4. `docs/dsh/skills/ball-art-review/SKILL.md`：统一职责、指挥及验收关系，沿用 Skill ID 保持兼容。
5. `docs/dsh/TASK.template.md`：明确游戏总指挥、检查成员、已确认布局和适用截止时间。
6. `docs/dsh/check-config.mjs`：增加 DSH 指挥角色一致性检查，不依赖尚未上传的角色提示词文件。
7. `docs/dsh/VALIDATION.md`：本记录。

完整游戏总指挥提示词仍在单独审阅，本次不上传。本次缩减范围的兼容修正仅去掉 README 中的角色文件链接和检查器对该文件的强制读取，并据实更新本记录；其余 DSH 配置与已审阅内容一致。

`package.example.json` 和 `config/privacy.patch.yml` 未变。未改游戏代码、既有测试、根 `AGENTS.md`、`art-team/`、`.codex/agents/` 或 GitHub Actions。未读取或写入实际 API Key，未启动团队、调用模型、安装到总指挥环境或建立自动桥接。

## DSH 离线检查：通过

环境：Linux、Node `24.22.1`，使用已有 DSH `0.2.1-rc.5`，未重新安装依赖。

- JavaScript 语法、安装清单 JSON、三份 YAML patch、Skill frontmatter 均通过。
- 在临时空 HOME、DSH_HOME、DSH_AGENTS_HOME 中运行两种 profile 的 `--dump-config`，未继承真实凭据、模型端点或代理，未启动服务或模型任务。
- Web 与 headless 实际组合 persona 均指向游戏总指挥；仍是两种不同接法，不将 headless 当成 Web preset。
- 所需插件可解析，Skill 支持存在，Web 未新增子角色工具，headless 的四个子角色工具仍禁用。
- 两种组合均关闭额外 Session Log 与 Session OTel 上传，不据此声称阻止正常模型请求或完成全部网络审计。
- 8 个正反例检查通过：正常 DSH 包及含空格路径的纯 DSH 包均通过，均不含总指挥角色文件；Web、headless、Skill 的错误指挥称呼、任务模板缺少游戏总指挥口径、开启额外日志上传均被拒绝；缺 runtime 参数返回退出码 2。
- DSH 包 9 文件常见 API token、GitHub token、JWT、私钥、明文凭据赋值与私有机器路径模式扫描无命中。未打开实际凭据文件；静态扫描不是任意秘密泄露的保证。

## 完整游戏回归：通过

按仓库真实工作流运行 Godot `4.6.3`，使用隔离的本轮用户数据目录，不改测试预期：

```bash
godot --headless --editor --import --quit
godot --headless --script tests/run_tests.gd
godot --headless --script tests/test_characters.gd
godot --headless --script tests/independent_gameplay_cases.gd
```

- 导入成功，退出码 0。
- 基础／控制器：22/22 自动用例通过，74,247 次断言，0 失败；2 个手工用例未运行。
- 角色及关联套件：11,849 次断言，0 失败；输出不提供统一独立用例总数，不将断言数当用例数。
- 独立玩法：25/25 用例通过，49 次断言，0 失败。
- 合计 86,145 次断言；三个套件退出码均为 0，日志无 ERROR、SCRIPT ERROR、Parse Error 或 FAIL。
- 导入产生的未跟踪 .import／.uid 辅助文件不纳入交付，游戏和既有团队文件无变更。

## 静态审阅与未验证项

本次不上传或启用完整角色提示词。游戏总指挥不再与现有美术总负责人混同；保留既有美术团队的用户指挥、受保护角色及最多 60 分钟要求，但不把所有游戏任务限为美术任务。补齐布局交接字段，避免缺少实现依据。DSH 配置检查不依赖未上传的角色提示词文件。

未验证总指挥目标环境的新安装、持久化、权限强制执行、真实 Skill 加载及模型调用；未实现或验证自动派工、结果回收、费用限制、超时中止、重复任务防护；未启动 Web UI 或 headless 模型任务，未做本次网页视觉／听觉、手机触控、Android 真机或公开部署检查。历史临时启动程序的成功测试不等于本次目标环境联调成功，也不授予持续凭据或付费调用权限。

## 上传前后

按用户确认仅上传本次 7 个 DSH 变更文件，先重新核对远端基准并保留用户其他改动。不强推、不重写历史，不上传运行状态、日志、凭据、node_modules 或临时测试程序。DSH 包另有 2 个未改文件提供上下文，不把它们计作新改动；不上传总指挥角色文件。

上传后核实远端提交与文件，并更新实际发布状态。本记录证明准备阶段已经完成的检查，不代替目标环境安装或运行验收。原包准备记录保留在 [原提交的 VALIDATION.md](https://github.com/Gankkiii/balls/blob/4e86f896af9abff9136c3895cd79b82ece63a6ab/docs/dsh/VALIDATION.md)。
