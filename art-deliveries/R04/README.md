# R04 点点接入资源包

本包对应用户已认可的 [R04评审页](https://gankkiii.github.io/ball_art_review/)（评审仓库提交 `33d13fc55256fb6ef4b7f7cf31ea75bd328b28e2`）。用户在评审后明确要求整理资源给点点写代码；不再重开造型选择。本次只交素材与说明，没有修改游戏代码或团队配置。

**先读 `INTEGRATION.md`，再按 `ASSET_MANIFEST.json` 导入 `assets/`。**

|位置|用途|
|---|---|
|`assets/characters/`|八角色透明原图、动作帧/精灵表、独立物件；具体状态和帧序见 `metadata/characters.json`|
|`assets/audio/`|32个独立事件WAV，见 `metadata/audio.json`；不把整段试听导入战斗|
|`assets/ui/`|本版已有独立UI原件；动态文字、填充、状态绑定由点点实现，见 `UI_INTEGRATION.md` 和 `metadata/ui.json`|
|`docs/characters/`|八角色独立设定；阅读 `docs/HANDOFF_STATUS.md` 区分上轮历史状态与本轮授权|
|`docs/DECISIONS.md`|用户确认的造型与反馈；鸭兔不重做，兔继续宽刀|
|`reference/`|网页概念预览与8段声音编排，只参考；不能当作游戏角色贴图、动画帧或技能定时器|
|`source/`|可用制作源及复建方式；不是正式游戏脚本|
|`QA_REPORT.md`|实际完成的检查、缺失及未验证项|
|`DIANDIAN_TASK.md`|可直接转交点点的实施任务|

鸭兔已在基线接入，继续使用 `assets/r02/`、`assets/audio/` 和旧 `art-deliveries/R02/visual-remake-v2/` 的来源/说明；不复制、不覆盖旧资源。全部8角色的普通实际受击统一眨眼，免伤、吸收、隐藏和不可受伤物件不能伪装受击。A像素风、横屏左右状态、浅色场地及现有操作保留。

包根 `.gdignore` 隔离文档、制作源和参考图。点点将需要的 `assets/` 复制到正式资源路径后导入；不要去掉隔离文件让Godot扫描整个交付目录。原生96画布不等于96游戏单位，身体视觉挂点与物理半径分别处理，不能按贴图轮廓重建碰撞。

这是一份**原始资源和代码实施说明交接**：可解码/可导入不等于在战斗中已经绑定。音频为程序合成拟声，非真实动物录音；人工听审、游戏内混音、真机显示与性能仍由后续接入验收。本轮缺失的内容明确列在接入清单内，不用概念图顶替。

完整性：从新目录解压后进入 `R04/`，运行 `sha256sum -c SHA256SUMS.txt`。仓库同时保留解压后的单独文件。ZIP位于同级 `art-deliveries/R04-assets.zip`，ZIP自身校验为 `art-deliveries/R04-assets.zip.sha256`。
