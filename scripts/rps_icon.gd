extends Control
## 대전 카드 그림: 로우폴리 가위바위보 + 불 (100x100 칸 기준 좌표)
##   기병 = 바위 ✊, 궁병 = 가위 ✌, 창병 = 보 ✋, 화공 = 불
##   (바위 > 가위 > 보 > 바위  =  기병 > 궁병 > 창병 > 기병)

const CARD_ICON := {"cav": "rock", "arc": "scissors", "spr": "paper", "fire": "fire"}
static var SHAPES := {   # (Packed 배열이라 const 대신 static var)
	"rock": [
		[PackedVector2Array([Vector2(20, 46), Vector2(80, 46), Vector2(84, 78), Vector2(72, 96), Vector2(30, 96), Vector2(18, 78)]), Color(0.953, 0.745, 0.557)],
		[PackedVector2Array([Vector2(20, 46), Vector2(50, 46), Vector2(46, 96), Vector2(30, 96), Vector2(18, 78)]), Color(1.000, 0.855, 0.690)],
		[PackedVector2Array([Vector2(20, 30), Vector2(35, 28), Vector2(37, 50), Vector2(21, 52)]), Color(1.000, 0.855, 0.690)],
		[PackedVector2Array([Vector2(35, 26), Vector2(50, 25), Vector2(51, 50), Vector2(37, 50)]), Color(0.953, 0.745, 0.557)],
		[PackedVector2Array([Vector2(50, 25), Vector2(65, 26), Vector2(65, 50), Vector2(51, 50)]), Color(1.000, 0.855, 0.690)],
		[PackedVector2Array([Vector2(65, 28), Vector2(79, 31), Vector2(80, 52), Vector2(65, 50)]), Color(0.953, 0.745, 0.557)],
		[PackedVector2Array([Vector2(16, 58), Vector2(50, 56), Vector2(58, 66), Vector2(52, 74), Vector2(20, 72)]), Color(0.863, 0.627, 0.439)],
		[PackedVector2Array([Vector2(16, 58), Vector2(50, 56), Vector2(36, 66), Vector2(20, 72)]), Color(0.953, 0.745, 0.557)],
	],
	"scissors": [
		[PackedVector2Array([Vector2(42.74, 58.11), Vector2(28.74, 8.11), Vector2(20.68, 5.28), Vector2(15.26, 11.89), Vector2(29.26, 61.89)]), Color(1.000, 0.855, 0.690)],
		[PackedVector2Array([Vector2(58.82, 61.57), Vector2(70.82, 9.57), Vector2(65.1, 3.23), Vector2(57.18, 6.43), Vector2(45.18, 58.43)]), Color(0.953, 0.745, 0.557)],
		[PackedVector2Array([Vector2(24, 52), Vector2(76, 52), Vector2(80, 80), Vector2(68, 96), Vector2(32, 96), Vector2(20, 80)]), Color(0.953, 0.745, 0.557)],
		[PackedVector2Array([Vector2(24, 52), Vector2(50, 52), Vector2(46, 96), Vector2(32, 96), Vector2(20, 80)]), Color(1.000, 0.855, 0.690)],
		[PackedVector2Array([Vector2(60, 50), Vector2(78, 54), Vector2(79, 66), Vector2(62, 64)]), Color(0.863, 0.627, 0.439)],
		[PackedVector2Array([Vector2(18, 62), Vector2(44, 64), Vector2(46, 76), Vector2(22, 76)]), Color(0.863, 0.627, 0.439)],
	],
	"paper": [
		[PackedVector2Array([Vector2(36.95, 51.26), Vector2(31.95, 11.26), Vector2(25.48, 7.83), Vector2(20.05, 12.74), Vector2(25.05, 52.74)]), Color(1.000, 0.855, 0.690)],
		[PackedVector2Array([Vector2(50, 49.87), Vector2(49, 3.87), Vector2(42.91, -0.2), Vector2(37, 4.13), Vector2(38, 50.13)]), Color(0.953, 0.745, 0.557)],
		[PackedVector2Array([Vector2(62.99, 50.41), Vector2(65.99, 6.41), Vector2(60.29, 1.81), Vector2(54.01, 5.59), Vector2(51.01, 49.59)]), Color(1.000, 0.855, 0.690)],
		[PackedVector2Array([Vector2(75.93, 54.94), Vector2(81.93, 16.94), Vector2(76.66, 11.85), Vector2(70.07, 15.06), Vector2(64.07, 53.06)]), Color(0.953, 0.745, 0.557)],
		[PackedVector2Array([Vector2(33.11, 65.98), Vector2(11.11, 37.98), Vector2(3.19, 38.42), Vector2(0.89, 46.02), Vector2(22.89, 74.02)]), Color(0.863, 0.627, 0.439)],
		[PackedVector2Array([Vector2(22, 48), Vector2(78, 48), Vector2(82, 80), Vector2(70, 96), Vector2(32, 96), Vector2(20, 80)]), Color(0.953, 0.745, 0.557)],
		[PackedVector2Array([Vector2(22, 48), Vector2(50, 48), Vector2(46, 96), Vector2(32, 96), Vector2(20, 80)]), Color(1.000, 0.855, 0.690)],
	],
	"fire": [
		[PackedVector2Array([Vector2(50, 4), Vector2(70, 30), Vector2(82, 56), Vector2(78, 80), Vector2(62, 96), Vector2(38, 96), Vector2(22, 80), Vector2(18, 58), Vector2(30, 40), Vector2(36, 52), Vector2(42, 26)]), Color(0.910, 0.282, 0.157)],
		[PackedVector2Array([Vector2(50, 4), Vector2(42, 26), Vector2(36, 52), Vector2(30, 40), Vector2(18, 58), Vector2(22, 80), Vector2(38, 96), Vector2(50, 96)]), Color(0.965, 0.408, 0.188)],
		[PackedVector2Array([Vector2(52, 34), Vector2(66, 56), Vector2(70, 76), Vector2(60, 92), Vector2(40, 92), Vector2(30, 78), Vector2(34, 60), Vector2(42, 66)]), Color(0.980, 0.643, 0.204)],
		[PackedVector2Array([Vector2(52, 56), Vector2(60, 70), Vector2(58, 86), Vector2(42, 86), Vector2(38, 74), Vector2(46, 74)]), Color(1.000, 0.886, 0.431)],
	],
}

var kind := "rock":
	set(v):
		kind = CARD_ICON.get(v, v)
		queue_redraw()


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _draw() -> void:
	if not SHAPES.has(kind):
		return
	var s := minf(size.x, size.y) / 100.0
	var o := (size - Vector2(100, 100) * s) / 2.0
	for item in SHAPES[kind]:
		var pts := PackedVector2Array()
		for p in (item[0] as PackedVector2Array):
			pts.append(o + p * s)
		draw_colored_polygon(pts, item[1])
