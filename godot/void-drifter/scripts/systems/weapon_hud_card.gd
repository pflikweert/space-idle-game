extends Control

# Pure presentation: the owner supplies actual weapon state each update.
var art: Texture2D
var units := 1.0
var remaining_fraction := 0.0
var reloading := false
var selected := true
var locked := false
var empty := false
var ammo_text := ""
var stars := 0
var star_slots := 3
var epic := false
var epic_fraction := 0.0
var ready_glow := 0.0
var initialized := false
var glow_tween: Tween
var star_texture: Texture2D = preload("res://assets/ui/icons/star.svg")
var empty_star_texture: Texture2D = preload("res://assets/ui/icons/star_empty.svg")
var lock_texture: Texture2D = preload("res://assets/ui/icons/lock.svg")

static func reload_fraction(remaining: float, duration: float) -> float:
	return clampf(remaining/maxf(duration,0.000001),0,1)

func update_state(remaining: float, duration: float, ammo: int, magazine: int, active: bool) -> void:
	var now_reloading := remaining > 0
	if initialized and reloading and not now_reloading and ammo > 0:
		ready_glow = 0.45
		if glow_tween: glow_tween.kill()
		glow_tween = create_tween()
		glow_tween.tween_property(self,"ready_glow",0.0,0.22)
	if glow_tween and glow_tween.is_valid() and ready_glow > 0.001:
		if active: glow_tween.play()
		else: glow_tween.pause()
	initialized = true
	reloading = now_reloading
	remaining_fraction = reload_fraction(remaining,duration)
	ammo_text = "%.1fs" % remaining if reloading else "%d/%d" % [ammo,magazine]
	queue_redraw()

func _process(_delta: float) -> void:
	if ready_glow > 0: queue_redraw()

func _draw() -> void:
	var u := units
	var frame := Rect2(Vector2.ZERO,size)
	var image_rect := frame
	var accent := Color("#b784f3") if epic else Color("#80d9e8")
	draw_style_box(_style(accent),frame)
	if empty:
		draw_rect(frame.grow(-u),Color(0.3,0.5,0.6,0.28),false,u)
		var center := frame.get_center()
		draw_line(center-Vector2(5,0)*u,center+Vector2(5,0)*u,Color(0.4,0.65,0.7,0.35),u)
		draw_line(center-Vector2(0,5)*u,center+Vector2(0,5)*u,Color(0.4,0.65,0.7,0.35),u)
		return
	if art:
		var source_size := art.get_size()
		# Slots are square, so the complete square illustration can fill the card.
		draw_texture_rect_region(art,image_rect,Rect2(Vector2.ZERO,source_size),Color(0.65,0.7,0.75) if reloading or locked else Color.WHITE)
	if reloading:
		# Intersect the remaining clockwise sector with the full rectangle; no ring.
		var center := frame.get_center()
		var radius := size.length()
		var points := PackedVector2Array([center])
		var begin := -PI/2 + TAU*(1.0-remaining_fraction)
		for index in range(65): points.append(center+Vector2.from_angle(lerpf(begin,3*PI/2,index/64.0))*radius)
		if remaining_fraction >= 0.9999: draw_rect(frame,Color(0.015,0.025,0.045,0.65))
		elif remaining_fraction > 0.0001:
			for polygon in Geometry2D.intersect_polygons(points,PackedVector2Array([Vector2.ZERO,Vector2(size.x,0),size,Vector2(0,size.y)])):
				draw_colored_polygon(polygon,Color(0.015,0.025,0.045,0.65))
	if ready_glow > 0: draw_rect(image_rect,Color(0.55,0.95,1,ready_glow))
	if locked: draw_texture_rect(lock_texture,Rect2(image_rect.get_center()-Vector2.ONE*8*u,Vector2.ONE*16*u),false)
	# Selection border, stars and ammo are drawn over/outside the reload mask.
	if selected: draw_rect(frame.grow(-u),accent,false,u)
	var text_size := ceili(9*u)
	# Use the same vector star assets as the level-up/current-loadout UI rather
	# than font glyphs: Godot's fallback font does not include ★ or ☆ on web.
	var star_side := minf(12*u,(size.x-8*u)/maxi(1,star_slots))
	var star_y := size.y-star_side-4*u
	for index in range(star_slots):
		var star_rect := Rect2(4*u+index*star_side,star_y,star_side,star_side)
		var star_asset := star_texture if index < stars else empty_star_texture
		var star_color := Color("#d9f8ff") if index < stars else Color.WHITE
		draw_texture_rect(star_asset,star_rect,false,star_color)
	var ammo_pos := Vector2(size.x-29*u,size.y-4*u)
	draw_string_outline(ThemeDB.fallback_font,ammo_pos,ammo_text,HORIZONTAL_ALIGNMENT_RIGHT,26*u,text_size,2*u,Color(0.01,0.02,0.04,0.9))
	draw_string(ThemeDB.fallback_font,ammo_pos,ammo_text,HORIZONTAL_ALIGNMENT_RIGHT,26*u,text_size,Color("#dcebf1"))
	draw_line(Vector2(3*u,size.y-2*u),Vector2(3*u+(size.x-6*u)*epic_fraction,size.y-2*u),Color("#b784f3"),u)

func _style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	# The artwork is the card surface; keep the style fill transparent so no
	# grey panel appears behind the level, stars or reload text.
	style.bg_color = Color(0.02,0.045,0.065,0.0)
	style.border_color = accent if selected else Color("#486b7b")
	style.set_border_width_all(1)
	style.corner_radius_top_left = 5
	style.corner_radius_bottom_right = 5
	return style
