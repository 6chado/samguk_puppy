class_name PuppyView
extends Control
## 강아지 그림 + 쓰다듬기 판정.
## assets/dogs/<id>_<form>_<eyes>.png 그림이 있으면 그걸 쓰고, 없으면 도형으로 그린 임시 강아지.
##   form : 0 새끼 / 1 청년 / 2 어른
##   eyes : open / closed(잘 때) / half(피곤할 때) / squint(>.<) / line(ㅡ.ㅡ)
## 캐릭터를 터치하면: 눈 질끈 + 꾹 눌렸다 튀어오름 + 로우폴리 하트·발바닥이 퐁퐁

signal petted

const BODY_RADIUS: Array[float] = [70.0, 95.0, 120.0, 145.0]  # 단계별 크기
const PET_DISTANCE := 140.0  # 누른 채로 이만큼 문지르면 한 번 더 쓰다듬
const PET_TIME := 0.5        # 눈 감고 꾹 눌리는 시간
const LIGHT := -2.24         # 왼쪽 위에서 빛 (로우폴리 음영용)
const HEART_COL := Color(1.0, 0.43, 0.56)
const HEART_RING := 46.0     # 하트가 머리 위 이만큼 떨어진 원 위에서 시작
const PAW_COL := Color(0.62, 0.40, 0.31)
const ANGER_COL := Color(0.92, 0.2, 0.24)
const SPRITE_DIR := "res://assets/dogs/"
## 게임 단계(0~3) → 그림 단계(form)와 크기
const STAGE_FORM: Array[int] = [0, 0, 1, 2]
const STAGE_SCALE: Array[float] = [0.53, 0.6, 0.7, 0.8]   # 단계별 크기 (전체적으로 약 13% 줄임)
## 화면 안 크기·위치 (조절은 여기서)
const BASE_W := 0.78      # 영역 가로의 몇 배까지
const BASE_H := 0.85      # 영역 세로의 몇 배까지
const CENTER_Y := 0.56    # 어른 기준 몸 한가운데가 영역 세로의 이 지점 (0.5 = 정중앙)
## 그림(48칸 기준) 안의 기준점
const FEET_Y := 43.8
const CENTER_X := 22.0
const MOUTH := Vector2(22.0, 31.5)
const HEAD_TOP_RIGHT := Vector2(36.0, 8.0)

var dog_id := "":
	set(v):
		dog_id = v
		_load_sprites()
		queue_redraw()
var _sprites: Dictionary = {}  # "form_eyes" -> Texture2D

var body_color := Color(0.9, 0.8, 0.6):
	set(v):
		body_color = v
		queue_redraw()
var stage := 0:
	set(v):
		stage = v
		queue_redraw()
var sleeping := false:
	set(v):
		sleeping = v
		queue_redraw()

var tired := false:
	set(v):
		tired = v
		queue_redraw()

var _happy_time := 0.0
var _eat_food := ""
var _eat_time := 0.0
var _eat_total := 1.0
var _pet_accum := 0.0
var _pops: Array[Dictionary] = []   # 하트·발바닥 파티클
var _pet_time := 0.0
var _angry_time := 0.0      # 고양이가 화났을 때: 부들부들 + 빨간 화남 표시
var _pet_eyes := "squint"
var _hit_rect := Rect2()             # 터치 판정 영역 (그림 위치에 맞춰 갱신)
var _anchor_box := Rect2()           # 흔들림 없는 그림 자리 (옆 버튼 위치 잡기용)
## 캐릭터 머리 오른쪽 옆에 붙어 다니는 버튼 (소개팅 하트)
var side_widget: Control
var _pop_origin := Vector2()
var _t := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(400, 380)


func _load_sprites() -> void:
	_sprites.clear()
	for form in 3:
		for eyes in ["open", "closed", "half", "squint", "line"]:
			var path := "%s%s_%d_%s.png" % [SPRITE_DIR, GameData.sprite_id(dog_id, form), form, eyes]
			if ResourceLoader.exists(path):
				_sprites["%d_%s" % [form, eyes]] = load(path)


func has_sprite() -> bool:
	return not _sprites.is_empty()


func bounce() -> void:
	_happy_time = 0.8


## 먹는 모션: 입 앞에 음식이 나타나서 냠냠 줄어듦
func eat(food_id: String, duration: float) -> void:
	_eat_food = food_id
	_eat_total = maxf(duration, 0.1)
	_eat_time = _eat_total
	_happy_time = duration


## 소개팅 버튼: 머리 오른쪽 옆(귀 바깥), 머리 높이 가운데. 화면 밖으로 안 나가게.
func _place_side_widget() -> void:
	if side_widget == null or not side_widget.visible:
		return
	var w := side_widget.size
	var box := _anchor_box
	if box.size == Vector2.ZERO:
		box = Rect2(size / 2 - Vector2(120, 120), Vector2(240, 240))
	var unit := box.size.x / 48.0
	var x := box.position.x + 40.5 * unit + 6.0
	var y := box.position.y + 20.0 * unit - w.y / 2.0
	x = clampf(x, 8.0, size.x - w.x - 8.0)
	y = clampf(y, 8.0, size.y - w.y - 8.0)
	side_widget.position = Vector2(x, y).round()


## 고양이 화남: petted 시그널을 받은 쪽(main)에서 바로 부름
func get_angry() -> void:
	_angry_time = 0.7


## 쓰다듬기: 눈 질끈 + 꾹 + 하트 퐁퐁 (화났으면 하트 대신 빨간 화남 표시)
func pet() -> void:
	_angry_time = 0.0
	petted.emit()            # 여기서 main 이 get_angry() 를 부를 수 있음
	_pet_time = PET_TIME
	_pet_eyes = "squint" if (_angry_time > 0.0 or randf() < 0.5) else "line"
	_happy_time = 0.6   # 그림 없는 장수용 ^^ 눈
	if _angry_time > 0.0:
		for i in 2:
			var side := -1.0 if i == 0 else 1.0
			_pops.append({
				"pos": _pop_origin + Vector2(side * randf_range(40, 70), randf_range(-10, 20)),
				"vel": Vector2(side * 20, -40),
				"life": 0.8, "max": 0.8, "paw": false, "angry": true,
				"size": 20.0, "rot": side * 0.3, "delay": i * 0.08,
			})
		return
	# 머리 위에서 부채꼴로 고르게 퍼지게: 각도를 나눠 갖고, 시작점도 바깥쪽 원 위에서
	var n := 2 if sleeping else 3                   # 하트 개수 (자는 중엔 더 적게)
	var spread := PI * 0.6                          # 위쪽 108도 부채꼴 (개수가 줄어서 조금 좁게)
	var start := -PI / 2 - spread / 2
	var order := range(n)
	order.shuffle()                                  # 나오는 순서만 랜덤
	for i in n:
		var slot: int = order[i]
		var a := start + spread * (slot + 0.5) / n + randf_range(-0.08, 0.08)
		var dir := Vector2(cos(a), sin(a))
		var life := randf_range(1.0, 1.25)
		_pops.append({
			"pos": _pop_origin + dir * HEART_RING,
			"vel": dir * randf_range(150, 190),
			"life": life, "max": life,
			"paw": false,
			"size": randf_range(17, 22),
			"rot": dir.x * 0.35,                     # 바깥쪽으로 살짝 기울어짐
			"delay": i * 0.06,
		})


func _process(delta: float) -> void:
	if not is_visible_in_tree():   # 안 보일 땐 매 프레임 다시 그리지 않음
		return
	_t += delta
	_happy_time = maxf(_happy_time - delta, 0.0)
	_eat_time = maxf(_eat_time - delta, 0.0)
	_pet_time = maxf(_pet_time - delta, 0.0)
	_place_side_widget()
	_angry_time = maxf(_angry_time - delta, 0.0)
	var alive: Array[Dictionary] = []
	for p in _pops:
		if p["delay"] > 0.0:
			p["delay"] -= delta
			alive.append(p)
			continue
		p["life"] -= delta
		if p["life"] <= 0.0:
			continue
		p["vel"] = p["vel"] * pow(0.15, delta) + Vector2(0, -40 * delta)   # 점점 느려지며 둥실
		p["pos"] = p["pos"] + p["vel"] * delta
		alive.append(p)
	_pops = alive
	queue_redraw()


# 터치는 emulate_mouse_from_touch 로 마우스 이벤트로 들어옴
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pet_accum = 0.0
		if _hit_rect.has_point(event.position):
			pet()
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		if not _hit_rect.has_point(event.position):
			return
		_pet_accum += event.relative.length()
		if _pet_accum >= PET_DISTANCE:
			_pet_accum = 0.0
			pet()


func _draw() -> void:
	if has_sprite():
		_draw_sprite()
	else:
		_draw_shapes()
	_draw_pops()


func _draw_sprite() -> void:
	var st := clampi(stage, 0, 3)
	var form: int = STAGE_FORM[st]
	var eyes := "open"
	if sleeping:
		eyes = "closed"
	elif _pet_time > 0.0:
		eyes = _pet_eyes
	elif tired:
		eyes = "half"
	var tex: Texture2D = _sprites.get("%d_%s" % [form, eyes], _sprites.get("%d_open" % form))
	if tex == null:
		return
	var base: float = minf(size.x * BASE_W, size.y * BASE_H)
	var S: float = base * STAGE_SCALE[st]
	var unit := S / 48.0
	# 발 위치는 단계와 상관없이 고정 → 클수록 위로 자람. 어른일 때 몸 가운데가 CENTER_Y 쯤 오게.
	var adult_unit: float = base * STAGE_SCALE[3] / 48.0
	var feet_y: float = size.y * CENTER_Y + (FEET_Y - 25.0) * adult_unit
	_anchor_box = Rect2(Vector2(size.x / 2 - CENTER_X * unit, feet_y - FEET_Y * unit), Vector2(S, S))

	# 그림자
	draw_set_transform(Vector2(size.x / 2, feet_y), 0.0, Vector2(1.0, 0.18))
	draw_circle(Vector2.ZERO, S * 0.32, Color(0, 0, 0, 0.12))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# 숨쉬기 / 신나서 폴짝
	var bob := sin(_t * (1.5 if sleeping else 3.0)) * (1.5 if sleeping else 3.0)
	if _happy_time > 0.0:
		bob -= absf(sin(_happy_time * 18.0)) * 14.0
	# 숨쉬듯 살짝 + 쓰다듬을 때 꾹 눌렸다 통통 튀어오름 (발은 바닥에 붙여둠)
	var sy := 1.0 + sin(_t * (1.5 if sleeping else 3.0)) * 0.012
	if _pet_time > 0.0:
		var p := 1.0 - _pet_time / PET_TIME
		sy -= 0.14 * exp(-4.5 * p) * cos(p * 13.0)
	var sx := 1.0 + (1.0 - sy) * 0.8
	var w := S * sx
	var h := S * sy
	var shake := sin(_t * 70.0) * 5.0 * (_angry_time / 0.7) if _angry_time > 0.0 else 0.0
	var top_left := Vector2(size.x / 2 - CENTER_X * unit * sx + shake, feet_y - FEET_Y * unit * sy + bob)
	_hit_rect = Rect2(top_left + Vector2(7, 3) * unit * Vector2(sx, sy), Vector2(30, 42) * unit * Vector2(sx, sy))
	_pop_origin = top_left + Vector2(CENTER_X * sx, 6.0 * sy) * unit   # 머리 꼭대기쯤
	var col := Color(0.86, 0.86, 0.92) if sleeping else Color.WHITE
	if _angry_time > 0.0:
		col = Color(1.0, 0.82, 0.82)
	draw_texture_rect(tex, Rect2(top_left, Vector2(w, h)), false, col)

	# 먹는 중인 음식
	if _eat_time > 0.0 and _eat_food != "":
		var progress := 1.0 - _eat_time / _eat_total
		var bites := floorf(progress * 3.0)
		var food_pos := top_left + MOUTH * unit
		FoodIcon.draw_food(self, _eat_food, food_pos, S / 440.0 * (1.0 - bites * 0.28))
		for i in int(bites) * 2:
			var ang := i * 2.1 + _t * 3.0
			draw_circle(food_pos + Vector2(cos(ang), sin(ang) * 0.5) * (S * 0.1), 3.0, Color(0.95, 0.9, 0.8))

	# Zzz
	if sleeping:
		var font := get_theme_default_font()
		var zp := top_left + HEAD_TOP_RIGHT * unit
		for i in 3:
			var float_y := fmod(_t * 20.0 + i * 8.0, 16.0)
			draw_string(font, zp + Vector2(i * 24, -i * 30 - float_y),
				"Z", HORIZONTAL_ALIGNMENT_LEFT, -1, 28 + i * 8, Color(0.4, 0.45, 0.75, 0.9))


## 그림이 아직 없는 장수용 임시 도형 강아지
func _draw_shapes() -> void:
	var r: float = BODY_RADIUS[clampi(stage, 0, BODY_RADIUS.size() - 1)]
	_hit_rect = Rect2(size / 2 - Vector2(r * 1.2, r * 1.2), Vector2(r * 2.4, r * 2.4))
	_pop_origin = size / 2 - Vector2(0, r * 0.9)
	_anchor_box = Rect2(size / 2 - Vector2(r * 1.3, r * 1.25), Vector2(r * 2.4, r * 2.4))
	var speed := 1.5 if sleeping else 3.0
	var amp := 2.0 if sleeping else 5.0
	var c := size / 2 + Vector2(0, sin(_t * speed) * amp)
	if _happy_time > 0.0:
		c.y -= absf(sin(_happy_time * 18.0)) * 14.0
	var ear_color := body_color.darkened(0.3)

	# 그림자
	draw_set_transform(Vector2(size.x / 2, size.y / 2 + r * 0.98), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, r * 0.85, Color(0, 0, 0, 0.12))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# 귀 (축 처진 귀)
	draw_circle(c + Vector2(-r * 0.78, -r * 0.35), r * 0.36, ear_color)
	draw_circle(c + Vector2(r * 0.78, -r * 0.35), r * 0.36, ear_color)
	# 얼굴
	draw_circle(c, r, body_color)
	# 주둥이
	draw_circle(c + Vector2(0, r * 0.3), r * 0.38, body_color.lightened(0.35))

	# 눈
	var eye_y := c.y - r * 0.12
	var dx := r * 0.38
	var eye_col := Color(0.12, 0.1, 0.1)
	for sx in [-1.0, 1.0]:
		var ex: float = c.x + dx * sx
		if sleeping:
			draw_arc(Vector2(ex, eye_y), r * 0.11, 0.2, PI - 0.2, 8, eye_col, 4.0)
		elif tired:
			# 반쯤 감긴 눈
			draw_line(Vector2(ex - r * 0.12, eye_y), Vector2(ex + r * 0.12, eye_y), eye_col, 4.0)
			draw_arc(Vector2(ex, eye_y), r * 0.1, 0.1, PI - 0.1, 8, eye_col, 4.0)
		elif _happy_time > 0.0:
			draw_arc(Vector2(ex, eye_y + r * 0.05), r * 0.11, PI + 0.2, TAU - 0.2, 8, eye_col, 4.0)
		else:
			draw_circle(Vector2(ex, eye_y), r * 0.1, eye_col)
			draw_circle(Vector2(ex + r * 0.03, eye_y - r * 0.03), r * 0.035, Color.WHITE)
		# 볼터치
		draw_circle(Vector2(c.x + r * 0.6 * sx, c.y + r * 0.22), r * 0.1, Color(1, 0.5, 0.5, 0.35))

	# 코
	draw_circle(c + Vector2(0, r * 0.18), r * 0.1, Color(0.15, 0.1, 0.1))
	# 혀
	if _happy_time > 0.0 and not sleeping:
		draw_circle(c + Vector2(0, r * 0.48), r * 0.1, Color(0.95, 0.45, 0.5))

	# 먹는 중인 음식 (3번에 나눠 한 입씩 줄어듦)
	if _eat_time > 0.0 and _eat_food != "":
		var progress := 1.0 - _eat_time / _eat_total
		var bites := floorf(progress * 3.0)
		var food_scale := r / 95.0 * (1.0 - bites * 0.28)
		var food_pos := c + Vector2(0, r * 0.95 + 8)
		FoodIcon.draw_food(self, _eat_food, food_pos, food_scale)
		# 부스러기
		for i in int(bites) * 2:
			var ang := i * 2.1 + _t * 3.0
			draw_circle(food_pos + Vector2(cos(ang), sin(ang) * 0.5) * (r * 0.45), 3.0, Color(0.95, 0.9, 0.8))

	# Zzz
	if sleeping:
		var font := get_theme_default_font()
		for i in 3:
			var float_y := fmod(_t * 20.0 + i * 8.0, 16.0)
			draw_string(font, c + Vector2(r * 0.7 + i * 24, -r * 0.6 - i * 30 - float_y),
				"Z", HORIZONTAL_ALIGNMENT_LEFT, -1, 28 + i * 8, Color(0.4, 0.45, 0.75, 0.9))


# ─────────── 로우폴리 하트·발바닥 ───────────
func _draw_pops() -> void:
	for p in _pops:
		if p["delay"] > 0.0:
			continue
		var age: float = p["max"] - p["life"]
		# 퐁! 하고 커졌다가 살짝 줄어듦
		var pop_scale := 1.0
		if age < 0.18:
			var k := age / 0.18
			pop_scale = 1.0 + 2.7 * pow(k - 1.0, 3) + 1.7 * pow(k - 1.0, 2)   # ease out back
		var alpha := clampf(p["life"] / (p["max"] * 0.4), 0.0, 1.0)
		var r: float = p["size"] * pop_scale
		if p.get("angry", false):
			_draw_poly_anger(p["pos"], r, p["rot"], alpha)
		elif p["paw"]:
			_draw_poly_paw(p["pos"], r, p["rot"], alpha)
		else:
			_draw_poly_heart(p["pos"], r, p["rot"], alpha)


func _tone(col: Color, ang: float, alpha: float) -> Color:
	var d := cos(ang - LIGHT)
	var k := 1.15 if d > 0.45 else (1.0 if d > -0.25 else 0.8)
	return Color(col.r * k, col.g * k, col.b * k, alpha)


## 점들을 중심에서 부채꼴로 나눠 면마다 다른 밝기로 칠함
func _fan(c: Vector2, pts: PackedVector2Array, col: Color, alpha: float) -> void:
	var n := pts.size()
	for i in n:
		var a := pts[i]
		var b := pts[(i + 1) % n]
		var mid := (a + b) * 0.5 - c
		draw_colored_polygon(PackedVector2Array([c, a, b]), _tone(col, mid.angle(), alpha))


func _draw_poly_heart(c: Vector2, r: float, rot: float, alpha: float) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var t := TAU * i / 10.0
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
		pts.append(c + Vector2(x, y).rotated(rot) * (r / 16.0))
	_fan(c + Vector2(-0.15, -0.2).rotated(rot) * r, pts, HEART_COL, alpha)


## 💢 화남 표시: 네 귀퉁이에서 꺾인 조각 4개 (로우폴리)
func _draw_poly_anger(c: Vector2, r: float, rot: float, alpha: float) -> void:
	for q in 4:
		var a := rot + q * PI / 2.0
		var pts := PackedVector2Array([
			Vector2(0.18, 0.18), Vector2(0.95, 0.30), Vector2(0.95, 0.62),
			Vector2(0.62, 0.62), Vector2(0.30, 0.95), Vector2(0.18, 0.95),
		])
		for i in pts.size():
			pts[i] = c + pts[i].rotated(a) * r
		_fan(c + Vector2(0.5, 0.5).rotated(a) * r, pts, ANGER_COL, alpha)


func _draw_poly_paw(c: Vector2, r: float, rot: float, alpha: float) -> void:
	# 큰 발바닥 (육각형)
	var pad_c := c + Vector2(0, 0.28 * r).rotated(rot)
	var pad := PackedVector2Array()
	for i in 6:
		var a := TAU * i / 6.0 + PI / 6.0
		pad.append(pad_c + Vector2(cos(a) * 0.58, sin(a) * 0.46).rotated(rot) * r)
	_fan(pad_c + Vector2(-0.08, -0.08).rotated(rot) * r, pad, PAW_COL, alpha)
	# 발가락 4개 (오각형)
	for off in [Vector2(-0.62, -0.28), Vector2(-0.22, -0.62), Vector2(0.22, -0.62), Vector2(0.62, -0.28)]:
		var tc: Vector2 = c + (off as Vector2).rotated(rot) * r
		var toe := PackedVector2Array()
		for i in 5:
			var a := TAU * i / 5.0 - PI / 2.0
			toe.append(tc + Vector2(cos(a), sin(a)).rotated(rot) * (0.22 * r))
		_fan(tc, toe, PAW_COL, alpha)
