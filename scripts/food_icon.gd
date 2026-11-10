class_name FoodIcon
extends Control
## 음식·아이콘 그림. assets/items/<id>.png (로우폴리) 가 있으면 그걸, 없으면 예전 도형으로.
##   id: rice(사료) / meat(고기) / sweet_potato(고고마) / dumpling(만두) / cat_grass(캣그라스)
## 다른 노드의 _draw 안에서도 FoodIcon.draw_food(self, ...) 로 그릴 수 있음.

const OUTLINE := Color(0.33, 0.2, 0.12)
const ITEM_DIR := "res://assets/items/"

static var _tex_cache: Dictionary = {}


static func item_texture(id: String) -> Texture2D:
	if not _tex_cache.has(id):
		var path := ITEM_DIR + id + ".png"
		_tex_cache[id] = load(path) if ResourceLoader.exists(path) else null
	return _tex_cache[id]

var food_id := "rice":
	set(v):
		food_id = v
		queue_redraw()


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _draw() -> void:
	draw_food(self, food_id, size / 2, minf(size.x, size.y) / 64.0)


## 64x64 기준 좌표(-32~32)로 그림. zoom 으로 크기 조절.
static func draw_food(ci: CanvasItem, id: String, center: Vector2, zoom: float, alpha := 1.0) -> void:
	var tex := item_texture(id)
	if tex:
		var side := 64.0 * zoom
		ci.draw_texture_rect(tex, Rect2(center - Vector2(side, side) / 2, Vector2(side, side)), false, Color(1, 1, 1, alpha))
		return
	ci.draw_set_transform(center, 0.0, Vector2(zoom, zoom))
	match id:
		"rice":
			_rice(ci, alpha)
		"meat":
			_meat(ci, alpha)
		"sweet_potato":
			_sweet_potato(ci, alpha)
		"dumpling":
			_dumpling(ci, alpha)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _c(col: Color, alpha: float) -> Color:
	return Color(col, col.a * alpha)


static func _ellipse(c: Vector2, rx: float, ry: float, rot := 0.0, n := 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts


static func _shape(ci: CanvasItem, pts: PackedVector2Array, fill: Color, alpha: float) -> void:
	ci.draw_colored_polygon(pts, _c(fill, alpha))
	var loop := pts.duplicate()
	loop.append(pts[0])
	ci.draw_polyline(loop, _c(OUTLINE, alpha), 2.5, true)


static func _rice(ci: CanvasItem, a: float) -> void:
	var white := Color(0.99, 0.98, 0.94)
	# 밥 봉우리
	for p in [Vector2(-11, 0), Vector2(11, 0), Vector2(0, -8)]:
		var r := 13.0 if p.y < 0 else 11.0
		ci.draw_circle(p, r + 1.5, _c(OUTLINE, a))
	for p in [Vector2(-11, 0), Vector2(11, 0), Vector2(0, -8)]:
		ci.draw_circle(p, 13.0 if p.y < 0 else 11.0, _c(white, a))
	# 밥알 반짝
	for p in [Vector2(-6, -10), Vector2(4, -4), Vector2(-12, -2), Vector2(10, -6)]:
		ci.draw_circle(p, 1.8, _c(Color(0.85, 0.83, 0.78), a))
	# 그릇
	var bowl := PackedVector2Array()
	for i in range(0, 13):
		var ang := PI * i / 12.0
		bowl.append(Vector2(cos(ang) * 27, 4 + sin(ang) * 22))
	_shape(ci, bowl, Color(0.36, 0.52, 0.78), a)
	ci.draw_line(Vector2(-20, 14), Vector2(20, 14), _c(Color(0.9, 0.95, 1.0, 0.7), a), 3.0)
	_shape(ci, PackedVector2Array([Vector2(-9, 25), Vector2(9, 25), Vector2(7, 30), Vector2(-7, 30)]),
		Color(0.3, 0.44, 0.68), a)


static func _meat(ci: CanvasItem, a: float) -> void:
	var bone := Color(0.98, 0.96, 0.9)
	# 뼈
	ci.draw_line(Vector2(6, 6), Vector2(22, 22), _c(OUTLINE, a), 10.0)
	ci.draw_line(Vector2(6, 6), Vector2(22, 22), _c(bone, a), 6.0)
	for p in [Vector2(20, 27), Vector2(27, 20)]:
		ci.draw_circle(p, 6.5, _c(OUTLINE, a))
	for p in [Vector2(20, 27), Vector2(27, 20)]:
		ci.draw_circle(p, 5.0, _c(bone, a))
	# 고기
	_shape(ci, _ellipse(Vector2(-5, -5), 22, 16, PI / 4), Color(0.72, 0.36, 0.22), a)
	ci.draw_colored_polygon(_ellipse(Vector2(-10, -10), 9, 5, PI / 4, 16), _c(Color(0.88, 0.55, 0.38), a))


static func _sweet_potato(ci: CanvasItem, a: float) -> void:
	# 싹
	_shape(ci, _ellipse(Vector2(22, -16), 8, 4, -0.9, 12), Color(0.45, 0.72, 0.35), a)
	# 몸통
	_shape(ci, _ellipse(Vector2(0, 2), 27, 15, -0.35), Color(0.64, 0.26, 0.38), a)
	# 반쯤 까진 노란 속살
	ci.draw_colored_polygon(_ellipse(Vector2(-16, 9), 9, 7, -0.35, 16), _c(Color(0.98, 0.8, 0.35), a))
	for p in [Vector2(2, -4), Vector2(10, 4), Vector2(-4, 8)]:
		ci.draw_line(p, p + Vector2(4, -1), _c(Color(0.42, 0.15, 0.25), a), 2.0)


static func _dumpling(ci: CanvasItem, a: float) -> void:
	var dough := Color(0.97, 0.93, 0.83)
	var pts := PackedVector2Array()
	for i in range(0, 17):
		var ang := PI + PI * i / 16.0
		pts.append(Vector2(cos(ang) * 28, 14 + sin(ang) * 30))
	pts.append(Vector2(26, 18))
	pts.append(Vector2(-26, 18))
	_shape(ci, pts, dough, a)
	# 주름
	for x in [-14.0, -5.0, 4.0, 13.0]:
		var top := Vector2(x, 14 - sqrt(maxf(28.0 * 28.0 - x * x, 0.0)) * 30.0 / 28.0 + 4)
		ci.draw_line(top, top + Vector2(-x * 0.15, 12), _c(Color(0.75, 0.66, 0.5), a), 2.0)
	# 김
	for x in [-8.0, 6.0]:
		ci.draw_arc(Vector2(x, -22), 4, PI * 0.5, PI * 1.5, 8, _c(Color(0.7, 0.7, 0.7, 0.6), a), 2.0)
