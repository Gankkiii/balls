extends CanvasLayer
## Navigation, sample collection, and locally saved hatchlings.
const NAMES := ["充气球", "炸弹母鸡", "泡泡鱼", "触电羊", "磁铁蟹", "倒霉鸭", "锻造兔", "仙人掌", "脱壳乌龟", "乌鸦"]
const IDS := ["puffer", "chicken", "bubble_fish", "electric_sheep", "magnet_crab", "duck", "rabbit", "cactus", "shell_turtle", "crow"]
const SKILLS := [["充气", "吸收"], ["乱跑", "大炸弹"], ["吸附泡泡", "八方泡泡"], ["转向墙壁", "放置羊毛"], ["磁力墙", "铁钉弹射"], ["调整雷表", "避雷针"], ["现场锻造", "淬火"], ["撒刺", "换地方生长"], ["躲进壳中", "旋转龟壳"], ["交换位置", "储存羽毛"]]
const TRAITS := ["特性一（待设计）", "特性二（待设计）", "特性三（待设计）"]
const SAVE_PATH := "user://balls_hatchlings_v1.jsonl"
const STATS := ["生命", "攻击", "防御", "速度", "重量", "大小"]
var game: Control
# Defaults to the real save; tests may supply an isolated path before the node enters the tree.
var save_path: String = SAVE_PATH
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
var font_bold: Font

func _ready() -> void:
	layer = 10
	font = load("res://assets/r06/fonts/regular.otf")
	font_bold = load("res://assets/r06/fonts/bold.otf")
	rng.randomize()
	make_samples()
	load_hatchlings()
	root = Control.new()
	var ui_theme := Theme.new()
	ui_theme.default_font = font
	ui_theme.default_font_size = 20
	root.theme = ui_theme
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	body = Control.new()
	body.position = Vector2(0, 92)
	body.size = Vector2(1600, 808)
	body.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(body)
	var header := ColorRect.new()
	header.color = Color("faf8ef"); header.size = Vector2(1600,92); header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(header)
	var brand := Label.new(); brand.text = "BALLS"; brand.position = Vector2(42,25); brand.add_theme_font_override("font",font); brand.add_theme_font_size_override("font_size",27); brand.add_theme_color_override("font_color",Color("293d40")); root.add_child(brand)
	for i in 4:
		var b := Button.new()
		b.text = ["竞技场", "主线", "仓库", "孵蛋"][i]
		b.position = Vector2(813 + i * 150, 18)
		b.size = Vector2(138, 54)
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
		var s := StyleBoxFlat.new()
		s.bg_color = Color("d7e9dc") if state == "pressed" else Color("faf8ef")
		s.border_color = Color("648d7b")
		s.set_border_width_all(2)
		if state == "disabled": s.bg_color = Color("deded5")
		b.add_theme_stylebox_override(state, s)

func switch_page(index: int) -> void:
	if index != 0 and page == 0:
		if game.visual.info_open: game.toggle_info()
		game.set_rate(0)
		game.stop_sounds()
	page = index
	for i in tabs.size(): tabs[i].modulate = Color("c2e5cb") if i == page else Color.WHITE
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
	var rect := ColorRect.new()
	rect.color = Color("f2f0e5") if page == 2 else (Color("f8eccd") if page == 3 else Color("dfe9e0"))
	rect.size = Vector2(1600,808)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(rect)

func panel(at: Vector2, size_value: Vector2, parent: Control = body) -> Panel:
	var p := Panel.new()
	p.position = at; p.size = size_value
	var s := StyleBoxFlat.new()
	s.bg_color = Color("fcfaf2")
	s.border_color = Color("bac7b8")
	s.set_border_width_all(2); s.set_corner_radius_all(8)
	p.add_theme_stylebox_override("panel", s)
	parent.add_child(p)
	return p

func text_label(parent: Control, value: String, at: Vector2, size_value: Vector2, font_size: int = 19) -> Label:
	var l := Label.new()
	l.text = value; l.position = at; l.size = size_value
	l.add_theme_font_override("font", font_bold if font_size >= 23 else font)
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
	var left := panel(Vector2(30,30),Vector2(418,670))
	text_label(left,"主线 · 旅程档案",Vector2(25,18),Vector2(350,48),30)
	var query := LineEdit.new()
	query.position = Vector2(25,78); query.size = Vector2(360,58)
	query.placeholder_text = "地点 / 章节"
	query.add_theme_font_override("font",font)
	query.add_theme_font_size_override("font_size",22)
	left.add_child(query)
	var entries := VBoxContainer.new()
	entries.position = Vector2(40,155); entries.size = Vector2(330,440)
	left.add_child(entries)
	var stage := panel(Vector2(474,30),Vector2(1096,670))
	var title := text_label(stage,"地点 A",Vector2(40,475),Vector2(400,50),34)
	text_label(stage,"内容与玩法待定",Vector2(40,535),Vector2(500,40),22)
	var scene := ColorRect.new()
	scene.position = Vector2(17,17); scene.size = Vector2(1062,420); scene.color = Color("d6e4bf")
	scene.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(scene)
	var hills := ColorRect.new()
	hills.position = Vector2(0,165); hills.size = Vector2(1062,165); hills.color = Color("b4cda1")
	scene.add_child(hills)
	var ground := ColorRect.new()
	ground.position = Vector2(0,330); ground.size = Vector2(1062,90); ground.color = Color("80a991")
	scene.add_child(ground)
	# Deliberately simple placeholder shapes, not finished chapter art.
	var house := ColorRect.new()
	house.position = Vector2(650,165); house.size = Vector2(140,130); house.color = Color("e7d6a9")
	scene.add_child(house)
	var roof := ColorRect.new()
	roof.position = Vector2(640,150); roof.size = Vector2(160,22); roof.color = Color("9f7354")
	scene.add_child(roof)
	var door := ColorRect.new()
	door.position = Vector2(706,230); door.size = Vector2(30,65); door.color = Color("658b7d")
	scene.add_child(door)
	for tree_x in [100,910]:
		var trunk := ColorRect.new(); trunk.position = Vector2(tree_x+25,225); trunk.size = Vector2(14,70); trunk.color = Color("81664d"); scene.add_child(trunk)
		var leaves := ColorRect.new(); leaves.position = Vector2(tree_x,180); leaves.size = Vector2(65,65); leaves.color = Color("598c6d"); scene.add_child(leaves)
	portrait(scene,3,Vector2(350,120),Vector2(240,240))
	var tag := text_label(scene,"章节舞台 · 示意",Vector2(30,30),Vector2(400,40),24)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var view := button(stage,"查看档案",Vector2(720,475),Vector2(330,78))
	view.pressed.connect(func(): show_message("主线档案",title.text + "\n内容与玩法待定。"))
	var refresh := func():
		clear_node(entries)
		var count := 0
		for name in ["地点 A","地点 B","地点 C","地点 D"]:
			if not query.text.is_empty() and not name.contains(query.text): continue
			var entry := Button.new()
			entry.text = name + "  ·  结构条目"
			entry.custom_minimum_size = Vector2(330,70)
			style_button(entry)
			entry.pressed.connect(func(): title.text = name)
			entries.add_child(entry)
			count += 1
		if count == 0: text_label(entries,"没有匹配结果",Vector2.ZERO,Vector2(300,40),20)
	query.text_changed.connect(func(_value: String): refresh.call())
	refresh.call()

func build_storage() -> void:
	background()
	text_label(body,"精灵画廊",Vector2(35,25),Vector2(500,50),30)
	text_label(body,"示例与已孵精灵 · 本机保存",Vector2(35,65),Vector2(500,32),17)
	var prev := button(body,"‹",Vector2(1010,22),Vector2(50,48))
	var next := button(body,"›",Vector2(1440,22),Vector2(50,48))
	prev.disabled = selected <= 0
	next.disabled = selected >= samples.size()-1
	prev.pressed.connect(func(): storage_selected(selected-1); build_storage_again())
	next.pressed.connect(func(): storage_selected(selected+1); build_storage_again())
	var pick := OptionButton.new()
	pick.position = Vector2(1070,22); pick.size = Vector2(355,48)
	pick.add_theme_font_override("font",font); pick.add_theme_font_size_override("font_size",18)
	for c in samples: pick.add_item(creature_title(c))
	pick.select(selected)
	pick.item_selected.connect(func(i: int): storage_selected(i); build_storage_again())
	body.add_child(pick)
	list = ItemList.new()
	list.visible = false
	for c in samples: list.add_item(creature_title(c),load(portrait_path(c.species)))
	list.item_selected.connect(storage_selected)
	body.add_child(list)
	list.select(selected)
	var offsets := [-2,-1,0,1,2]
	for slot in 5:
		var idx: int = selected + offsets[slot]
		var big := slot == 2
		var x: float = [35,308,581,1035,1308][slot]
		var width: float = 435 if big else 256
		var top: float = 90 if big else 120
		var h: float = 250 if big else 190
		if idx < 0 or idx >= samples.size(): continue
		var card := panel(Vector2(x,top),Vector2(width,h))
		if big:
			var selected_style := StyleBoxFlat.new()
			selected_style.bg_color = Color("e4efdd"); selected_style.border_color = Color("7da184"); selected_style.set_border_width_all(3); selected_style.set_corner_radius_all(8)
			card.add_theme_stylebox_override("panel",selected_style)
		portrait(card,samples[idx].species,Vector2(width/2-65,12),Vector2(130,130))
		var name := text_label(card,creature_title(samples[idx]),Vector2(10,h-42),Vector2(width-20,35),20 if big else 17)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var click := Button.new(); click.flat = true; click.position = Vector2.ZERO; click.size = card.size
		click.tooltip_text = creature_title(samples[idx]); click.pressed.connect(func(): storage_selected(idx); build_storage_again())
		card.add_child(click)
	detail = panel(Vector2(35,365),Vector2(1530,430))
	show_detail()

func build_storage_again() -> void:
	clear_node(body)
	build_storage()

func storage_selected(index: int) -> void:
	if index < 0 or index >= samples.size(): return
	selected = index
	show_detail()

func skill_name(species: int, slot: int) -> String:
	if slot < 2: return SKILLS[species][slot]
	return "技能%d（待设计）" % (slot + 1)

func show_detail() -> void:
	if not is_instance_valid(detail): return
	clear_node(detail)
	var c: Dictionary = samples[selected]
	text_label(detail,creature_title(c),Vector2(25,12),Vector2(750,35),23)
	text_label(detail,"属性          种族基础          先天          后天          最终",Vector2(25,58),Vector2(800,35),20)
	for i in 6:
		text_label(detail,"%s                 待定               %d               %d              待定" % [STATS[i],c.innate[i],c.training[i]],Vector2(28,100+i*43),Vector2(800,36),20)
	text_label(detail,"特性："+c.trait,Vector2(900,22),Vector2(580,38),21)
	var other_traits: Array[String] = []
	for trait_name in TRAITS:
		if trait_name != c.trait: other_traits.append(trait_name)
	text_label(detail,"其他特性："+" / ".join(other_traits),Vector2(900,62),Vector2(590,35),16)
	text_label(detail,"技能 1：%s  +%d" % [skill_name(c.species,c.skills[0]),c.ranks[0]],Vector2(900,122),Vector2(590,36),20)
	text_label(detail,"技能 2：%s  +%d" % [skill_name(c.species,c.skills[1]),c.ranks[1]],Vector2(900,168),Vector2(590,36),20)
	var others: Array[String] = []
	for slot in 5:
		if slot not in c.skills: others.append(skill_name(c.species,slot))
	var extras := text_label(detail,"其他技能："+" / ".join(others),Vector2(900,220),Vector2(590,100),16)
	extras.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var info := button(detail,"属性说明",Vector2(680,12),Vector2(155,40))
	info.pressed.connect(func(): show_message("属性说明","种族基础与最终属性待设计。\n先天值来自个体；后天值来自后续培养。"))

func build_breeding() -> void:
	background()
	text_label(body,"孵蛋 · 遗传工作台",Vector2(40,24),Vector2(800,50),32)
	text_label(body,"后代保存到本机 · 数值暂定",Vector2(1100,30),Vector2(450,30),17)
	var mom_card := panel(Vector2(45,105),Vector2(430,305))
	var dad_card := panel(Vector2(1125,105),Vector2(430,305))
	parent_card(mom_card,true)
	parent_card(dad_card,false)
	detail = panel(Vector2(500,105),Vector2(600,635))
	refresh_breeding_preview()
	var pool := panel(Vector2(45,435),Vector2(430,305))
	text_label(pool,"母种族技能池",Vector2(22,20),Vector2(380,42),25)
	if mother >= 0:
		var c: Dictionary = samples[mother]
		for i in 5: text_label(pool,skill_name(c.species,i),Vector2(22,74+i*32),Vector2(380,30),18)
	else: text_label(pool,"请选择母亲",Vector2(22,80),Vector2(380,35),20)
	var rules := button(pool,"规则说明",Vector2(22,235),Vector2(385,50))
	rules.pressed.connect(func(): show_message("孵蛋规则","一公一母，后代种类和特性随母亲。\n先天值在父母区间内随机，后天值归零。\n技能强化概率为暂定方案。"))
	var ranges := panel(Vector2(1125,435),Vector2(430,305))
	text_label(ranges,"先天范围 · 每项独立随机",Vector2(22,20),Vector2(390,42),22)
	if mother >= 0 and father >= 0:
		for i in 6:
			var lo := mini(samples[mother].innate[i],samples[father].innate[i])
			var hi := maxi(samples[mother].innate[i],samples[father].innate[i])
			text_label(ranges,"%s  %d～%d" % [STATS[i],lo,hi],Vector2(22+(i%2)*190,75+int(i/2)*43),Vector2(185,35),20)
		text_label(ranges,"后天全 0 · 种族基础 / 最终待定",Vector2(22,225),Vector2(390,35),17)
	else: text_label(ranges,"请选择母亲和父亲",Vector2(22,85),Vector2(385,35),20)

func parent_card(card: Control, maternal: bool) -> void:
	var index := mother if maternal else father
	text_label(card,"母亲 ♀" if maternal else "父亲 ♂",Vector2(20,15),Vector2(320,35),22)
	if index >= 0:
		var c: Dictionary = samples[index]
		portrait(card,c.species,Vector2(20,58),Vector2(110,110))
		text_label(card,creature_title(c),Vector2(145,65),Vector2(275,65),21)
		text_label(card,"%s +%d / %s +%d" % [skill_name(c.species,c.skills[0]),c.ranks[0],skill_name(c.species,c.skills[1]),c.ranks[1]],Vector2(20,175),Vector2(390,40),17)
	else: text_label(card,"尚未选择",Vector2(30,90),Vector2(300,40),22)
	var choose := button(card,"更换母亲" if maternal else "更换父亲",Vector2(215,235),Vector2(195,48))
	choose.pressed.connect(open_parent_picker.bind(maternal))
	var info := button(card,"查看详情",Vector2(20,235),Vector2(185,48))
	info.disabled = index < 0
	if index >= 0: info.pressed.connect(func(): show_creature_details(index))

func open_parent_picker(maternal: bool) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "选择母亲 ♀" if maternal else "选择父亲 ♂"
	dialog.dialog_text = "选择候选并查看详情，确认后才会替换亲本。"
	dialog.ok_button_text = "使用"
	dialog.size = Vector2i(800,650)
	root.add_child(dialog)
	var items := ItemList.new()
	items.custom_minimum_size = Vector2(740,340)
	items.add_theme_font_override("font",font); items.add_theme_font_size_override("font_size",20)
	var ids: Array[int] = []
	for i in samples.size():
		if samples[i].sex == (0 if maternal else 1):
			ids.append(i); items.add_item(creature_title(samples[i]),load(portrait_path(samples[i].species)))
			items.set_item_metadata(items.item_count-1,i)
	items.fixed_icon_size = Vector2i(48,48)
	var stack := VBoxContainer.new()
	dialog.add_child(stack)
	stack.add_child(items)
	var summary := Label.new()
	summary.custom_minimum_size = Vector2(740,190)
	summary.add_theme_font_override("font",font); summary.add_theme_font_size_override("font_size",18)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(summary)
	var chosen := [-1]
	items.item_selected.connect(func(i: int):
		chosen[0] = ids[i]
		var c: Dictionary = samples[ids[i]]
		var stats: Array[String] = []
		for n in 6: stats.append("%s %d/%d" % [STATS[n],c.innate[n],c.training[n]])
		summary.text = "%s\n特性：%s（其他特性待设计）\n技能：%s +%d / %s +%d；另三项待设计\n六项属性：先天/后天（种族基础 / 最终待定）\n%s" % [creature_title(c),c.trait,skill_name(c.species,c.skills[0]),c.ranks[0],skill_name(c.species,c.skills[1]),c.ranks[1],"   ".join(stats)]
	)
	dialog.confirmed.connect(func():
		dialog.hide()
		if chosen[0] < 0: return
		if maternal:
			if mother != chosen[0]: tie_choice = 0
			mother = chosen[0]
		else: father = chosen[0]
		clear_node(body); build_breeding()
	)
	dialog.canceled.connect(func(): dialog.hide(); dialog.queue_free())
	dialog.confirmed.connect(dialog.queue_free)
	dialog.popup_centered()

func show_creature_details(index: int) -> void:
	var c: Dictionary = samples[index]
	var parts: Array[String] = []
	for i in 6: parts.append("%s  待定 / %d / %d / 待定" % [STATS[i],c.innate[i],c.training[i]])
	var skills: Array[String] = []
	for i in 5: skills.append(skill_name(c.species,i) + (" +%d" % c.ranks[c.skills.find(i)] if c.skills.has(i) else ""))
	var other_traits: Array[String] = []
	for trait_name in TRAITS:
		if trait_name != c.trait: other_traits.append(trait_name)
	show_message(creature_title(c),"特性：%s\n其他特性：%s\n技能：%s\n属性（种族 / 先天 / 后天 / 最终）：\n%s" % [c.trait," / ".join(other_traits)," / ".join(skills),"\n".join(parts)])

func show_message(title_value: String, message: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = title_value
	dialog.dialog_text = message
	dialog.size = Vector2i(780,400)
	root.add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(func(): dialog.hide(); dialog.queue_free())
	dialog.popup_centered()

func refresh_breeding_preview() -> void:
	if not is_instance_valid(detail): return
	clear_node(detail)
	text_label(detail,"后代预览",Vector2(24,20),Vector2(540,45),28)
	if mother < 0 or father < 0:
		text_label(detail,"请选择一只母精灵和一只公精灵。",Vector2(24,90),Vector2(550,80),20)
		return
	var mom: Dictionary = samples[mother]
	var dad: Dictionary = samples[father]
	var ranks: Array = mom.ranks
	var own: int = 0 if ranks[0] > ranks[1] else 1
	if ranks[0] == ranks[1]: own = tie_choice
	text_label(detail,"%s · 特性跟随母亲 · 精灵 Lv.0" % NAMES[mom.species],Vector2(24,85),Vector2(545,36),21)
	text_label(detail,"技能 1："+skill_name(mom.species,mom.skills[own]),Vector2(24,140),Vector2(545,40),22)
	if ranks[0] == ranks[1]:
		for i in 2:
			var choice := button(detail,("● " if tie_choice == i else "○ ")+skill_name(mom.species,mom.skills[i])+" +%d" % mom.ranks[i],Vector2(24,195+i*62),Vector2(545,54))
			choice.pressed.connect(func(): tie_choice = i; refresh_breeding_preview())
	var min_rank := mini(maxi(mom.ranks[0],mom.ranks[1]),maxi(dad.ranks[0],dad.ranks[1]))
	var max_rank := maxi(maxi(mom.ranks[0],mom.ranks[1]),maxi(dad.ranks[0],dad.ranks[1]))
	var desc := text_label(detail,"技能强化 +%d～+%d，可能突破（概率暂定）\n技能 2：其余四项随机，+1～+9\n先天值在父母范围内随机，后天全 0。" % [min_rank,max_rank],Vector2(24,340),Vector2(545,120),18)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var preview := button(detail,"查看后代预览",Vector2(24,505),Vector2(255,55))
	preview.pressed.connect(func(): show_message("后代预览","种类：%s\n特性随母亲，精灵 Lv.0\n技能 1：%s\n技能强化与六项先天值执行时随机。" % [NAMES[mom.species],skill_name(mom.species,mom.skills[own])]))
	var hatch := button(detail,"确认孵蛋",Vector2(300,505),Vector2(270,55))
	hatch.pressed.connect(confirm_hatching)
	text_label(detail,hatch_notice if not hatch_notice.is_empty() else "孵蛋后保存到本机",Vector2(24,570),Vector2(545,35),16)

func confirm_hatching() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "确认孵蛋"
	dialog.dialog_text = "将随机生成后代并保存到本机。确认继续吗？"
	dialog.ok_button_text = "孵蛋"
	root.add_child(dialog)
	dialog.confirmed.connect(func():
		dialog.hide()
		var previous := samples.size()
		hatch_creature()
		if samples.size() == previous + 1:
			show_hatch_success()
		else:
			show_message("孵蛋失败",hatch_notice)
	)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(func(): dialog.hide(); dialog.queue_free())
	dialog.popup_centered()


func show_hatch_success() -> void:
	var result := ConfirmationDialog.new()
	result.title = "孵蛋成功"
	result.dialog_text = hatch_notice
	result.ok_button_text = "查看仓库"
	result.cancel_button_text = "留在孵蛋"
	root.add_child(result)
	result.confirmed.connect(func():
		result.hide()
		switch_page(2)
		result.queue_free()
	)
	result.canceled.connect(func(): result.hide(); result.queue_free())
	result.popup_centered()

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
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(save_path) else FileAccess.WRITE
	var file := FileAccess.open(save_path, mode)
	if file == null: return false
	# Keep a previous complete or interrupted last line separate from the new one.
	# Preserve existing bytes; never truncate a player's save during recovery.
	if file.get_length() > 0:
		file.seek(file.get_length() - 1)
		var last_byte := file.get_8()
		file.seek_end()
		if last_byte != 10: file.store_string("\n")
	else:
		file.seek_end()
	file.store_line(JSON.stringify(child))
	file.flush()
	var ok := file.get_error() == OK
	file.close()
	return ok

func load_hatchlings() -> void:
	if not FileAccess.file_exists(save_path): return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null: return
	while not file.eof_reached():
		var line := file.get_line()
		if line.is_empty(): continue
		var parsed := JSON.new()
		if parsed.parse(line) != OK: continue
		var value: Variant = parsed.data
		if valid_hatchling(value):
			for key in ["species", "sex", "level"]: value[key] = int(value[key])
			if value.has("number"): value.number = int(value.number)
			for key in ["skills", "ranks", "innate", "training"]:
				for i in value[key].size(): value[key][i] = int(value[key][i])
			samples.append(value)
	file.close()

func whole_number(value: Variant) -> bool:
	if not (value is int or value is float): return false
	var n := float(value)
	return is_finite(n) and n == floor(n)

func valid_hatchling(value: Variant) -> bool:
	if not value is Dictionary: return false
	for key in ["species", "sex", "level", "trait", "skills", "ranks", "innate", "training"]:
		if not value.has(key): return false
	if not whole_number(value.species) or not whole_number(value.sex) or not whole_number(value.level): return false
	if int(value.species) < 0 or int(value.species) >= NAMES.size() or int(value.sex) not in [0, 1]: return false
	if int(value.level) < 0 or int(value.level) > 100: return false
	if value.has("number") and (not whole_number(value.number) or int(value.number) < 1): return false
	if not value.trait is String: return false
	for key in ["skills", "ranks", "innate", "training"]:
		if not value[key] is Array: return false
	if value.skills.size() != 2 or value.ranks.size() != 2 or value.innate.size() != 6 or value.training.size() != 6: return false
	for slot in value.skills:
		if not whole_number(slot) or int(slot) < 0 or int(slot) >= 5: return false
	if value.skills[0] == value.skills[1]: return false
	for rank in value.ranks:
		if not whole_number(rank) or int(rank) < 1 or int(rank) > 10: return false
	for stat in value.innate:
		if not whole_number(stat) or int(stat) < 1 or int(stat) > 50: return false
	var training_total := 0
	for stat in value.training:
		if not whole_number(stat) or int(stat) < 0 or int(stat) > 100: return false
		training_total += int(stat)
	return training_total <= 200
