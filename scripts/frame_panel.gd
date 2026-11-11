extends PanelContainer
## 액자 프레임 카드: 바깥 테두리가 그라데이션 (스페셜 칭호 카드)

const GradTag := preload("res://scripts/gradient_tag.gd")

var c1 := Color.WHITE
var c2 := Color.WHITE
var bg := Color(0.97, 0.93, 0.86)
var frame_w := 7.0
var rad := 22.0


func setup(from: Color, to: Color, pad: int) -> void:
	c1 = from
	c2 = to
	var sb := StyleBoxEmpty.new()
	sb.set_content_margin_all(pad + frame_w)
	add_theme_stylebox_override("panel", sb)
	mouse_filter = MOUSE_FILTER_PASS
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	GradTag.draw_grad(self, r, rad, c1, c2)
	var inner := r.grow(-frame_w)
	draw_colored_polygon(GradTag.round_rect(inner, maxf(rad - frame_w, 4.0)), bg)
