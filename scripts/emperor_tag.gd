extends Control
## 황제 칭호 꼬리표: 위아래 그라데이션 + 테두리 + 왼쪽 왕관 + 테두리 안에서만 반짝이는 별
##   theme: gold(유비·조조·손권) / red(원술·여포·원소·공손찬) / black(유방·항우)

const THEMES := {
	"gold":  {"top": Color8(255, 238, 156), "bot": Color8(232, 168, 46), "border": Color8(176, 116, 24),
		"fg": Color8(118, 68, 10), "ol": Color8(255, 248, 214), "star": Color8(255, 255, 240)},
	"red":   {"top": Color8(232, 82, 82), "bot": Color8(164, 26, 40), "border": Color8(240, 196, 84),
		"fg": Color8(255, 230, 136), "ol": Color8(104, 14, 24), "star": Color8(255, 236, 170)},
	"black": {"top": Color8(78, 74, 90), "bot": Color8(24, 22, 30), "border": Color8(222, 182, 80),
		"fg": Color8(255, 222, 112), "ol": Color8(14, 12, 18), "star": Color8(255, 240, 190)},
}

var text := ""
var theme_key := "gold"
var px := 20
var _t := 0.0


func setup(text_: String, theme_: String, font_px: int) -> void:
	text = text_
	theme_key = theme_ if THEMES.has(theme_) else "gold"
	px = font_px
	mouse_filter = MOUSE_FILTER_IGNORE
	size_flags_vertical = SIZE_SHRINK_CENTER
	_t = randf() * 4.0
	_fit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE or what == NOTIFICATION_THEME_CHANGED:
		_fit()


func _font() -> Font:
	return get_theme_font("font", "Label")


func _fit() -> void:
	var f := _font()
	if f == null:
		return
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var h := px * 1.6
	custom_minimum_size = Vector2(ceilf(w + h * 0.95 + px * 1.1), ceilf(h))


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	queue_redraw()


func _round_rect(r: Rect2, rad: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var cs := [Vector2(r.end.x - rad, r.position.y + rad), Vector2(r.end.x - rad, r.end.y - rad),
		Vector2(r.position.x + rad, r.end.y - rad), Vector2(r.position.x + rad, r.position.y + rad)]
	for k in 4:
		for j in 7:
			var a: float = -PI / 2 + k * PI / 2 + j * (PI / 2) / 6.0
			pts.append(cs[k] + Vector2(cos(a), sin(a)) * rad)
	return pts


func _star(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var rr := r if i % 2 == 0 else r * 0.32
		pts.append(c + Vector2.from_angle(i * PI / 4.0) * rr)
	draw_colored_polygon(pts, col)


func _draw() -> void:
	var th: Dictionary = THEMES[theme_key]
	var r := Rect2(Vector2.ZERO, size)
	var rad := minf(size.y * 0.32, 12.0)
	# 바탕: 위 밝게 → 아래 진하게
	var pts := _round_rect(r.grow(-1.0), rad)
	var cols := PackedColorArray()
	for p in pts:
		cols.append((th["top"] as Color).lerp(th["bot"], clampf(p.y / size.y, 0.0, 1.0)))
	draw_polygon(pts, cols)
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, th["border"], 3.0, true)
	# 왕관
	var h := size.y
	var cx := px * 0.55
	var s := h * 0.52
	var y0 := (h - s) / 2.0
	var crown := PackedVector2Array([Vector2(cx, y0 + s), Vector2(cx, y0 + s * 0.28), Vector2(cx + s * 0.28, y0 + s * 0.6),
		Vector2(cx + s * 0.5, y0), Vector2(cx + s * 0.72, y0 + s * 0.6), Vector2(cx + s, y0 + s * 0.28), Vector2(cx + s, y0 + s)])
	draw_colored_polygon(crown, Color8(255, 214, 90))
	var co := crown.duplicate()
	co.append(crown[0])
	draw_polyline(co, Color8(140, 88, 20), 1.6, true)
	for g in [Vector2(cx, y0 + s * 0.28), Vector2(cx + s * 0.5, y0), Vector2(cx + s, y0 + s * 0.28)]:
		draw_circle(g, s * 0.1, Color8(230, 60, 70))
	# 글씨 (테두리 글씨)
	var f := _font()
	if f:
		var tx := cx + s + px * 0.35
		var base_y := (h - f.get_height(px)) / 2.0 + f.get_ascent(px)
		draw_string_outline(f, Vector2(tx, base_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, maxi(3, px / 5), th["ol"])
		draw_string(f, Vector2(tx, base_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, th["fg"])
	# 반짝이: 테두리 안쪽 모서리에서만 깜빡
	var a1 := 0.5 + 0.5 * sin(_t * 4.0)
	var a2 := 0.5 + 0.5 * sin(_t * 4.0 + 2.2)
	var sr := minf(rad * 0.55, 5.5)
	_star(Vector2(size.x - rad * 0.95, rad * 0.95), sr * (0.55 + 0.45 * a1), Color(th["star"], 0.35 + 0.65 * a1))
	_star(Vector2(size.x - rad * 1.9, size.y - rad * 0.9), sr * 0.7 * (0.55 + 0.45 * a2), Color(th["star"], 0.3 + 0.7 * a2))
