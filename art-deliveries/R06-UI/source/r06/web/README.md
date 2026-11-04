# R06 静态原型整合

运行 `python web/R06-web-build.py --source /path/to/R06-ui-review --repo /path/to/ball_art_review`。可用本目录上级完整 sources/r06 树作为输入。

builder仅复制本轮公开扩展白名单、生成review-data与SHA256清单；不发布、不删历史、不改游戏。静态父页面源码位于web/site（对应仓库docs/index.html及docs/r06/app.js/style.css）。四页iframe按需加载并保留当前内存，导航按origin/source/page白名单校验；只有hatch发往storage时转发JSON克隆后的演示child。无localStorage、存档写入或联网提交。

外壳映射由同一 builder 执行：`web/site/index.html` → `docs/index.html`，`web/site/r06/app.js` → `docs/r06/app.js`，`web/site/r06/style.css` → `docs/r06/style.css`。因此上述单条命令会恢复外壳、四页原型与数据，并重建公开哈希清单；不会仅复制素材而遗漏入口。
