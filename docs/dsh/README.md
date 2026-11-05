# 给游戏总指挥的 DSH 网页制作员接入说明

这是一套放在 Balls 仓库、供**游戏总指挥（游戏总策划）**在**自己的执行环境**安装的配置与交接资料。本文及本目录中的“总指挥”均指该角色，完整角色提示词单独审阅，本次暂不上传；使用本包不依赖该提示词文件。DSH 是供该角色使用的外部网页制作工具，不是已注册到 Codex 的内置工具。它不会因为被读取或拉取就启动团队，也不会自动连接 Codex 和 DSH。不要把当前环境的安装路径、账号或临时测试 launcher 搬过去。

推荐先使用 **Web 界面人工交接**：用户向游戏总指挥说明本轮目标 → 总指挥整理任务与已审核素材 → DSH 网页制作员制作 → 总指挥审稿并组织相应检查 → 按本轮授权发布。工作可用于玩法提案、设计方案、开发成果或美术成果的评审，不要求每轮都启动美术团队或更新游戏。用户保留最终决定权。

DSH 网页制作员仍只辅助获准的简单、重复、不需要视觉或听觉判断的工作。本次统一指挥角色，不扩大工具权限：DSH 按已确认的布局、文案和素材完成实现及机械检查；信息组织取舍、视觉/听觉判断和最终验收仍由相应岗位负责。若要扩大职责，先由用户明确同意，不修改受保护文件来绕过。

原接入包已上传至 Balls，基准为 [4e86f89](https://github.com/Gankkiii/balls/commit/4e86f896af9abff9136c3895cd79b82ece63a6ab)。**本次按用户确认仅上传统一游戏总指挥口径的 DSH 修订，完整总指挥角色提示词暂不上传、未启用。** 仓库有文件不等于总指挥环境已安装，也不等于自动调用桥接已经完成。

## 1. 包含什么，验证到了哪一步

- `package.example.json`：独立工具目录的安装清单，固定 `@deepseek-ai/dsh` 为 `0.2.1-rc.5`。没有携带密钥或既有会话。
- `config/webpage-worker.patch.yml`：来自此前实际配置的「网页制作员」Web preset，ID 为 `webpage-worker`；不替换其他 preset，也不修改 Codex 角色配置。
- `skills/ball-art-review/SKILL.md`：游戏评审网页制作规范，保留 Git 历史及文案确认要求；沿用 `ball-art-review` 标识以保持兼容，不代表指挥角色仍属于美术团队。
- `config/privacy.patch.yml`：关闭额外的 Session Log 上传和 Session OTel 反馈上传。**这不阻止任务、读入材料和工具结果作为模型上下文发送给 DeepSeek**，也不删除本地会话记录。
- `config/headless-webpage-worker.patch.yml`：可选的一次性模式适配，独立设置 persona 并禁用再分派子角色的工具。它不是 Web preset，也不是自动派工桥接。
- `TASK.template.md`：总指挥填写的单轮任务及公开清单模板。
- `check-config.mjs`：离线配置组合检查，使用临时空 HOME/DSH_HOME，不读取现有密钥，不启动模型任务或 Web 服务。
- `VALIDATION.md`：历史准备记录、本次实际检查结果与未验证项。

本包不改 `art-team/`、`.codex/agents/`、根 `AGENTS.md`、游戏逻辑或发布工作流。上述仓库规则仍须由总指挥读取并遵守；本说明没有授权变更它们。游戏总指挥不是现有美术总负责人：现有美术团队仍须由用户亲自下达任务，点点仍按授权负责游戏接入。若具体任务需要改变受保护的指挥关系或岗位职责，先说明冲突并取得用户对对应变更的确认，不能靠本说明绕过。

## 2. 环境和边界

建议在总指挥能实际使用终端、读写文件和预览网页的同一台机器/容器安装。仅在聊天里写「已安装」或只有网页链接，不代表总指挥能调用它。若执行环境不持久，重启后需重新检查文件和配置。

以下命令供 **Bash / Linux / macOS** 使用；本次实际检查环境是 Linux，Node `24.22.1`。依赖中的 Commander 要求 Node `>=22.12.0`，建议使用 Node 24 LTS。Windows 原生 PowerShell 未测试，不要直接照搬 Bash 语法；可在支持的 Linux 环境完成后再验证。

- Balls 是游戏仓库和说明的来源；网页工作目录应与正式游戏目录分开。
- 已有评审目标为 `Gankkiii/ball_art_review`。每轮核对其实际分支、入口、部署方式与固定网址，不以本文历史路径覆盖现状。
- DSH 配置、凭据、会话和缓存放在仓库之外。`.gitignore` 不是保密或权限边界。
- 不把完整游戏仓库、个人 HOME、内部团队配置或无关资料复制给网页制作员，只提供本轮经审核的必要材料。
- 独立工作目录只能减少误操作，不是操作系统级隔离；同一用户运行的工具仍可能读取用户文件。若需硬隔离，使用经授权配置的独立容器/账号，不把提示词当作安全沙箱。

## 3. 首次安装（由总指挥在目标环境执行）

先确认这次获准安装软件。以下仅是说明，本包没有替你执行安装、启动或调用付费 API。

设置绝对路径，`BALLS_REPO` 改成该环境中的真实检出目录：

```bash
export BALLS_REPO="/absolute/path/to/balls"
export DSH_ROOT="$HOME/.local/share/balls-dsh-webpage"
export DSH_TOOLS="$DSH_ROOT/runtime"
export DSH_HOME="$DSH_ROOT/state"
export DSH_AGENTS_HOME="$DSH_ROOT/agents"
export DSH_CONFIG="$DSH_ROOT/config"
export DSH_WORKSPACE="$DSH_ROOT/work"
```

`DSH_ROOT` 必须位于任何 Git 检出之外。首次安装用一个不存在的目录；如果已有这个目录，先检查旧配置、会话与凭据，不能直接覆盖。确认后在新目录中执行：

```bash
test -f "$BALLS_REPO/docs/dsh/package.example.json" || exit 1
test ! -e "$DSH_ROOT" || { echo "目录已存在，请先检查，勿直接覆盖。"; exit 1; }
umask 077
mkdir -p "$DSH_TOOLS" "$DSH_HOME" "$DSH_AGENTS_HOME/skills/ball-art-review" "$DSH_CONFIG" "$DSH_WORKSPACE"
cp "$BALLS_REPO/docs/dsh/package.example.json" "$DSH_TOOLS/package.json"
cp "$BALLS_REPO/docs/dsh/config/"*.yml "$DSH_CONFIG/"
cp "$BALLS_REPO/docs/dsh/skills/ball-art-review/SKILL.md" "$DSH_AGENTS_HOME/skills/ball-art-review/SKILL.md"
npm install --prefix "$DSH_TOOLS"
node "$DSH_TOOLS/node_modules/@deepseek-ai/dsh/lib/bin.js" --version
node "$BALLS_REPO/docs/dsh/check-config.mjs" "$DSH_TOOLS"
```

应显示 DSH `0.2.1-rc.5` 和检查通过。安装固定的是 DSH 主包，不是完整依赖锁；保留目标环境 npm 生成的 `package-lock.json` 以便同环境后续用 `npm ci` 重装，不把该环境的状态目录提交到 Balls。升级 DSH 后重新做离线检查和小任务验收，不使用 `@latest` 静默升级。

安装失败时报告版本、失败步骤及去除凭据后的错误。不要改为不明下载脚本或跳过安全警告，也不要反复重新安装掩盖问题。

## 4. 先检查，后配置凭据和付费调用

`check-config.mjs` 只读取本仓库的样板并执行 DSH 的 `--dump-config`，不检验已复制配置是否被人修改。可用 `cmp` 对照三份 patch 和 skill；再在启动时确认加载的是 `DSH_CONFIG` 下的这套文件。

真实凭据只由用户在**目标环境的受支持安全凭据入口/秘密管理器**配置，不写进聊天、本文、任务模板、命令参数、Git、共享日志或截图。不复用其他机器的密钥文件，也不要让总指挥索要或打印完整值。

- Web 可使用该实例的「设置 → 模型」配置。若保存凭据，DSH 默认持久化到 `DSH_HOME` 下的本地凭据文件；由用户决定是否允许保存。本包未写入任何凭据。
- 默认 headless **不读取 Web 保存的凭据**，使用启动环境或 `.env` 后备。本方案不建议写 `.env`；需要 headless 时，由用户的秘密管理器在启动进程时注入 `DEEPSEEK_API_KEY`。不要通过命令行明文填入。
- Web 与 headless 不会共享一个「自动登录且可调度」的身份。凭据可用、模型可选、额度可用和任务授权是不同的检查。
- 本轮素材会发送给所选模型提供方。先确认允许发送的材料、模型、预算与是否允许调用；隐私 patch 不是「离线模式」。
- CLI 的 Web 启动 URL 含会话凭据，只在目标用户的私密环境打开，不粘贴到公开仓库、报告或评审网页。

## 5. 推荐接法：Web 网页制作员

完成安装、检查和必要授权后，从**独立网页工作目录**启动：

```bash
cd "$DSH_WORKSPACE"
node "$DSH_TOOLS/node_modules/@deepseek-ai/dsh/lib/bin.js" \
  --profile web \
  --patch "$DSH_CONFIG/webpage-worker.patch.yml" \
  --patch "$DSH_CONFIG/privacy.patch.yml" \
  --host 127.0.0.1 --port 3080 --no-open
```

此命令只是在目标环境运行 Web UI，不是部署评审网页。进程会驻留，完成后用 Ctrl+C 停止。端口占用时选择另一空闲本机端口并记录；不要因此改成公网监听。远程机器的 `127.0.0.1` 不等于用户电脑，需使用该环境已经批准的安全访问方式，不能擅自暴露管理界面。

在 UI 中创建新会话并**显式选择「网页制作员」**。添加 preset 不会自动切换默认 `standard`，也不会把已有会话改成网页制作员。开始付费小任务前核对工作目录、模型、权限模式与费用授权；不设 `danger-full-access`，不关闭审批来绕过阻碍。

先把 `TASK.template.md` 复制到工作目录并填写。总指挥先确认布局／页面结构（或明确沿用现有页面）及「要展示哪些字、每处为什么必要、确切短文案」，再交给 DSH。已确认的清单无需重复问；未确认的取舍先退回总指挥，不能用大段文字占位。

建议首次获准的最小验收：使用一张可公开示例图及已确认短文案，只输出本地网页和交付说明，不上传、不部署、不读无关仓库。检查 skill 能否实际加载、图片能否展示、文字是否符合清单，确认后再用于正式轮次。

## 6. 可选接法：定制 headless（不是自动桥接）

官方 headless 是一次性 runner，不加载 Web 的 preset 注册方式。因此以下做法不成立：启动普通 `dsh --profile headless`，就声称它使用了「网页制作员」。`--session-id` 也不能把带 Web preset 的会话直接交给 headless 接管。

本包的 headless patch 把网页职责放入 headless 的 `system-prompt`，使用同一 `ball-art-review` skill，并禁用其默认的子角色分派工具。它只做配置组合检查，**尚未在总指挥环境验证真实模型调用、权限处理、结果收集与中止**。需要交互确认时，任务应停止并返回问题，不能假设存在可回答的界面。

只有本轮已获准模型调用、素材传输与本地制作，且秘密管理器已为该进程提供凭据后，才可运行如下命令。`TASK.md` 必须是填写完整的交接单，不要原样运行空模板：

```bash
cd "$DSH_WORKSPACE"
node "$DSH_TOOLS/node_modules/@deepseek-ai/dsh/lib/bin.js" \
  --profile headless \
  --patch "$DSH_CONFIG/headless-webpage-worker.patch.yml" \
  --patch "$DSH_CONFIG/privacy.patch.yml" \
  --json - < TASK.md > result.jsonl 2> diagnostic.log
```

结果和诊断日志可能包含素材信息、模型输出与工具结果，只保留在受控目录，不自动发布。检查退出码、事件中的错误/结束原因、最终文件和验收结果；退出码 0 不代表视觉、文案、手机体验或发布验收通过。

若以后需要总指挥自动调用 DSH，应另外实现并验证：明确的任务与素材传递、权限阻塞返回、费用控制、进程超时与终止、产物收集、失败/部分完成检测、重复任务防护和发布审批。此前的临时测试 launcher 不具备这些保证，本文没有安装自动调度器、监听器、定时任务或 Codex 插件。

## 7. 每轮工作与发布规则

1. 用户亲自给总指挥下达本轮任务；总指挥读取当前仓库规则、角色设定和设计决定，不因安装/读文档就启动团队。
2. 总指挥整理可公开且可发给 DeepSeek 的材料，确认文案、已选方案、候选项、相对路径与验收标准。网页制作员不替用户决定设计、不改游戏逻辑、不改其他岗位配置、不再创建子角色。
3. 在独立网页工作区/分支制作。网页以图、动画、视频、音效为主；简短文字只保留理解和选择所需内容。依本轮需求保留选择区和可编辑反馈模板，不能覆盖用户已经写入的意见。选择草稿、打开页面和播放媒体都不是最终批准。
4. 总指挥审稿，并根据现有成员、任务与授权安排检查真实入口、资源、媒体播放、手机视口、触控和反馈模板。无条件验证的项目标记「未验证」，不得伪造完成。开始前记录本轮截止时间；现有美术团队任务仍从实际启动起最多 60 分钟，其他任务按用户已确认的时限执行。调用 DSH 不重新计时，也不会因为这段文字而自动被强制停止。
5. 使用用户指定的固定评审仓库和网址；**当前评审网页及其受管文件只保留最新一轮**。先明确替换清单，再移除被新一轮替代的当前网页/源文件，不误删游戏仓库中的素材交付或其他无关资料。
6. **正常替换通过新增 Git 提交保留历史。** 不执行 force push、filter-repo、删除仓库或其他历史重写。旧内容仍可能在历史、缓存和已下载副本中；不可恢复清理须说明影响并在当次取得用户确认，不能保证收回所有副本。
7. 只有本轮授权覆盖目标、文件和公开发布，才提交到对应公开仓库并按获准流程合并/部署；本地制作与审稿不自动授予发布权。公开仓库分支和 Git 历史同样视为公开，不能上传密钥、内部配置或未获许可材料。
8. 发布后验证固定网址与预期版本、入口和资源；失败保留成果，说明实际状态。网页评审与游戏接入是不同交付；需要给点点素材包时另行核对，上传失败或只有本地路径时不能说交接成功。

## 8. 升级、停用和排错

- 找不到「网页制作员」：检查启动时是否有 Web patch、版本是否一致、是否在新会话选择 preset；读离线检查结果，不声称默认 standard 已变成该角色。
- 找不到 skill：检查 `DSH_AGENTS_HOME/skills/ball-art-review/SKILL.md` 及 frontmatter，留意项目 `.dsh/skills` 或 `.agents/skills` 中同名 skill 的更高优先级；必要时在干净工作目录重试。没有读到正文就先停止依赖工作。
- Web 可用而 headless 缺凭据：先看两者的凭据来源差异，不复制账号文件或为了通行启用更多持久访问。
- 配置变化后：保留旧版本，更新仓库外副本，重新运行检查并创建新会话；不要用 `--from-default-profile` 覆盖已有自定义配置。
- 停用：停止对应进程，不再传入本包 patch 即不添加该配置。不要删除用户的其他 profile、会话或凭据。需撤销密钥时由用户在提供方处理，删除本地目录不会撤销远端密钥。

## 参考来源

本说明以安装包 `0.2.1-rc.5` 内的真实文档与配置为依据：`@deepseek-ai/dsh/README.zh.md`、`dsh-web-app`、`dsh-headless`、`dsh-agent-preset`、`dsh-skill-filesystem`、`dsh-home-paths`、`dsh-credentials-local`、`dsh-session-log-deepseek` 和 `dsh-session-telemetry-otel` 的 README。官方源码仓库：[deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness)。版本升级后以该版本真实帮助和包内文档重新核对。
