extends Control
## 튜토리얼 스포트라이트: 화면을 어둡게 하고 targets 부분만 뚫어서 반짝이게 + 말풍선
##   action = false : 아무 데나 누르면 다음 (tapped 시그널)
##   action = true  : 뚫린 곳(버튼)만 직접 누를 수 있음. 다음으로 넘어가는 건 main 이 정함

signal tapped

const DIM := Color(0, 0, 0, 0.6)
const GLOW := Color(1.0, 0.85, 0.3)

var targets: Array = []
var action := false
var _hole := Rect2()
var _t := 0.0
var _panel: PanelContainer
var _label: Label
var _hint: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	_panel = PanelContainer.new()
	_panel.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_panel)
	var v := VBoxContainer.new()
	v.mouse_filter = MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 10)
	_panel.add_child(v)
	_label = Label.new()
	_label.mouse_filter = MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(520, 0)
	_label.add_theme_font_size_override("font_size", 34)
	v.add_child(_label)
	_hint = Label.new()
	_hint.mouse_filter = MOUSE_FILTER_IGNORE
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 22)
	_hint.add_theme_color_override("font_color", Color(0.6, 0.5, 0.42))
	v.add_child(_hint)
	hide()
	set_process(false)


func show_step(text: String, step_targets: Array, is_action: bool) -> void:
	targets = step_targets
	action = is_action
	_label.text = text
	_hint.text = "반짝이는 곳을 눌러 보세요!" if is_action else "화면을 눌러 계속 →"
	show()
	move_to_front()
	set_process(true)
	_update_hole()
	_place_panel()
	queue_redraw()


func finish() -> void:
	hide()
	set_process(false)
	targets = []


func _process(delta: float) -> void:
	_t += delta
	_update_hole()
	_place_panel()
	queue_redraw()


## 대상 컨트롤들을 다 감싸는 사각형 (안 보이는 건 빼고)
func _update_hole() -> void:
	var r := Rect2()
	var first := true
	for c in targets:
		if c == null or not is_instance_valid(c) or not (c as Control).is_visible_in_tree():
			continue
		var g: Rect2 = (c as Control).get_global_rect()
		if g.size == Vector2.ZERO:
			continue
		r = g if first else r.merge(g)
		first = false
	if first:
		_hole = Rect2()
		return
	_hole = Rect2(r.position - global_position, r.size).grow(10)


## 말풍선: 뚫린 곳이 아래쪽이면 그 위에, 위쪽이면 그 아래에 (없으면 가운데)
func _place_panel() -> void:
	_panel.reset_size()
	var ps := _panel.get_combined_minimum_size()
	var x := (size.x - ps.x) / 2.0
	var y: float
	if _hole.size == Vector2.ZERO:
		y = (size.y - ps.y) / 2.0
	elif _hole.get_center().y > size.y * 0.5:
		y = _hole.position.y - ps.y - 24.0
	else:
		y = _hole.end.y + 24.0
	_panel.position = Vector2(x, clampf(y, 20.0, maxf(20.0, size.y - ps.y - 20.0)))


func _draw() -> void:
	if _hole.size == Vector2.ZERO:
		draw_rect(Rect2(Vector2.ZERO, size), DIM)
		return
	var h := _hole
	draw_rect(Rect2(0, 0, size.x, h.position.y), DIM)
	draw_rect(Rect2(0, h.end.y, size.x, size.y - h.end.y), DIM)
	draw_rect(Rect2(0, h.position.y, h.position.x, h.size.y), DIM)
	draw_rect(Rect2(h.end.x, h.position.y, size.x - h.end.x, h.size.y), DIM)
	var pulse := 0.5 + 0.5 * sin(_t * 5.0)
	draw_rect(h, Color(GLOW, 0.55 + 0.45 * pulse), false, 5.0)


## 직접 눌러야 하는 단계: 뚫린 곳 클릭은 아래 버튼으로 그대로 통과
func _has_point(point: Vector2) -> bool:
	if action and _hole.has_point(point):
		return false
	return true


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if not action:
			tapped.emit()
