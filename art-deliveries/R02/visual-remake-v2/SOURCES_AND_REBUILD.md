# 来源与制作源复现

## 本轮新制视觉

人物、UI、环境和VFX均由本轮原创像素/矢量几何制作源导出，没有从评审PNG裁切、视频抽帧、描摹截图生成透明假原件，也没有引入下载的第三方图形。SVG是可编辑几何源，不含嵌入位图、外部图片或秘密；Python脚本记录几何与帧变化。此来源说明不构成排他权或法律审计保证。

已有R01 A透明原件虽已从历史提交恢复，但用户明确选择全部重制，因此没有将R01字节放入本版usable。旧R02视觉原件在当前可访问环境、仓库历史、分支和Release中未找回；新素材不得改称“旧R02原始恢复件”。

## 复现依赖和命令

使用Python 3及Pillow；UI脚本还使用系统Inkscape导出SVG。预览文字使用系统字体，字体二进制不随包分发。各分类README说明实际参数；不要为了复现安装不明字体或复制机器凭据。

所有重建均写入**新的空临时目录**，不要对已审核交付目录运行覆盖。示例中的路径以本包根为当前目录，输出路径仅为示例，须尚不存在：

```bash
python3 payload/usable/visual/characters/source/build_characters.py --output /tmp/balls-r02-characters-new
python3 payload/usable/visual/build_environment_vfx.py --output /tmp/balls-r02-env-vfx-new
```

人物源会同时导出PNG/SVG、manifest和审核预览；人物PNG使用nearest×2。SVG经矢量渲染器导出时，alpha=0下的隐藏RGB可能不同，但透明度和可见像素一致。不要篡改校验值来掩盖实际资产差异。

UI的脚本以其父目录作为输出根，因此先复制整个visual目录到新临时目录（保留预览所需的相邻角色与环境），再在副本执行：

```bash
cp -a payload/usable/visual /tmp/balls-r02-visual-rebuild-new
python3 /tmp/balls-r02-visual-rebuild-new/ui/source/build_ui.py
python3 /tmp/balls-r02-visual-rebuild-new/ui/source/build_preview.py
```

UI预览脚本若需要相邻的角色与环境，遵循UI README中的目录结构说明；独立36组件由build_ui.py直接生成，不依赖旧截图。预览不在usable目录，制作源重建时生成的preview需要单独归类，不能自动导入。

## 原音效

7条WAV来源为 `Gankkiii/ball_art_review@e626fb7753205258a42d67a201f1baa29d5e2476` 的对应 `docs/audio/` 文件，与旧交付选用音效逐字相同。原来源说明称程序合成、无第三方采样；其旧合成源码当前未找回，本版不冒称这些源码已补齐或可重新合成完全相同音频。音效映射见接入清单。

## 公开与未分发内容

用户授权将本版交付上传公开balls仓库。包内不含私人截图、凭据、密钥、签名、内部角色配置或字体二进制。审核预览只显示本轮实际素材与示意数据。游戏基线为 `190eb33f1acfc107c433c0155170c0046927d4c1`，本轮只增加和更新交付文档/素材，不修改游戏代码或团队规则。
