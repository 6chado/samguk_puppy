class_name PolyIcon
extends Control
## 로우폴리 아이콘: "heart"(애인) / "heart_empty"(호감도 빈 칸) / "skull"(앙숙) / "crown"(주군) / "trust"(신뢰 방패) / "family"(가족 집)
## 다른 노드의 _draw 에서도 PolyIcon.draw_heart(self, ...) 처럼 쓸 수 있음.

const LIGHT := -2.24
const HEART_COL := Color(1.0, 0.43, 0.56)
const BONE_COL := Color(0.95, 0.93, 0.88)
const HOLE_COL := Color(0.22, 0.18, 0.2)
const EMPTY_COL := Color(0.84, 0.80, 0.78)
const GOLD_COL := Color(0.97, 0.78, 0.30)
const GEM_COL := Color(0.86, 0.24, 0.30)
const SHIELD_COL := Color(0.36, 0.6, 0.86)
const ROOF_COL := Color(0.9, 0.56, 0.28)
const WALL_COL := Color(0.98, 0.9, 0.76)

var kind := "heart":
	set(v):
		kind = v
		queue_redraw()


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(30, 30)


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.46
	if kind == "skull":
		draw_skull(self, size / 2, r, 1.0)
	elif kind == "family":          # 가족: 주황 지붕 집
		draw_house(self, size / 2, r)
	elif kind == "trust":           # 신뢰: 파란 방패
		draw_shield(self, size / 2, r)
	elif kind == "crown":           # 주군 표시 작은 왕관
		draw_crown(self, size / 2, r)
	elif kind == "heart_empty":     # 호감도 빈 칸
		draw_heart(self, size / 2, r, 0.0, 1.0, EMPTY_COL)
	else:
		draw_heart(self, size / 2, r, 0.0, 1.0)


static func tone(col: Color, ang: float, alpha: float) -> Color:
	var d := cos(ang - LIGHT)
	var k := 1.15 if d > 0.45 else (1.0 if d > -0.25 else 0.8)
	return Color(col.r * k, col.g * k, col.b * k, alpha)


## 점들을 중심에서 부채꼴로 나눠 면마다 다른 밝기로
static func fan(ci: CanvasItem, c: Vector2, pts: PackedVector2Array, col: Color, alpha: float) -> void:
	var n := pts.size()
	for i in n:
		var a := pts[i]
		var b := pts[(i + 1) % n]
		ci.draw_colored_polygon(PackedVector2Array([c, a, b]), tone(col, ((a + b) * 0.5 - c).angle(), alpha))


static func draw_heart(ci: CanvasItem, c: Vector2, r: float, rot: float, alpha: float, col := HEART_COL) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var t := TAU * i / 10.0
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
		pts.append(c + Vector2(x, y).rotated(rot) * (r / 16.0))
	fan(ci, c + Vector2(-0.15, -0.2).rotated(rot) * r, pts, col, alpha)


static func draw_skull(ci: CanvasItem, c: Vector2, r: float, alpha: float) -> void:
	# 머리통 (팔각형)
	var head := PackedVector2Array()
	for i in 8:
		var a := TAU * i / 8.0 + PI / 8.0
		head.append(c + Vector2(cos(a) * 0.9, sin(a) * 0.78 - 0.12) * r)
	fan(ci, c + Vector2(-0.1, -0.25) * r, head, BONE_COL, alpha)
	# 턱
	var jaw := PackedVector2Array([
		c + Vector2(-0.5, 0.45) * r, c + Vector2(0.5, 0.45) * r,
		c + Vector2(0.42, 0.92) * r, c + Vector2(-0.42, 0.92) * r,
	])
	fan(ci, c + Vector2(0, 0.62) * r, jaw, BONE_COL, alpha)
	# 눈구멍 (육각형), 코 (세모), 이빨 선
	var hole := Color(HOLE_COL, alpha)
	for sx in [-1.0, 1.0]:
		var e := PackedVector2Array()
		for i in 6:
			var a := TAU * i / 6.0
			e.append(c + Vector2(sx * 0.36 + cos(a) * 0.22, -0.05 + sin(a) * 0.2) * r)
		ci.draw_colored_polygon(e, hole)
	ci.draw_colored_polygon(PackedVector2Array([
		c + Vector2(0, 0.18) * r, c + Vector2(-0.1, 0.36) * r, c + Vector2(0.1, 0.36) * r]), hole)
	for tx in [-0.2, 0.0, 0.2]:
		ci.draw_line(c + Vector2(tx, 0.55) * r, c + Vector2(tx, 0.88) * r, hole, maxf(1.0, r * 0.07))


static func draw_crown(ci: CanvasItem, c: Vector2, r: float) -> void:
	# 뾰족 3개 왕관 + 아래 띠 + 가운데 보석
	var pts := PackedVector2Array([
		c + Vector2(-0.95, 0.55) * r, c + Vector2(-0.95, -0.55) * r, c + Vector2(-0.48, -0.05) * r,
		c + Vector2(0.0, -0.8) * r, c + Vector2(0.48, -0.05) * r, c + Vector2(0.95, -0.55) * r,
		c + Vector2(0.95, 0.55) * r,
	])
	fan(ci, c + Vector2(0, 0.15) * r, pts, GOLD_COL, 1.0)
	var band := PackedVector2Array([
		c + Vector2(-0.95, 0.35) * r, c + Vector2(0.95, 0.35) * r,
		c + Vector2(0.95, 0.7) * r, c + Vector2(-0.95, 0.7) * r,
	])
	ci.draw_colored_polygon(band, tone(GOLD_COL, 2.0, 1.0))
	var gem := PackedVector2Array()
	for i in 6:
		var a := TAU * i / 6.0
		gem.append(c + Vector2(cos(a) * 0.17, 0.1 + sin(a) * 0.17) * r)
	ci.draw_colored_polygon(gem, GEM_COL)
	for x in [-0.95, 0.0, 0.95]:
		ci.draw_circle(c + Vector2(x, -0.55 if x != 0.0 else -0.8) * r, r * 0.12, tone(GOLD_COL, -2.2, 1.0))


static func draw_shield(ci: CanvasItem, c: Vector2, r: float) -> void:
	var pts := PackedVector2Array([
		c + Vector2(0, -0.92) * r, c + Vector2(0.8, -0.62) * r, c + Vector2(0.74, 0.1) * r,
		c + Vector2(0.42, 0.62) * r, c + Vector2(0, 0.94) * r, c + Vector2(-0.42, 0.62) * r,
		c + Vector2(-0.74, 0.1) * r, c + Vector2(-0.8, -0.62) * r,
	])
	fan(ci, c + Vector2(-0.1, -0.15) * r, pts, SHIELD_COL, 1.0)
	# 가운데 하얀 십자 띠
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.09, -0.7) * r, c + Vector2(0.09, -0.7) * r,
		c + Vector2(0.09, 0.72) * r, c + Vector2(-0.09, 0.72) * r]), Color(1, 1, 1, 0.85))
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.6, -0.16) * r, c + Vector2(0.6, -0.16) * r,
		c + Vector2(0.6, 0.02) * r, c + Vector2(-0.6, 0.02) * r]), Color(1, 1, 1, 0.85))


static func draw_house(ci: CanvasItem, c: Vector2, r: float) -> void:
	var wall := PackedVector2Array([
		c + Vector2(-0.62, -0.05) * r, c + Vector2(0.62, -0.05) * r,
		c + Vector2(0.62, 0.86) * r, c + Vector2(-0.62, 0.86) * r,
	])
	fan(ci, c + Vector2(0, 0.4) * r, wall, WALL_COL, 1.0)
	var roof := PackedVector2Array([
		c + Vector2(0, -0.9) * r, c + Vector2(0.95, -0.02) * r, c + Vector2(-0.95, -0.02) * r,
	])
	fan(ci, c + Vector2(0, -0.3) * r, roof, ROOF_COL, 1.0)
	# 문 (하트 모양 창 대신 단순한 문)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.18, 0.38) * r, c + Vector2(0.18, 0.38) * r,
		c + Vector2(0.18, 0.86) * r, c + Vector2(-0.18, 0.86) * r]), tone(ROOF_COL, 2.0, 1.0))
