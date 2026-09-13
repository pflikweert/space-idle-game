extends "res://scripts/systems/progression_panel.gd"

const Cards := preload("res://scripts/systems/railgun_cards.gd")
var wide_cards := false
var preserved_unlocks: Array = []
var art: Texture2D
var rail_ui_factor := 1.0
var choice_card_art_size := 64.0
var choice_loadout_slot_size := 64.0

func illustration(key: String) -> Texture2D:
	var path := "res://assets/ui/railgun_cards/%s.png" % key
	return load(path) if ResourceLoader.exists(path) else art

func portrait(key: String, height: float) -> TextureRect:
	var image := TextureRect.new()
	image.texture = illustration(key)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# Card art is square source artwork. Never crop it to a shallow card strip.
	image.clip_contents = false
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2(height,height) * rail_ui_factor
	image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return image


func show_railgun(game: Control) -> void:
	preserved_unlocks = game.profile.get("railgunPreservedUnlocks",[])
	var view: String = game.menu_view
	var level: int = game.profile.railgunLevel
	var state: Dictionary = game.cards
	var actions: Array = []
	var tabs: Array = []
	var title := "RAILGUN  Lv.%d" % level
	var summary := "◈ %s    ▣ %d" % [game._money(game.profile.totalCoins),game.profile.railgunModules]
	var selecting: bool = game.status == "card_choice"
	var build: bool = view == "build"
	if art == null:
		var source: Texture2D = game.ship_textures.get("icon")
		if source != null:
			var cropped := AtlasTexture.new()
			cropped.atlas = source
			cropped.region = Rect2(source.get_image().get_used_rect()).grow(6).intersection(Rect2(Vector2.ZERO,source.get_size()))
			art = cropped
	if view == "railgun" and not selecting:
		_show_upgrade(game, level)
		return
	if selecting:
		title = "LEVEL UP"
		summary = "RAILGUN  %s   ·   Lv.%d" % [Cards.stars(state),int(state.choices)+2]
		actions = [{"text":game._auto_cards_text(),"action":"auto_cards","inline":true}]
	elif build:
		title = "RAILGUN BUILD"
		summary = "%s  ·  %d cards\n%s" % [Cards.stars(state),state.choices,Cards.progress_text(state)]
		actions = [{"text":"Back","action":"back"}]
	else:
		tabs = [{"text":"Upgrade","action":"railgun","selected":view=="railgun"},{"text":"Cards","action":"railgun_catalog","selected":view!="railgun"}]
		actions = [{"text":"Back","action":"back"}]
	if game.save_error:
		summary += "\nSave failed. Keep this tab open and retry."
		actions.append({"text":"Retry Save","action":"save"})
	show_content(title,summary,tabs,[],actions)
	if selecting:
		# Cards define the choice panel height; there is no inner scrollbar.
		scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.custom_minimum_size.y = 0.0
		rows.custom_minimum_size.y = 220.0 * rail_ui_factor
	else:
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.custom_minimum_size.y = 0.0
	if selecting or build: scroll.set_deferred("scroll_vertical",0)
	if selecting:
		_set_choice_overlay_style()
		_add_collection_row(state,level)
	else:
		_set_default_overlay_style()
		title_label.add_theme_color_override("default_color", Color("#dba1ff") if Cards.is_epic(state) else Color("#96edff"))
	if view == "railgun_detail" and not selecting:
		var card := Cards.definition(game.card_detail)
		_add_card(rows,card,"", "",level,state)
		rows.add_child(_card_label("One rank per selection. " + ("Maximum %d ranks per run." % card.cap if card.cap > 0 else "Repeatable throughout the run."),13,Color("#c2dce6")))
		actions = [{"text":"Back to Cards","action":"card_detail_back"}]
		_clear(footer)
		footer.add_child(button(actions[0].text,actions[0].action))
		if game.save_error: footer.add_child(button("Retry Save","save"))
	else:
		if build:
			var stats: Dictionary = game._railgun_stats()
			_add_stat_grid(rows,stats)
		if selecting:
			var choice_gap := Control.new()
			choice_gap.custom_minimum_size.y = 12 * rail_ui_factor
			rows.add_child(choice_gap)
		var grid := GridContainer.new()
		grid.columns = 3
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation",4)
		grid.add_theme_constant_override("v_separation",6)
		rows.add_child(grid)
		var ids: Array = state.offer if selecting else []
		if not selecting:
			for entry in Cards.CATALOG:
				if not build or int(state.ranks.get(entry.id,0)) > 0: ids.append(entry.id)
		if ids.is_empty():
			rows.add_child(_card_label("Your first card unlocks at 20 XP. Defeat enemies to fill the XP bar.",13,Color("#c2dce6")))
		var group_level := -1
		for id in ids:
			var entry := Cards.definition(id)
			if not selecting and not build and int(entry.unlock) != group_level:
				if group_level != -1:
					while grid.get_child_count() % 3 != 0:
						var spacer := Control.new()
						spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
						grid.add_child(spacer)
				group_level = int(entry.unlock)
				rows.add_child(_card_label("START CARDS" if group_level == 1 else "LEVEL %d" % group_level,15,Color("#8bbdcb")))
				grid = GridContainer.new()
				grid.columns = 3
				grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				grid.add_theme_constant_override("h_separation",4)
				rows.add_child(grid)
			var action: String = "card:"+id if selecting else "card_info:"+id
			
			_add_card(grid,entry,action,"",level,state)
		if not selecting and not build:
			while grid.get_child_count() % 3 != 0:
				var spacer := Control.new()
				spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				grid.add_child(spacer)
	set_ui_factor(rail_ui_factor)

func _set_choice_overlay_style() -> void:
	var panel_style := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	panel_style.bg_color = Color(0.0,0.0,0.0,0.0)
	panel_style.border_color = Color(0.0,0.0,0.0,0.0)
	panel_style.set_border_width_all(0)
	panel_style.content_margin_left = 6 * rail_ui_factor
	panel_style.content_margin_right = 6 * rail_ui_factor
	panel_style.content_margin_top = 6 * rail_ui_factor
	panel_style.content_margin_bottom = 6 * rail_ui_factor
	add_theme_stylebox_override("panel",panel_style)

func _set_default_overlay_style() -> void:
	var panel_style := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	panel_style.bg_color = Color(0.035,0.04,0.10,0.96)
	panel_style.border_color = Color("#8bbdcb")
	panel_style.set_border_width_all(1)
	panel_style.content_margin_left = 8
	panel_style.content_margin_right = 8
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	add_theme_stylebox_override("panel",panel_style)

func _add_collection_row(state: Dictionary, level: int) -> void:
	var heading := _card_label("CURRENT LOADOUT",11,Color("#69e6f5"))
	var collection := VBoxContainer.new()
	collection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	purchase_options.visible = true
	purchase_options.add_child(collection)
	collection.add_child(heading)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",4 * rail_ui_factor)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection.add_child(row)
	_add_collection_card(row,{"art_key":"hero"},1,Cards.stars(state))
	for index in range(4): _add_collection_card(row,{},0)

func _collection_shell() -> PanelContainer:
	var shell := PanelContainer.new()
	shell.clip_contents = true
	# Five equal slots span precisely the same content width as the three-card grid.
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.custom_minimum_size = Vector2.ONE * choice_loadout_slot_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.01,0.05,0.08,0.22)
	style.border_color = Color(0.32,0.84,0.92,0.82)
	style.set_border_width_all(2)
	style.border_width_bottom = 2
	style.set_content_margin_all(4 * rail_ui_factor)
	style.corner_radius_top_left = 8
	style.corner_radius_bottom_right = 8
	shell.add_theme_stylebox_override("panel",style)
	return shell

func _add_collection_card(parent: Control, entry: Dictionary, rank: int, stars := "") -> void:
	var shell := _collection_shell()
	parent.add_child(shell)
	if entry.is_empty(): return
	var frame := Control.new()
	# PanelContainer applies the inset, leaving the cyan border visible around art.
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shell.add_child(frame)
	var image := portrait(entry.art_key,0)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_child(image)
	var star_label := _card_label("[center]%s[/center]" % (stars if not stars.is_empty() else "★".repeat(mini(4,rank))+"☆".repeat(maxi(0,4-rank))),10,Color("#d9f8ff"))
	star_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	star_label.position.y = -18 * rail_ui_factor
	star_label.size.y = 18 * rail_ui_factor
	star_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(star_label)


# Permanent upgrade UI only; both previews use the same weapon calculation as combat.
func _show_upgrade(game: Control, level: int) -> void:
	show_content("[center]Railgun Lv.%d[/center]" % level,"",[],[],[])
	var base := Cards.fresh()
	var current := Cards.stats(base,level,game._stat("damage"),game._stat("crit_chance"))
	var upcoming := Cards.stats(base,mini(Cards.MAX_LEVEL,level+1),game._stat("damage"),game._stat("crit_chance"))
	var intro := HBoxContainer.new()
	intro.add_theme_constant_override("separation",12)
	rows.add_child(intro)
	var image := portrait("hero",88)
	image.custom_minimum_size = Vector2.ONE * 88 * rail_ui_factor
	image.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	image.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	intro.add_child(image)
	var description := _card_label("Fires rounds automatically. Run cards can add projectiles and pierce extra enemies after a kill.",13,Color("#b5dce5"))
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	intro.add_child(description)
	var improvements := _add_stat_grid(rows,current,upcoming)
	for entry in Cards.CATALOG:
		if int(entry.unlock) <= 1: continue
		var unlocked := Cards.is_unlocked(entry,level,preserved_unlocks)
		var shell := _upgrade_panel(Color("#193848") if unlocked else Color("#101f2e"),7)
		rows.add_child(shell)
		var line := HBoxContainer.new()
		shell.add_child(line)
		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(words)
		words.add_child(_card_label(entry.name,13,Color("#deefeb") if unlocked else Color("#96acbb")))
		words.add_child(_card_label("Unlocked" if unlocked else "Locked",11,Color("#69f0bc") if unlocked else Color("#96acbb")))
		var badge := _upgrade_panel(Color("#26495b") if unlocked else Color("#192f40"),6)
		badge.size_flags_horizontal = Control.SIZE_SHRINK_END
		badge.size_flags_vertical = Control.SIZE_FILL
		badge.custom_minimum_size.x = 54 * rail_ui_factor
		line.add_child(badge)
		badge.add_child(_card_label("[center]Lv.%d[/center]" % entry.unlock,15,Color("#c4e2e9")))
	var improvement := "Maximum level reached" if level >= Cards.MAX_LEVEL else "Upgrade: " + ", ".join(improvements)
	footer.add_child(_card_label("[center]%s[/center]" % improvement,13,Color("#69f0bc")))
	var cost := Cards.price(level)
	var blocked: bool = level >= Cards.MAX_LEVEL or not game.profile.activeRun.is_empty() or game.status not in ["menu","dead"] or game.profile.totalCoins < cost.coins or game.profile.railgunModules < cost.modules
	var actions := HBoxContainer.new()
	footer.add_child(actions)
	var upgrade := button("Max Level" if level >= Cards.MAX_LEVEL else "Upgrade","railgun_buy",blocked)
	upgrade.size_flags_stretch_ratio = 2.0
	for state in ["normal","hover","pressed","disabled"]:
		var style := upgrade.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		style.bg_color = Color("#f5bf18") if not blocked else Color("#766326")
		style.border_color = Color("#ffdf72") if not blocked else Color("#ac9142")
		style.corner_radius_top_left = 8
		style.corner_radius_bottom_right = 8
		style.corner_detail = 1
		upgrade.add_theme_stylebox_override(state,style)
		upgrade.add_theme_color_override("font_"+state+"_color",Color("#172432") if not blocked else Color("#e0d3a8"))
	upgrade.add_theme_color_override("font_color",Color("#172432"))
	actions.add_child(upgrade)
	actions.add_child(button("Card Info","railgun_catalog"))
	var currencies := HBoxContainer.new()
	footer.add_child(currencies)
	for currency in [["◈",game.profile.totalCoins,cost.coins],["▣",game.profile.railgunModules,cost.modules]]:
		var amount := str(int(currency[1]))
		if level < Cards.MAX_LEVEL and currency[1] < currency[2]: amount = "[color=#ff8585]"+amount+"[/color]"
		var text := "%s  %s / %s" % [currency[0],amount,str(int(currency[2])) if level < Cards.MAX_LEVEL else "--"]
		var label := _card_label("[center]%s[/center]" % text,12,Color("#c4e2e9"))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		currencies.add_child(label)
	if not game.profile.activeRun.is_empty() and level < Cards.MAX_LEVEL:
		footer.add_child(_card_label("Finish the current run to upgrade.",11,Color("#ffe080")))
	var navigation := HBoxContainer.new()
	footer.add_child(navigation)
	var back := button("Back","back")
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.custom_minimum_size.x = 64 * rail_ui_factor
	navigation.add_child(back)
	if game.save_error:
		navigation.add_child(_card_label("Save failed. Retry save.",11,Color("#ff8585")))
		navigation.add_child(button("Retry Save","save"))
	set_ui_factor(rail_ui_factor)

func _add_stat_grid(parent: Control, current: Dictionary, upcoming: Dictionary = {}) -> Array[String]:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",6)
	parent.add_child(grid)
	var improvements: Array[String] = []
	for item in [["Damage","damage"],["Crit","crit"],["Magazine","magazine"],["Reload","reload"],["Projectiles","shots"],["Piercing","hits"]]:
		var key: String = item[1]
		var value := _stat_value(key,float(current[key]))
		if not upcoming.is_empty():
			var delta := float(upcoming[key])-float(current[key])
			if not is_zero_approx(delta):
				var change := ("+" if delta > 0 else "-") + _stat_value(key,absf(delta),true)
				var better := delta < 0 if key == "reload" else delta > 0
				value += " [color=%s]%s[/color]" % ["#69f0bc" if better else "#ff8585",change]
				improvements.append("%s %s" % [item[0],change])
		var tile := _upgrade_panel(Color("#172f40"))
		grid.add_child(tile)
		var stack := VBoxContainer.new()
		stack.add_theme_constant_override("separation",2)
		tile.add_child(stack)
		var strip := _upgrade_panel(Color("#24485a"),2)
		stack.add_child(strip)
		strip.add_child(_card_label("[center]%s[/center]" % item[0],11,Color("#bbd4de")))
		stack.add_child(_card_label("[center]%s[/center]" % value,15,Color("#d5f2f6")))
	return improvements

func _stat_value(key: String, value: float, difference := false) -> String:
	match key:
		"damage": return ("%.2f" % value).trim_suffix("0").trim_suffix(".")
		"crit": return "%.0f%%" % (value*100)
		"reload": return "%.2fs" % value
		"hits": return str(int(value) if difference else maxi(0,int(value)-1))
	return str(int(value))

func _card_title_plate(text: String, accent: Color) -> PanelContainer:
	var plate := PanelContainer.new()
	# Keep every card body aligned, including titles that wrap on narrow screens.
	plate.custom_minimum_size.y = 54 * rail_ui_factor
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent,0.12)
	style.border_color = Color(accent,0.82)
	style.border_width_bottom = 2
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 0
	style.content_margin_left = 8 * rail_ui_factor
	style.content_margin_right = 8 * rail_ui_factor
	style.content_margin_top = 4 * rail_ui_factor
	style.content_margin_bottom = 4 * rail_ui_factor
	plate.add_theme_stylebox_override("panel",style)
	var label := _card_label("[b]%s[/b]" % text,8 if not wide_cards else 10,Color("#f3fbff"))
	label.fit_content = false
	label.custom_minimum_size.y = 46 * rail_ui_factor
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plate.add_child(label)
	return plate

func _add_card(parent: Control, entry: Dictionary, action: String, detail: String, level: int, state: Dictionary) -> void:
	var accent := Color("#d697ff") if entry.epic else Color("#81deef")
	var locked := not Cards.is_unlocked(entry,level,preserved_unlocks)
	var shell := PanelContainer.new()
	shell.clip_contents = true
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14,0.11,0.22,0.52) if entry.epic else Color(0.03,0.13,0.18,0.46)
	style.border_color = accent.darkened(0.35) if locked else accent
	style.set_border_width_all(2)
	style.corner_radius_top_left = 7
	style.corner_radius_bottom_right = 7
	# Keep artwork flush to the inner edge while reserving the border pixels.
	style.set_content_margin_all(2 * rail_ui_factor)
	style.shadow_color = Color(accent,0.12)
	style.shadow_size = 5 if entry.epic else 0
	shell.add_theme_stylebox_override("panel",style)
	parent.add_child(shell)
	if entry.epic and not locked and action.begins_with("card:"):
		var pulse := shell.create_tween().set_loops()
		pulse.tween_property(style,"border_color",accent.lightened(0.35),0.9)
		pulse.tween_property(style,"border_color",accent,0.9)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation",0)
	shell.add_child(content)
	var title := str(entry.name)
	var rank := int(state.ranks.get(entry.id,0))
	if rank > 0: title += "  " + (["I","II","III","IV"][mini(3,rank-1)] if entry.epic else "+%d" % rank)
	content.add_child(_card_title_plate(title,accent))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation",0)
	content.add_child(body)
	var image := portrait(entry.art_key,choice_card_art_size / rail_ui_factor)
	if locked: image.modulate = Color(0.35,0.4,0.45)
	body.add_child(image)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.custom_minimum_size.y = 44 * rail_ui_factor
	var text_inset := MarginContainer.new()
	text_inset.add_theme_constant_override("margin_left",8 * rail_ui_factor)
	text_inset.add_theme_constant_override("margin_right",8 * rail_ui_factor)
	text_inset.add_theme_constant_override("margin_top",4 * rail_ui_factor)
	text_inset.add_theme_constant_override("margin_bottom",6 * rail_ui_factor)
	text_inset.add_child(words)
	body.add_child(text_inset)
	# Every screen uses the same card body; rank only changes the title.
	var effect := _card_label(entry.short_effect,11 if not wide_cards else 13,Color("#dfedf4"))
	effect.fit_content = false
	effect.custom_minimum_size.y = (32 if not wide_cards else 36) * rail_ui_factor
	words.add_child(effect)
	if not detail.is_empty(): words.add_child(_card_label(detail,13,Color("#8df5cb")))
	if not action.is_empty():
		# The entire card is a target; all labels ignore input so text/art clicks select too.
		_ignore_input(shell)
		shell.mouse_filter = Control.MOUSE_FILTER_PASS
		shell.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		shell.gui_input.connect(_card_input.bind(shell,action))
		shell.focus_mode = Control.FOCUS_ALL
		var focus := style.duplicate() as StyleBoxFlat
		focus.border_color = Color("#edc254")
		focus.set_border_width_all(2)
		shell.add_theme_stylebox_override("focus",focus)
		shell.mouse_entered.connect(func(): shell.modulate = Color(1.1,1.1,1.1))
		shell.mouse_exited.connect(func(): shell.modulate = Color.WHITE)

func _card_input(event: InputEvent, shell: Control, action: String) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT or event is InputEventScreenTouch:
		if event.pressed:
			shell.set_meta("press_start",event.position)
		elif shell.has_meta("press_start"):
			var start: Vector2 = shell.get_meta("press_start")
			shell.remove_meta("press_start")
			if start.distance_to(event.position)<12.0:
				shell.accept_event()
				selected.emit(action)
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		if shell.has_meta("press_start") and Vector2(shell.get_meta("press_start")).distance_to(event.position)>=12.0:
			shell.remove_meta("press_start")
	elif event.is_action_pressed("ui_accept"):
		shell.accept_event()
		selected.emit(action)

func _ignore_input(node: Node) -> void:
	if node is Control: node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children(): _ignore_input(child)

func _focus_if_live(control: Control) -> void:
	if is_instance_valid(control) and control.is_inside_tree(): control.grab_focus()
