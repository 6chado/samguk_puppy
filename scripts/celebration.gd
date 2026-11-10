class_name Celebration
extends Control
## 성장 연출: 화면 번쩍 → 강아지 주변 반짝이 팡! → 폭죽 슉-팡! → "OO 강아지가 성장했어요!"
## 입력은 막지 않음 (mouse_filter IGNORE). GPU 파티클 대신 _draw 로 그려서 웹/모바일에서도 가벼움.
## 가볍게: 입자는 딕셔너리 대신 Packed 배열에 담고, 개수는 줄이고, 대신 빠르게 터지고 천천히 사라지게.

signal finished

const COLORS: Array[Color] = [
	Color("ff5a5a"), Color("ffc93c"), Color("5ad1ff"),
	Color("7dff8a"), Color("ff8ad8"), Color("fff6d8"),
]
const GRAVITY := 520.0
const BANNER_HOLD := 1.6
const ROCKET_TIME := 0.36      # 폭죽이 올라가는 시간 (짧을수록 슉!)
const DRAG := 0.05             # 1초 뒤 남는 속도 비율 (작을수록 팡 퍼졌다가 확 멈춤)

# 폭죽 (올라가는 중)
var _r_from := PackedVector2Array()
var _r_to := PackedVector2Array()
var _r_t := PackedFloat32Array()       # 음수면 아직 대기
var _r_col := PackedColorArray()
var _r_trail := PackedFloat32Array()
# 불꽃 입자
var _p_pos := PackedVector2Array()
var _p_vel := PackedVector2Array()
var _p_life := PackedFloat32Array()
var _p_max := PackedFloat32Array()
var _p_size := PackedFloat32Array()
var _p_spin := PackedFloat32Array()
var _p_col := PackedColorArray()
var _p_star := PackedByteArray()

var _flash: ColorRect
var _banner_tween: Tween
# 축하 문구는 Label/컨테이너 없이 _draw 에서 화면 가로 한가운데에 직접 그림
var _title := ""
var _subtitle := ""
var _banner_scale := 0.0:
	set(v):
		_banner_scale = v
		queue_redraw()
var _banner_alpha := 0.0:
	set(v):
		_banner_alpha = v
		queue_redraw()


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 0.92, 0)
	_flash.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_flash)
	set_process(false)


## 화면(뷰포트) 크기 - 컨트롤 크기가 어떻게 잡히든 항상 실제 화면 기준
func _screen() -> Rect2:
	return Rect2(-global_position, get_viewport_rect().size)


## center: 반짝이가 터질 위치 (보통 강아지 가운데)
func play(title: String, subtitle: String, center: Vector2) -> void:
	var scr := _screen()
	# 1) 화면 번쩍
	_flash.position = scr.position
	_flash.size = scr.size
	_flash.color.a = 0.5
	create_tween().tween_property(_flash, "color:a", 0.0, 0.25)

	# 2) 강아지 주변 반짝이 팡!
	_burst(center, 30, 260.0, 640.0, 0.7, Color.TRANSPARENT)

	# 3) 폭죽 4발: 아래에서 슉 올라가서 화면 위쪽 여기저기서 팡 (조금씩 시간차)
	for i in 4:
		var x := scr.position.x + scr.size.x * (0.14 + 0.72 * i / 3.0) + randf_range(-30, 30)
		_r_from.append(Vector2(x + randf_range(-20, 20), scr.end.y + 12))
		_r_to.append(Vector2(x, scr.position.y + scr.size.y * randf_range(0.16, 0.36)))
		_r_t.append(-(0.04 + i * 0.11))
		_r_col.append(COLORS[randi() % COLORS.size()])
		_r_trail.append(0.0)

	# 4) 축하 문구: 뿅 커졌다가 → 잠깐 머물고 → 사라짐
	_title = title
	_subtitle = subtitle
	if _banner_tween:
		_banner_tween.kill()
	_banner_alpha = 1.0
	_banner_scale = 0.2
	_banner_tween = create_tween()
	_banner_tween.tween_property(self, "_banner_scale", 1.15, 0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.tween_property(self, "_banner_scale", 1.0, 0.1)
	_banner_tween.tween_interval(BANNER_HOLD)
	_banner_tween.tween_property(self, "_banner_alpha", 0.0, 0.35)
	_banner_tween.tween_callback(func() -> void: finished.emit())
	set_process(true)


func _draw_banner() -> void:
	if _banner_alpha <= 0.0 or _title == "":
		return
	var scr := _screen()
	var font := get_theme_default_font()
	var w := scr.size.x
	var c := Vector2(scr.position.x + w / 2.0, scr.position.y + 285.0)   # 화면 가로 정중앙
	var outline := Color(0.36, 0.2, 0.1, _banner_alpha)
	draw_set_transform(c, 0.0, Vector2(_banner_scale, _banner_scale))
	var left := -w / 2.0
	draw_string_outline(font, Vector2(left, -10), _title, HORIZONTAL_ALIGNMENT_CENTER, w, 46, 14, outline)
	draw_string(font, Vector2(left, -10), _title, HORIZONTAL_ALIGNMENT_CENTER, w, 46,
		Color(1.0, 0.83, 0.3, _banner_alpha))
	draw_string_outline(font, Vector2(left, 40), _subtitle, HORIZONTAL_ALIGNMENT_CENTER, w, 30, 10, outline)
	draw_string(font, Vector2(left, 40), _subtitle, HORIZONTAL_ALIGNMENT_CENTER, w, 30,
		Color(1, 1, 1, _banner_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 한 점에서 사방으로 팡! (star_ratio = 반짝이 별 비율, base = 주로 쓸 색)
func _burst(at: Vector2, count: int, min_speed: float, max_speed: float, star_ratio: float, base: Color) -> void:
	for i in count:
		var a := TAU * (i + randf() * 0.6) / count       # 고르게 퍼지도록
		var star := randf() < star_ratio
		var col: Color = base if base.a > 0.0 and randf() < 0.7 else COLORS[randi() % COLORS.size()]
		var life := randf_range(0.7, 1.15)
		_add_particle(at, Vector2(cos(a), sin(a)) * randf_range(min_speed, max_speed), col, life,
			randf_range(6.0, 12.0) if star else randf_range(3.5, 6.5), star)


func _add_particle(pos: Vector2, vel: Vector2, col: Color, life: float, size_px: float, star: bool) -> void:
	_p_pos.append(pos)
	_p_vel.append(vel)
	_p_life.append(life)
	_p_max.append(life)
	_p_size.append(size_px)
	_p_spin.append(randf() * TAU)
	_p_col.append(col)
	_p_star.append(1 if star else 0)


func _process(delta: float) -> void:
	# 폭죽: 빠르게 솟았다가(감속) 목표 높이에서 팡
	var k := 0
	for i in _r_t.size():
		var t := _r_t[i] + delta
		if t >= ROCKET_TIME:
			var col := _r_col[i]
			_burst(_r_to[i], 24, 300.0, 720.0, 0.2, col)
			continue
		if t > 0.0:
			_r_trail[i] += delta
			if _r_trail[i] > 0.035:
				_r_trail[i] = 0.0
				_add_particle(_rocket_pos(i, t), Vector2(randf_range(-20, 20), 80), Color(1, 0.9, 0.6), 0.28, 2.5, false)
		_r_from[k] = _r_from[i]
		_r_to[k] = _r_to[i]
		_r_t[k] = t
		_r_col[k] = _r_col[i]
		_r_trail[k] = _r_trail[i]
		k += 1
	_r_from.resize(k)
	_r_to.resize(k)
	_r_t.resize(k)
	_r_col.resize(k)
	_r_trail.resize(k)

	# 불꽃 입자: 강한 공기저항(팡 퍼졌다 멈춤) + 살짝 떨어짐 + 서서히 사라짐
	var drag := pow(DRAG, delta)
	var fall := Vector2(0, GRAVITY * 0.35 * delta)
	var n := 0
	for i in _p_life.size():
		var life := _p_life[i] - delta
		if life <= 0.0:
			continue
		var vel := _p_vel[i] * drag + fall
		_p_pos[n] = _p_pos[i] + vel * delta
		_p_vel[n] = vel
		_p_life[n] = life
		_p_max[n] = _p_max[i]
		_p_size[n] = _p_size[i]
		_p_spin[n] = _p_spin[i] + delta * 6.0
		_p_col[n] = _p_col[i]
		_p_star[n] = _p_star[i]
		n += 1
	# (Packed 배열은 값으로 복사되니까 하나씩 직접 줄임)
	_p_pos.resize(n)
	_p_vel.resize(n)
	_p_life.resize(n)
	_p_max.resize(n)
	_p_size.resize(n)
	_p_spin.resize(n)
	_p_col.resize(n)
	_p_star.resize(n)

	queue_redraw()
	if _r_t.is_empty() and _p_life.is_empty() and _banner_alpha <= 0.0:
		set_process(false)


## 폭죽 위치: 처음엔 빠르고 끝에서 느려지는 슉
func _rocket_pos(i: int, t: float) -> Vector2:
	var u := clampf(t / ROCKET_TIME, 0.0, 1.0)
	u = 1.0 - (1.0 - u) * (1.0 - u)
	return _r_from[i].lerp(_r_to[i], u)


func _draw() -> void:
	_draw_particles()
	_draw_banner()


func _draw_particles() -> void:
	for i in _r_t.size():
		if _r_t[i] <= 0.0:
			continue
		var pos := _rocket_pos(i, _r_t[i])
		var dir := (_r_to[i] - _r_from[i]).normalized()
		draw_line(pos, pos - dir * 26.0, Color(1, 0.95, 0.75, 0.85), 3.0)
		draw_circle(pos, 5.0, _r_col[i])
	for i in _p_life.size():
		var t := _p_life[i] / _p_max[i]
		var col := _p_col[i]
		col.a = clampf(t * 1.4, 0.0, 1.0)
		var sz := _p_size[i] * (0.5 + 0.5 * t)
		if _p_star[i] == 1:
			_draw_star(_p_pos[i], sz, _p_spin[i], col)
		else:
			draw_circle(_p_pos[i], sz * 0.5, col)


## 반짝이 모양 (뾰족한 4각 별)
func _draw_star(c: Vector2, r: float, rot: float, col: Color) -> void:
	var pts := PackedVector2Array()
	pts.resize(8)
	for i in 8:
		var rad := r if i % 2 == 0 else r * 0.32
		var a := rot + i * PI / 4.0
		pts[i] = c + Vector2(cos(a), sin(a)) * rad
	draw_colored_polygon(pts, col)
