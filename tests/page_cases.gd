extends RefCounted
## Tests the current interface prototype, not an unimplemented breeding system.
var host
var start_checks := 0

func ck(ok: bool, message: String) -> void:
	host.check(ok, "P " + message)

func has_text(node: Node, fragment: String) -> bool:
	if node is Label and (node as Label).text.contains(fragment): return true
	for child in node.get_children():
		if has_text(child, fragment): return true
	return false

func options_in(node: Node, out: Array) -> void:
	if node is OptionButton: out.append(node)
	for child in node.get_children(): options_in(child, out)

func run(runner) -> void:
	host = runner
	start_checks = host.checks
	ck(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/main.tscn", "P01 direct arena launch")
	ck(not ResourceLoader.exists("res://scenes/showcase.tscn"), "P02 obsolete showcase is absent")
	var main = load("res://scenes/main.tscn").instantiate()
	host.root.add_child(main)
	main.set_process(false)
	var pages = null
	for node in main.get_children():
		if node is CanvasLayer and node.get_script() == load("res://scripts/game_pages.gd"):
			pages = node
	ck(pages != null, "P03 page controller created")
	if pages == null:
		main.free()
		return
	ck(pages.tabs.size() == 4, "P04 four navigation entries")
	ck(pages.page == 0 and not pages.body.visible, "P05 initial arena visible")
	ck(main.arena.roster.size() == 2 and main.arena.roster[0] != main.arena.roster[1], "P06 arena random pair distinct")
	main.set_rate(2)
	pages.tabs[1].pressed.emit()
	ck(pages.page == 1 and pages.body.visible and has_text(pages.body, "主线"), "P07 story entry and placeholder")
	ck(main.rate == 0, "P08 leaving arena pauses combat")
	var time_before: float = main.arena.simulation_time
	main.advance_real_time(2.0)
	ck(main.arena.simulation_time == time_before, "P09 combat remains frozen on another page")
	pages.tabs[2].pressed.emit()
	ck(pages.page == 2 and pages.list.item_count == pages.samples.size(), "P10 storage lists every sample individual")
	ck(has_text(pages.body, "示例与已孵精灵"), "P11 storage labels sample data")
	ck(pages.samples.size() == 20, "P12 sample roster count")
	for i in pages.samples.size():
		var c: Dictionary = pages.samples[i]
		ck(c.sex in [0, 1] and c.level == 0 and c.innate.size() == 6 and c.training.size() == 6 and c.ranks.size() == 2, "P13 sample shape %d" % i)
		for value in c.innate: ck(value >= 1 and value <= 50, "P14 innate range")
		for value in c.training: ck(value == 0, "P15 sample training zero")
	pages.list.item_selected.emit(3)
	ck(pages.selected == 3 and has_text(pages.detail, pages.creature_title(pages.samples[3])), "P16 selecting a different individual updates detail")
	for field in ["特性", "技能 1", "技能 2", "种族基础", "先天", "后天", "最终", "生命", "攻击", "防御", "速度", "重量", "大小", "待定"]:
		ck(has_text(pages.detail, field), "P17 storage detail field " + field)
	pages.tabs[3].pressed.emit()
	ck(pages.page == 3 and has_text(pages.body, "后代保存到本机"), "P18 breeding prototype label")
	ck(has_text(pages.detail, "请选择一只母精灵和一只公精灵"), "P19 missing parents guidance")
	var selects: Array = []
	options_in(pages.body, selects)
	ck(selects.size() == 2, "P20 both parent selectors present")
	if selects.size() == 2:
		var m: OptionButton = selects[0]; var f: OptionButton = selects[1]
		ck(m.get_item_id(0) == -1 and f.get_item_id(0) == -1, "P21 default parent selection blank")
		for i in range(1, m.item_count): ck(pages.samples[m.get_item_id(i)].sex == 0, "P22 mother choices female")
		for i in range(1, f.item_count): ck(pages.samples[f.get_item_id(i)].sex == 1, "P23 father choices male")
		m.select(1); m.item_selected.emit(1)
		ck(pages.mother == m.get_item_id(1) and has_text(pages.detail, "请选择"), "P24 one parent cannot produce preview")
		f.select(2); f.item_selected.emit(2)
		ck(pages.father == f.get_item_id(2), "P25 cross-species father selection")
		var mom: Dictionary = pages.samples[pages.mother]
		var dad: Dictionary = pages.samples[pages.father]
		ck(mom.species != dad.species and has_text(pages.detail, pages.NAMES[mom.species]), "P26 child species follows mother")
		ck(has_text(pages.detail, "特性：跟随母亲") and has_text(pages.detail, "初始等级：0"), "P27 mother trait and newborn level")
		for i in 6:
			var lo := mini(mom.innate[i], dad.innate[i]); var hi := maxi(mom.innate[i], dad.innate[i])
			ck(has_text(pages.detail, "%s  %d～%d" % [pages.STATS[i], lo, hi]), "P28 parental interval %d" % i)
		ck(has_text(pages.detail, "不与技能 1 相同") and has_text(pages.detail, "+1～+9"), "P29 second skill rules")
		ck(has_text(pages.detail, "孵蛋后保存到本机"), "P30 hatching save notice shown")
		m.select(0); m.item_selected.emit(0)
		ck(pages.mother == -1 and has_text(pages.detail, "请选择"), "P30a clearing mother clears preview")
		m.select(1); m.item_selected.emit(1)
		f.select(0); f.item_selected.emit(0)
		ck(pages.father == -1 and has_text(pages.detail, "请选择"), "P30b clearing father clears preview")
		f.select(2); f.item_selected.emit(2)
		var tied: Array = []
		options_in(pages.detail, tied)
		ck(tied.size() == 1, "P31 equal mother skills offer choice")
		if tied.size() == 1:
			tied[0].select(1); tied[0].item_selected.emit(1)
			ck(pages.tie_choice == 1 and has_text(pages.detail, pages.SKILLS[mom.species][1]), "P32 tied choice updates preview")
		var mother_id: int = pages.mother
		var father_id: int = pages.father
		pages.tabs[2].pressed.emit()
		ck(pages.list.item_count == 20 and pages.selected == 3, "P33 return retains selected storage individual")
		pages.tabs[3].pressed.emit()
		ck(pages.mother == mother_id and pages.father == father_id, "P34 parent selections retained")
	pages.tabs[0].pressed.emit()
	ck(pages.page == 0 and not pages.body.visible and main.rate == 0, "P35 return arena remains paused")
	main.set_rate(1)
	main.advance_real_time(1.0 / 60.0)
	ck(main.arena.simulation_time > time_before, "P36 battle can resume")
	main.free()
	print("PAGE CASES checks=%d" % (host.checks - start_checks))
