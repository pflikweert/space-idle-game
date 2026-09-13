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
	var area := Rect2(safe.x,safe.y,size.x-safe.x-safe.z,size.y-safe.y-safe.w)
	var short := size.y/units < 500 and size.x > size.y
	var top_height := (48.0 if short else 68.0)*units
	# Square slots keep the card illustration uncropped and make the weapon strip
	# slightly more prominent without exceeding the safe HUD width.
	var slot_side := minf(86,(area.size.x/units-32)/5)
	var card_size := Vector2.ONE * slot_side * units
	var card := Rect2(Vector2(area.get_center().x-(card_size.x*5+16*units)/2,area.end.y-card_size.y-4*units),card_size)
	var slots: Array[Rect2] = []
	for index in range(5): slots.append(Rect2(card.position+Vector2(index*(card_size.x+4*units),0),card_size))
	var buttons: Array[Rect2] = []
	for index in range(4):
		buttons.append(Rect2(area.end.x-4*units-(4-index)*46*units,(area.position.y+2*units) if short else area.position.y+24*units,45*units,45*units))
	# A wide, transparent wave touch target fits between the health readout and controls.
	var wave := Rect2(area.end.x - 3.0 * 46.0 * units - 100.0 * units, area.position.y + 2.0 * units, 96.0 * units, 45.0 * units)
	return {"area":area,"short":short,"top":top_height,"weapon":card,"slots":slots,"buttons":buttons,
		"wave":wave,
		"dodge":Rect2(area.end.x-88*units,card.position.y-96*units,84*units,44*units),
		"cards":Rect2(area.end.x-88*units,card.position.y-48*units,84*units,44*units)}
