extends RefCounted
## Exercises real hatch/save behavior with a unique, isolated test save.
var host
var check_start := 0

func ck(ok: bool, msg: String) -> void:
	host.check(ok, "H " + msg)

func find_page(scene: Node):
	for node in scene.get_children():
		if node is CanvasLayer and node.get_script() == load("res://scripts/game_pages.gd"): return node
	return null

func find_button(node: Node, caption: String):
	if node is Button and node.text == caption: return node
	for child in node.get_children():
		var result = find_button(child, caption)
		if result != null: return result
	return null

func new_game(path: String):
	var game = load("res://scenes/main.tscn").instantiate()
	game.page_save_path_override = path
	host.root.add_child(game)
	game.set_process(false)
	return game

func seed_for_breakthrough(required: bool, low: int = 5, high: int = 7) -> int:
	var probe := RandomNumberGenerator.new()
	for n in 10000:
		probe.seed = n
		probe.randi_range(0, 3)
		probe.randi_range(low, high)
		if (probe.randf() < 0.01) == required: return n
	return -1

func run(runner) -> void:
	host = runner
	check_start = host.checks
	var path := "user://hatch_test_%d_%d.jsonl" % [OS.get_process_id(), Time.get_ticks_usec()]
	ck(not FileAccess.file_exists(path), "isolated test file is new")
	var game = new_game(path)
	var p = find_page(game)
	ck(p != null and p.samples.size() == 20, "fresh isolated roster has samples only")
	if p == null:
		game.free(); return
	var initial = p.samples.duplicate(true)
	p.hatch_creature()
	ck(p.samples.size() == 20 and not FileAccess.file_exists(path), "no parents no hatch")
	p.mother = 0; p.father = -1
	p.hatch_creature()
	ck(p.samples.size() == 20, "one parent no hatch")
	p.father = 2
	p.hatch_creature()
	ck(p.samples.size() == 20, "same sex parents rejected")
	p.father = 3
	p.samples[0].trait = "测试母亲特性"
	p.samples[0].skills = [4, 2]; p.samples[0].ranks = [7, 3]
	p.samples[0].level = 80; p.samples[0].training = [10,20,30,40,50,50]
	p.samples[0].innate = [1,50,12,48,25,33]
	p.samples[3].trait = "测试父亲特性"
	p.samples[3].skills = [1, 0]; p.samples[3].ranks = [2, 5]
	p.samples[3].level = 50; p.samples[3].training = [1,2,3,4,5,6]
	p.samples[3].innate = [50,1,12,30,26,20]
	var mother: Dictionary = p.samples[0].duplicate(true)
	var father: Dictionary = p.samples[3].duplicate(true)
	p.switch_page(3)
	var hatch = find_button(p.detail, "确认孵蛋")
	ck(hatch != null, "real hatch button exists")
	if hatch != null: hatch.pressed.emit()
	var confirmation = null
	for node in p.root.get_children():
		if node is ConfirmationDialog and not node.is_queued_for_deletion(): confirmation = node
	ck(confirmation != null and p.samples.size() == 20, "confirm screen opens before actual hatch")
	if confirmation != null: confirmation.confirmed.emit()
	ck(p.samples.size() == 21 and p.selected == 20, "button adds and selects exactly one child")
	if p.samples.size() != 21:
		game.free(); return
	var child: Dictionary = p.samples[20].duplicate(true)
	ck(child.species == mother.species and child.trait == mother.trait, "child gets maternal species and trait")
	ck(child.sex in [0,1] and child.level == 0 and child.training == [0,0,0,0,0,0], "newborn fields reset")
	ck(child.skills[0] == 4 and child.skills[0] != child.skills[1] and child.skills[1] in [0,1,2,3], "higher maternal skill inherited and other skill differs")
	ck(child.ranks[0] >= 5 and child.ranks[0] <= 8 and child.ranks[1] >= 1 and child.ranks[1] <= 9, "first rank range and possible temporary breakthrough; second rank 1 to 9")
	for i in 6:
		ck(child.innate[i] >= mini(mother.innate[i], father.innate[i]) and child.innate[i] <= maxi(mother.innate[i], father.innate[i]), "inclusive innate interval %d" % i)
	ck(child.innate[2] == 12, "equal parental stat stays equal")
	ck(p.samples[0] == mother and p.samples[3] == father, "hatch leaves both parents unchanged")
	ck(FileAccess.file_exists(path), "hatch writes isolated save")
	p.switch_page(2)
	ck(p.list.item_count == 21 and p.selected == 20, "hatchling appears in storage and is selected")
	p.switch_page(3)
	p.samples[0].ranks = [4, 4]
	for choice in [0,1]:
		p.tie_choice = choice
		p.hatch_creature()
		ck(p.samples.back().skills[0] == p.samples[0].skills[choice], "tied mother choice %d" % choice)
	p.samples[0].ranks = [2,7]
	p.hatch_creature()
	ck(p.samples.back().skills[0] == p.samples[0].skills[1], "higher second maternal skill chosen")
	p.samples[0].innate = [1,50,1,50,1,50]
	p.samples[3].innate = [1,50,1,50,1,50]
	p.samples[0].ranks = [7,3]; p.samples[3].ranks = [5,2]
	var forced_seed := seed_for_breakthrough(true)
	var normal_seed := seed_for_breakthrough(false)
	ck(forced_seed >= 0 and normal_seed >= 0, "deterministic seeds for breakthrough and no breakthrough")
	if forced_seed >= 0 and normal_seed >= 0:
		p.rng.seed = normal_seed; p.hatch_creature()
		ck(p.samples.back().ranks[0] >= 5 and p.samples.back().ranks[0] <= 7, "non-breakthrough rank within parents")
		p.rng.seed = forced_seed; p.hatch_creature()
		ck(p.samples.back().ranks[0] == 8, "breakthrough exceeds higher parent by one")
		ck(p.samples.back().innate == [1,50,1,50,1,50], "matching minimum and maximum stats inherited exactly")
	p.samples[0].ranks = [10,3]; p.samples[3].ranks = [10,2]
	for i in 12:
		p.hatch_creature()
		ck(p.samples.back().ranks[0] == 10 and p.samples.back().ranks[1] <= 9, "rank cap and second rank bounds")
	p.samples[0].ranks = [9,3]; p.samples[3].ranks = [9,2]
	var seed_nine := seed_for_breakthrough(true, 9, 9)
	ck(seed_nine >= 0, "seed found for temporary 9 to 10 breakthrough")
	if seed_nine >= 0:
		p.rng.seed = seed_nine; p.hatch_creature()
		ck(p.samples.back().ranks[0] == 10, "temporary breakthrough can produce plus ten")
	p.rng.seed = 34561
	var genders := {}; var selected_skills := {}
	for i in 100:
		p.hatch_creature()
		genders[p.samples.back().sex] = true
		selected_skills[p.samples.back().skills[1]] = true
	ck(genders.size() == 2, "fixed-seed sample generates both genders")
	ck(selected_skills.size() == 4, "fixed-seed sample reaches all four distinct candidate skills")
	var dist: Array = [0,0,0,0,0,0,0,0,0,0]
	p.rng.seed = 49051
	for i in 45000: dist[p.random_skill_rank()] += 1
	for rank in range(1,10):
		var expected_count := (10 - rank) * 1000
		ck(abs(dist[rank] - expected_count) < expected_count * 0.25, "temporary second-rank weights %d" % rank)
	# Reject malformed records before they become runtime creatures.
	var malformed: Dictionary = child.duplicate(true)
	malformed.level = -1
	ck(not p.valid_hatchling(malformed), "invalid negative level rejected")
	malformed = child.duplicate(true); malformed.skills = [0.1,0.9]
	ck(not p.valid_hatchling(malformed), "fractional skill identifiers rejected")
	malformed = child.duplicate(true); malformed.training = [100,100,100,0,0,0]
	ck(not p.valid_hatchling(malformed), "training above total cap rejected")
	malformed = child.duplicate(true); malformed.level = "bad"
	ck(not p.valid_hatchling(malformed), "nonnumeric level rejected")
	var expected: Array = p.samples.slice(20).duplicate(true)
	game.free()
	game = new_game(path)
	p = find_page(game)
	ck(p.samples.size() == 20 + expected.size(), "reopening restores all children once")
	if p.samples.size() == 20 + expected.size():
		for i in expected.size(): ck(p.samples[20+i] == expected[i], "saved fields round trip %d" % i)
	if p.samples.size() > 20:
		var index := -1
		for i in range(20, p.samples.size()):
			if p.samples[i].sex == 1: index = i; break
		if index < 0: index = 1
		p.mother = 0; p.father = index; p.switch_page(3)
		var before: int = p.samples.size()
		p.hatch_creature()
		ck(p.samples.size() == before + 1, "subsequent hatching works after reopen")
	var count_before: int = p.samples.size()
	var selected_before: int = p.selected
	p.save_path = "user://nonexistent_test_dir_%d/child.jsonl" % OS.get_process_id()
	p.hatch_creature()
	ck(p.samples.size() == count_before and p.selected == selected_before and p.hatch_notice.contains("保存失败"), "failed write does not report or add child")
	game.free()
	# A complete JSON record may be left without its final newline after interruption.
	# Appending a later hatch must not corrupt that earlier valid record.
	var frag_path := "user://hatch_fragment_%d_%d.jsonl" % [OS.get_process_id(), Time.get_ticks_usec()]
	var fragment := FileAccess.open(frag_path, FileAccess.WRITE)
	fragment.store_string(JSON.stringify(child)); fragment.close()
	game = new_game(frag_path); p = find_page(game)
	ck(p.samples.size() == 21, "valid final record loads without trailing newline")
	p.mother = 0; p.father = 1; p.switch_page(3); p.hatch_creature()
	ck(p.samples.size() == 22, "hatch after newline-free record succeeds in memory")
	game.free()
	game = new_game(frag_path); p = find_page(game)
	ck(p.samples.size() == 22, "earlier and new records survive reload after missing newline")
	game.free()
	# An interrupted partial final JSON record must not hide preceding or later valid records.
	fragment = FileAccess.open(frag_path, FileAccess.WRITE)
	fragment.store_line(JSON.stringify(child)); fragment.store_string("{\"species\":")
	fragment.close()
	game = new_game(frag_path); p = find_page(game)
	ck(p.samples.size() == 21, "bad final record is skipped without losing preceding valid child")
	p.mother = 0; p.father = 1; p.switch_page(3); p.hatch_creature()
	game.free()
	game = new_game(frag_path); p = find_page(game)
	ck(p.samples.size() == 22, "new valid child survives append after truncated record")
	game.free()
	if FileAccess.file_exists(frag_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(frag_path))
	var abs_path := ProjectSettings.globalize_path(path)
	ck(FileAccess.file_exists(path), "only dedicated test file removed")
	if FileAccess.file_exists(path): DirAccess.remove_absolute(abs_path)
	ck(not FileAccess.file_exists(path), "isolated test file cleaned")
	print("HATCH CASES checks=%d" % (host.checks - check_start))
