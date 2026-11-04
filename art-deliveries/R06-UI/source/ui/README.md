# R06 组件制作源

`source/export_components.py`从`source/input_scenes/`内的原SVG节点导出14项组件，`source/input_css/`保留CSS原参数。

在复制出的制作目录运行`python3 source/export_components.py`，输出到该目录的`png/`、`svg/`、`metadata/components.json`。需要Python/Pillow/Inkscape，不依赖游戏；现存导出逐字复现记录在validation.json。交付用PNG对应包根assets/ui/，可编辑SVG另对应source/ui/components/。不要覆盖游戏资源或用整页截图裁片。
