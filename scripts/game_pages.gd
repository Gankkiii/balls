extends CanvasLayer
## Navigation, sample collection, and locally saved hatchlings.
const NAMES := ["充气球", "炸弹母鸡", "泡泡鱼", "触电羊", "磁铁蟹", "倒霉鸭", "锻造兔", "仙人掌", "脱壳乌龟", "乌鸦"]
const IDS := ["puffer", "chicken", "bubble_fish", "electric_sheep", "magnet_crab", "duck", "rabbit", "cactus", "shell_turtle", "crow"]
const SKILLS := [["充气", "吸收"], ["乱跑", "大炸弹"], ["吸附泡泡", "八方泡泡"], ["转向墙壁", "放置羊毛"], ["磁力墙", "铁钉弹射"], ["调整雷表", "避雷针"], ["现场锻造", "淬火"], ["撒刺", "换地方生长"], ["躲进壳中", "旋转龟壳"], ["交换位置", "储存羽毛"]]
const TRAITS := ["特性一（待设计）", "特性二（待设计）", "特性三（待设计）"]
const SAVE_PATH := "user://balls_hatchlings_v1.jsonl"
const STATS := ["生命", "攻击", "防御", "速度", "重量", "大小"]
var game: Control
var page := 0
var samples: Array[Dictionary] = []
var selected := 0
var mother := -1
var father := -1
var tie_choice := 0
var rng := RandomNumberGenerator.new()
var hatch_notice := ""
var root: Control
var body: Control
var detail: Control
var list: ItemList
var tabs: Array[Button] = []
var font: Font

func _ready() -> void:
	layer = 10
	font = load("res://assets/arena-ui.otf")
	rng.randomize()
	make_samples()
	load_hatchlings()
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	body = Control.new()
	body.position = Vector2(0, 68)
	body.size = Vector2(1100, 712)
	body.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(body)
	for i in 4:
		var b := Button.new()
		b.text = ["竞技场", "主线", "仓库", "孵蛋"][i]
		b.position = Vector2(430 + i * 151, 15)
		b.size = Vector2(140, 44)
		style_button(b)
		b.pressed.connect(switch_page.bind(i))
		root.add_child(b)
		tabs.append(b)
	switch_page(0)

func make_samples() -> void:
	# Temporary, deterministic examples: no captured creatures or final balance values.
	for i in 10:
		for sex in 2:
			var values: Array = []
			for k in 6:
				values.append(8 + ((i * 13 + sex * 19 + k * 7) % 43))
			samples.append({"species": i, "sex": sex, "level": 0, "trait": TRAITS[0], "skills": [0,1], "innate": values, "training": [0,0,0,0,0,0], "ranks": [1 + (i + sex) % 5, 1 + (i * 2 + sex) % 5]})

func style_button(b: Button) -> void:
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", Color("243746"))
	for state in ["normal", "hover", "pressed", "disabled"]:
		var s := StyleBoxTexture.new()
		s.texture = load("res://assets/r04/ui/retained/r02/button_" + state + ".png")
		s.texture_margin_left = 12; s.texture_margin_right = 12
		s.texture_margin_top = 12; s.texture_margin_bottom = 12
		b.add_theme_stylebox_override(state, s)

func switch_page(index: int) -> void:
	if index != 0 and page == 0:
		game.set_rate(0)
		game.stop_sounds()
	page = index
	for i in tabs.size(): tabs[i].modulate = Color("89dbc4") if i == page else Color.WHITE
	body.visible = page != 0
	clear_node(body)
	if page == 1: build_story()
	elif page == 2: build_storage()
	elif page == 3: build_breeding()

func clear_node(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func background() -> void:
	var rect := TextureRect.new()
	rect.texture = load("res://assets/r04/ui/environment/screen_surround.png")
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.size = Vector2(1100, 712)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(rect)

func panel(at: Vector2, size_value: Vector2, parent: Control = body) -> Panel:
	var p := Panel.new()
	p.position = at; p.size = size_value
	var s := StyleBoxFlat.new()
	s.bg_color = Color("f4ead5")
	s.border_color = Color("815a43")
	s.set_border_width_all(3); s.set_corner_radius_all(8)
	p.add_theme_stylebox_override("panel", s)
	parent.add_child(p)
	return p

func text_label(parent: Control, value: String, at: Vector2, size_value: Vector2, font_size: int = 19) -> Label:
	var l := Label.new()
	l.text = value; l.position = at; l.size = size_value
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color("243746"))
	parent.add_child(l)
	return l

func button(parent: Control, caption: String, at: Vector2, size_value: Vector2) -> Button:
	var b := Button.new()
	b.text = caption; b.position = at; b.size = size_value
	style_button(b); parent.add_child(b)
	return b

func portrait_path(species: int) -> String:
	var path: String = "res://assets/r04/characters/" + IDS[species] + "/idle.png"
	if species == 5 or species == 6:
		path = "res://assets/r02/characters/" + IDS[species] + "/default.png"
	return path

func portrait(parent: Control, species: int, at: Vector2, size_value: Vector2) -> void:
	var image := TextureRect.new()
	image.texture = load(portrait_path(species))
	image.position = at; image.size = size_value
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(image)

func creature_title(c: Dictionary) -> String:
	return "%s  %s  Lv.%d%s" % [NAMES[c.species], "♀" if c.sex == 0 else "♂", c.level, ("  #%d" % c.number) if c.has("number") else ""]

func build_story() -> void:
	background()
	var p := panel(Vector2(105, 85), Vector2(890, 500))
	text_label(p, "主线", Vector2(35, 25), Vector2(500, 50), 30)
	text_label(p, "这里先留空，主线玩法以后再设计。", Vector2(35, 105), Vector2(800, 50), 21)

func build_storage() -> void:
	background()
	var left := panel(Vector2(28, 18), Vector2(390, 670))
	text_label(left, "精灵仓库", Vector2(22, 13), Vector2(250, 35), 26)
	text_label(left, "示例与已孵精灵 · 本机保存", Vector2(22, 53), Vector2(340, 30), 15)
	list = ItemList.new()
	list.position = Vector2(18, 90); list.size = Vector2(354, 555)
	list.add_theme_font_override("font", font); list.add_theme_font_size_override("font_size", 19)
	for c in samples: list.add_item(creature_title(c), load(portrait_path(c.species)))
	list.fixed_icon_size = Vector2i(36, 36)
	list.item_selected.connect(storage_selected)
	left.add_child(list)
	list.select(selected)
	detail = panel(Vector2(436, 18), Vector2(636, 670))
	show_detail()

func storage_selected(index: int) -> void:
	selected = index
	show_detail()

func skill_name(species: int, slot: int) -> String:
	if slot < 2: return SKILLS[species][slot]
	return "技能%d（待设计）" % (slot + 1)

func show_detail() -> void:
	clear_node(detail)
	var c: Dictionary = samples[selected]
	portrait(detail, c.species, Vector2(24, 16), Vector2(115, 115))
	text_label(detail, creature_title(c), Vector2(155, 16), Vector2(450, 40), 23)
	text_label(detail, "特性：" + c.trait, Vector2(155, 56), Vector2(460, 30), 17)
	var other_traits: Array[String] = []
	for trait_name in TRAITS:
		if trait_name != c.trait: other_traits.append(trait_name)
	text_label(detail, "其他特性：" + " / ".join(other_traits), Vector2(155, 94), Vector2(465, 28), 14)
	text_label(detail, "技能 1：%s  +%d" % [skill_name(c.species, c.skills[0]), c.ranks[0]], Vector2(24, 146), Vector2(570, 30), 18)
	text_label(detail, "技能 2：%s  +%d" % [skill_name(c.species, c.skills[1]), c.ranks[1]], Vector2(24, 179), Vector2(570, 30), 18)
	var other_skills: Array[String] = []
	for slot in 5:
		if slot not in c.skills: other_skills.append(skill_name(c.species, slot))
	text_label(detail, "其他技能：" + " / ".join(other_skills), Vector2(24, 217), Vector2(590, 30), 15)
	text_label(detail, "属性          种族基础     先天     后天     最终", Vector2(24, 267), Vector2(570, 30), 18)
	for i in 6:
		text_label(detail, "%s                待定           %d          %d         待定" % [STATS[i], c.innate[i], c.training[i]], Vector2(26, 306 + i * 43), Vector2(570, 35), 18)
	text_label(detail, "未设计的特性、技能及基础数值仅为占位", Vector2(24, 608), Vector2(580, 30), 15)

func build_breeding() -> void:
	background()
	var p := panel(Vector2(35, 18), Vector2(1030, 670))
	text_label(p, "孵蛋 · 亲本选择", Vector2(25, 14), Vector2(500, 40), 26)
	text_label(p, "后代保存到本机 · 数值暂定", Vector2(650, 23), Vector2(340, 28), 15)
	var m := OptionButton.new(); var f := OptionButton.new()
	m.position = Vector2(25, 90); m.size = Vector2(445, 48)
	f.position = Vector2(555, 90); f.size = Vector2(445, 48)
	for x in [m, f]:
		x.add_theme_font_override("font", font); x.add_theme_font_size_override("font_size", 18)
	p.add_child(m); p.add_child(f)
	m.add_item("选择母亲 ♀"); f.add_item("选择父亲 ♂")
	m.set_item_id(0, -1); f.set_item_id(0, -1)
	for i in samples.size():
		if samples[i].sex == 0: m.add_item(creature_title(samples[i]), i)
		else: f.add_item(creature_title(samples[i]), i)
	m.select(0); f.select(0)
	for i in range(1, m.item_count):
		if m.get_item_id(i) == mother: m.select(i)
	for i in range(1, f.item_count):
		if f.get_item_id(i) == father: f.select(i)
	m.item_selected.connect(func(index: int): mother = m.get_item_id(index); refresh_breeding_preview())
	f.item_selected.connect(func(index: int): father = f.get_item_id(index); refresh_breeding_preview())
	detail = Control.new(); detail.position = Vector2(25, 160); detail.size = Vector2(980, 470); p.add_child(detail)
	refresh_breeding_preview()

func refresh_breeding_preview() -> void:
	clear_node(detail)
	if mother < 0 or father < 0:
		text_label(detail, "请选择一只母精灵和一只公精灵。", Vector2(0, 15), Vector2(900, 40), 20)
		text_label(detail, "后代种类和特性跟随母亲，先天值在父母之间随机。", Vector2(0, 65), Vector2(950, 40), 19)
		text_label(detail, "请选择亲本后开始孵蛋。", Vector2(0, 115), Vector2(900, 40), 19)
		return
	var mom: Dictionary = samples[mother]; var dad: Dictionary = samples[father]
	var ranks: Array = mom.ranks
	var highest := maxi(ranks[0], ranks[1])
	var skill: String = skill_name(mom.species, mom.skills[0]) if ranks[0] > ranks[1] else skill_name(mom.species, mom.skills[1])
	if ranks[0] == ranks[1]: skill = skill_name(mom.species, mom.skills[tie_choice])
	text_label(detail, "后代：%s    特性：跟随母亲    初始等级：0" % NAMES[mom.species], Vector2(0, 0), Vector2(960, 38), 20)
	text_label(detail, "技能 1：%s  （母亲最高 +%d）" % [skill, highest], Vector2(0, 47), Vector2(960, 35), 19)
	if ranks[0] == ranks[1]:
		var choice := OptionButton.new()
		choice.position = Vector2(610, 43); choice.size = Vector2(310, 38)
		choice.add_theme_font_override("font", font); choice.add_theme_font_size_override("font_size", 16)
		choice.add_item(skill_name(mom.species, mom.skills[0])); choice.add_item(skill_name(mom.species, mom.skills[1])); choice.select(tie_choice)
		choice.item_selected.connect(func(i: int): tie_choice = i; refresh_breeding_preview())
		detail.add_child(choice)
	text_label(detail, "等级：父母最高等级之间随机；1% 概率超过父母较高值一级（临时）", Vector2(0, 83), Vector2(970, 35), 17)
	text_label(detail, "技能 2：从母亲种族其余技能随机，不与技能 1 相同；+1～+9 递减概率", Vector2(0, 119), Vector2(970, 35), 17)
	text_label(detail, "先天值范围（含两端）：", Vector2(0, 170), Vector2(500, 30), 19)
	for i in 6:
		var lo := mini(mom.innate[i], dad.innate[i]); var hi := maxi(mom.innate[i], dad.innate[i])
		text_label(detail, "%s  %d～%d" % [STATS[i], lo, hi], Vector2((i % 3) * 280, 212 + int(i / 3) * 40), Vector2(260, 30), 18)
	text_label(detail, "后天值为 0；立即孵化。技能等级概率为临时方案。", Vector2(0, 315), Vector2(970, 35), 18)
	var hatch := button(detail, "孵蛋", Vector2(0, 360), Vector2(160, 50))
	hatch.pressed.connect(hatch_creature)
	text_label(detail, hatch_notice if not hatch_notice.is_empty() else "孵蛋后保存到本机", Vector2(180, 365), Vector2(770, 40), 17)


func random_skill_rank() -> int:
	# Temporary, strictly decreasing weights 9:8:...:1 for +1 ... +9.
	var ticket := rng.randi_range(1, 45)
	for rank in range(1, 10):
		ticket -= 10 - rank
		if ticket <= 0: return rank
	return 9

func hatch_creature() -> void:
	if mother < 0 or father < 0: return
	var mom: Dictionary = samples[mother]; var dad: Dictionary = samples[father]
	if mom.sex != 0 or dad.sex != 1: return
	var own_slot: int = 0 if mom.ranks[0] > mom.ranks[1] else 1
	if mom.ranks[0] == mom.ranks[1]: own_slot = tie_choice
	var first: int = mom.skills[own_slot]
	var candidates: Array[int] = []
	for index in 5:
		if index != first: candidates.append(index)
	var second: int = candidates[rng.randi_range(0, candidates.size() - 1)]
	var mom_best := maxi(mom.ranks[0], mom.ranks[1])
	var dad_best := maxi(dad.ranks[0], dad.ranks[1])
	var rank_one := rng.randi_range(mini(mom_best, dad_best), maxi(mom_best, dad_best))
	if maxi(mom_best, dad_best) < 10 and rng.randf() < 0.01: rank_one = maxi(mom_best, dad_best) + 1
	var inherited: Array = []
	for i in 6:
		inherited.append(rng.randi_range(mini(mom.innate[i], dad.innate[i]), maxi(mom.innate[i], dad.innate[i])))
	var child := {"species": mom.species, "sex": rng.randi_range(0, 1), "level": 0, "trait": mom.trait, "skills": [first, second], "ranks": [rank_one, random_skill_rank()], "innate": inherited, "training": [0,0,0,0,0,0], "number": samples.size() + 1}
	if not append_hatchling(child):
		hatch_notice = "保存失败，请检查设备存储空间。"
		refresh_breeding_preview()
		return
	samples.append(child)
	selected = samples.size() - 1
	hatch_notice = "已孵出：%s；可到仓库查看" % creature_title(child)
	refresh_breeding_preview()

func append_hatchling(child: Dictionary) -> bool:
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(SAVE_PATH) else FileAccess.WRITE
	var file := FileAccess.open(SAVE_PATH, mode)
	if file == null: return false
	file.seek_end()
	file.store_line(JSON.stringify(child))
	file.flush()
	var ok := file.get_error() == OK
	file.close()
	return ok

func load_hatchlings() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null: return
	while not file.eof_reached():
		var line := file.get_line()
		if line.is_empty(): continue
		var value: Variant = JSON.parse_string(line)
		if valid_hatchling(value):
			for key in ["species", "sex", "level"]: value[key] = int(value[key])
			if value.has("number"): value.number = int(value.number)
			for key in ["skills", "ranks", "innate", "training"]:
				for i in value[key].size(): value[key][i] = int(value[key][i])
			samples.append(value)
	file.close()

func valid_hatchling(value: Variant) -> bool:
	if not value is Dictionary: return false
	for key in ["species", "sex", "level", "trait", "skills", "ranks", "innate", "training"]:
		if not value.has(key): return false
	if not (value.species is int or value.species is float) or not (value.sex is int or value.sex is float): return false
	if int(value.species) < 0 or int(value.species) >= NAMES.size() or int(value.sex) not in [0, 1]: return false
	if not value.trait is String: return false
	for key in ["skills", "ranks", "innate", "training"]:
		if not value[key] is Array: return false
	if value.skills.size() != 2 or value.ranks.size() != 2 or value.innate.size() != 6 or value.training.size() != 6: return false
	for slot in value.skills:
		if not (slot is int or slot is float) or int(slot) < 0 or int(slot) >= 5: return false
	if value.skills[0] == value.skills[1]: return false
	for rank in value.ranks:
		if not (rank is int or rank is float) or int(rank) < 1 or int(rank) > 10: return false
	for stat in value.innate:
		if not (stat is int or stat is float) or int(stat) < 1 or int(stat) > 50: return false
	for stat in value.training:
		if not (stat is int or stat is float) or int(stat) < 0 or int(stat) > 100: return false
	return true
