# 独立资源检查复现

在新的临时Godot4.6.3项目中复制包根assets为res://assets；另将source/ui/components复制到res://assets/component_vectors。复制isolated_expected.json为res://expected.json，isolated_resource_check.gd.txt改名check.gd。运行Godot headless editor --import --quit后，以--script check.gd执行。原工程只用于测试资源load/尺寸/字符，不是游戏UI代码。实际日志在qa/RESOURCE_*_FINAL.txt。游戏原有回归命令见docs/INTEGRATION.md。

点击框实测工具：从包根HTTP服务本包（例如python3 -m http.server 8034），安装Python Playwright与/usr/bin/chromium后，执行`python3 source/qa/capture_hit_regions.py http://127.0.0.1:8034`。输出metadata/hit_regions.json。此脚本只读取浏览器参考布局，不能代替Godot/手机触控验收。
