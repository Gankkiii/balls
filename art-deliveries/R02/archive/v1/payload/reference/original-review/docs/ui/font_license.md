# R02 字体来源与授权核验

核验日期：2026-11-03。仅本地概念绘制；本目录未复制、子集化或分发字体二进制。

## 实际使用

- 文件：`/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc`
- Debian 包：`fonts-noto-cjk 1:20240730+repack1-1`
- 实际 face：**Noto Sans CJK SC，TTC index 2**；已通过 fontTools 读取 name 表确认。R01 脚本使用默认 face 0（JP），本轮改为简体中文 face，避免不同地区字形的无意混用。
- 文件 SHA-256：`b76b0433203017ca80401b2ee0dd69350349871c4b19d504c34dbdd80541690a`
- 文字直接在2倍输出分辨率以 TrueType 抗锯齿绘制，不把中文压成低分辨率位图再放大。像素风由图标、角色和边框承担。

## 证据

1. 本机 `/usr/share/doc/fonts-noto-cjk/copyright` 将字体文件列在 `Files: *` 下，标明 `Copyright: 2010-2012, Google Corporation` 与 `License: SIL-1.1`；Debian 打包脚本单列 GPL，不能把它误认为字体许可证。相关原文摘录保存在 `font_license_evidence.txt`。
2. 官方上游 [Noto CJK Sans LICENSE](https://github.com/notofonts/noto-cjk/blob/main/Sans/LICENSE) 于本轮通过网页读取，声明 SIL Open Font License 1.1。许可支持使用、嵌入与满足条件的再分发；以字体生成的图片/文档不因此必须使用 OFL。
3. 本轮只交付渲染 PNG 与生成源码。源码引用环境字体路径，未把系统字体夹带进交付。

## 后续接入限制与未知项

- Godot 若需打包字体，应从可追溯官方字体发布取得所需文件，并随字体保留相应版权与 OFL 文本；不要只带本说明替代许可证全文。
- 若修改/转换/子集化字体，需要重新核查 OFL 保留名称和分发要求；本轮未做这些操作。
- 尚未校验本机二进制与某个上游发布包逐字节一致，证据链为本机包元数据、字体 name 表与上游许可证，不声称已做供应链审计。
- 本轮只检查所用字符字形覆盖与离线图片；Godot 字体导入、设备栅格化、动态字号、系统辅助功能与 Android/iPhone 真机均未验证。
