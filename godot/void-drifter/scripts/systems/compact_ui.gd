extends RefCounted

# All dimensions are physical screen pixels, converted once at the viewport boundary.
const TEXT := Color("#d9e8ef")
const CYAN := Color("#8bbdcb")
const EPIC := Color("#c58aff")
const GOLD := Color("#edc254")

static func layout(size: Vector2, units: float) -> Dictionary:
	var landscape := size.x > size.y and size.y / units < 500
	var top := (48.0 if landscape else 80.0) * units
	var bottom := (52.0 if landscape else 72.0) * units
	return {"top":top,"bottom":bottom,"landscape":landscape,
		"field":Rect2(0,top,size.x,maxf(1,size.y-top-bottom))}

static func panel(accent := CYAN) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025,0.055,0.075,0.94)
	style.border_color = Color(accent,0.65)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_bottom_right = 8
	style.set_content_margin_all(8)
	return style

# Visual layout only; layout().field remains the existing combat boundary.
static func hud_layout(size: Vector2, units: float, safe := Vector4.ZERO) -> Dictionary:
	# The command rail floats over the playfield. Keep the HUD width untouched so
	# the header and footer stay centred and do not get squeezed left.
	var area := Rect2(safe.x,safe.y,size.x-safe.x-safe.z,size.y-safe.y-safe.w)
	var short := size.y/units < 500 and size.x > size.y
	var top_height := (88.0 if short else 104.0)*units
	# Square slots keep the card illustration uncropped and make the weapon strip
	# slightly more prominent without exceeding the safe HUD width.
	var slot_side := minf(86,(area.size.x/units-32)/5)
	var card_size := Vector2.ONE * slot_side * units
	var slot_gap := 8.0*units
	var card := Rect2(Vector2(area.get_center().x-(card_size.x*5+slot_gap*4.0)/2,area.end.y-card_size.y-6*units),card_size)
	var slots: Array[Rect2] = []
	for index in range(5): slots.append(Rect2(card.position+Vector2(index*(card_size.x+slot_gap),0),card_size))
	var menu_x := size.x-safe.z-54.0*units
	var menu_height := 3.0*42.0*units + 2.0*6.0*units
	var menu_y := area.position.y + (area.size.y-menu_height)/2.0
	var buttons: Array[Rect2] = []
	for index in range(5):
		buttons.append(Rect2(menu_x,menu_y+index*48.0*units,46.0*units,42.0*units))
	# Wave is a readout in the centre header, not a second button.
	var wave := Rect2(area.get_center().x-74.0*units,area.position.y+8.0*units,148.0*units,70.0*units)
	return {"area":area,"short":short,"top":top_height,"weapon":card,"slots":slots,"buttons":buttons,
		"wave":wave,
		"dodge":Rect2(menu_x,menu_y+5*48.0*units,46.0*units,42.0*units),
		"cards":Rect2(menu_x,menu_y+4*48.0*units,46.0*units,42.0*units),
		"side":Rect2(menu_x,area.position.y,size.x-menu_x,area.size.y)}
