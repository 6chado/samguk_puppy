extends Label
## 칭호 꼬리표
##   plain   : 단색 (병졸 회색 → 동 → 은 → 금 → 다이아)
##   rainbow : 무지개로 계속 바뀜 (황제)
##   sparkle : 연한 금색 바탕 + 무지개빛 테두리가 반짝반짝 (스페셜 칭호)

var mode := "plain"
var base := Color(0.62, 0.6, 0.58)
var _sb := StyleBoxFlat.new()
var _t := 0.0


func setup(text_: String, base_: Color, mode_: String, font_px: int) -> void:
	text = text_
	base = base_
	mode = mode_
	add_theme_font_size_override("font_size", font_px)
	size_flags_vertical = SIZE_SHRINK_CENTER
	mouse_filter = MOUSE_FILTER_IGNORE
	_sb.set_corner_radius_all(10)
	_sb.content_margin_left = 10
	_sb.content_margin_right = 10
	_sb.content_margin_top = 2
	_sb.content_margin_bottom = 2
	add_theme_stylebox_override("normal", _sb)
	_t = randf() * 4.0
	_paint()
	set_process(mode != "plain")


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	_paint()
	queue_redraw()


func _paint() -> void:
	match mode:
		"rainbow":
			_sb.bg_color = Color.from_hsv(fmod(_t * 0.18, 1.0), 0.5, 0.95)
			_sb.border_color = Color.from_hsv(fmod(_t * 0.18 + 0.35, 1.0), 0.6, 1.0)
			_sb.set_border_width_all(3)
			add_theme_color_override("font_color", Color.WHITE)
			add_theme_color_override("font_outline_color", Color(0.35, 0.25, 0.4))
			add_theme_constant_override("outline_size", 5)
		"sparkle":
			_sb.bg_color = Color(1.0, 0.95, 0.78)
			_sb.border_color = Color.from_hsv(fmod(_t * 0.3, 1.0), 0.55, 1.0)
			_sb.set_border_width_all(4)
			add_theme_color_override("font_color", Color(0.55, 0.36, 0.08))
		_:
			_sb.bg_color = base
			_sb.set_border_width_all(0)
			var light := base.get_luminance() > 0.62
			add_theme_color_override("font_color", Color(0.25, 0.25, 0.32) if light else Color.WHITE)


## 반짝이: 오른쪽 위에 작은 별이 깜빡
func _draw() -> void:
	if mode == "plain":
		return
	var a := 0.5 + 0.5 * sin(_t * 5.0)
	var c := Vector2(size.x - 6, 5)
	var r := 6.0 * (0.6 + 0.4 * a)
	var pts := PackedVector2Array()
	for i in 8:
		var rad := r if i % 2 == 0 else r * 0.3
		var ang := i * PI / 4.0
		pts.append(c + Vector2(cos(ang), sin(ang)) * rad)
	draw_colored_polygon(pts, Color(1, 1, 1, 0.5 + 0.5 * a))
