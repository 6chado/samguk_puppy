class_name HeartButton
extends Control
## 하트 모양 버튼 (천천히 둥실둥실 떠다님). 글자는 text 로 바꿈

signal pressed

const PolyIconScript := preload("res://scripts/poly_icon.gd")

var disabled := false:
	set(v):
		disabled = v
		queue_redraw()

var text := "소개팅":
	set(v):
		text = v
		if _label:
			_label.text = v

var _t := 0.0
var _press := 0.0
var _label: Label


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(108, 100)
	size = custom_minimum_size
	_label = Label.new()
	_label.text = text
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color(0.6, 0.15, 0.3))
	_label.add_theme_constant_override("outline_size", 6)
	_label.mouse_filter = MOUSE_FILTER_IGNORE
	_label.set_anchors_preset(PRESET_FULL_RECT)
	_label.offset_top = -6
	add_child(_label)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	_press = maxf(_press - delta, 0.0)
	var s := _scale_now()
	_label.pivot_offset = size / 2
	_label.scale = Vector2(s, s)
	_label.position.y = _bob()
	queue_redraw()


const FLOAT_PERIOD := 3.0   # 위아래로 한 번 둥실 오가는 시간(초)
const FLOAT_HEIGHT := 3.5   # 둥실 높이(px)
const FLOAT_TILT := 0.06    # 살짝 갸웃 (라디안)


## 살살 떠다니기: 천천히 위아래 + 아주 살짝 기울기
func _bob() -> float:
	return sin(_t * TAU / FLOAT_PERIOD) * FLOAT_HEIGHT


func _tilt() -> float:
	return sin(_t * TAU / (FLOAT_PERIOD * 1.7)) * FLOAT_TILT


## 크기는 그대로, 누를 때만 쏙 작아짐
func _scale_now() -> float:
	return 1.0   # 누를 때 모션은 main 의 젤리(보잉)로 통일


func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_press = 0.15
		accept_event()
		pressed.emit()


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.5 * _scale_now()
	var col := PolyIconScript.HEART_COL if not disabled else Color(0.75, 0.7, 0.72)
	PolyIconScript.draw_heart(self, size / 2 + Vector2(0, 4 + _bob()), r, _tilt(), 1.0, col)
