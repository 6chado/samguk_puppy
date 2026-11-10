extends Control
## 사진 찍기 무대: 폴라로이드 틀 + 배경 + 멍냥이 1~3마리
##   1마리: 가만히 앉아 있음
##   2마리: 서로 기대서 볼을 맞댐 + 가운데 하트
##   3마리: 일렬로 앉아 머리 위에 천도복숭아
## 표정은 멍냥이마다 따로 ("expr")

const SPRITE_DIR := "res://assets/dogs/"
const FORM_NAMES: Array[String] = ["아기", "청년", "어른"]
const FORM_SCALE: Array[float] = [0.84, 0.92, 1.0]    # 아기는 조금 작게
const FRAME_COL := Color(1, 1, 1)
## 배경색: [이름, 위, 아래(바닥)]
const BACKGROUNDS: Array = [
	["핑크", Color(1.0, 0.92, 0.9), Color(0.99, 0.86, 0.82)],
	["빨강", Color(1.0, 0.86, 0.85), Color(0.97, 0.76, 0.75)],
	["노랑", Color(1.0, 0.97, 0.84), Color(0.97, 0.91, 0.72)],
	["초록", Color(0.9, 0.97, 0.87), Color(0.8, 0.92, 0.77)],
	["파랑", Color(0.88, 0.94, 1.0), Color(0.77, 0.86, 0.96)],
	["보라", Color(0.94, 0.9, 1.0), Color(0.86, 0.8, 0.96)],
]
const TEXT_COL := Color(0.45, 0.32, 0.26)
const HEART_COL := Color(1.0, 0.43, 0.56)

## 표정 이름 → 눈 그림 (+ 덧붙일 표시)
const EXPRESSIONS := {
	"기본": "open", "웃음": "squint", "찡그림": "line", "화남": "line", "졸림": "half", "잠": "closed",
}
const EXPRESSION_ORDER: Array[String] = ["기본", "웃음", "찡그림", "화남", "졸림", "잠"]

var pets: Array = []          # [{"id": dog_id, "form": 0~2, "expr": "기본"}, ...] 1~3마리
var bg := 0:                  # BACKGROUNDS 번호
	set(v):
		bg = clampi(v, 0, BACKGROUNDS.size() - 1)
		queue_redraw()
var title := "삼국지 멍냥이":    # 사진 아래 글씨 (직접 수정 가능)
	set(v):
		title = v
		queue_redraw()

var _tex: Dictionary = {}
var _top: Dictionary = {}     # 그림 경로 -> 맨 위 불투명 픽셀 높이 비율 (모자 꼭대기)


func set_pets(list: Array) -> void:
	pets = list
	queue_redraw()


func _tex_for(dog_id: String, form: int, eyes: String) -> Texture2D:
	var path := "%s%s_%d_%s.png" % [SPRITE_DIR, dog_id, form, eyes]
	if not _tex.has(path):
		_tex[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex[path]


## 그림에서 가장 위쪽(모자·귀 끝) 위치 비율 0~1
func _top_frac(dog_id: String, form: int, eyes: String) -> float:
	var path := "%s%s_%d_%s.png" % [SPRITE_DIR, dog_id, form, eyes]
	if not _top.has(path):
		var f := 4.0 / 48.0
		var tex := _tex_for(dog_id, form, eyes)
		if tex:
			var img := tex.get_image()
			if img and not img.is_empty():
				if img.is_compressed():
					img.decompress()
				f = float(img.get_used_rect().position.y) / float(img.get_height())
		_top[path] = f
	return _top[path]


func _eyes_of(pet: Dictionary) -> String:
	return EXPRESSIONS.get(pet.get("expr", "기본"), "open")


## 사진 안쪽(틀 빼고) 영역
func photo_rect() -> Rect2:
	var m := size.x * 0.045
	return Rect2(Vector2(m, m), Vector2(size.x - m * 2, size.y - m * 2 - size.y * 0.09))


func _draw() -> void:
	# 폴라로이드 틀
	draw_rect(Rect2(Vector2.ZERO, size), FRAME_COL)
	var r := photo_rect()
	# 배경: 위아래 두 색 + 바닥
	var mid := r.position.y + r.size.y * 0.62
	var back_top: Color = BACKGROUNDS[bg][1]
	var back_bottom: Color = BACKGROUNDS[bg][2]
	draw_rect(Rect2(r.position, Vector2(r.size.x, mid - r.position.y)), back_top)
	draw_rect(Rect2(Vector2(r.position.x, mid), Vector2(r.size.x, r.end.y - mid)), back_bottom)
	# 작은 반짝이 장식
	for p in [Vector2(0.1, 0.12), Vector2(0.88, 0.18), Vector2(0.16, 0.42), Vector2(0.82, 0.48), Vector2(0.5, 0.08)]:
		_draw_sparkle(r.position + r.size * p, r.size.x * 0.018, Color(1, 1, 1, 0.9))
	# 아래 글씨 (틀 위)
	var font := get_theme_default_font()
	var caption := title.strip_edges()
	if font and caption != "":
		var fs := int(size.y * 0.048)
		# 아래 흰 여백 안, 가운데보다 살짝 아래 / 가로 가운데 정렬
		var base_y := size.y - (size.y - r.end.y) * 0.32
		draw_string(font, Vector2(0, base_y), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, TEXT_COL)

	match pets.size():
		1:
			_draw_single(r)
		2:
			_draw_pair(r)
		3:
			_draw_trio(r)
		_:
			if font:
				draw_string(font, Vector2(r.position.x, r.get_center().y), "아래에서 멍냥이를 골라 주세요",
					HORIZONTAL_ALIGNMENT_CENTER, r.size.x, int(size.y * 0.04), TEXT_COL)


## 멍냥이 하나 그리기. feet = 발 위치, side = 그림 한 변, rot = 기울기(발 기준)
func _draw_pet(pet: Dictionary, feet: Vector2, side: float, rot := 0.0) -> Rect2:
	var form: int = int(pet["form"])
	side *= FORM_SCALE[form]
	var tex := _tex_for(pet["id"], form, _eyes_of(pet))
	draw_set_transform(feet, rot, Vector2.ONE)
	# 바닥 그림자
	draw_set_transform(feet, 0.0, Vector2(1.0, 0.18))
	draw_circle(Vector2.ZERO, side * 0.3, (BACKGROUNDS[bg][2] as Color).darkened(0.06))
	draw_set_transform(feet, rot, Vector2.ONE)
	var top_left := Vector2(-22.0 / 48.0 * side, -43.8 / 48.0 * side)
	if tex:
		draw_texture_rect(tex, Rect2(top_left, Vector2(side, side)), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return Rect2(feet + top_left, Vector2(side, side))


## 표정 덧표시: 화남 💢 / 잠 zZ (머리 오른쪽 위)
func _draw_mark(pet: Dictionary, box: Rect2, side: float) -> void:
	var head_tr := box.position + Vector2(0.78, 0.22) * side
	match pet.get("expr", "기본"):
		"화남":
			_draw_anger(head_tr, side * 0.1)
		"잠":
			var font := get_theme_default_font()
			if font:
				draw_string(font, head_tr + Vector2(0, -side * 0.02), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, int(side * 0.08), TEXT_COL)
				draw_string(font, head_tr + Vector2(side * 0.07, -side * 0.1), "Z", HORIZONTAL_ALIGNMENT_LEFT, -1, int(side * 0.11), TEXT_COL)


func _draw_single(r: Rect2) -> void:
	var side := r.size.y * 0.78
	var feet := Vector2(r.get_center().x, r.end.y - r.size.y * 0.1)
	var box := _draw_pet(pets[0], feet, side)
	_draw_mark(pets[0], box, box.size.x)


func _draw_pair(r: Rect2) -> void:
	var side := r.size.y * 0.66
	var y := r.end.y - r.size.y * 0.1
	var gap := side * 0.4
	var a := _draw_pet(pets[0], Vector2(r.get_center().x - gap, y), side, 0.15)    # 오른쪽으로 기댐
	var b := _draw_pet(pets[1], Vector2(r.get_center().x + gap, y), side, -0.15)   # 왼쪽으로 기댐
	_draw_mark(pets[0], a, a.size.x)
	_draw_mark(pets[1], b, b.size.x)
	_draw_heart(Vector2(r.get_center().x, y - side * 0.95), side * 0.09)


func _draw_trio(r: Rect2) -> void:
	var side := r.size.y * 0.52
	var y := r.end.y - r.size.y * 0.1
	var peach := FoodIcon.item_texture("item_peach")
	for i in 3:
		var pet: Dictionary = pets[i]
		var x := r.position.x + r.size.x * (0.2 + 0.3 * i)
		var box := _draw_pet(pet, Vector2(x, y), side)
		var s := box.size.x
		_draw_mark(pet, box, s)
		if peach:
			# 머리(모자) 꼭대기보다 한참 위에 둥실
			var form: int = int(pet["form"])
			var top := box.position.y + _top_frac(pet["id"], form, _eyes_of(pet)) * s
			var ps := side * 0.3
			var c := Vector2(box.position.x + 22.0 / 48.0 * s, top - ps * 0.5 - side * 0.07)
			draw_texture_rect(peach, Rect2(c - Vector2(ps, ps) / 2, Vector2(ps, ps)), false)


func _draw_sparkle(c: Vector2, rr: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var rad := rr if i % 2 == 0 else rr * 0.32
		var a := i * PI / 4.0
		pts.append(c + Vector2(cos(a), sin(a)) * rad)
	draw_colored_polygon(pts, col)


func _draw_heart(c: Vector2, rr: float) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var t := TAU * i / 24.0
		pts.append(c + Vector2(16.0 * pow(sin(t), 3), -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))) * (rr / 16.0))
	draw_colored_polygon(pts, HEART_COL)


## 화남 표시 💢 : 십자 틈을 두고 가운데로 휘어진 굵은 곡선 네 개
func _draw_anger(c: Vector2, rr: float) -> void:
	var col := Color(0.93, 0.18, 0.24)
	var w := maxf(3.0, rr * 0.28)
	for q in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
		var p0: Vector2 = c + Vector2(q.x * 0.3, q.y) * rr
		var p2: Vector2 = c + Vector2(q.x, q.y * 0.3) * rr
		var k: Vector2 = c + q * 0.3 * rr          # 가운데 쪽으로 당기는 점
		var pts := PackedVector2Array()
		for j in 13:
			var t := j / 12.0
			pts.append(p0 * (1 - t) * (1 - t) + k * 2.0 * (1 - t) * t + p2 * t * t)
		draw_polyline(pts, col, w, true)
		draw_circle(p0, w * 0.5, col)
		draw_circle(p2, w * 0.5, col)
