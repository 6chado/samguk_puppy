extends Control
## 스페셜 칭호 꼬리표: 짝꿍 진영 색 그라데이션 (왼쪽 → 오른쪽) + 테두리 + 안쪽에서만 반짝이는 별

var text := ""
var c1 := Color(0.3, 0.6, 0.36)
var c2 := Color(0.6, 0.85, 0.45)
var px := 20
var _t := 0.0


func setup(text_: String, from: Color, to: Color, font_px: int) -> void:
	text = text_
	c1 = from
	c2 = to
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
	custom_minimum_size = Vector2(ceilf(w + px * 1.4), ceilf(px * 1.6))


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	queue_redraw()


static func round_rect(r: Rect2, rad: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var cs := [Vector2(r.end.x - rad, r.position.y + rad), Vector2(r.end.x - rad, r.end.y - rad),
		Vector2(r.position.x + rad, r.end.y - rad), Vector2(r.position.x + rad, r.position.y + rad)]
	for k in 4:
		for j in 7:
			var a: float = -PI / 2 + k * PI / 2 + j * (PI / 2) / 6.0
			pts.append(cs[k] + Vector2(cos(a), sin(a)) * rad)
	return pts


## 왼쪽 → 오른쪽 그라데이션 둥근 네모 (액자 프레임에도 씀)
static func draw_grad(ci: CanvasItem, r: Rect2, rad: float, from: Color, to: Color) -> void:
	var pts := round_rect(r, rad)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(from.lerp(to, clampf((p.x - r.position.x) / maxf(r.size.x, 1.0), 0.0, 1.0)))
	ci.draw_polygon(pts, cols)


func _draw() -> void:
	var rad := minf(size.y * 0.32, 12.0)
	var r := Rect2(Vector2.ZERO, size).grow(-1.0)
	draw_grad(self, r, rad, c1, c2)
	# 윗부분 살짝 밝게 (광택)
	var top := Rect2(r.position + Vector2(rad * 0.6, 2), Vector2(r.size.x - rad * 1.2, r.size.y * 0.32))
	draw_rect(top, Color(1, 1, 1, 0.16))
	var ol := round_rect(r, rad)
	ol.append(ol[0])
	draw_polyline(ol, c1.darkened(0.3), 2.5, true)
	var f := _font()
	if f:
		var base_y := (size.y - f.get_height(px)) / 2.0 + f.get_ascent(px)
		var tx := (size.x - f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x) / 2.0
		draw_string_outline(f, Vector2(tx, base_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, maxi(3, px / 5), c1.darkened(0.5))
		draw_string(f, Vector2(tx, base_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, Color.WHITE)
	# 안쪽 모서리에서만 반짝
	var a := 0.5 + 0.5 * sin(_t * 4.0)
	var sr := minf(rad * 0.5, 5.0) * (0.55 + 0.45 * a)
	var c := Vector2(size.x - rad * 0.95, rad * 0.95)
	var star := PackedVector2Array()
	for i in 8:
		star.append(c + Vector2.from_angle(i * PI / 4.0) * (sr if i % 2 == 0 else sr * 0.32))
	draw_colored_polygon(star, Color(1, 1, 1, 0.4 + 0.6 * a))
