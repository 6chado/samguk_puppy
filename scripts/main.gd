extends Control
## 화면 전체를 코드로 구성: 홈 / 키우러 가기(목록) / 도감 / 키우기 화면 + 오버레이(전투·알림·관계도·가방)
## 나중에 씬으로 옮기거나 스프라이트로 바꿔도 로직 함수들은 그대로 쓰면 됨

const FONT_PATH := "res://assets/fonts/main.ttf"  # 한글 폰트 넣을 위치 (웹에서 필수)
## 온글잎 박다현체 전용: ♤ ♧ 를 쓰면 고양이 얼굴이 나옴
const CAT := "♤"
const CAT2 := "♧"
const BG_COLOR := Color(0.98, 0.95, 0.88)
const TEXT_COLOR := Color(0.28, 0.22, 0.16)
const SUB_COLOR := Color(0.52, 0.42, 0.34)
const PINK := Color(0.94, 0.42, 0.56)
const SPRITE_DIR := "res://assets/dogs/"

const ENEMIES: Array[String] = ["황건적 멍멍이", "산적 똥개", "남만 들개", "동탁군 불독", "원소군 진돗개"]
const BATTLE_MOVES: Array[String] = ["박치기", "앞발 펀치", "꼬리 휘두르기", "왕왕 짖기", "몸통 박치기"]
const STRATEGIES: Array[String] = ["화공", "매복", "이간"]  # i 는 (i+1)%3 을 이김
const PET_MESSAGES: Array[String] = ["좋아!", "꼬리 붕붕", "더 쓰다듬어줘!", "멍!", "발라당"]
const CAT_PET_MESSAGES: Array[String] = ["골골골...", "냐옹", "왜옭", "먕", "냐냐냐"]   # "먉"은 폰트에 없어서 "먕"
const CAT_ANGRY_MESSAGES: Array[String] = ["하악!", "저리 가!", "그만 만져!", "꺼져!"]
const PLAY_MESSAGES: Array[String] = ["공놀이를 했어요!", "같이 낮잠을 잤어요!", "꼬리잡기를 했어요!", "간식을 나눠 먹었어요!"]

var puppy: Puppy
var busy := false
var _pending_gift: Dictionary = {}
var _overlay_mode := ""
var _last_pet_ms := -100000
var _pet_streak := 0
var _tex_cache: Dictionary = {}
var _tab_faction := ""     # 목록·도감에서 고른 진영 탭

## 글씨 크기 전체 배율 (전부 조금씩 크게)
const FONT_SCALE := 1.2
## 버튼 누를 때 젤리 출렁임 세기 (1.0 = 처음 버전, 0.5 = 절반)
const JELLY := 0.5
const FACTION_COLORS := {"shu": Color(0.24, 0.6, 0.36), "wei": Color(0.26, 0.4, 0.72), "wu": Color(0.82, 0.28, 0.28),
	"special": Color(0.52, 0.32, 0.7)}

var page: Control          # 홈 / 목록 / 도감 (매번 새로 만듦)
var raise_screen: Control

var title_label: Label
var stage_label: Label
var exp_bar: ProgressBar
var exp_label: Label
var fatigue_bar: ProgressBar
var fatigue_label: Label
var sleep_button: Button
var bag_button: Button
var puppy_view: PuppyView
var message_label: Label
var food_buttons: Dictionary = {}
var battle_button: Button
var back_button: Button

var overlay: Control
var overlay_title: Label
var overlay_image: TextureRect
var overlay_log: Label
var strategy_box: HBoxContainer
var drops_box: HBoxContainer
var confirm_button: Button
var cancel_button: Button      # 경고창에서만 보이는 "취소"
var celebration: Celebration
# 새로 추가한 스크립트는 class_name 등록이 늦을 수 있어서 preload 로 직접 불러옴
const HeartButtonScript := preload("res://scripts/heart_button.gd")
const PolyIconScript := preload("res://scripts/poly_icon.gd")
var relation_button
var relation_box: VBoxContainer
var relation_scroll: ScrollContainer   # 관계가 많으면 이 안에서 손가락 스크롤

const TutorialScript := preload("res://scripts/tutorial_layer.gd")
const PhotoStageScript := preload("res://scripts/photo_stage.gd")
var _photo_sel: Array[String] = []     # 고른 멍냥이 (고른 순서 = 왼쪽부터)
var _photo_expr: Dictionary = {}      # dog_id -> 표정 이름
var _photo_stage                       # 사진 무대
var _photo_cards: Dictionary = {}      # dog_id -> 카드 버튼
var _photo_expr_box: VBoxContainer
var _photo_ui: Array = []
var _photo_title := "삼국지 멍냥이"     # 사진 아래 글씨
var _photo_form: Dictionary = {}      # dog_id -> 사진에서 쓸 모습 (0 아기 / 1 청년 / 2 어른)
var _photo_bg := 0                    # 배경색 번호
var _photo_bg_btns: Array = []              # 찰칵 모드에서 숨길 것들
var tut                        # 튜토리얼 스포트라이트
var _tut_step := -1
var _tut_wait := ""            # 지금 단계가 기다리는 행동 (battle / fed / home / gacha_page / gacha_done)
var food_row: HBoxContainer
var _home_gacha_btn: Button
var _gacha_pull: Button
var _gacha_ticket_row: Control
var _gacha_ticket_label: Label

var rel_overlay: Control
var rel_title: Label
var rel_msg: Label
var rel_list: VBoxContainer
var bag_overlay: Control
var bag_list: VBoxContainer


## 멈춤 원인 추적용: 로그 파일에 바로 기록됨 (flush_stdout_on_print)
func _log(msg: String) -> void:
	print("[%s] %s" % [Time.get_time_string_from_system(), msg])


func _ready() -> void:
	_log("시작")
	randomize()
	_setup_theme()
	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)
	_build_raise_screen()
	_build_overlay()
	var r := _build_panel_overlay(Vector2(600, 720))
	rel_overlay = r[0]
	var rv: VBoxContainer = r[1]
	rel_title = _label("", 36)
	rv.add_child(rel_title)
	var hint := _label("놀기로 하트를, 선물하기로 복숭아를 채워요. 꽉 차면 고백 / 의형제!\n같은 진영은 금방 친해져요. 신뢰 관계는 한 칸 덜 채워도 돼요.", 20)
	hint.add_theme_color_override("font_color", SUB_COLOR)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rv.add_child(hint)
	rel_msg = _label(" ", 24)
	rel_msg.add_theme_color_override("font_color", PINK.darkened(0.2))
	rv.add_child(rel_msg)
	rel_list = r[2]
	var b := _build_panel_overlay(Vector2(600, 620))
	bag_overlay = b[0]
	(b[1] as VBoxContainer).add_child(_label("가방 (희귀템)", 36))
	var bag_hint := _label("전투·책략에서 가끔 나와요. 한 번 쓰면 사라져요.", 20)
	bag_hint.add_theme_color_override("font_color", SUB_COLOR)
	(b[1] as VBoxContainer).add_child(bag_hint)
	bag_list = b[2]
	celebration = Celebration.new()  # 성장 연출 (맨 위, 터치는 통과)
	add_child(celebration)
	tut = TutorialScript.new()
	add_child(tut)
	tut.tapped.connect(_tut_next)
	_show_home()
	if not GameState.tutorial_done:
		_tut_start()
	_log("시작 완료")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		GameState.save_now()


# ═════════════════════════ 홈 / 목록 / 도감 ═════════════════════════

## 새 페이지 틀: 이전 페이지 지우고, 오버레이들보다 아래에 깔기
func _new_page() -> VBoxContainer:
	raise_screen.hide()
	overlay.hide()
	if page:
		page.queue_free()
	var m := _screen_margin()
	move_child(m, 1)
	page = m
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)
	return v


## 왼쪽 "← 뒤로" + 가운데 제목
func _page_header(v: VBoxContainer, back_text: String, back_cb: Callable, title: String) -> void:
	var header := HBoxContainer.new()
	v.add_child(header)
	var back := _button(back_text, back_cb)
	back.custom_minimum_size = Vector2(150, 70)
	back.add_theme_font_size_override("font_size", _fs(24))
	header.add_child(back)
	var t := _label(title, 38)
	t.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(t)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(150, 0)
	header.add_child(spacer)


func _scroll_list(v: VBoxContainer) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER   # 모바일: 바 없이 손가락으로 스크롤
	v.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 16)
	scroll.add_child(list)
	return list


func _grid(list: VBoxContainer) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	list.add_child(grid)
	return grid


func _show_home() -> void:
	_log("홈 화면")
	var v := _new_page()
	var top_row := HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(top_row)
	var reset := _button("초기화", _ask_reset)
	reset.custom_minimum_size = Vector2(110, 48)
	reset.add_theme_font_size_override("font_size", _fs(18))
	var grey := Color(0.72, 0.68, 0.64)
	reset.add_theme_stylebox_override("normal", _box(grey, 14))
	reset.add_theme_stylebox_override("hover", _box(grey.lightened(0.1), 14))
	reset.add_theme_stylebox_override("pressed", _box(grey.darkened(0.15), 14))
	top_row.add_child(reset)
	v.add_child(_label("%s 삼국지 멍냥이 키우기 %s" % [CAT, CAT2], 37))

	var ticket_row := HBoxContainer.new()
	ticket_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ticket_row.add_theme_constant_override("separation", 8)
	v.add_child(ticket_row)
	var ticket_icon := TextureRect.new()
	ticket_icon.texture = FoodIcon.item_texture("ticket")
	ticket_icon.custom_minimum_size = Vector2(52, 52)
	ticket_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ticket_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ticket_row.add_child(ticket_icon)
	ticket_row.add_child(_label("뽑기권 %d장" % GameState.tickets, 28))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(30, 0)
	ticket_row.add_child(spacer)
	ticket_row.add_child(_label("도감 %d/%d" % [GameState.owned.size(), GameData.DOGS.size()], 28))

	var id: String = GameState.current
	var home_view := PuppyView.new()   # 홈에서도 쓰다듬으면 하트는 나옴 (수치는 안 바뀜)
	home_view.size_flags_vertical = SIZE_EXPAND_FILL
	v.add_child(home_view)
	home_view.body_color = GameData.DOGS[id]["color"]
	home_view.dog_id = id
	home_view.stage = GameState.stage_of(id)
	v.add_child(_label("%s  ·  %s" % [GameData.DOGS[id]["name"], GameData.stage_name(GameState.stage_of(id), id)], 34))

	var go := _button("키우러 가기", _show_roster)
	go.custom_minimum_size = Vector2(0, 120)
	go.add_theme_font_size_override("font_size", _fs(38))
	v.add_child(go)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var gacha := _button("뽑기", _show_gacha)
	_home_gacha_btn = gacha
	_set_button_icon(gacha, "ticket")
	gacha.custom_minimum_size = Vector2(0, 110)
	gacha.size_flags_horizontal = SIZE_EXPAND_FILL
	var pink := PINK
	gacha.add_theme_stylebox_override("normal", _box(pink, 18))
	gacha.add_theme_stylebox_override("hover", _box(pink.lightened(0.1), 18))
	gacha.add_theme_stylebox_override("pressed", _box(pink.darkened(0.15), 18))
	row.add_child(gacha)
	var dex := _button("도감", _show_dex)
	_set_button_icon(dex, "icon_strategy")
	dex.custom_minimum_size = Vector2(0, 110)
	dex.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(dex)
	var cam := _button("사진", _show_photo)
	_set_button_icon(cam, "icon_camera")
	cam.custom_minimum_size = Vector2(0, 110)
	cam.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(cam)


## 키우러 가기: 데리고 있는 멍냥이를 진영 탭별로
func _show_roster() -> void:
	_faction_page("roster")


## 도감: 모은 멍냥이는 키운 데까지의 그림 + 이름 (누르면 성장 그림), 모르는 애는 ???
func _show_dex() -> void:
	_faction_page("dex")


## 진영 탭(촉/위/오) + 맨 위 가운데 주군 한 마리 + 그 아래 3x4
func _faction_page(kind: String) -> void:
	_log("%s 화면" % kind)
	if _tab_faction == "":
		_tab_faction = GameData.DOGS[GameState.current]["faction"]
	var v := _new_page()
	var title := "키우러 가기" if kind == "roster" else "도감 %d / %d" % [GameState.owned.size(), GameData.DOGS.size()]
	_page_header(v, "← 홈", _show_home, title)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	v.add_child(tabs)
	for fid in GameData.FACTION_ORDER:
		var total := 0
		for id in GameData.DOGS:
			if GameData.DOGS[id]["faction"] == fid:
				total += 1
		var have: int = GameState.owned_in(fid).size()
		var label := "%s\n%d" % [GameData.FACTIONS[fid]["name"], have] if kind == "roster" \
			else "%s\n%d/%d" % [GameData.FACTIONS[fid]["name"], have, total]
		var tab := _button(label, func() -> void:
			_tab_faction = fid
			_faction_page(kind))
		tab.custom_minimum_size = Vector2(0, 96)
		tab.size_flags_horizontal = SIZE_EXPAND_FILL
		tab.add_theme_font_size_override("font_size", _fs(24))
		var col: Color = FACTION_COLORS[fid]
		if fid == _tab_faction:
			tab.add_theme_stylebox_override("normal", _box(col, 18))
			tab.add_theme_stylebox_override("hover", _box(col.lightened(0.08), 18))
		else:
			var off := _card_box(Color(1, 0.98, 0.94), col.lightened(0.35), 4)
			tab.add_theme_stylebox_override("normal", off)
			tab.add_theme_stylebox_override("hover", _card_box(Color(1, 0.96, 0.9), col, 4))
			for key in ["font_color", "font_hover_color", "font_focus_color"]:
				tab.add_theme_color_override(key, col.darkened(0.15))
		tab.add_theme_stylebox_override("pressed", _box(col.darkened(0.15), 18))
		tabs.add_child(tab)

	var list := _scroll_list(v)
	var cur := _tab_faction
	var lord: String = GameData.FACTIONS[cur]["lord"]
	var others: Array[String] = []
	for id in GameData.DOGS:
		if GameData.DOGS[id]["faction"] == cur and id != lord:
			if kind == "dex" or GameState.owns(id):
				others.append(id)

	# 맨 윗줄: 주군 한 마리 가운데 (금색 테두리)
	var top := CenterContainer.new()
	list.add_child(top)
	if lord != "" and (GameState.owns(lord) or kind == "dex"):
		var card := _page_card(kind, lord)
		card.custom_minimum_size.x = 214
		if GameState.owns(lord):
			var gold := Color(0.95, 0.74, 0.22)
			card.add_theme_stylebox_override("normal", _card_box(Color(1.0, 0.97, 0.86), gold, 7))
			card.add_theme_stylebox_override("hover", _card_box(Color(1.0, 0.95, 0.8), gold, 7))
			card.add_theme_stylebox_override("pressed", _card_box(Color(0.98, 0.9, 0.72), gold, 7))
		top.add_child(card)

	if others.is_empty():
		var none := _label("아직 없어요. 뽑기로 데려와요!", 26)
		none.add_theme_color_override("font_color", SUB_COLOR)
		list.add_child(none)
		return
	var grid := _grid(list)
	for id in others:
		grid.add_child(_page_card(kind, id))


## 목록/도감 카드 하나
func _page_card(kind: String, dog_id: String) -> Button:
	var dog: Dictionary = GameData.DOGS[dog_id]
	if kind == "roster":
		var st: int = GameState.stage_of(dog_id)
		return _dog_card(dog_id, PuppyView.STAGE_FORM[st], "%s\n%s" % [dog["name"], GameData.stage_name(st, dog_id)],
			_show_raise.bind(dog_id))
	if GameState.owns(dog_id):
		# 도감 카드: 지금까지 키운 단계까지의 모습 (어른 그림은 어른까지 키워야 보임)
		return _dog_card(dog_id, PuppyView.STAGE_FORM[GameState.stage_of(dog_id)], dog["name"], _show_growth.bind(dog_id))
	var unknown := _button("???", func() -> void: pass)
	unknown.disabled = true
	unknown.custom_minimum_size = Vector2(0, 230)
	unknown.size_flags_horizontal = SIZE_EXPAND_FILL
	unknown.add_theme_font_size_override("font_size", _fs(40))
	unknown.add_theme_stylebox_override("disabled", _card_box(Color(0.93, 0.9, 0.85), Color(0.82, 0.78, 0.72), 4))
	unknown.add_theme_color_override("font_disabled_color", Color(0.6, 0.55, 0.5))
	return unknown


## 도감에서 누르면: 새끼 > 청년 > 어른 그림 (아직 못 키운 단계는 ???)
func _show_growth(dog_id: String) -> void:
	var dog: Dictionary = GameData.DOGS[dog_id]
	_open_overlay(dog["name"], "", "home_notice")
	overlay_log.hide()
	var reached: int = PuppyView.STAGE_FORM[GameState.stage_of(dog_id)]
	for form in 3:
		if form > 0:
			drops_box.add_child(_label(">", 40))
		var cell := CenterContainer.new()
		cell.custom_minimum_size = Vector2(170, 190)
		drops_box.add_child(cell)
		if form <= reached:
			var pic := TextureRect.new()
			pic.texture = _dog_tex(dog_id, form)
			pic.custom_minimum_size = Vector2(170, 170)
			pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			cell.add_child(pic)
		else:
			var q := _label("???", 44)
			q.add_theme_color_override("font_color", Color(0.65, 0.6, 0.55))
			cell.add_child(q)
	drops_box.show()
	confirm_button.text = "닫기"
	confirm_button.show()


## 그림 + 글씨 카드 버튼 (연한 바탕 + 주황 테두리, 글씨는 진하게)
func _dog_card(dog_id: String, form: int, text: String, cb: Callable) -> Button:
	var b := _button(text, cb)
	b.icon = _dog_tex(dog_id, form)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.add_theme_constant_override("icon_max_width", 140)
	b.custom_minimum_size = Vector2(0, 230)
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", _fs(26))
	var edge := Color(0.86, 0.52, 0.32)
	b.add_theme_stylebox_override("normal", _card_box(Color(1, 0.98, 0.94), edge, 4))
	b.add_theme_stylebox_override("hover", _card_box(Color(1, 0.95, 0.88), edge, 4))
	b.add_theme_stylebox_override("pressed", _card_box(Color(0.98, 0.9, 0.8), edge, 4))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(key, TEXT_COLOR)
	return b


## 연한 바탕 + 색 테두리
func _card_box(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var sb := _box(bg, 18)
	sb.border_color = border
	sb.set_border_width_all(width)
	return sb


## 멍냥이 그림 (form 0 새끼 / 1 청년 / 2 어른)
func _dog_tex(dog_id: String, form: int) -> Texture2D:
	var path := "%s%s_%d_open.png" % [SPRITE_DIR, dog_id, form]
	if not _tex_cache.has(path):
		_tex_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex_cache[path]


# ═════════════════════════ 튜토리얼 ═════════════════════════

const TUT_LAST := 12


func _tut_start() -> void:
	_log("튜토리얼 시작")
	_tut_step = -1
	_show_raise(GameState.current)
	_tut_next()


func _tut_next() -> void:
	_tut_step += 1
	_tut_wait = ""
	if _tut_step > TUT_LAST:
		tut.finish()
		_tut_step = -1
		GameState.tutorial_done = true
		GameState.save_now()
		_log("튜토리얼 끝")
		return
	match _tut_step:
		0:
			tut.show_step("삼국지 멍냥이들을 키워봐요 :)", [], false)
		1:
			_tut_wait = "battle"
			tut.show_step("먼저 전투를 눌러 볼까요?\n이기면 음식을 얻어요!", [battle_button], true)
		2:
			_tut_wait = "fed"
			tut.show_step("얻은 음식을 줘 보세요!", [food_row], true)
		3:
			tut.show_step("위는 경험치 바, 아래는 피로도 바예요.\n경험치가 차면 성장하고,\n피로도가 꽉 차면 잠을 자야 해요.", [exp_bar, fatigue_bar], false)
		4:
			tut.show_step("이쪽에는 이 멍냥이와 특별한 관계를 맺은 멍냥이들이 떠요!", [relation_scroll], false)
		5:
			tut.show_step("이쪽에서 멍냥이들의 관계도를 볼 수 있어요!", [relation_button], false)
		6:
			tut.show_step("가방에서는 특별한 아이템들을 사용할 수 있어요!", [bag_button], false)
		7:
			_tut_wait = "home"
			tut.show_step("이제 홈으로 나가 볼까요?", [back_button], true)
		8:
			_tut_wait = "gacha_page"
			tut.show_step("뽑기를 눌러 보세요!", [_home_gacha_btn], true)
		9:
			tut.show_step("여기서 새 멍냥이들을 만날 수 있어요.", [_gacha_machine], false)
		10:
			if GameState.give_start_bonus():
				_gacha_ticket_label.text = "보유한 뽑기권  x%d" % GameState.tickets
				if not GameState.unowned().is_empty():
					_gacha_pull.disabled = false
					_gacha_pull.text = "뽑기"
			tut.show_step("뽑기권 x%d 증정!" % GameData.STARTING_TICKETS, [_gacha_ticket_row], false)
		11:
			_tut_wait = "gacha_done"
			tut.show_step("뽑기를 눌러 볼까요?", [_gacha_pull], true)
		12:
			tut.show_step("열심히 멍냥이들을 키워\n모든 삼국지 멍냥이들을 만나봅시다 :)", [], false)


## 튜토리얼이 기다리던 행동이 일어나면 다음 단계로
func _tut_event(what: String) -> void:
	if _tut_step >= 0 and _tut_wait == what:
		_tut_next()


## 초기화 경고창
func _ask_reset() -> void:
	_open_overlay("초기화", "모든 멍냥이 도감이 초기화됩니다.\n초기화 하시겠습니까?", "reset_confirm")
	var red := Color(0.86, 0.32, 0.32)
	confirm_button.text = "초기화"
	confirm_button.add_theme_stylebox_override("normal", _box(red, 18))
	confirm_button.add_theme_stylebox_override("hover", _box(red.lightened(0.1), 18))
	confirm_button.add_theme_stylebox_override("pressed", _box(red.darkened(0.15), 18))
	confirm_button.show()
	cancel_button.show()


## 진짜 처음으로: 저장 지우고 화면 상태도 싹 비움
func _do_reset() -> void:
	_log("전체 초기화")
	GameState.reset_all()
	if puppy and puppy.stage_changed.is_connected(_on_stage_changed):
		puppy.stage_changed.disconnect(_on_stage_changed)
	puppy = null
	busy = false
	_pending_gift = {}
	_tab_faction = ""
	_show_home()
	_tut_start()


# ═════════════════════════ 사진 찍기 ═════════════════════════

func _show_photo() -> void:
	_log("사진 화면")
	var v := _new_page()
	_photo_ui = []
	_photo_cards = {}
	var header_start := v.get_child_count()
	_page_header(v, "← 홈", _show_home, "사진 찍기")
	_photo_ui.append(v.get_child(header_start))

	_photo_stage = PhotoStageScript.new()
	_photo_stage.custom_minimum_size = Vector2(0, 520)
	_photo_stage.size_flags_horizontal = SIZE_EXPAND_FILL
	_photo_stage.title = _photo_title
	_photo_stage.bg = _photo_bg
	v.add_child(_photo_stage)

	# 사진 아래 글씨 고치기
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	v.add_child(title_row)
	_photo_ui.append(title_row)
	var edit := LineEdit.new()
	edit.text = _photo_title
	edit.placeholder_text = "사진에 넣을 글씨"
	edit.max_length = 16
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.clear_button_enabled = true
	edit.size_flags_horizontal = SIZE_EXPAND_FILL
	edit.custom_minimum_size = Vector2(0, 56)
	edit.add_theme_font_size_override("font_size", _fs(20))
	edit.add_theme_color_override("font_color", TEXT_COLOR)
	edit.add_theme_color_override("font_placeholder_color", SUB_COLOR)
	edit.add_theme_color_override("caret_color", TEXT_COLOR)
	edit.add_theme_color_override("clear_button_color", SUB_COLOR)
	edit.add_theme_stylebox_override("normal", _card_box(Color(1, 0.98, 0.94), Color(0.86, 0.52, 0.32), 3))
	edit.add_theme_stylebox_override("focus", _card_box(Color(1, 0.98, 0.94), PINK, 4))
	edit.text_changed.connect(func(t: String) -> void:
		_photo_title = t
		_photo_stage.title = t)
	edit.text_submitted.connect(func(_t: String) -> void: edit.release_focus())
	title_row.add_child(edit)
	# 웹(특히 폰)에서는 게임 입력칸에 키보드가 안 떠서 → 누르면 브라우저 기본 입력창으로 받음
	if OS.has_feature("web"):
		edit.editable = false
		edit.focus_mode = Control.FOCUS_NONE
		edit.clear_button_enabled = false
		edit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		edit.add_theme_stylebox_override("read_only", _card_box(Color(1, 0.98, 0.94), Color(0.86, 0.52, 0.32), 3))
		edit.add_theme_color_override("font_uneditable_color", TEXT_COLOR)
		edit.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
				_photo_prompt_title(edit))
	# 배경색 (동그란 색 버튼)
	_photo_bg_btns = []
	for i in PhotoStageScript.BACKGROUNDS.size():
		var sw := Button.new()
		sw.custom_minimum_size = Vector2(46, 56)
		sw.focus_mode = Control.FOCUS_NONE
		sw.tooltip_text = PhotoStageScript.BACKGROUNDS[i][0]
		sw.pressed.connect(_on_photo_bg.bind(i))
		title_row.add_child(sw)
		_photo_bg_btns.append(sw)

	# 표정 고르기: 고른 멍냥이마다 한 줄씩 (이름 + 표정 버튼)
	_photo_expr_box = VBoxContainer.new()
	_photo_expr_box.add_theme_constant_override("separation", 6)
	v.add_child(_photo_expr_box)
	_photo_ui.append(_photo_expr_box)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	v.add_child(scroll)
	_photo_ui.append(scroll)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
	for fid in GameData.FACTION_ORDER:
		for id in GameState.owned_in(fid):
			var card := _dog_card(id, PuppyView.STAGE_FORM[GameState.stage_of(id)], GameData.DOGS[id]["name"], _on_photo_pick.bind(id))
			card.custom_minimum_size = Vector2(0, 150)
			card.add_theme_constant_override("icon_max_width", 92)
			card.add_theme_font_size_override("font_size", _fs(20))
			grid.add_child(card)
			_photo_cards[id] = card

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	_photo_ui.append(row)
	var shoot := _button("찰칵!", _photo_capture_mode)
	shoot.custom_minimum_size = Vector2(0, 100)
	shoot.size_flags_horizontal = SIZE_EXPAND_FILL
	shoot.add_theme_stylebox_override("normal", _box(PINK, 18))
	shoot.add_theme_stylebox_override("hover", _box(PINK.lightened(0.1), 18))
	shoot.add_theme_stylebox_override("pressed", _box(PINK.darkened(0.15), 18))
	row.add_child(shoot)
	var save := _button("사진 저장", _save_photo)
	save.custom_minimum_size = Vector2(0, 100)
	save.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(save)

	# 처음엔 지금 키우던 멍냥이 한 마리
	_photo_sel = []
	_photo_expr = {}
	_photo_form = {}
	if GameState.owns(GameState.current):
		_photo_sel.append(GameState.current)
	_photo_refresh()


func _on_photo_pick(id: String) -> void:
	if _photo_sel.has(id):
		_photo_sel.erase(id)
	elif _photo_sel.size() < 3:
		_photo_sel.append(id)
	else:
		return   # 3마리까지
	_photo_refresh()


## 웹: 브라우저 입력창(prompt)으로 글씨 받기 - 폰 키보드·한글 입력이 정상으로 됨
func _photo_prompt_title(edit: LineEdit) -> void:
	var js := "prompt(%s, %s)" % [JSON.stringify("사진에 넣을 글씨 (16자까지)"), JSON.stringify(_photo_title)]
	var r = JavaScriptBridge.eval(js, true)
	if r == null:
		return   # 취소
	var t := str(r).strip_edges().left(16)
	_photo_title = t
	edit.text = t
	_photo_stage.title = t


func _on_photo_bg(i: int) -> void:
	_photo_bg = i
	_photo_stage.bg = i
	_photo_refresh()


## 모습 바꾸기: 키운 데까지 아기 → 청년 → 어른 → 아기 ...
func _on_photo_form(id: String) -> void:
	var reached: int = PuppyView.STAGE_FORM[GameState.stage_of(id)]
	_photo_form[id] = (int(_photo_form.get(id, reached)) + 1) % (reached + 1)
	_photo_refresh()


func _on_photo_expr(id: String, e: String) -> void:
	_photo_expr[id] = e
	_photo_refresh()


## 고른 멍냥이·표정을 무대와 버튼에 반영
func _photo_refresh() -> void:
	var list: Array = []
	for id in _photo_sel:
		var reached: int = PuppyView.STAGE_FORM[GameState.stage_of(id)]
		list.append({"id": id, "form": clampi(int(_photo_form.get(id, reached)), 0, reached), "expr": _photo_expr.get(id, "기본")})
	_photo_stage.set_pets(list)
	# 표정 줄 다시 만들기 (고른 순서대로)
	for c in _photo_expr_box.get_children():
		_photo_expr_box.remove_child(c)
		c.queue_free()
	for i in _photo_sel.size():
		var id: String = _photo_sel[i]
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 5)
		_photo_expr_box.add_child(line)
		var nm := _label("%d %s" % [i + 1, GameData.DOGS[id]["name"]], 18)
		nm.custom_minimum_size = Vector2(90, 0)
		nm.clip_text = true
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		line.add_child(nm)
		# 모습 (누를 때마다 바뀜, 키운 단계까지만)
		var reached: int = PuppyView.STAGE_FORM[GameState.stage_of(id)]
		var form := clampi(int(_photo_form.get(id, reached)), 0, reached)
		var fb := _button("%s ↔" % PhotoStageScript.FORM_NAMES[form] if reached > 0 else PhotoStageScript.FORM_NAMES[form],
			_on_photo_form.bind(id))
		fb.custom_minimum_size = Vector2(86, 52)
		fb.add_theme_font_size_override("font_size", _fs(16))
		fb.disabled = reached == 0
		var fcol := Color(0.4, 0.62, 0.86) if reached > 0 else Color(0.72, 0.68, 0.64)
		fb.add_theme_stylebox_override("normal", _box(fcol, 12))
		fb.add_theme_stylebox_override("hover", _box(fcol.lightened(0.1), 12))
		fb.add_theme_stylebox_override("disabled", _box(fcol, 12))
		fb.add_theme_color_override("font_disabled_color", Color(1, 1, 1))
		line.add_child(fb)
		var cur: String = _photo_expr.get(id, "기본")
		for e in PhotoStageScript.EXPRESSION_ORDER:
			var b := _button(e, _on_photo_expr.bind(id, e))
			b.custom_minimum_size = Vector2(0, 52)
			b.size_flags_horizontal = SIZE_EXPAND_FILL
			b.add_theme_font_size_override("font_size", _fs(16))
			var col := PINK if e == cur else Color(0.86, 0.52, 0.32)
			b.add_theme_stylebox_override("normal", _box(col, 12))
			b.add_theme_stylebox_override("hover", _box(col.lightened(0.1), 12))
			line.add_child(b)
	# 배경색 버튼: 고른 건 테두리 굵게
	for i in _photo_bg_btns.size():
		var sw: Button = _photo_bg_btns[i]
		var col: Color = PhotoStageScript.BACKGROUNDS[i][1]
		var on := i == _photo_bg
		for st in ["normal", "hover", "pressed"]:
			sw.add_theme_stylebox_override(st, _card_box(col, PINK.darkened(0.1) if on else Color(0.86, 0.75, 0.66), 5 if on else 2))
	for id in _photo_cards:
		var card: Button = _photo_cards[id]
		var idx := _photo_sel.find(id)
		var name_s: String = GameData.DOGS[id]["name"]
		card.text = name_s if idx < 0 else "%d · %s" % [idx + 1, name_s]
		var border := PINK if idx >= 0 else Color(0.86, 0.52, 0.32)
		var width := 7 if idx >= 0 else 4
		card.add_theme_stylebox_override("normal", _card_box(Color(1, 0.98, 0.94), border, width))
		card.add_theme_stylebox_override("hover", _card_box(Color(1, 0.95, 0.88), border, width))


## 찰칵: 버튼·목록 다 숨기고 사진만 (화면을 누르면 돌아옴)
func _photo_capture_mode() -> void:
	if _photo_sel.is_empty():
		return
	for c in _photo_ui:
		c.hide()
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.9)
	flash.set_anchors_preset(PRESET_FULL_RECT)
	flash.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(flash)
	flash.create_tween().tween_property(flash, "color:a", 0.0, 0.35).finished.connect(flash.queue_free)
	var catcher := Control.new()
	catcher.set_anchors_preset(PRESET_FULL_RECT)
	catcher.mouse_filter = MOUSE_FILTER_STOP
	add_child(catcher)
	var hint := _label("화면을 누르면 돌아가요", 20)
	hint.add_theme_color_override("font_color", SUB_COLOR)
	catcher.add_child(hint)
	hint.set_anchors_and_offsets_preset(PRESET_CENTER_BOTTOM, PRESET_MODE_MINSIZE, 30)
	hint.create_tween().tween_property(hint, "modulate:a", 0.0, 0.6).set_delay(1.2)   # 캡쳐에 안 찍히게 금방 사라짐
	catcher.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			catcher.queue_free()
			for c in _photo_ui:
				if is_instance_valid(c):
					c.show())


## 사진만 잘라서 저장 (웹: 바로 다운로드 / PC: 사진 폴더)
func _save_photo() -> void:
	if _photo_sel.is_empty():
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var vis := get_viewport().get_visible_rect().size
	var k := Vector2(img.get_width() / vis.x, img.get_height() / vis.y)
	var r: Rect2 = _photo_stage.get_global_rect()
	var region := Rect2i(Vector2i(r.position * k), Vector2i(r.size * k)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	var shot := img.get_region(region)
	var stamp := Time.get_datetime_string_from_system().replace(":", "").replace("-", "").replace("T", "_")
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(shot.save_png_to_buffer(), "mengnyang_%s.png" % stamp, "image/png")
		_open_overlay("사진 저장", "사진을 내려받았어요!", "home_notice")
	else:
		var dir := OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
		if dir == "":
			dir = OS.get_user_data_dir()
		var path := dir.path_join("멍냥이사진_%s.png" % stamp)
		var err := shot.save_png(path)
		_open_overlay("사진 저장", ("사진을 저장했어요!\n%s" % path) if err == OK else "저장하지 못했어요..", "home_notice")
	confirm_button.show()
	_log("사진 저장")


# ═════════════════════════ 뽑기 ═════════════════════════

const LEVER_PIVOT := Vector2(406.79, 353.92) / 512.0   # 손잡이 회전축 (그림 크기 대비 비율)
const LEVER_PULL_DEG := 150.0                          # 당기면 이만큼 돌아감 (시계방향)
const GACHA_SUSPENSE := 2.2                            # 두근두근 유지 시간
var _gacha_busy := false
var _gacha_machine: Control
var _gacha_lever: TextureRect


func _show_gacha() -> void:
	_log("뽑기 화면")
	_gacha_busy = false
	var v := _new_page()
	_page_header(v, "← 홈", _show_home, "뽑기")

	var ticket_row := HBoxContainer.new()
	ticket_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ticket_row.add_theme_constant_override("separation", 10)
	v.add_child(ticket_row)
	var ticket_icon := TextureRect.new()
	ticket_icon.texture = FoodIcon.item_texture("ticket")
	ticket_icon.custom_minimum_size = Vector2(64, 64)
	ticket_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ticket_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ticket_row.add_child(ticket_icon)
	_gacha_ticket_label = _label("보유한 뽑기권  x%d" % GameState.tickets, 34)
	ticket_row.add_child(_gacha_ticket_label)
	_gacha_ticket_row = ticket_row

	# 뽑기 기계: 몸통 + 손잡이(같은 크기 그림을 겹쳐서 회전축 기준으로 돌림)
	var center := CenterContainer.new()
	center.size_flags_vertical = SIZE_EXPAND_FILL
	v.add_child(center)
	var machine := Control.new()
	machine.custom_minimum_size = Vector2(520, 520)
	machine.mouse_filter = MOUSE_FILTER_STOP     # 기계를 콕 누르면 보잉
	machine.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and not _gacha_busy:
			_jelly(machine))
	center.add_child(machine)
	_gacha_machine = machine
	for tex_name in ["gacha_machine", "gacha_lever"]:
		var t := TextureRect.new()
		t.texture = FoodIcon.item_texture(tex_name)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_SCALE
		t.size = machine.custom_minimum_size
		t.mouse_filter = MOUSE_FILTER_IGNORE
		machine.add_child(t)
		if tex_name == "gacha_lever":
			t.pivot_offset = LEVER_PIVOT * machine.custom_minimum_size
			_gacha_lever = t

	var left: int = GameState.unowned().size()
	var hint := _label("아직 못 만난 멍냥이 %d마리 중 한 마리가 찾아와요" % left if left > 0 else "모든 멍냥이를 다 모았어요!", 24)
	hint.add_theme_color_override("font_color", SUB_COLOR)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(hint)

	var pull := _button("뽑기", _on_gacha)
	_gacha_pull = pull
	pull.custom_minimum_size = Vector2(0, 120)
	pull.add_theme_font_size_override("font_size", _fs(40))
	pull.add_theme_stylebox_override("normal", _box(PINK, 18))
	pull.add_theme_stylebox_override("hover", _box(PINK.lightened(0.1), 18))
	pull.add_theme_stylebox_override("pressed", _box(PINK.darkened(0.15), 18))
	if left <= 0:
		pull.text = "다 모았어요!"
		pull.disabled = true
	elif GameState.tickets <= 0:
		pull.text = "뽑기권이 없어요"
		pull.disabled = true     # 회색
	v.add_child(pull)
	_tut_event("gacha_page")


func _on_gacha() -> void:
	if _gacha_busy or GameState.tickets <= 0 or GameState.unowned().is_empty():
		return
	_gacha_busy = true
	# 손잡이 철컥: 아래로 내려갔다가 올라옴 + 기계 살짝 흔들
	var tw := create_tween()
	tw.tween_property(_gacha_lever, "rotation_degrees", LEVER_PULL_DEG, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_gacha_lever, "rotation_degrees", 0.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_gacha_machine.scale = Vector2.ONE
	_gacha_machine.pivot_offset = _gacha_machine.custom_minimum_size * Vector2(0.45, 0.9)
	var shake := create_tween()
	shake.tween_interval(0.2)
	for i in 3:
		shake.tween_property(_gacha_machine, "rotation_degrees", 2.0, 0.05)
		shake.tween_property(_gacha_machine, "rotation_degrees", -2.0, 0.05)
	shake.tween_property(_gacha_machine, "rotation_degrees", 0.0, 0.05)
	await tw.finished

	var id: String = GameState.draw_gacha()
	_log("뽑기: " + id)
	_open_overlay("두근두근...", "", "gacha")
	overlay_image.texture = FoodIcon.item_texture("capsule")
	overlay_image.show()
	overlay_image.pivot_offset = overlay_image.custom_minimum_size / 2
	var wobble := overlay_image.create_tween().set_loops()
	wobble.tween_property(overlay_image, "rotation", 0.2, 0.12)
	wobble.tween_property(overlay_image, "rotation", -0.2, 0.12)
	await get_tree().create_timer(GACHA_SUSPENSE).timeout
	wobble.kill()
	overlay_image.rotation = 0.0

	var dog: Dictionary = GameData.DOGS[id]
	var sp: String = GameData.species(id)
	overlay_title.text = "%s %s%s 찾아왔어요!" % [dog["name"], sp, _ig(sp)]
	overlay_image.texture = _dog_tex(id, 0)
	overlay_image.scale = Vector2(0.2, 0.2)
	overlay_image.create_tween().tween_property(overlay_image, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	overlay_log.text = "%s 진영 · %s" % [GameData.FACTIONS[dog["faction"]]["name"],
		"책사" if GameData.is_strategist(id) else ("군주" if GameData.is_lord(id) else "무장")]
	celebration.play("", "", overlay_image.global_position + overlay_image.size / 2 - celebration.global_position)
	confirm_button.text = "반가워!"
	confirm_button.show()


# ═════════════════════════ 키우기 화면 ═════════════════════════

func _build_raise_screen() -> void:
	var m := _screen_margin()
	raise_screen = m
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	m.add_child(v)

	var header := HBoxContainer.new()
	v.add_child(header)
	back_button = _button("← 목록", _on_back)
	back_button.custom_minimum_size = Vector2(150, 70)
	back_button.add_theme_font_size_override("font_size", _fs(24))
	header.add_child(back_button)
	title_label = _label("", 40)
	title_label.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(title_label)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(150, 0)
	header.add_child(spacer)

	stage_label = _label("", 30)
	v.add_child(stage_label)
	exp_bar = ProgressBar.new()
	exp_bar.show_percentage = false
	exp_bar.custom_minimum_size = Vector2(0, 26)
	v.add_child(exp_bar)
	exp_label = _label("", 22)
	v.add_child(exp_label)
	var fatigue_row := HBoxContainer.new()
	fatigue_row.add_theme_constant_override("separation", 10)
	v.add_child(fatigue_row)
	fatigue_label = _label("피로도", 22)
	fatigue_row.add_child(fatigue_label)
	fatigue_bar = ProgressBar.new()
	fatigue_bar.show_percentage = false
	fatigue_bar.max_value = GameData.FATIGUE_MAX
	fatigue_bar.size_flags_horizontal = SIZE_EXPAND_FILL
	fatigue_bar.size_flags_vertical = SIZE_SHRINK_CENTER
	fatigue_bar.custom_minimum_size = Vector2(0, 22)
	fatigue_bar.add_theme_stylebox_override("fill", _box(Color(0.55, 0.55, 0.85), 11))
	fatigue_row.add_child(fatigue_bar)

	puppy_view = PuppyView.new()
	puppy_view.size_flags_vertical = SIZE_EXPAND_FILL
	puppy_view.petted.connect(_on_petted)
	v.add_child(puppy_view)

	# 오른쪽 위 구석: 하트 = 관계도 버튼 (글씨 없음)
	relation_button = HeartButtonScript.new()
	relation_button.text = ""
	relation_button.pressed.connect(_jelly.bind(relation_button))   # 버튼처럼 보잉
	relation_button.pressed.connect(_open_relations)
	puppy_view.add_child(relation_button)
	relation_button.custom_minimum_size = Vector2(84, 78)
	relation_button.size = relation_button.custom_minimum_size
	# 왼쪽 위 관계도(해골·이름) 줄과 같은 높이, 오른쪽 끝. 화면 크기가 바뀌어도 따라감
	puppy_view.resized.connect(_place_relation_button)
	_place_relation_button()
	# 왼쪽 위: ♥ 애인 / 해골 앙숙. 누르면 설명창
	relation_box = VBoxContainer.new()
	relation_box.mouse_filter = MOUSE_FILTER_PASS   # 끌면 스크롤로 넘어가게
	relation_box.add_theme_constant_override("separation", 4)
	relation_box.gui_input.connect(_on_relation_box_input)
	# 관계가 많아도 캐릭터·버튼을 덮지 않게: 높이를 제한한 스크롤 안에 넣음
	relation_scroll = ScrollContainer.new()
	relation_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	relation_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	relation_scroll.position = Vector2(6, 6)
	puppy_view.add_child(relation_scroll)
	relation_scroll.add_child(relation_box)
	puppy_view.resized.connect(_fit_relation_scroll)

	message_label = _label(" ", 28)
	v.add_child(message_label)

	# 음식 버튼: 그림 + 이름 + 경험치, 개수는 오른쪽 위 동그라미 뱃지
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	food_row = row
	for food_id in GameData.FOOD_ORDER:
		var b := _button("", _on_feed.bind(food_id))
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 150)
		row.add_child(b)

		var box := VBoxContainer.new()
		box.set_anchors_preset(PRESET_FULL_RECT)
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", 0)
		box.mouse_filter = MOUSE_FILTER_IGNORE
		b.add_child(box)
		var icon := FoodIcon.new()
		icon.food_id = food_id
		icon.custom_minimum_size = Vector2(0, 72)
		box.add_child(icon)
		var name_label := _label(GameData.FOODS[food_id]["name"], 24)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		name_label.mouse_filter = MOUSE_FILTER_IGNORE
		box.add_child(name_label)
		var gain_label := _label("", 18)
		gain_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
		gain_label.mouse_filter = MOUSE_FILTER_IGNORE
		box.add_child(gain_label)

		var badge := _badge()
		b.add_child(badge)
		badge.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT, PRESET_MODE_MINSIZE, 6)

		food_buttons[food_id] = {"button": b, "content": box, "gain": gain_label, "badge": badge,
			"icon": icon, "name": name_label}

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 10)
	v.add_child(bottom)
	battle_button = _button("전투", _on_battle)
	battle_button.custom_minimum_size = Vector2(0, 110)
	battle_button.add_theme_font_size_override("font_size", 30)
	battle_button.size_flags_horizontal = SIZE_EXPAND_FILL
	battle_button.size_flags_stretch_ratio = 1.6
	bottom.add_child(battle_button)
	bag_button = _button("가방", _open_bag)
	_set_button_icon(bag_button, "item_pouch")
	bag_button.add_theme_constant_override("icon_max_width", 48)
	bag_button.custom_minimum_size = Vector2(0, 110)
	bag_button.add_theme_font_size_override("font_size", 30)
	bag_button.size_flags_horizontal = SIZE_EXPAND_FILL
	bottom.add_child(bag_button)
	sleep_button = _button("잠자기", _on_sleep)
	_set_button_icon(sleep_button, "icon_sleep")
	sleep_button.add_theme_constant_override("icon_max_width", 48)
	sleep_button.custom_minimum_size = Vector2(0, 110)
	sleep_button.add_theme_font_size_override("font_size", 30)
	sleep_button.size_flags_horizontal = SIZE_EXPAND_FILL
	var night := Color(0.42, 0.45, 0.72)
	sleep_button.add_theme_stylebox_override("normal", _box(night, 18))
	sleep_button.add_theme_stylebox_override("hover", _box(night.lightened(0.1), 18))
	sleep_button.add_theme_stylebox_override("pressed", _box(night.darkened(0.15), 18))
	bottom.add_child(sleep_button)
	raise_screen.hide()


func _place_relation_button() -> void:
	relation_button.position = Vector2(puppy_view.size.x - relation_button.size.x - 6, 0)


func _show_raise(dog_id: String) -> void:
	_log("키우기 화면: " + dog_id)
	if page:
		page.queue_free()
		page = null
	raise_screen.show()
	GameState.current = dog_id
	_bind_puppy(GameState.get_puppy(dog_id))

	var dog: Dictionary = GameData.DOGS[dog_id]
	title_label.text = dog["name"]
	_set_button_icon(battle_button, "icon_strategy" if GameData.is_strategist(dog_id) else "icon_battle")
	puppy_view.body_color = dog["color"]
	puppy_view.dog_id = dog_id  # 그림 있으면 그림으로
	puppy_view.stage = puppy.stage
	puppy_view.sleeping = false
	busy = false
	_show_msg("너무 피곤해.." if puppy.is_exhausted() else "%s %s랑 놀자!" % [dog["name"], GameData.species(dog_id)])
	_refresh()
	GameState.save_game()


func _bind_puppy(p: Puppy) -> void:
	if puppy and puppy.stage_changed.is_connected(_on_stage_changed):
		puppy.stage_changed.disconnect(_on_stage_changed)
	puppy = p
	puppy.stage_changed.connect(_on_stage_changed)


func _refresh() -> void:
	if puppy == null or not raise_screen.visible:
		return
	var stage := puppy.stage
	stage_label.text = GameData.stage_name(stage, puppy.dog_id)
	exp_bar.min_value = 0
	if puppy.is_adult():
		exp_bar.max_value = 1
		exp_bar.value = 1
		exp_label.text = "다 컸다! 친밀도 %d" % puppy.affection
	else:
		var lo: int = GameData.STAGE_EXP[stage]
		var hi: int = GameData.STAGE_EXP[stage + 1]
		exp_bar.max_value = hi
		exp_bar.min_value = lo
		exp_bar.value = puppy.total_exp
		exp_label.text = "경험치 %d / %d" % [puppy.total_exp, hi]

	var exhausted := puppy.is_exhausted()
	fatigue_bar.value = puppy.fatigue
	fatigue_label.text = "피로도 MAX" if exhausted else "피로도"
	puppy_view.tired = exhausted and not puppy_view.sleeping

	for food_id in food_buttons:
		var ui: Dictionary = food_buttons[food_id]
		var count := puppy.food_count(food_id)
		var b: Button = ui["button"]
		var content: Control = ui["content"]
		var badge: Label = ui["badge"]
		var gain: Label = ui["gain"]
		b.disabled = busy or exhausted or count <= 0
		content.modulate.a = 0.45 if b.disabled else 1.0
		badge.text = str(count)
		badge.visible = count > 0
		gain.text = "친밀도+1" if puppy.is_adult() else "+%d exp" % GameData.FOODS[food_id]["exp"]
		(ui["icon"] as FoodIcon).food_id = GameData.food_icon_id(food_id, puppy.dog_id)
		(ui["name"] as Label).text = GameData.food_name(food_id, puppy.dog_id)
	battle_button.disabled = busy or exhausted
	_style_battle_button()
	relation_button.disabled = busy
	_update_relations()
	sleep_button.disabled = busy or puppy.fatigue <= 0
	sleep_button.text = "잠자기!!" if exhausted else "잠자기"
	var items := 0
	for item_id in GameData.ITEM_ORDER:
		items += GameState.item_count(item_id)
	bag_button.text = "가방 %d" % items if items > 0 else "가방"
	bag_button.disabled = busy
	back_button.disabled = busy


## 네잎클로버 효과 중이면 전투 버튼이 초록 클로버 색 + 남은 횟수
func _style_battle_button() -> void:
	var base_text := "책략 내기" if GameData.is_strategist(puppy.dog_id) else "전투"
	if GameState.luck > 0:
		battle_button.text = "%s\n클로버 %d번" % [base_text, GameState.luck]
		var green := Color(0.36, 0.66, 0.36)
		battle_button.add_theme_stylebox_override("normal", _clover_box(green))
		battle_button.add_theme_stylebox_override("hover", _clover_box(green.lightened(0.1)))
		battle_button.add_theme_stylebox_override("pressed", _clover_box(green.darkened(0.15)))
	else:
		battle_button.text = base_text
		for key in ["normal", "hover", "pressed"]:
			battle_button.remove_theme_stylebox_override(key)


func _clover_box(col: Color) -> StyleBoxFlat:
	var sb := _box(col, 18)
	sb.border_color = Color(0.78, 0.92, 0.6)
	sb.set_border_width_all(4)
	return sb


func _set_busy(v: bool) -> void:
	busy = v
	_refresh()


func _show_msg(text: String) -> void:
	message_label.text = text


# ── 행동: 음식 주기 (연타 가능, 누를 때마다 한 입) ──
func _on_feed(food_id: String) -> void:
	if busy or puppy.is_exhausted() or puppy.food_count(food_id) <= 0:
		return
	var food: Dictionary = GameData.FOODS[food_id]
	var stage_before := puppy.stage
	_log("밥: %s (exp %d, 피로 %d)" % [food_id, puppy.total_exp, puppy.fatigue])
	puppy.feed(food_id)  # 여기서 단계가 바뀌면 _on_stage_changed 호출됨
	puppy.add_fatigue(GameData.FATIGUE_PER_FOOD)
	puppy_view.eat(GameData.food_icon_id(food_id, puppy.dog_id), GameData.EAT_ANIM_SECONDS)
	if puppy.is_exhausted():
		_show_msg("배불러... 너무 피곤해..")
	elif puppy.stage != stage_before:
		pass  # "성장했다!" 메시지 유지
	else:
		_show_msg("%s 냠냠 %s" % [GameData.food_name(food_id, puppy.dog_id), "친밀도 +1" if puppy.is_adult() else "+%d exp" % food["exp"]])
	_after_action()
	_tut_event("fed")


# ── 행동: 쓰다듬기 (횟수에 안 들어감) ──
func _on_petted() -> void:
	if puppy == null:
		return
	if puppy_view.sleeping:
		_show_msg("음냐음냐..")
		return
	var now := Time.get_ticks_msec()
	var gap := (now - _last_pet_ms) / 1000.0
	if gap < GameData.PET_COOLDOWN:
		return  # 너무 빠른 연타: 하트만 나오고 끝
	_pet_streak = _pet_streak + 1 if gap <= GameData.PET_STREAK_GAP else 1
	_last_pet_ms = now

	if GameData.is_strategist(puppy.dog_id):
		# 고양이: 쓰다듬을수록 피곤, 연속 5번부터는 화냄
		if _pet_streak >= GameData.PET_CAT_ANGRY_STREAK:
			puppy.add_fatigue(GameData.PET_CAT_ANGRY_FATIGUE)
			puppy_view.get_angry()
			_show_msg(CAT_ANGRY_MESSAGES.pick_random())
		else:
			puppy.add_fatigue(GameData.PET_CAT_FATIGUE)
			if puppy.is_adult():
				puppy.affection += 1
			_show_msg(CAT_PET_MESSAGES.pick_random())
		if puppy.is_exhausted():
			_show_msg(message_label.text + "\n너무 피곤해..")
	else:
		# 강아지: 아주 조금 회복. 단, 피로도가 꽉 찼으면 잠을 자야만 풀림
		if puppy.is_exhausted():
			_show_msg("졸려... 쓰담쓰담 좋아... 그래도 자야 해")
		else:
			puppy.add_fatigue(-GameData.PET_DOG_RELIEF)
			if puppy.is_adult():
				puppy.affection += 1
			_show_msg(PET_MESSAGES.pick_random())
	_refresh()
	GameState.save_game()


# ── 행동 후 공통: 저장 → 어른 선물 창 ──
func _after_action() -> void:
	_refresh()
	GameState.save_game()
	if not _pending_gift.is_empty():
		# 성장 폭죽이 먼저 끝나고 선물 창이 뜨게
		var gift := _pending_gift
		_pending_gift = {}
		_set_busy(true)
		await get_tree().create_timer(Celebration.BANNER_HOLD + 0.4).timeout
		_open_overlay("선물이 왔어요!", gift["text"], "gift")
		overlay_image.texture = FoodIcon.item_texture("ticket")
		overlay_image.show()
		confirm_button.text = "고마워!"
		confirm_button.show()
		_set_busy(true)


# ── 행동: 잠자기 → 피로도 리셋 ──
func _on_sleep() -> void:
	if busy or puppy.fatigue <= 0:
		return
	_log("잠 시작")
	_set_busy(true)
	puppy_view.tired = false
	puppy_view.sleeping = true
	_show_msg("쿨쿨...")
	await get_tree().create_timer(GameData.SLEEP_SECONDS).timeout
	puppy_view.sleeping = false
	puppy.rest()
	GameState.save_game()
	_show_msg("잘 잤다!")
	_log("잠 끝")
	_set_busy(false)


func _on_stage_changed(stage: int) -> void:
	_log("성장: %d" % stage)
	puppy_view.stage = stage
	var dog_name: String = GameData.DOGS[puppy.dog_id]["name"]
	var sp: String = GameData.species(puppy.dog_id)
	var stage_name: String = GameData.stage_name(stage, puppy.dog_id)
	_show_msg("%s%s 됐다!" % [stage_name, _ig(stage_name)])
	puppy_view.bounce()
	var center := puppy_view.global_position + puppy_view.size / 2 - celebration.global_position
	if puppy.is_adult():
		# "유비 강아지가 / 어른강아지가 되었어요!" → 폭죽 끝나면 선물 창
		celebration.play("%s %s%s" % [dog_name, sp, _ig(sp)], "%s%s 되었어요!" % [stage_name, _ig(stage_name)], center)
		var got: int = GameState.grant_adult_reward(puppy.dog_id)
		if got > 0:
			_pending_gift = {"text": "%s %s%s 선물을 물어왔어요!\n\n뽑기권 x%d" % [dog_name, sp, _ig(sp), got]}
		# 크면 풀리는 앙숙: 화해 알림
		for other in GameState.owned:
			var m: String = GameData.grow_out_by(puppy.dog_id, other)
			if (m == puppy.dog_id or m == "both") and GameData.reconciled(puppy.dog_id, other):
				var other_name: String = GameData.DOGS[other]["name"]
				var note := "\n\n%s%s 화해했어요! 이제 친해질 수 있어요" % [other_name, _rang(other_name)]
				if _pending_gift.is_empty():
					_pending_gift = {"text": "%s%s 어른이 되면서..." % [dog_name, _ig(dog_name)] + note}
				else:
					_pending_gift["text"] += note
	else:
		celebration.play("%s %s%s 성장했어요!" % [dog_name, sp, _ig(sp)], "%s%s 됐어요" % [stage_name, _ig(stage_name)], center)


## 받침 있으면 "이", 없으면 "가"
func _ig(word: String) -> String:
	return "이" if _has_batchim(word) else "가"


## 받침 있으면 "이랑", 없으면 "랑"
func _rang(word: String) -> String:
	return "이랑" if _has_batchim(word) else "랑"


func _has_batchim(word: String) -> bool:
	var code := word.unicode_at(word.length() - 1)
	return code >= 0xAC00 and code <= 0xD7A3 and (code - 0xAC00) % 28 != 0


func _on_back() -> void:
	if busy:
		return
	GameState.save_game()
	if _tut_wait == "home":    # 튜토리얼: 홈으로 바로
		_show_home()
		_tut_event("home")
		return
	_show_roster()


# ═════════════════════════ 전투 / 책략 ═════════════════════════

func _on_battle() -> void:
	if busy or puppy.is_exhausted():
		return
	_log("전투 시작")
	_set_busy(true)
	if GameData.is_strategist(puppy.dog_id):
		_start_strategy()
	else:
		_run_battle()


func _run_battle() -> void:
	var me: String = GameData.DOGS[puppy.dog_id]["name"]
	var enemy: String = ENEMIES.pick_random()
	_open_overlay("전투!", "%s 등장!" % enemy, "battle")
	var win_rate: float = GameData.BATTLE_BASE_WIN_RATE + puppy.stage * GameData.BATTLE_WIN_RATE_PER_STAGE
	var win: bool = randf() < win_rate
	for i in 3:
		await get_tree().create_timer(GameData.BATTLE_LINE_SECONDS).timeout
		var attacker: String = me if i % 2 == 0 else enemy
		overlay_log.text += "\n%s의 %s!" % [attacker, BATTLE_MOVES.pick_random()]
	await get_tree().create_timer(GameData.BATTLE_LINE_SECONDS).timeout
	var drops: Array[String] = GameData.roll_drops(GameData.BATTLE_WIN_DROPS if win else GameData.BATTLE_LOSE_DROPS)
	puppy.add_foods(drops)
	_log("전투 결과: %s" % [drops])
	overlay_log.text += "\n\n" + ("승리! 적이 군량을 두고 도망쳤다" if win else "졌다... 그래도 뭔가 주워왔다")
	_show_drops(drops, _roll_special())
	confirm_button.show()


func _start_strategy() -> void:
	var text := "상대 책사 고양이가 수를 고민하고 있다...\n\n화공 > 매복 > 이간 > 화공"
	_open_overlay("책략 내기", text, "battle")
	strategy_box.show()


func _on_strategy(pick: int) -> void:
	strategy_box.hide()
	var enemy_pick := randi() % STRATEGIES.size()
	overlay_log.text = "나: %s   vs   상대: %s" % [STRATEGIES[pick], STRATEGIES[enemy_pick]]
	await get_tree().create_timer(GameData.BATTLE_LINE_SECONDS * 2).timeout
	var amount: Vector2i
	var result: String
	if pick == enemy_pick:
		amount = GameData.STRATEGY_DRAW_DROPS
		result = "비겼다! 서로 군량을 나눠 가졌다"
	elif enemy_pick == (pick + 1) % STRATEGIES.size():
		amount = GameData.STRATEGY_WIN_DROPS
		result = "계략 성공! 적 군량고를 털었다"
	else:
		amount = GameData.STRATEGY_LOSE_DROPS
		result = "간파당했다... 겨우 하나 챙겼다"
	var drops: Array[String] = GameData.roll_drops(amount)
	puppy.add_foods(drops)
	overlay_log.text += "\n\n" + result
	_show_drops(drops, _roll_special())
	confirm_button.show()


## 희귀템 뽑기: 나오면 가방에 넣고 글로 알려줌
func _roll_special() -> String:
	var lucky: bool = GameState.luck > 0
	if lucky:
		GameState.luck -= 1
		GameState.save_game()
		overlay_log.text += "\n(네잎클로버 효과! 남은 %d번)" % GameState.luck
	var sp: String = GameData.roll_special(lucky)
	if sp != "":
		GameState.add_item(sp)
		overlay_log.text += "\n\n★ 희귀템 발견! %s ★" % GameData.ITEMS[sp]["name"]
		_log("희귀템: " + sp)
	return sp


## 얻은 음식(+희귀템)을 그림으로 쭉 띄우기 (하나씩 슉슉 튀어나옴)
func _show_drops(drops: Array[String], special := "") -> void:
	for c in drops_box.get_children():
		c.queue_free()
	var sorted := drops.duplicate()
	sorted.sort_custom(func(a: String, b: String) -> bool:
		return GameData.FOOD_ORDER.find(a) < GameData.FOOD_ORDER.find(b))
	var ids: Array[String] = []
	for f in sorted:
		ids.append(GameData.food_icon_id(f, puppy.dog_id))
	if special != "":
		ids.append(GameData.ITEMS[special]["icon"])
	for i in ids.size():
		var icon := FoodIcon.new()
		icon.food_id = ids[i]
		var side := 92.0 if (special != "" and i == ids.size() - 1) else 72.0
		icon.custom_minimum_size = Vector2(side, side)
		icon.pivot_offset = Vector2(side, side) / 2
		icon.scale = Vector2.ZERO
		drops_box.add_child(icon)
		var tw := icon.create_tween()
		tw.tween_interval(i * 0.04)
		tw.tween_property(icon, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	drops_box.show()


# ═════════════════════════ 가방 (희귀템) ═════════════════════════

func _open_bag() -> void:
	if busy or puppy == null:
		return
	_fill_bag()
	bag_overlay.move_to_front()
	bag_overlay.show()


func _fill_bag() -> void:
	for c in bag_list.get_children():
		c.queue_free()
	if GameState.luck > 0:
		var luck_l := _label("네잎클로버 효과 중!  남은 전투·책략 %d번" % GameState.luck, 24)
		luck_l.add_theme_color_override("font_color", Color(0.25, 0.55, 0.25))
		bag_list.add_child(luck_l)
	for item_id in GameData.ITEM_ORDER:
		var item: Dictionary = GameData.ITEMS[item_id]
		var count: int = GameState.item_count(item_id)
		var row := _card_row()
		var h: HBoxContainer = row.get_child(0)
		var icon := FoodIcon.new()
		icon.food_id = item["icon"]
		icon.custom_minimum_size = Vector2(80, 80)
		icon.modulate.a = 1.0 if count > 0 else 0.35
		h.add_child(icon)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = SIZE_EXPAND_FILL
		info.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_child(info)
		var name_l := _label("%s  x%d" % [item["name"], count], 28)
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		info.add_child(name_l)
		var desc := _label(item["desc"], 20)
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		desc.add_theme_color_override("font_color", SUB_COLOR)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(desc)
		var use := _button("쓰기", _use_item.bind(item_id))
		use.custom_minimum_size = Vector2(110, 70)
		use.size_flags_vertical = SIZE_SHRINK_CENTER
		use.disabled = count <= 0 or _item_block_reason(item_id) != ""
		h.add_child(use)
		bag_list.add_child(row)


## 지금 못 쓰는 이유 (쓸 수 있으면 "")
func _item_block_reason(item_id: String) -> String:
	match item_id:
		"ginseng":
			if puppy.fatigue <= 0:
				return "피곤하지 않아요"
	return ""


func _use_item(item_id: String) -> void:
	if _item_block_reason(item_id) != "" or not GameState.take_item(item_id):
		return
	bag_overlay.hide()
	match item_id:
		"ginseng":
			puppy.rest()
			_show_msg("산삼 냠냠! 기운이 펄펄!")
		"peach":
			if puppy.is_adult():
				puppy.affection += GameData.PEACH_EXP
				_show_msg("천도복숭아 냠냠! 친밀도 +%d" % GameData.PEACH_EXP)
			else:
				var before := puppy.stage
				puppy.add_exp(GameData.PEACH_EXP)
				if puppy.stage == before:
					_show_msg("천도복숭아 냠냠! +%d exp" % GameData.PEACH_EXP)
		"clover":
			GameState.luck += GameData.CLOVER_BATTLES
			_show_msg("뭔가 좋은 일이 일어날 것 같아!")
		"pouch":
			var got: String = GameData.roll_weighted(GameData.POUCH_WEIGHTS)
			if got == "ticket":
				GameState.tickets += 1
				_show_msg("복주머니에서... 뽑기권이 나왔어요!!")
			else:
				GameState.add_item(got)
				_show_msg("복주머니에서 %s%s 나왔어요!" % [GameData.ITEMS[got]["name"], _ig(GameData.ITEMS[got]["name"])])
	_log("아이템 사용: " + item_id)
	_after_action()


# ═════════════════════════ 관계도 / 호감도 / 커플 ═════════════════════════

## 왼쪽 위 작은 관계도: 의형제(복숭아) → 커플(하트) → 신뢰(방패) → 가족(집) → 앙숙(해골) 순서. 데리고 있는 애만
const BOND_ORDER: Array[String] = ["peach", "heart", "trust", "family", "skull"]


func _update_relations() -> void:
	for c in relation_box.get_children():
		relation_box.remove_child(c)
		c.queue_free()
	_fit_relation_scroll.call_deferred()
	if puppy == null:
		return
	var me := puppy.dog_id
	var rows: Array = []
	for other in GameState.owned:
		if other == me:
			continue
		var kinds := _bond_kinds(me, other)
		if not kinds.is_empty():
			rows.append([BOND_ORDER.find(kinds[0]), other, kinds])
	rows.sort_custom(func(a: Array, b: Array) -> bool:
		return a[0] < b[0])
	for r in rows:
		relation_box.add_child(_relation_row(r[2], r[1]))
	_fit_relation_scroll.call_deferred()


## 관계 목록 크기: 내용만큼, 단 화면 왼쪽 40% · 위쪽 45%까지만 (넘치면 스크롤)
const RELATION_MAX_W := 0.45
const RELATION_MAX_H := 0.45


func _fit_relation_scroll() -> void:
	if relation_scroll == null:
		return
	var content := relation_box.get_combined_minimum_size()
	relation_scroll.size = Vector2(minf(content.x, puppy_view.size.x * RELATION_MAX_W),
		minf(content.y, puppy_view.size.y * RELATION_MAX_H))


## 둘 사이의 모든 관계 (BOND_ORDER 순서)
func _bond_kinds(me: String, other: String) -> Array[String]:
	var kinds: Array[String] = []
	if GameState.is_sworn(me, other):
		kinds.append("peach")
	if GameState.is_couple(me, other):
		kinds.append("heart")
	if GameData.is_trusted(me, other):
		kinds.append("trust")
	if GameData.is_family(me, other):
		kinds.append("family")
	if GameData.is_rival(me, other):
		kinds.append("skull")
	return kinds


## 관계 아이콘 하나 (heart / skull 은 로우폴리 도형, peach 는 천도복숭아 그림)
func _bond_icon(kind: String, side: float) -> Control:
	if kind == "peach":
		var t := TextureRect.new()
		t.texture = FoodIcon.item_texture("item_peach")
		t.custom_minimum_size = Vector2(side, side)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.mouse_filter = MOUSE_FILTER_IGNORE
		return t
	var icon = PolyIconScript.new()
	icon.kind = kind
	icon.custom_minimum_size = Vector2(side, side)
	return icon


func _relation_row(kinds: Array, other: String) -> Control:
	var row := HBoxContainer.new()
	row.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	for kind in kinds:
		row.add_child(_bond_icon(kind, 40))
	var l := _label(GameData.DOGS[other]["name"], 28)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_child(l)
	return row


## 하트·복숭아·해골 누르면 설명창
## 관계 목록: 손가락으로 끌면 스크롤, 콕 누르면(거의 안 움직이고 뗐을 때) 설명창
var _rel_press := Vector2.INF
var _rel_scroll_at := 0


func _on_relation_box_input(event: InputEvent) -> void:
	if busy:
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if event.pressed:
		_rel_press = event.global_position
		_rel_scroll_at = relation_scroll.scroll_vertical
		return
	var tapped : bool = _rel_press != Vector2.INF and event.global_position.distance_to(_rel_press) < 16.0 \
		and absi(relation_scroll.scroll_vertical - _rel_scroll_at) < 4
	_rel_press = Vector2.INF
	if tapped:
		relation_box.accept_event()
		_open_overlay("멍냥이 관계도", "복숭아는 의형제, 하트는 커플,\n방패는 신뢰, 집은 가족,\n해골은 앙숙이에요.", "notice")
		for pair in [["peach", "의형제"], ["heart", "커플"], ["trust", "신뢰"], ["family", "가족"], ["skull", "앙숙"]]:
			drops_box.add_child(_bond_icon(pair[0], 40))
			drops_box.add_child(_label(pair[1], 20))
		drops_box.show()
		confirm_button.show()
		_set_busy(true)


func _open_relations() -> void:
	if busy or puppy == null:
		return
	var me_name: String = GameData.DOGS[puppy.dog_id]["name"]
	rel_title.text = "%s의 관계도" % me_name
	rel_msg.text = " "
	_fill_relations()
	rel_overlay.move_to_front()
	rel_overlay.show()


func _fill_relations() -> void:
	for c in rel_list.get_children():
		c.queue_free()
	var me := puppy.dog_id
	var others: Array[String] = []
	for id in GameState.owned:
		if id != me:
			others.append(id)
	if others.is_empty():
		var none := _label("아직 다른 멍냥이가 없어요.\n뽑기로 친구를 데려와요!", 26)
		none.add_theme_color_override("font_color", SUB_COLOR)
		rel_list.add_child(none)
		return
	# 커플·의형제 → 친한 순 → 앙숙은 맨 아래
	others.sort_custom(func(a: String, b: String) -> bool:
		return _rel_rank(me, a) > _rel_rank(me, b))
	for other in others:
		rel_list.add_child(_relation_card(me, other))


func _rel_rank(me: String, other: String) -> int:
	if GameData.is_rival(me, other):
		return -1
	var r: int = GameState.affinity_of(me, other) + GameState.gift_count(me, other)
	if GameState.is_couple(me, other):
		r += 100
	if GameState.is_sworn(me, other):
		r += 50
	return r


## 하트/복숭아 4칸 줄
func _meter(kind: String, filled: int, total: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	for i in total:
		if kind == "peach":
			var t := _bond_icon("peach", 32) as TextureRect
			if i >= filled:
				t.modulate = Color(0.55, 0.55, 0.55, 0.35)   # 빈 칸
			row.add_child(t)
		else:
			row.add_child(_bond_icon("heart" if i < filled else "heart_empty", 32))
	return row


## 카톡 친구목록처럼: 얼굴 + 이름(+관계 아이콘) + 하트 4칸(놀기→고백) + 복숭아 4칸(선물→의형제)
func _relation_card(me: String, other: String) -> Control:
	var row := _card_row()
	var h: HBoxContainer = row.get_child(0)
	var face := TextureRect.new()
	face.texture = _dog_tex(other, PuppyView.STAGE_FORM[GameState.stage_of(other)])
	face.custom_minimum_size = Vector2(92, 92)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.size_flags_vertical = SIZE_SHRINK_CENTER
	h.add_child(face)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 2)
	h.add_child(info)
	var dog: Dictionary = GameData.DOGS[other]
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	info.add_child(name_row)
	var name_l := _label(dog["name"], 30)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_row.add_child(name_l)
	# 꼬리표: 의형제(노랑) 커플(분홍) 신뢰(파랑) 가족(주황) 앙숙(회색)
	if GameState.is_sworn(me, other):
		name_row.add_child(_tag("의형제", Color(0.9, 0.7, 0.18)))
	if GameState.is_couple(me, other):
		name_row.add_child(_tag("커플", PINK))
	if GameData.is_trusted(me, other):
		name_row.add_child(_tag("신뢰", Color(0.3, 0.56, 0.78)))
	if GameData.is_family(me, other):
		name_row.add_child(_tag("가족", Color(0.78, 0.56, 0.3)))
	if GameData.is_rival(me, other):
		name_row.add_child(_tag("앙숙", Color(0.56, 0.54, 0.53)))
	var sub := _label("%s 진영 · %s" % [GameData.FACTIONS[dog["faction"]]["name"], GameData.stage_name(GameState.stage_of(other), other)], 18)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	sub.add_theme_color_override("font_color", SUB_COLOR)
	info.add_child(sub)

	var actions := VBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 6)
	h.add_child(actions)

	if GameData.is_rival(me, other):
		var rival_row := HBoxContainer.new()
		rival_row.add_child(_bond_icon("skull", 34))
		var why := "주군끼리는 앙숙!" if GameData.is_lord(me) and GameData.is_lord(other) else "서로 싫어해요"
		var mender: String = GameData.grow_out_by(me, other)
		if mender == "both":
			why = "둘 다 어른 되면 화해할지도..?"
		elif mender != "":
			why = "%s 어른 되면 화해할지도..?" % GameData.DOGS[mender]["name"]
		var l := _label(why, 20)
		l.add_theme_color_override("font_color", SUB_COLOR)
		rival_row.add_child(l)
		info.add_child(rival_row)
		return row

	# 하트 줄: 놀기 → 고백
	var couple: bool = GameState.is_couple(me, other)
	var aff_max: int = GameData.affinity_max(me, other)
	info.add_child(_meter("heart", aff_max if couple else GameState.affinity_of(me, other), aff_max))
	# 복숭아 줄: 선물하기 → 의형제
	var bonded: bool = GameState.is_sworn(me, other)
	var gift_max: int = GameData.gift_max(me, other)
	info.add_child(_meter("peach", gift_max if bonded else GameState.gift_count(me, other), gift_max))

	if not couple:
		if GameState.affinity_of(me, other) < aff_max:
			actions.add_child(_small_button("놀기", _on_play.bind(other), "", Color()))
		else:
			actions.add_child(_small_button("고백하기", _on_confess.bind(other), _confess_block_reason(me, other), PINK,
				"성공 %d%%" % roundi(GameData.confess_chance(me, other) * 100)))
	if not bonded:
		if GameState.gift_count(me, other) < gift_max:
			var no_peach := "복숭아가 없어요" if GameState.item_count("peach") <= 0 else ""
			actions.add_child(_small_button("선물하기", _on_gift.bind(other), no_peach, Color(0.95, 0.6, 0.62)))
		else:
			actions.add_child(_small_button("의형제 맺기", _on_swear.bind(other), _swear_block_reason(me, other), Color(0.92, 0.5, 0.6),
				"성공 %d%%" % roundi(GameData.swear_chance(me, other) * 100)))
	return row


## 이름 옆 작은 색 꼬리표 (신뢰 / 가족)
func _tag(text: String, col: Color) -> Label:
	var l := _label(text, 17)
	l.add_theme_color_override("font_color", Color.WHITE)
	var sb := _box(col, 10)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	l.add_theme_stylebox_override("normal", sb)
	l.size_flags_vertical = SIZE_SHRINK_CENTER
	return l


## 관계도 카드 오른쪽 작은 버튼 (못 누르면 회색 + 아래에 이유)
func _small_button(text: String, cb: Callable, block: String, col: Color, note := "") -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	var b := _button(text, cb)
	b.custom_minimum_size = Vector2(150, 64)
	b.add_theme_font_size_override("font_size", _fs(22))
	if col != Color():
		b.add_theme_stylebox_override("normal", _box(col, 18))
		b.add_theme_stylebox_override("hover", _box(col.lightened(0.1), 18))
		b.add_theme_stylebox_override("pressed", _box(col.darkened(0.15), 18))
	b.disabled = block != ""
	box.add_child(b)
	if block != "" or note != "":
		var l := _label(block if block != "" else note, 15)
		l.add_theme_color_override("font_color", SUB_COLOR)
		box.add_child(l)
	return box


## 고백 못 하는 이유 (할 수 있으면 "")
func _confess_block_reason(me: String, other: String) -> String:
	if GameData.is_family(me, other):
		return "가족이라 고백은 안 돼요"
	if not GameState.get_puppy(me).is_adult() or not GameState.get_puppy(other).is_adult():
		return "둘 다 어른이 되면!"
	if not GameState.can_take_partner(me):
		return "이미 애인이 있어요"
	if not GameState.can_take_partner(other):
		return "상대는 이미 커플"
	return ""


## 의형제 못 하는 이유 (할 수 있으면 "")
func _swear_block_reason(me: String, other: String) -> String:
	if not GameState.can_take_sworn(me):
		return "의형제가 벌써 %d명" % GameData.SWORN_MAX
	if not GameState.can_take_sworn(other):
		return "상대 의형제가 꽉 찼어요"
	return ""


func _on_play(other: String) -> void:
	var me := puppy.dog_id
	var me_name: String = GameData.DOGS[me]["name"]
	var other_name: String = GameData.DOGS[other]["name"]
	var gained: bool = GameState.play_together(me, other)
	if gained:
		var now: int = GameState.affinity_of(me, other)
		rel_msg.text = "%s%s %s %s\n호감도 +1%s" % [me_name, _rang(me_name), other_name, PLAY_MESSAGES.pick_random(),
			("  고백할 수 있어요!" if not GameData.is_family(me, other) else "  (가족이라 고백은 안 돼요)") if now >= GameData.affinity_max(me, other) else ""]
	else:
		rel_msg.text = "%s%s %s 아직 어색한가 봐요...\n(다른 진영이라 친해지기 어려워요)" % [me_name, _rang(me_name), other_name]
	_log("놀기: %s - %s (%s)" % [me, other, gained])
	_fill_relations()


func _on_gift(other: String) -> void:
	var me := puppy.dog_id
	if not GameState.give_peach(me, other):
		return
	var me_name: String = GameData.DOGS[me]["name"]
	var other_name: String = GameData.DOGS[other]["name"]
	var n: int = GameState.gift_count(me, other)
	rel_msg.text = "%s%s %s에게 천도복숭아를 선물했어요! (%d/%d)%s" % [me_name, _ig(me_name), other_name, n, GameData.gift_max(me, other),
		"\n의형제를 맺을 수 있어요!" if n >= GameData.gift_max(me, other) else ""]
	_log("선물: %s -> %s (%d)" % [me, other, n])
	_fill_relations()


func _on_confess(other: String) -> void:
	var me := puppy.dog_id
	if _confess_block_reason(me, other) != "" or GameState.affinity_of(me, other) < GameData.affinity_max(me, other):
		return
	rel_overlay.hide()
	var me_name: String = GameData.DOGS[me]["name"]
	var other_name: String = GameData.DOGS[other]["name"]
	_set_busy(true)
	_open_overlay("고백 중...", "%s ♥ %s\n\n두근두근..." % [me_name, other_name], "notice")
	await get_tree().create_timer(1.0).timeout
	if randf() >= GameData.confess_chance(me, other):
		GameState.reset_affinity(me, other)
		overlay_title.text = "고백이 실패했어요.."
		overlay_log.text = "%s%s %s\n\n다른 좋은 털뭉치 만나..\n(하트가 처음으로 돌아갔어요)" % [other_name, _ig(other_name), "고개를 저었어요" ]
		_log("고백 실패: %s - %s" % [me, other])
		_update_relations()
		confirm_button.show()
		return
	GameState.add_couple(me, other)
	overlay_title.text = "커플이 되었습니다!"
	overlay_log.text = "%s ♥ %s\n\n오늘부터 1일 ♥" % [me_name, other_name]
	celebration.play("커플이 되었습니다!", "%s ♥ %s" % [me_name, other_name],
		puppy_view.global_position + puppy_view.size / 2 - celebration.global_position)
	_log("커플 성공: %s - %s" % [me, other])
	_update_relations()
	confirm_button.show()


func _on_swear(other: String) -> void:
	var me := puppy.dog_id
	if _swear_block_reason(me, other) != "" or GameState.gift_count(me, other) < GameData.gift_max(me, other):
		return
	rel_overlay.hide()
	var me_name: String = GameData.DOGS[me]["name"]
	var other_name: String = GameData.DOGS[other]["name"]
	_set_busy(true)
	_open_overlay("의형제", "복숭아 동산에서...\n\n%s, %s" % [me_name, other_name], "notice")
	overlay_image.texture = FoodIcon.item_texture("item_peach")
	overlay_image.show()
	await get_tree().create_timer(1.0).timeout
	if randf() >= GameData.swear_chance(me, other):
		GameState.reset_gifts(me, other)
		overlay_title.text = "의형제를 맺지 못했어요.."
		overlay_log.text = "%s%s 아직 마음을 열지 않았어요.\n\n(복숭아가 처음으로 돌아갔어요)" % [other_name, _ig(other_name)]
		_log("의형제 실패: %s - %s" % [me, other])
		_update_relations()
		confirm_button.show()
		return
	GameState.add_sworn(me, other)
	overlay_title.text = "의형제가 되었어요!"
	overlay_log.text = "%s, %s\n\n태어난 날은 달라도\n같은 날 같이 간식 먹자!" % [me_name, other_name]
	celebration.play("의형제!", "%s · %s" % [me_name, other_name],
		puppy_view.global_position + puppy_view.size / 2 - celebration.global_position)
	_log("의형제: %s - %s" % [me, other])
	_update_relations()
	confirm_button.show()


# ═════════════════════════ 오버레이 ═════════════════════════

func _build_overlay() -> void:
	overlay = Control.new()
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	overlay.mouse_filter = MOUSE_FILTER_STOP
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	panel.add_child(v)

	overlay_title = _label("", 40)
	overlay_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_title.custom_minimum_size = Vector2(560, 0)
	v.add_child(overlay_title)
	overlay_image = TextureRect.new()
	overlay_image.custom_minimum_size = Vector2(220, 220)
	overlay_image.size_flags_horizontal = SIZE_SHRINK_CENTER
	overlay_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(overlay_image)
	overlay_log = _label("", 28)
	overlay_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_log.custom_minimum_size = Vector2(560, 120)
	overlay_log.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	v.add_child(overlay_log)

	drops_box = HBoxContainer.new()
	drops_box.alignment = BoxContainer.ALIGNMENT_CENTER
	drops_box.add_theme_constant_override("separation", 4)
	v.add_child(drops_box)

	strategy_box = HBoxContainer.new()
	strategy_box.add_theme_constant_override("separation", 12)
	v.add_child(strategy_box)
	for i in STRATEGIES.size():
		var b := _button(STRATEGIES[i], _on_strategy.bind(i))
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 100)
		strategy_box.add_child(b)

	confirm_button = _button("확인", _on_overlay_confirm)
	cancel_button = _button("취소", func() -> void:
		overlay.hide()
		_overlay_mode = "")
	cancel_button.custom_minimum_size = Vector2(0, 90)
	confirm_button.custom_minimum_size = Vector2(0, 90)
	v.add_child(confirm_button)
	v.add_child(cancel_button)
	overlay.hide()


## 목록형 창 (관계도·가방): [루트, 위쪽 VBox, 스크롤 안 목록] 반환. 닫기 버튼 포함
func _build_panel_overlay(list_size: Vector2) -> Array:
	var root := Control.new()
	root.set_anchors_preset(PRESET_FULL_RECT)
	root.mouse_filter = MOUSE_FILTER_STOP
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	panel.add_child(outer)
	var top := VBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	outer.add_child(top)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = list_size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER   # 모바일: 바 없이 손가락으로 스크롤
	outer.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	var close := _button("닫기", func() -> void:
		root.hide()
		_refresh())
	close.custom_minimum_size = Vector2(0, 80)
	outer.add_child(close)
	root.hide()
	return [root, top, list]


## 목록 한 줄 카드 (연한 배경 + 가로 배치). 첫 자식이 HBoxContainer
func _card_row() -> PanelContainer:
	var card := PanelContainer.new()
	var sb := _box(Color(0.97, 0.93, 0.86), 18)
	sb.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	card.add_child(h)
	return card


func _open_overlay(title: String, text: String, mode: String) -> void:
	_overlay_mode = mode
	overlay_title.text = title
	overlay_log.text = text
	overlay_log.show()
	overlay_image.hide()
	overlay_image.scale = Vector2.ONE
	overlay_image.rotation = 0.0
	strategy_box.hide()
	confirm_button.hide()
	confirm_button.text = "확인"
	for key in ["normal", "hover", "pressed"]:
		confirm_button.remove_theme_stylebox_override(key)
	cancel_button.hide()
	drops_box.hide()
	for c in drops_box.get_children():
		c.queue_free()
	overlay.move_to_front()
	celebration.move_to_front()
	overlay.show()


func _on_overlay_confirm() -> void:
	_log("확인 버튼")
	overlay.hide()
	match _overlay_mode:
		"gacha":
			_show_gacha()
			_tut_event("gacha_done")
			return
		"home_notice":
			return
		"reset_confirm":
			_do_reset()
			return
	_set_busy(false)
	if _overlay_mode == "battle":
		puppy.add_fatigue(GameData.FATIGUE_PER_BATTLE)
		if puppy.is_exhausted():
			_show_msg("싸웠더니 너무 피곤해..")
		_after_action()
		_tut_event("battle")


# ═════════════════════════ UI 헬퍼 ═════════════════════════

func _setup_theme() -> void:
	var t := Theme.new()
	t.default_font_size = 34
	if ResourceLoader.exists(FONT_PATH):
		var font: FontFile = load(FONT_PATH)
		# 폰트에 없는 글자가 나오면 Godot이 윈도우 시스템 폰트를 전부 뒤져서 멈출 수 있음 → 끄기
		font.allow_system_fallback = false
		t.default_font = font
	else:
		push_warning("한글 폰트 없음: %s 에 ttf를 넣어주세요 (웹 빌드에서 한글이 깨져요)" % FONT_PATH)

	t.set_color("font_color", "Label", TEXT_COLOR)

	var base := Color(0.86, 0.52, 0.32)
	t.set_stylebox("normal", "Button", _box(base, 18))
	t.set_stylebox("hover", "Button", _box(base.lightened(0.1), 18))
	t.set_stylebox("pressed", "Button", _box(base.darkened(0.15), 18))
	t.set_stylebox("disabled", "Button", _box(Color(0.80, 0.76, 0.70), 18))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(key, "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.75))

	var panel := _box(Color(1, 0.99, 0.96), 28)
	panel.set_content_margin_all(32)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("background", "ProgressBar", _box(Color(0.88, 0.83, 0.75), 13))
	t.set_stylebox("fill", "ProgressBar", _box(Color(0.95, 0.62, 0.35), 13))
	theme = t


## 버튼 글씨 옆 로우폴리 아이콘 (칼 / 두루마리 / 달님+구름 / 뽑기권 ...)
func _set_button_icon(b: Button, id: String) -> void:
	b.icon = FoodIcon.item_texture(id)
	b.add_theme_constant_override("icon_max_width", 64)
	b.add_theme_constant_override("h_separation", 12)
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER


## 음식 버튼 오른쪽 위 개수 동그라미
func _badge() -> Label:
	var badge := _label("0", 20)
	badge.add_theme_color_override("font_color", Color.WHITE)
	var badge_box := _box(Color(0.42, 0.24, 0.14), 14)
	badge_box.set_content_margin_all(2)
	badge_box.content_margin_left = 9
	badge_box.content_margin_right = 9
	badge.add_theme_stylebox_override("normal", badge_box)
	badge.mouse_filter = MOUSE_FILTER_IGNORE
	return badge


func _box(col: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(10)
	return sb


func _screen_margin() -> MarginContainer:
	var m := MarginContainer.new()
	m.set_anchors_preset(PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 28)
	m.add_theme_constant_override("margin_right", 28)
	m.add_theme_constant_override("margin_top", 40)
	m.add_theme_constant_override("margin_bottom", 32)
	add_child(m)
	return m


func _label(text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", _fs(font_size))
	return l


func _fs(font_size: int) -> int:
	return int(round(font_size * FONT_SCALE))


func _button(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(callback)
	b.button_down.connect(_jelly.bind(b))
	return b


## 누르는 순간 보잉! 젤리처럼 찌그러졌다 튕기며 돌아옴
func _jelly(c: Control) -> void:
	if not is_instance_valid(c):
		return
	c.pivot_offset = c.size / 2
	if c.has_meta("jelly"):              # 연타하면 앞의 출렁임은 끊고 새로
		var old: Tween = c.get_meta("jelly")
		if old and old.is_valid():
			old.kill()
	var tw := c.create_tween()
	c.set_meta("jelly", tw)
	# 출렁임 세기: JELLY 를 키우면 더 보잉, 줄이면 더 얌전
	var k := JELLY
	tw.tween_property(c, "scale", Vector2(1.0 + 0.12 * k, 1.0 - 0.14 * k), 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "scale", Vector2(1.0 - 0.06 * k, 1.0 + 0.07 * k), 0.08).set_trans(Tween.TRANS_SINE)
	tw.tween_property(c, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
