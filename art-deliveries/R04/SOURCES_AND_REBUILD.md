# 来源与安全复建

本包视觉来源是用户已认可的R04原始程序几何与透明原稿，音频为本项目原创程序合成拟声；没有读取评审截图来冒充角色原件，没有外部动物录音或采样。旧R03被否决的16个音轨不在本包。少量公共UI操作/鸭兔符号沿用已有R02原件，其来源在UI metadata单独标出，不冒称本轮重新设计。

`reference/` 是公开R04原件组合的概念预览，仍不是实际游戏录屏；`reference/audio/` 为8个整段试听，不是独立事件输入。独立WAV原字节与评审提交保持一致。源程序中的旧候选辅助函数只用于保留可编辑依赖，不代表用户重新选了它们；正式使用以 `assets/` 和 `metadata/` 为准。

## 复建方式

在交付目录以外的新目录复制整包后再运行制作源，避免覆盖已核验原件。各岗位的具体参数、产物范围与复现结果见其源说明及 `QA_REPORT.md`。

- 角色：`python3 source/characters/export_characters.py --output /tmp/r04-characters-new`。需Python 3、Pillow；`source/characters/README.md`列出范围，输出到新目录。`source/characters/` 包含导出脚本及原始几何依赖；`metadata/characters.json` 是路径、尺寸、锚点、朝向、帧序与状态说明的接口。
- UI：在复制包根运行 `python3 source/ui/export_ui.py`。需Python 3、Pillow和Inkscape；原SVG和PNG另有保留。它按原图程序的组件几何导出，不裁截图；运行后只改复制包的UI及对应metadata。
- 音频：`python3 source/audio/build_character_audio.py --output /tmp/balls-r04-audio-new`。需Python 3、NumPy、SciPy。会重建40个WAV（32独立事件+8整段试听）和评审数据；正式游戏输入仅取metadata列明的32事件，不直接把40个输出全部复制进战斗。该程序的原评审状态是历史来源记录，本轮交接状态由 `docs/HANDOFF_STATUS.md` 说明。
- 独立Godot导入：`python3 source/validation/import_smoke.py --package /path/to/R04 --logs /tmp/r04-import-logs`。需Godot 4.6.3；脚本创建临时独立工程，只复制assets与manifest，按明确WAV导入设置（compress/mode=0，保留48k/mono/16bit，不裁切/归一化/循环）逐PNG/WAV加载并核对尺寸/音频格式，不连接、不改正式游戏，也不证明事件已绑定。
- 包装：`python3 source/package/assemble.py --source /path/to/frozen-staging --destination /tmp/rebuild/R04 --zip /tmp/rebuild/R04-assets.zip`。源/目标必须分离且目标不存在，保留既有文件。此步骤只创建快照、manifest、SHA和ZIP，不自动上传或发布；重新打包后必须重新解压校验。

PNG/SVG/布局数据和源码为可用制作输入，不把脚本中的绝对工具/字体路径当成游戏内资源路径。系统字体只用于既有参考图说明及操作符号渲染，本包不包含字体二进制；游戏继续使用仓库现有字体与授权。没有新增背景音乐或新第三方字体。

制作来源/可重复生成不等于排他版权或法律审计结论。人工听审、真实设备、游戏内事件同步与混音未由源复现证明，需点点接入后分别验证。

Godot 4.6.3新工程默认WAV `compress/mode=2`会转成QOA（AudioStreamWAV.format=3），不是源文件损坏。为了保留本包PCM16原声音，点点在Import面板把Compression Mode设Disabled(0)，关闭强制8bit/变采样、trim/normalize/loop后Reimport；也可用项目`[importer_defaults]`的`wav`字典设置上述参数作为新导入默认。本包没有改正式项目配置。
