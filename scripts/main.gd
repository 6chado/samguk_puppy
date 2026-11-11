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
const CLOVER_COL := Color(0.4, 0.68, 0.38)   # 클로버(화해) 버튼·꼬리표
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
	"special": Color(0.52, 0.32, 0.7), "jin": Color(0.17, 0.5, 0.5),
	"han": Color(0.87, 0.49, 0.17), "chu": Color(0.25, 0.23, 0.29)}

var page: Control          # 홈 / 목록 / 도감 (매번 새로 만듦)
var raise_screen: Control

var title_label: Label
var stage_label: Label
var title_tag: HBoxContainer   # 키우기 화면 칭호 꼬리표 자리
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
var _anger_mark: Control   # 창 그림 위 💢
var overlay_image2: TextureRect   # 두 마리 같이 보여 줄 때 오른쪽 그림
var overlay_image3: TextureRect
var _anger_marks: Array = []
var overlay_extra: VBoxContainer
var overlay_stats: HBoxContainer   # 그림 밑 작은 상태 (대전 결과: 칭호·전공)
var _tear_marks: Array = []       # 그림 위 ㅠㅠ 눈물
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
const RpsIconScript := preload("res://scripts/rps_icon.gd")
const ShinyTagScript := preload("res://scripts/shiny_tag.gd")
const EmperorTagScript := preload("res://scripts/emperor_tag.gd")
const StoryData := preload("res://scripts/story_data.gd")
const GradTagScript := preload("res://scripts/gradient_tag.gd")
const FramePanelScript := preload("res://scripts/frame_panel.gd")
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
	tut.tapped.connect(func() -> void:
		if _btut_step >= 0:
			_btut_next()
		else:
			_tut_next())
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
	ticket_row.add_child(_label("도감 %d/%d" % [GameState.owned.size(), GameState.dex_total()], 28))

	var id: String = GameState.current
	var home_view := PuppyView.new()   # 홈에서도 쓰다듬으면 하트는 나옴 (수치는 안 바뀜)
	home_view.size_flags_vertical = SIZE_EXPAND_FILL
	v.add_child(home_view)
	home_view.body_color = GameData.DOGS[id]["color"]
	home_view.dog_id = id
	home_view.stage = GameState.stage_of(id)
	v.add_child(_label("%s  ·  %s" % [GameData.DOGS[id]["name"], GameData.stage_name(GameState.stage_of(id), id)], 34))

	# 대전 (튜토리얼 보기 전엔 회색 잠김)
	var mini := _button("대전", _show_mini)
	_set_button_icon(mini, "icon_strategy")
	mini.custom_minimum_size = Vector2(0, 100)
	var navy := Color(0.36, 0.38, 0.6)
	mini.add_theme_stylebox_override("normal", _box(navy, 18))
	mini.add_theme_stylebox_override("hover", _box(navy.lightened(0.1), 18))
	mini.add_theme_stylebox_override("pressed", _box(navy.darkened(0.15), 18))
	mini.add_theme_stylebox_override("disabled", _box(Color(0.74, 0.72, 0.7), 18))
	mini.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.9))
	if not GameState.battle_tut_done:
		mini.disabled = true
		mini.text = "대전 · 무장과 책사를 어른으로 키우면 열려요"
		mini.add_theme_font_size_override("font_size", _fs(22))
	v.add_child(mini)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var gacha := _button("뽑기", _show_gacha)
	_home_gacha_btn = gacha
	_set_button_icon(gacha, "ticket")
	gacha.custom_minimum_size = Vector2(0, 110)
	gacha.size_flags_horizontal = SIZE_EXPAND_FILL
	var pink := _gacha_color()
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
	var story := _button("이야기", _show_sp_stories)
	_set_button_icon(story, "item_scroll")
	story.custom_minimum_size = Vector2(0, 110)
	story.size_flags_horizontal = SIZE_EXPAND_FILL
	var plum := Color(0.55, 0.45, 0.72)
	story.add_theme_stylebox_override("normal", _box(plum, 18))
	story.add_theme_stylebox_override("hover", _box(plum.lightened(0.1), 18))
	story.add_theme_stylebox_override("pressed", _box(plum.darkened(0.15), 18))
	row.add_child(story)
	for b in [gacha, dex, cam, story]:   # 4개라 글씨·아이콘 조금 작게
		b.add_theme_font_size_override("font_size", _fs(28))
		b.add_theme_constant_override("icon_max_width", 48)
		b.add_theme_constant_override("h_separation", 6)
	var go := _button("키우러 가기", _show_roster)
	go.custom_minimum_size = Vector2(0, 120)
	go.add_theme_font_size_override("font_size", _fs(38))
	v.add_child(go)
	(func() -> void:
		if not _story_check():
			_btut_check()).call_deferred()


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
		_tab_faction = GameData.faction_of(GameState.current)
	var v := _new_page()
	var title := "키우러 가기" if kind == "roster" else "도감 %d / %d" % [GameState.owned.size(), GameState.dex_total()]
	_page_header(v, "← 홈", _show_home, title)
	if kind == "dex":   # 칭호·스페셜 칭호·단체 칭호·이야기 모아 보기
		var rec := _button("칭호 · 이야기 모아 보기", _show_records.bind("rank"))
		_set_button_icon(rec, "item_scroll")
		rec.custom_minimum_size = Vector2(0, 80)
		rec.add_theme_font_size_override("font_size", _fs(26))
		_yellow_outline(rec)
		v.add_child(rec)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	v.add_child(tabs)
	for fid in GameData.faction_order():
		var total := 0
		for id in GameData.DOGS:
			if GameData.faction_of(id) == fid and GameData.available(id):
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
		if GameData.faction_of(id) == cur and id != lord and GameData.available(id):
			if kind == "dex" or GameState.owns(id):
				others.append(id)

	# 맨 윗줄: 주군 한 마리 가운데 (금색 테두리). 아래 칸들과 크기가 똑같도록 같은 3칸 격자에 [빈칸, 주군, 빈칸]
	if lord != "" and (GameState.owns(lord) or kind == "dex"):
		var top := _grid(list)
		var card := _page_card(kind, lord)
		if GameState.owns(lord):
			var gold := Color(0.95, 0.74, 0.22)
			card.add_theme_stylebox_override("normal", _card_box(Color(1.0, 0.97, 0.86), gold, 4))
			card.add_theme_stylebox_override("hover", _card_box(Color(1.0, 0.95, 0.8), gold, 4))
			card.add_theme_stylebox_override("pressed", _card_box(Color(0.98, 0.9, 0.72), gold, 4))
		for c in [Control.new(), card, Control.new()]:
			(c as Control).size_flags_horizontal = SIZE_EXPAND_FILL
			top.add_child(c)

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
	# 성장 과정 밑에: 칭호 + 전공 현황
	overlay_extra.add_child(_rank_panel(dog_id, true))
	# 이 멍냥이 이야기가 있고 이미 봤으면: 다시 보기 버튼 (칭호 아래, 닫기 위)
	if STORY_IDS.has(dog_id) and _story_seen(dog_id):
		var sp: String = GameData.species(dog_id)
		var rb := _button("%s %s 이야기 다시 보기" % [dog["name"], sp], _replay_story.bind(dog_id))
		rb.custom_minimum_size = Vector2(0, 76)
		rb.add_theme_font_size_override("font_size", _fs(24))
		var col := Color(0.55, 0.45, 0.72)
		rb.add_theme_stylebox_override("normal", _box(col, 18))
		rb.add_theme_stylebox_override("hover", _box(col.lightened(0.1), 18))
		rb.add_theme_stylebox_override("pressed", _box(col.darkened(0.15), 18))
		overlay_extra.add_child(rb)
	overlay_extra.show()
	confirm_button.text = "닫기"
	confirm_button.show()


## 칭호 꼬리표 (없으면 null). 단계별 색, 황제는 각자 이름의 왕관 꼬리표
func _rank_tag(id: String, px: int, lv := -1) -> Control:
	if lv < 0:
		lv = GameState.rank_of(id)
	if lv <= 0:
		return null
	if GameData.is_emperor_lv(id, lv):   # 황제: 각자 이름 + 금·빨강·검정 꼬리표
		var e = EmperorTagScript.new()
		e.setup(GameData.rank_name(id, lv), GameData.emperor_theme(id), _fs(px))
		return e
	var t = ShinyTagScript.new()
	t.setup(GameData.rank_name(id, lv), GameData.rank_color(lv), "plain", _fs(px))
	return t


## 스페셜 칭호 꼬리표 (반짝이는 무지갯빛 테두리)
func _special_tag(text: String, px: int) -> Control:
	var cols := _special_colors(text)
	var t = GradTagScript.new()
	t.setup(text, cols[0], cols[1], _fs(px))
	return t


## 스페셜 칭호 그라데이션 색: 같은 진영이면 진한색 → 연한색 (촉: 초록 → 연두), 다르면 진영 색 → 진영 색
func _special_colors(title: String) -> Array:
	for sp in GameData.SPECIAL_TITLES:
		if sp["name"] == title:
			var fa: String = GameData.faction_of(sp["a"])
			var fb: String = GameData.faction_of(sp["b"])
			var ca: Color = FACTION_COLORS.get(fa, Color(0.86, 0.6, 0.2))
			var cb: Color = FACTION_COLORS.get(fb, Color(0.86, 0.6, 0.2))
			if fa == fb:
				return [ca.darkened(0.08), ca.lightened(0.45)]
			return [ca, cb]
	return [Color(0.86, 0.6, 0.2), Color(0.98, 0.82, 0.4)]


## 단체 칭호 꼬리표 (하늘색 바탕 + 반짝이는 테두리)
func _group_tag(text: String, px: int) -> Control:
	var cols := _group_colors(text)
	var t = GradTagScript.new()
	t.setup(text, cols[0], cols[1], _fs(px))
	return t


## 단체 칭호 그라데이션 색: 멤버 진영이 다 같으면 진한색 → 연한색, 섞였으면 첫 진영 색 → 다른 진영 색
func _group_colors(title: String) -> Array:
	for g in GameData.GROUP_TITLES:
		if g["name"] == title:
			var facs: Array[String] = []
			for m in g["members"]:
				var f: String = GameData.faction_of(m)
				if not facs.has(f):
					facs.append(f)
			var ca: Color = FACTION_COLORS.get(facs[0], Color(0.3, 0.55, 0.85))
			if facs.size() == 1:
				return [ca.darkened(0.08), ca.lightened(0.45)]
			return [ca, FACTION_COLORS.get(facs[-1], Color(0.55, 0.82, 0.98))]
	return [Color(0.3, 0.55, 0.85), Color(0.55, 0.82, 0.98)]


## 전공 막대 바탕: 지금 칭호 색을 연하게 (막 칭호가 올라 0칸이어도 동·은·금 색이 보이게)
func _bar_bg(col: Color, lv: int) -> Color:
	return Color(0.88, 0.84, 0.78) if lv <= 0 else col.lerp(Color(0.97, 0.94, 0.88), 0.62)


## 칭호 + 전공 막대. full = 도감용 (아래에 스페셜 칭호도)
func _rank_panel(id: String, full: bool) -> Control:
	var rp: Dictionary = GameState.rank_progress(id)
	var lv := int(rp["lv"])
	var col: Color = GameData.rank_bar_color(id, lv)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9 if not full else 12)
	box.mouse_filter = MOUSE_FILTER_IGNORE
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 8)
	head.mouse_filter = MOUSE_FILTER_IGNORE
	if full:
		head.add_child(_label("칭호", 26))
	var rt := _rank_tag(id, 24 if full else 16)
	if rt:
		head.add_child(rt)
	else:
		var none := _label("아직 없어요" if full else "칭호 없음", 24 if full else 15)
		none.add_theme_color_override("font_color", SUB_COLOR)
		none.mouse_filter = MOUSE_FILTER_IGNORE
		head.add_child(none)
	box.add_child(head)
	# 전공 막대: 지금 칭호 → 다음 칭호
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 20 if full else 10)
	bar.mouse_filter = MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", _box(_bar_bg(col, lv), 6))
	bar.add_theme_stylebox_override("fill", _box(col.darkened(0.05), 6))
	var num: Label
	if int(rp["next"]) < 0:
		bar.max_value = 1
		bar.value = 1
		num = _label("최고 칭호! (전공 %d)" % rp["exp"], 22 if full else 14)
	else:
		bar.max_value = int(rp["next"]) - int(rp["prev"])
		bar.value = int(rp["exp"]) - int(rp["prev"])
		num = _label(("다음 칭호까지 %d / %d" if full else "%d / %d") % [int(rp["exp"]) - int(rp["prev"]), int(rp["next"]) - int(rp["prev"])], 22 if full else 14)
	num.add_theme_color_override("font_color", SUB_COLOR)
	num.mouse_filter = MOUSE_FILTER_IGNORE
	var pad := MarginContainer.new()
	pad.mouse_filter = MOUSE_FILTER_IGNORE
	pad.add_theme_constant_override("margin_left", 14 if not full else 40)
	pad.add_theme_constant_override("margin_right", 14 if not full else 40)
	pad.add_child(bar)
	box.add_child(pad)
	box.add_child(num)
	# 스페셜 칭호 (도감)
	if full:
		var sp_head := _label("스페셜 칭호", 24)
		box.add_child(sp_head)
		var specials: Array = GameState.specials_of(id)
		if specials.is_empty():
			var hint := _label("특별한 짝꿍과 함께 대전에서 이기면 받을 수 있어요", 18)
			hint.add_theme_color_override("font_color", SUB_COLOR)
			box.add_child(hint)
		else:
			var flow := HFlowContainer.new()
			flow.alignment = FlowContainer.ALIGNMENT_CENTER
			flow.add_theme_constant_override("h_separation", 8)
			flow.add_theme_constant_override("v_separation", 8)
			for name_ in specials:
				flow.add_child(_special_tag(name_, 22))
			box.add_child(flow)
		# 단체 칭호 (속한 게 있을 때만): 받았으면 반짝 태그, 아니면 몇 명 채웠는지
		var groups: Array = GameData.groups_of(id)
		if not groups.is_empty():
			box.add_child(_label("단체 칭호", 24))
			var gflow := HFlowContainer.new()
			gflow.alignment = FlowContainer.ALIGNMENT_CENTER
			gflow.add_theme_constant_override("h_separation", 10)
			gflow.add_theme_constant_override("v_separation", 8)
			for g in groups:
				if GameState.group_done(g):
					gflow.add_child(_group_tag(g["name"], 22))
				else:
					var gl := _label("%s %d/%d" % [g["name"], GameState.group_count(g), (g["members"] as Array).size()], 20)
					gl.add_theme_color_override("font_color", SUB_COLOR)
					gflow.add_child(gl)
			box.add_child(gflow)
			var gh := _label("멤버 모두 칭호 3단계(교위·참군) 이상이면 받아요", 16)
			gh.add_theme_color_override("font_color", SUB_COLOR)
			box.add_child(gh)
	return box


## 그림 + 글씨 카드 버튼 (연한 바탕 + 주황 테두리, 글씨는 진하게)
func _dog_card(dog_id: String, form: int, text: String, cb: Callable) -> Button:
	var b := _button(text, cb)
	b.icon = _centered_tex(_dog_tex(dog_id, form))
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.add_theme_constant_override("icon_max_width", 128)   # 잘라낸 그림이라 폭 128 = 높이 약 140 (예전과 같음)
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


## 카드용: 그림의 몸 중심(가로 22/48)이 가운데 오도록 오른쪽 빈 곳을 잘라낸 그림 (꼬리 때문에 왼쪽으로 쏠려 보이는 것 보정)
func _centered_tex(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	var key := "centered:%s" % tex.resource_path
	if not _tex_cache.has(key):
		var at := AtlasTexture.new()
		at.atlas = tex
		var sz := tex.get_size()
		at.region = Rect2(0, 0, sz.x * 44.0 / 48.0, sz.y)
		_tex_cache[key] = at
	return _tex_cache[key]


## 멍냥이 그림 (form 0 새끼 / 1 청년 / 2 어른)
func _dog_tex(dog_id: String, form: int, eyes := "open") -> Texture2D:
	var path := "%s%s_%d_%s.png" % [SPRITE_DIR, GameData.sprite_id(dog_id, form), form, eyes]
	if not _tex_cache.has(path):
		if _tex_cache.size() > 240:   # 그림을 너무 많이 쥐고 있으면 메모리가 커짐 → 비우고 다시
			_tex_cache.clear()
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
	_open_overlay("초기화", "모든 멍냥이·아이템·칭호가 사라지고\n최신 버전으로 처음 튜토리얼부터 다시 시작해요.\n초기화 하시겠습니까?", "reset_confirm")
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
	# 웹: 깃허브에 올라간 최신 버전 파일을 새로 받아서 다시 시작 (브라우저에 남은 옛날 파일 무시)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""
			setTimeout(() => Promise.all(['index.html', 'index.js', 'index.pck', 'index.wasm'].map(
				f => fetch(f, {cache: 'reload'}).catch(() => null)
			)).finally(() => location.reload()), 1500);
		""", true)
		_open_overlay("초기화 중..", "최신 버전을 받아오고 있어요.\n잠시만 기다려 주세요!", "notice")
		return
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
	for fid in GameData.faction_order():
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


## 뽑기 기계 색: 처음 = 빨강·분홍 / 진 열림 = 청록 / 초한 열림 = 주황·금색
func _gacha_theme() -> String:
	if GameData.chohan_open():
		return "_chohan"
	if GameData.jin_open():
		return "_jin"
	return ""


func _gacha_color() -> Color:
	match _gacha_theme():
		"_chohan":
			return Color(0.9, 0.58, 0.18)
		"_jin":
			return Color(0.2, 0.6, 0.57)
	return PINK


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
		t.texture = FoodIcon.item_texture(tex_name + _gacha_theme())
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
	overlay_image.texture = FoodIcon.item_texture("capsule" + _gacha_theme())
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
	overlay_log.text = "%s 진영 · %s" % [GameData.FACTIONS[GameData.faction_of(id)]["name"],
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

	var stage_row := HBoxContainer.new()
	stage_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stage_row.add_theme_constant_override("separation", 10)
	v.add_child(stage_row)
	stage_label = _label("", 30)
	stage_row.add_child(stage_label)
	title_tag = HBoxContainer.new()   # 대전 칭호 (회색→동→은→금→다이아→무지개)
	title_tag.size_flags_vertical = SIZE_SHRINK_CENTER
	stage_row.add_child(title_tag)
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
	relation_box.mouse_filter = MOUSE_FILTER_STOP
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
	for c in title_tag.get_children():
		c.queue_free()
	var rt := _rank_tag(dog_id, 22)
	if rt:
		title_tag.add_child(rt)
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
	if puppy.dog_id == "sima_yi":
		_story_check()   # 사마의 친밀도 50 → 진 이야기


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
	elif puppy and puppy.dog_id == "sima_yi":
		_story_check()   # 사마의 친밀도 50 → 진 이야기


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
		"golden_peach":
			if puppy.is_adult():
				puppy.affection += GameData.GOLDEN_PEACH_EXP
				_show_msg("황금복숭아 냠냠! 친밀도 +%d" % GameData.GOLDEN_PEACH_EXP)
			else:
				var before2 := puppy.stage
				puppy.add_exp(GameData.GOLDEN_PEACH_EXP)
				if puppy.stage == before2:
					_show_msg("황금복숭아 냠냠! +%d exp" % GameData.GOLDEN_PEACH_EXP)
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


var _rel_sig := ""   # 옆 관계 목록이 바뀌었는지 (같으면 다시 안 만듦 → 렉 줄이기)


func _update_relations() -> void:
	var sig := ""
	if puppy != null:
		sig = puppy.dog_id
		for other in GameState.owned:
			if other != puppy.dog_id:
				var k := _bond_kinds(puppy.dog_id, other)
				if not k.is_empty():
					sig += "|%s:%s" % [other, ",".join(PackedStringArray(k))]
	if sig == _rel_sig and relation_box.get_child_count() > 0:
		return
	_rel_sig = sig
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
func _on_relation_box_input(event: InputEvent) -> void:
	if busy:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
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


var _rel_gen := 0   # 관계도 목록을 새로 만들 때마다 +1 (나눠 만들던 이전 작업 멈춤)


func _fill_relations() -> void:
	_rel_gen += 1
	_rel_sig = ""   # 관계가 바뀌었을 수 있으니 옆 목록도 다음에 다시
	for c in rel_list.get_children():
		rel_list.remove_child(c)
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
	# 한 번에 다 만들면 멈칫 → 처음 8장만 바로, 나머지는 한 프레임에 6장씩
	var gen := _rel_gen
	for i in others.size():
		if i >= 8 and i % 6 == 2:
			await get_tree().process_frame
			if gen != _rel_gen or puppy == null or puppy.dog_id != me:
				return
		var card := _relation_card(me, others[i])
		card.set_meta("other", others[i])
		rel_list.add_child(card)


## 카드 하나만 새로 (놀기·선물 뒤에 목록 전체를 다시 만들지 않게). 순서는 그대로
func _refresh_rel_card(other: String) -> void:
	if puppy == null:
		return
	_rel_sig = ""
	for c in rel_list.get_children():
		if c.has_meta("other") and str(c.get_meta("other")) == other:
			var i: int = c.get_index()
			var card := _relation_card(puppy.dog_id, other)
			card.set_meta("other", other)
			rel_list.add_child(card)
			rel_list.move_child(card, i)
			rel_list.remove_child(c)
			c.queue_free()
			return
	_fill_relations()


func _rel_rank(me: String, other: String) -> int:
	if GameData.is_rival(me, other) or GameState.is_sulky(me, other):
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
		if kind == "clover":
			var c := TextureRect.new()
			c.texture = FoodIcon.item_texture("item_clover")
			c.custom_minimum_size = Vector2(32, 32)
			c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			c.mouse_filter = MOUSE_FILTER_IGNORE
			if i >= filled:
				c.modulate = Color(0.55, 0.55, 0.55, 0.35)
			row.add_child(c)
		elif kind == "peach":
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
	var sulking: bool = GameState.is_sulky(me, other)
	face.texture = _dog_tex(other, PuppyView.STAGE_FORM[GameState.stage_of(other)],
		"line" if sulking and GameState.sulker(me, other) == other else "open")   # 토라진 애는 찡그린 얼굴
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
	if sulking:
		name_row.add_child(_tag("토라짐", CLOVER_COL))
	var sub := _label("%s 진영 · %s" % [GameData.FACTIONS[GameData.faction_of(other)]["name"], GameData.stage_name(GameState.stage_of(other), other)], 18)
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
		# 둘 다 어른이면 클로버 3개로 화해할 수 있음
		if GameState.get_puppy(me).is_adult() and GameState.get_puppy(other).is_adult():
			info.add_child(_meter("clover", GameState.clover_count(me, other), GameData.MAKEUP_CLOVERS))
			actions.add_child(_clover_button(me, other))
		else:
			var hint := _label("둘 다 어른이 되면 클로버로 화해할 수 있어요", 16)
			hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			hint.add_theme_color_override("font_color", SUB_COLOR)
			info.add_child(hint)
		return row

	# 토라진 사이: 놀기·선물 대신 클로버로 달래기
	if sulking:
		var who: String = GameState.sulker(me, other)
		var l := _label("%s %s%s 토라졌어요.." % [GameData.DOGS[who]["name"], GameData.species(who), "가"], 20)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.add_theme_color_override("font_color", SUB_COLOR)
		info.add_child(l)
		info.add_child(_meter("clover", GameState.clover_count(me, other), GameData.MAKEUP_CLOVERS))
		actions.add_child(_clover_button(me, other))
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
			actions.add_child(_small_button("고백하기", _on_confess.bind(other), _confess_block_reason(me, other), PINK))
	if not bonded:
		if GameState.gift_count(me, other) < gift_max:
			var no_peach := "복숭아가 없어요" if GameState.peach_total() <= 0 else ""
			actions.add_child(_small_button("선물하기", _on_gift.bind(other), no_peach, Color(0.95, 0.6, 0.62)))
		else:
			actions.add_child(_small_button("의형제 맺기", _on_swear.bind(other), _swear_block_reason(me, other), Color(0.92, 0.5, 0.6)))
	if couple:
		actions.add_child(_small_button("헤어지기", _on_breakup.bind(other), "", Color(0.6, 0.58, 0.62)))
	return row


## 초록 클로버 선물 버튼 (토라진 애 달래기 / 앙숙 화해)
func _clover_button(me: String, other: String) -> Control:
	var no_clover := "클로버가 없어요" if GameState.item_count("clover") <= 0 else ""
	return _small_button("클로버 선물", _on_clover.bind(other), no_clover, CLOVER_COL,
		"화해까지 %d/%d" % [GameState.clover_count(me, other), GameData.MAKEUP_CLOVERS])


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
	if GameData.is_lord(me) and GameData.is_lord(other):
		return "주군끼리는 고백 안 돼요"
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
	_refresh_rel_card(other)
	if gained:
		_story_check()


func _on_gift(other: String) -> void:
	var me := puppy.dog_id
	if not GameState.give_peach(me, other):
		return
	var me_name: String = GameData.DOGS[me]["name"]
	var other_name: String = GameData.DOGS[other]["name"]
	var n: int = GameState.gift_count(me, other)
	rel_msg.text = "%s%s %s에게 %s를 선물했어요! (%d/%d)%s" % [me_name, _ig(me_name), other_name, GameData.ITEMS[GameState.last_gift]["name"], n, GameData.gift_max(me, other),
		"\n의형제를 맺을 수 있어요!" if n >= GameData.gift_max(me, other) else ""]
	_log("선물: %s -> %s (%d)" % [me, other, n])
	if GameState.peach_total() <= 0:
		_fill_relations()   # 복숭아가 다 떨어지면 다른 카드 버튼도 바뀜
	else:
		_refresh_rel_card(other)


## 창 가운데 그림을 그 멍냥이 얼굴로 (eyes: open / squint / line / closed / half)
func _overlay_face(dog_id: String, eyes: String, angry := false) -> void:
	overlay_image.texture = _centered_tex(_dog_tex(dog_id, PuppyView.STAGE_FORM[GameState.stage_of(dog_id)], eyes))
	overlay_image.show()
	_anger_mark.visible = angry
	_anger_mark.queue_redraw()


## 두 마리 같이 (sad = 감은 눈 + 눈물 ㅠㅠ)
func _overlay_pair(a: String, b: String, eyes: String, sad := false) -> void:
	_overlay_face(a, eyes)
	overlay_image2.texture = _centered_tex(_dog_tex(b, PuppyView.STAGE_FORM[GameState.stage_of(b)], eyes))
	overlay_image2.show()
	for t in _tear_marks:
		t.visible = sad
		t.queue_redraw()


## ── 반짝반짝 빛 (이야기 속 아이템) ──
var _glow: Control
var _glow_a := 0.0
var _glow_tw: Tween


func _start_glow() -> void:
	_stop_glow()
	_glow.show()
	overlay_image.pivot_offset = overlay_image.custom_minimum_size / 2
	_glow_tw = create_tween().set_loops()
	_glow_tw.set_parallel(true)
	_glow_tw.tween_method(func(a: float) -> void:
		_glow_a = a
		_glow.queue_redraw(), 0.0, TAU / 6.0, 1.6)
	_glow_tw.tween_property(overlay_image, "scale", Vector2(1.06, 1.06), 0.8).set_trans(Tween.TRANS_SINE)
	_glow_tw.tween_property(overlay_image, "modulate", Color(1.25, 1.2, 1.0), 0.8).set_trans(Tween.TRANS_SINE)
	_glow_tw.chain().tween_property(overlay_image, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_SINE)
	_glow_tw.parallel().tween_property(overlay_image, "modulate", Color.WHITE, 0.8).set_trans(Tween.TRANS_SINE)


func _stop_glow() -> void:
	if _glow_tw:
		_glow_tw.kill()
		_glow_tw = null
	if _glow:
		_glow.hide()
	if overlay_image:
		overlay_image.modulate = Color.WHITE


func _draw_glow() -> void:
	var c := _glow.size / 2
	var r := minf(_glow.size.x, _glow.size.y)
	for k in 3:   # 부드러운 둥근 빛
		_glow.draw_circle(c, r * (0.5 - k * 0.1), Color(1.0, 0.92, 0.5, 0.16))
	for i in 12:  # 빙글빙글 도는 빛줄기
		var a := _glow_a + i * TAU / 12
		var w := 0.09
		var tip := r * (0.78 if i % 2 == 0 else 0.62)
		var pts := PackedVector2Array([c, c + Vector2.from_angle(a - w) * tip, c + Vector2.from_angle(a + w) * tip])
		_glow.draw_colored_polygon(pts, Color(1.0, 0.88, 0.4, 0.42))


## ㅠㅠ 눈물 두 줄기 (눈 아래 파란 물방울)
func _draw_tears(c: Control) -> void:
	# 그림이 실제로 그려진 자리 기준 (가운데 맞춤으로 오른쪽을 잘라낸 그림도 맞게)
	var img := c.get_parent() as TextureRect
	var tsz := Vector2(48, 48)
	if img and img.texture:
		tsz = img.texture.get_size()
	var k := minf(c.size.x / tsz.x, c.size.y / tsz.y)
	var o := (c.size - tsz * k) / 2.0
	var u := tsz.y / 48.0 * k          # 48칸 격자 한 칸 크기
	var col := Color(0.42, 0.7, 0.96, 0.95)
	for ex in [14.3, 29.7]:
		var top := o + Vector2(ex, 27.2) * u
		var r := u * 1.05
		for j in 3:   # 위에서 아래로 흐르는 물방울
			c.draw_circle(top + Vector2(0, j * r * 1.7), r * (0.7 + 0.15 * j), col)


## 실패했을 때 얼굴: ㅡ.ㅡ 아니면 잠자는 얼굴 (랜덤)
func _overlay_sad_face(dog_id: String) -> void:
	_overlay_face(dog_id, ["line", "closed"].pick_random())


## 💢 그리기 (사진 모드와 같은 모양)
func _draw_anger(ci: CanvasItem, c: Vector2, rr: float) -> void:
	var col := Color(0.93, 0.18, 0.24)
	var w := maxf(3.0, rr * 0.28)
	for q in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
		var p0: Vector2 = c + Vector2(q.x * 0.3, q.y) * rr
		var p2: Vector2 = c + Vector2(q.x, q.y * 0.3) * rr
		var k: Vector2 = c + q * 0.3 * rr
		var pts := PackedVector2Array()
		for j in 13:
			var t := j / 12.0
			pts.append(p0 * (1 - t) * (1 - t) + k * 2.0 * (1 - t) * t + p2 * t * t)
		ci.draw_polyline(pts, col, w, true)
		ci.draw_circle(p0, w * 0.5, col)
		ci.draw_circle(p2, w * 0.5, col)


# ── 이야기 장면 (진영 이동 이벤트) ──
## 한 장 = {"text", "btn", "cast": [[그림 id, 눈, 표시("", "tears", "anger")], ...]} (1~3마리)
var _story: Array = []
var _story_title := ""
var _story_done: Callable


func _play_story(title: String, pages: Array, on_done: Callable) -> void:
	_story = pages.duplicate()
	_story_title = title
	_story_done = on_done
	rel_overlay.hide()
	_story_next()


func _story_next() -> void:
	if _story.is_empty():
		var cb := _story_done
		_story_done = Callable()
		if cb.is_valid():
			cb.call()
		return
	var pg: Dictionary = _story.pop_front()
	_open_overlay(str(pg.get("reveal", _story_title)), pg["text"], "story")
	_overlay_cast(pg["cast"])
	if pg.has("item"):   # 아이템 한 개가 빛나는 장면 (두루마리)
		overlay_image.texture = FoodIcon.item_texture(pg["item"])
		overlay_image.custom_minimum_size = Vector2(180, 180)
		overlay_image.material = null
		overlay_image.show()
		_start_glow()
	confirm_button.text = pg["btn"]
	confirm_button.show()
	if pg.get("party", false):
		celebration.play("", "", get_viewport_rect().size / 2 - celebration.global_position)


## 창 가운데 그림 1~3마리 + 표정 + 표시
func _overlay_cast(cast: Array) -> void:
	var imgs := [overlay_image, overlay_image2, overlay_image3]
	var side := 180.0   # 1~3마리 모두 같은 크기 → 창 크기가 장마다 안 바뀜
	for i in 3:
		var img: TextureRect = imgs[i]
		img.visible = i < cast.size()
		_tear_marks[i].hide()
		_anger_marks[i].hide()
		if i >= cast.size():
			continue
		var c: Array = cast[i]
		var id: String = c[0]
		var base: String = id.trim_suffix("_jin").trim_suffix("_shu")
		var form := 2
		if GameData.DOGS.has(id) and GameState.owns(id):
			form = PuppyView.STAGE_FORM[GameState.stage_of(id)]
		img.custom_minimum_size = Vector2(side, side)
		img.texture = _dog_tex(id, form, c[1]) if GameData.DOGS.has(id) or base != id else null
		var mark: String = c[2] if c.size() > 2 else ""
		img.material = _silhouette_mat() if mark == "sil" else null   # 스포 방지: 회색 그림자
		_tear_marks[i].visible = mark == "tears"
		_anger_marks[i].visible = mark == "anger"
		_tear_marks[i].queue_redraw()
		_anger_marks[i].queue_redraw()


## 멍냥이 이야기 목록 (도감에서 다시 보기). 새 이야기는 여기와 _story_book() 에 추가
const STORY_IDS: Array[String] = ["xiahou_ba", "sima_yi", "liu_bang"]


## 이야기 내용: {"title", "pages"}
func _story_book(id: String) -> Dictionary:
	match id:
		"xiahou_ba":
			return {"title": "하후패 강아지 이야기", "pages": [
				{"text": "사마의 고양이가 위나라에서 큰 소동을 일으켰어요.\n하후패 강아지는 무서웠어요.", "btn": "걱정마",
					"cast": [["sima_yi", "line", "anger"], ["xiahou_ba", "closed", "tears"]]},
				{"text": "그때 장비 강아지와 유선 강아지가\n하후패 강아지를 안아줬어요!", "btn": "다행이야!!",
					"cast": [["zhang_fei", "squint"], ["xiahou_ba", "squint"], ["liu_shan", "squint"]]},
				{"text": "하후패 강아지는 촉으로 진영을 옮기기로 했어요!", "btn": "잘 됐다!",
					"cast": [["xiahou_ba_shu", "squint"]], "party": true},
			]}
		"sima_yi":
			return {"title": "사마의 고양이 이야기", "pages": [
				{"text": "사마의 고양이에게 조조 강아지가 찾아왔어요.", "btn": "무슨 일이야?",
					"cast": [["cao_cao", "open"], ["sima_yi", "open"]]},
				{"text": "\"목이랑 몸이 이상해!\n너, 사실은 늑대 아니야?\"", "btn": "아니야!",
					"cast": [["cao_cao", "line", "anger"], ["sima_yi", "half"]]},
				{"text": "\"고양이인 척 해 봤자 소용없어!\"", "btn": "뭐?!",
					"cast": [["cao_cao", "line", "anger"], ["sima_yi", "closed", "tears"]]},
				{"text": "사마의 고양이는 큰 결심을 했어요.", "btn": "뭔데?",
					"cast": [["sima_yi", "line"]]},
				{"text": "바로... 자신의 나라를 만들기로!", "btn": "대단해!",
					"cast": [["sima_yi_jin", "squint"]]},
				{"text": "사마의 고양이의 새 진영, 진이 생겼어요!\n이제 새로운 진나라의 멍냥이들을 만날 수 있어요!", "btn": "확인",
					"cast": [["sima_yi_jin", "squint"]], "party": true},
			]}
		"liu_bang":   # 진까지 다 모으면: 서고의 두루마리가 빛나며 초한지 멍냥이들이 나타남
			return {"title": "낡은 두루마리 이야기", "pages": [
				{"text": "모든 멍냥이를 다 모았어요!", "btn": "우와!",
					"cast": [["liu_bei", "squint"], ["cao_cao", "squint"], ["sun_quan", "squint"]]},
				{"text": "어라..?", "btn": "무슨 일이야?",
					"cast": [["liu_bei", "open"], ["cao_cao", "open"], ["sun_quan", "open"]]},
				{"text": "서고 속 오래된 두루마리가\n빛나기 시작했어요!", "btn": "이 빛은..?!",
					"cast": [], "item": "item_scroll"},
				{"text": "축하해요!\n400년 전 역사 속 멍냥이들이 해금되었어요!\n뽑기에서 새로운 멍냥이들을 만날 수 있어요!", "btn": "신난다!",
					"cast": [["liu_bang", "squint", "sil"], ["xiang_yu", "squint", "sil"]], "party": true},
			]}
	return {}




# ═════════════════════════ 도감: 기록 모아 보기 ═════════════════════════
## tab: rank(칭호) / special(스페셜 칭호) / group(단체 칭호) / story(이야기)
const REC_TABS := [["rank", "칭호"], ["special", "스페셜"], ["group", "단체"], ["story", "이야기"]]
const STORY_HINTS := {
	"xiahou_ba": "하후패를 어른까지 키우기",
	"sima_yi": "사마의를 어른으로 키우고 친밀도 50",
	"liu_bang": "진나라까지 모든 멍냥이 모으기",
}
var _rec_tab := "rank"


func _show_records(tab: String) -> void:
	_rec_tab = tab
	_log("기록 화면: " + tab)
	var v := _new_page()
	_page_header(v, "← 도감", _show_dex, "칭호 · 이야기")
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	v.add_child(tabs)
	for t in REC_TABS:
		var b := _button(t[1], _show_records.bind(t[0]))
		b.custom_minimum_size = Vector2(0, 76)
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", _fs(24))
		if t[0] == tab:   # 고른 탭 = 노란 단색
			b.add_theme_stylebox_override("normal", _box(YELLOW, 18))
			b.add_theme_stylebox_override("hover", _box(YELLOW.lightened(0.08), 18))
			b.add_theme_stylebox_override("pressed", _box(YELLOW.darkened(0.1), 18))
		else:             # 나머지 = 노란 테두리
			_yellow_outline(b)
		tabs.add_child(b)
	var head := VBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	v.add_child(head)
	# 목록: 오른쪽에 잡기 쉬운 스크롤 막대 (막대 자리만큼 비워서 카드와 안 겹치게)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_fat_scrollbar(scroll)
	v.add_child(scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_right", int(REL_BAR_W) + 10)
	scroll.add_child(pad)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	pad.add_child(list)
	_drag_scroll(scroll, pad)
	match tab:
		"rank":
			_rec_ranks(head, list)
		"special":
			_rec_specials(head, list)
		"group":
			_rec_groups(head, list)
		"story":
			_rec_stories(head, list)


const YELLOW := Color(0.94, 0.7, 0.16)


## 노란 테두리 버튼 (누르면 노란 단색)
func _yellow_outline(b: Button) -> void:
	b.add_theme_stylebox_override("normal", _card_box(Color(1, 0.98, 0.92), YELLOW, 4))
	b.add_theme_stylebox_override("hover", _card_box(Color(1, 0.96, 0.86), YELLOW, 4))
	b.add_theme_stylebox_override("pressed", _box(YELLOW, 18))
	for key in ["font_color", "font_hover_color", "font_focus_color"]:
		b.add_theme_color_override(key, YELLOW.darkened(0.35))
	b.add_theme_color_override("font_pressed_color", Color.WHITE)


## 작은 얼굴 (안 데려온 애는 검은 그림자)
func _rec_face(id: String, side: float, dim := false) -> TextureRect:
	var t := TextureRect.new()
	var owned := GameState.owns(id)
	var form: int = PuppyView.STAGE_FORM[GameState.stage_of(id)] if owned else 2
	t.texture = _centered_tex(_dog_tex(id, form, "open"))
	t.custom_minimum_size = Vector2(side, side)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = MOUSE_FILTER_IGNORE
	if not owned:
		t.material = _silhouette_mat()   # 회색 단색 그림자
	elif dim:
		t.modulate = Color(0.6, 0.6, 0.6, 0.55)
	return t


## 아직 안 데려온 멍냥이 이름은 ??? 로 가림
func _mask_names(text: String, ids: Array) -> String:
	for i in ids:
		if not GameState.owns(i):
			text = text.replace(str(GameData.DOGS[i]["name"]), "???")
	return text


func _rec_count(head: VBoxContainer, text: String, hint: String) -> void:
	head.add_child(_label(text, 30))
	if hint != "":
		var h := _label(hint, 18)
		h.add_theme_color_override("font_color", SUB_COLOR)
		h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		head.add_child(h)


func _rec_name(id: String) -> String:
	return GameData.DOGS[id]["name"] if GameState.owns(id) else "???"


# ── 칭호: 단계표 + 칭호 받은 멍냥이 (높은 순) ──
func _rec_ranks(head: VBoxContainer, list: VBoxContainer) -> void:
	var ids: Array = []
	for id in GameState.owned:
		if GameState.rank_of(id) > 0:
			ids.append(id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var ea := int(GameState.battle_exp.get(a, 0))
		var eb := int(GameState.battle_exp.get(b, 0))
		return ea > eb if ea != eb else GameData.DOGS[a]["name"] < GameData.DOGS[b]["name"])
	_rec_count(head, "칭호 받은 멍냥이 %d마리" % ids.size(), "대전에서 이길수록 전공이 쌓여 칭호가 올라가요")
	# 단계표
	for pair in [["무장", GameData.WAR_RANKS, "guan_yu"], ["책사", GameData.STRAT_RANKS, "zhuge_liang"]]:
		var row := HFlowContainer.new()
		row.alignment = FlowContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("h_separation", 6)
		row.add_theme_constant_override("v_separation", 6)
		var l := _label(pair[0] + "  ", 20)
		l.add_theme_color_override("font_color", SUB_COLOR)
		row.add_child(l)
		var ranks: Array = pair[1]
		for i in ranks.size():
			if ranks[i] == "황제":
				var e = EmperorTagScript.new()
				e.setup("황제", "gold", _fs(17))
				row.add_child(e)
				continue
			var t = ShinyTagScript.new()
			t.setup(ranks[i], GameData.rank_color(i + 1), "plain", _fs(17))
			row.add_child(t)
		head.add_child(row)
	if ids.is_empty():
		var none := _label("아직 칭호를 받은 멍냥이가 없어요", 22)
		none.add_theme_color_override("font_color", SUB_COLOR)
		list.add_child(none)
		return
	for id in ids:
		var card := _card_row()
		var h: HBoxContainer = card.get_child(0)
		h.add_child(_rec_face(id, 72))
		var col := VBoxContainer.new()   # 위: 이름 + 칭호 / 아래: 전공 막대 + 숫자
		col.size_flags_horizontal = SIZE_EXPAND_FILL
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 4)
		h.add_child(col)
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 10)
		col.add_child(top)
		var name_l := _label(GameData.DOGS[id]["name"], 26)
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		top.add_child(name_l)
		var rt := _rank_tag(id, 18)
		if rt:
			top.add_child(rt)
		var rp: Dictionary = GameState.rank_progress(id)
		var lv := int(rp["lv"])
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 14)
		bar.size_flags_horizontal = SIZE_EXPAND_FILL
		bar.mouse_filter = MOUSE_FILTER_IGNORE
		bar.add_theme_stylebox_override("background", _box(_bar_bg(GameData.rank_bar_color(id, lv), lv), 7))
		bar.add_theme_stylebox_override("fill", _box(GameData.rank_bar_color(id, lv).darkened(0.05), 7))
		var num: Label
		if int(rp["next"]) < 0:
			bar.max_value = 1
			bar.value = 1
			num = _label("최고 칭호! (전공 %d)" % rp["exp"], 16)
		else:
			bar.max_value = int(rp["next"]) - int(rp["prev"])
			bar.value = int(rp["exp"]) - int(rp["prev"])
			num = _label("%d / %d" % [int(rp["exp"]) - int(rp["prev"]), int(rp["next"]) - int(rp["prev"])], 16)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		num.add_theme_color_override("font_color", SUB_COLOR)
		col.add_child(bar)
		col.add_child(num)
		list.add_child(card)


# ── 스페셜 칭호: 받은 것만 (받기 전엔 누구랑인지도 비밀) ──
func _rec_specials(head: VBoxContainer, list: VBoxContainer) -> void:
	var done: Array = []
	var total := 0
	for sp in GameData.SPECIAL_TITLES:
		if not (GameData.available(sp["a"]) and GameData.available(sp["b"])):
			continue
		total += 1
		if GameState.pair_win_count(sp["a"], sp["b"]) >= int(sp["wins"]):
			done.append(sp)
	_rec_count(head, "스페셜 칭호 %d / %d" % [done.size(), total],
		"대전에서 불꽃 표시가 뜨는 짝꿍과 %d번 이기면 받아요" % int(GameData.SPECIAL_TITLES[0]["wins"]))
	if done.is_empty():
		var none := _label("아직 받은 스페셜 칭호가 없어요.\n대전에서 멍냥이를 고를 때\n불꽃이 뜨는 짝꿍을 찾아봐요!", 24)
		none.add_theme_color_override("font_color", SUB_COLOR)
		list.add_child(none)
		return
	for sp in done:
		var fc := _special_colors(sp["name"])   # 칭호 색 그대로 액자 테두리
		var card = FramePanelScript.new()
		card.setup(fc[0], fc[1], 18)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 12)
		card.add_child(col)
		var top := CenterContainer.new()
		top.add_child(_special_tag(sp["name"], 36))
		col.add_child(top)
		var mem := HBoxContainer.new()
		mem.alignment = BoxContainer.ALIGNMENT_CENTER
		mem.add_theme_constant_override("separation", 40)
		for m in [sp["a"], sp["b"]]:
			var mv := VBoxContainer.new()
			mv.add_theme_constant_override("separation", 0)
			mv.add_child(_rec_face(m, 180))
			mv.add_child(_label(GameData.DOGS[m]["name"], 30))
			mem.add_child(mv)
		col.add_child(mem)
		list.add_child(card)


# ── 단체 칭호 ──
func _rec_groups(head: VBoxContainer, list: VBoxContainer) -> void:
	var gs: Array = []
	for g in GameData.GROUP_TITLES:
		var ok := true
		for m in g["members"]:
			if not GameData.available(m):
				ok = false
		if ok:
			gs.append(g)
	var n := 0
	for g in gs:
		if GameState.group_done(g):
			n += 1
	_rec_count(head, "단체 칭호 %d / %d" % [n, gs.size()], "멤버를 모두 데려와서 모두 칭호 3단계(교위·참군) 이상이면 받아요")
	for g in gs:
		var got := GameState.group_done(g)
		var card: PanelContainer
		if got:   # 받은 단체 칭호: 칭호 색 그라데이션 액자 프레임
			var gc := _group_colors(g["name"])
			var fp = FramePanelScript.new()
			fp.setup(gc[0], gc[1], 14)
			card = fp
		else:
			card = PanelContainer.new()
			var sb := _box(Color(0.97, 0.93, 0.86), 18)
			sb.set_content_margin_all(20)
			card.add_theme_stylebox_override("panel", sb)
			card.mouse_filter = MOUSE_FILTER_PASS
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 12)
		card.add_child(col)
		var top := HBoxContainer.new()
		top.alignment = BoxContainer.ALIGNMENT_CENTER
		top.add_theme_constant_override("separation", 10)
		if got:
			top.add_child(_group_tag(g["name"], 32))
		else:
			top.add_child(_label(g["name"], 32))
		var cnt := _label("%d / %d" % [GameState.group_count(g), (g["members"] as Array).size()], 26)
		cnt.add_theme_color_override("font_color", Color(0.3, 0.6, 0.36) if got else SUB_COLOR)
		top.add_child(cnt)
		col.add_child(top)
		var mem := HBoxContainer.new()
		mem.alignment = BoxContainer.ALIGNMENT_CENTER
		mem.add_theme_constant_override("separation", 10)
		for m in g["members"]:
			var mv := VBoxContainer.new()
			mv.add_theme_constant_override("separation", 0)
			var reached: bool = GameState.owns(m) and GameState.rank_of(m) >= GameData.GROUP_RANK
			mv.add_child(_rec_face(m, 104 if (g["members"] as Array).size() <= 4 else 96, not reached))
			var ml := _label(_rec_name(m), 22)
			ml.add_theme_color_override("font_color", TEXT_COLOR if reached else SUB_COLOR)
			mv.add_child(ml)
			mem.add_child(mv)
		col.add_child(mem)
		list.add_child(card)


# ── 이야기: 진영 이야기 + 스페셜 이야기 ──
func _rec_stories(head: VBoxContainer, list: VBoxContainer) -> void:
	var all: Array = []
	for id in STORY_IDS:
		if id != GameData.CHOHAN_STORY or GameData.jin_open():
			all.append(id)
	all += _sp_list()
	var n := 0
	for id in all:
		if _story_seen(id):
			n += 1
	_rec_count(head, "본 이야기 %d / %d" % [n, all.size()], "본 이야기는 언제든 다시 볼 수 있어요")
	for id in all:
		var sp: bool = str(id).begins_with("sp_")
		var title: String
		var faces: Array
		var hint: String
		if sp:
			var b := _sp_book(id)
			title = b["title"]
			faces = b["faces"]
			hint = "%s · 공훈패 %d" % [_mask_names(str(b["cond"]), b["faces"]), GameData.SPECIAL_STORY_COST]
		else:
			title = _story_book(id)["title"]
			faces = [id] if id != GameData.CHOHAN_STORY else ["liu_bang", "xiang_yu"]
			hint = _mask_names(str(STORY_HINTS.get(id, "")), faces)
		var seen := _story_seen(id)
		var card := _card_row()
		var h: HBoxContainer = card.get_child(0)
		var fbox := HBoxContainer.new()
		fbox.add_theme_constant_override("separation", -22)
		for f in faces:
			fbox.add_child(_rec_face(f, 104 if faces.size() <= 2 else 86, not seen))
		h.add_child(fbox)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = SIZE_EXPAND_FILL
		info.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_child(info)
		var tl := _label(title if seen else "???", 32)
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		if not seen:
			tl.add_theme_color_override("font_color", SUB_COLOR)
		info.add_child(tl)
		var hl := _label(("스페셜 이야기 · " if sp else "진영 이야기 · ") + hint, 21)
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hl.add_theme_color_override("font_color", SUB_COLOR)
		info.add_child(hl)
		if seen:
			h.add_child(_big_small(_small_button("다시 보기", _rec_replay.bind(id), "", Color(0.55, 0.45, 0.72))))
		elif sp:
			h.add_child(_big_small(_small_button("열러 가기", _show_sp_stories, "", Color(0.86, 0.6, 0.2))))
		list.add_child(card)


## _small_button 을 크게 (이야기 탭용)
func _big_small(box: Control) -> Control:
	var b := box.get_child(0) as Button
	b.custom_minimum_size = Vector2(170, 84)
	b.add_theme_font_size_override("font_size", _fs(28))
	return box


func _rec_replay(id: String) -> void:
	var book := _sp_book(id) if id.begins_with("sp_") else _story_book(id)
	if book.is_empty():
		return
	_play_story(book["title"], book["pages"], func() -> void:
		_set_busy(false)
		_show_records("story"))

# ═════════════════════════ 스페셜 이야기 ═════════════════════════
## 조건을 채우고 공훈패(대전에서 받음)를 내면 열리는 짧은 이야기. 한 번 열면 다시 보기 무료
const SP_FIRST: Array[String] = ["sp_taoyuan", "sp_changban", "sp_guagu", "sp_kongcheng", "sp_fengyi", "sp_wancheng", "sp_chengdu"]
var SP_STORIES: Array[String] = []   # 위 7개 + story_data.gd 의 이야기들 (처음 쓸 때 채움)


## 지금 열린 진영 멍냥이만 나오는 이야기만 (진·한·초 열리기 전엔 숨김)
func _sp_list() -> Array[String]:
	if SP_STORIES.is_empty():
		SP_STORIES.append_array(SP_FIRST)
		SP_STORIES.append_array(StoryData.ORDER)
	var out: Array[String] = []
	for id in SP_STORIES:
		var ok := true
		for f in _sp_book(id).get("faces", []):
			if not GameData.available(f):
				ok = false
		if ok:
			out.append(id)
	return out


func _sp_book(id: String) -> Dictionary:
	match id:
		"sp_taoyuan":
			return {"title": "복숭아 동산의 약속", "faces": ["liu_bei", "guan_yu", "zhang_fei"],
				"cond": "유비·관우·장비가 서로 모두 의형제", "pages": [
				{"text": "탁현의 복숭아 동산에 유비 강아지, 관우 강아지,\n장비 강아지가 모였어요.", "btn": "무슨 일이야?",
					"cast": [["liu_bei", "open"], ["guan_yu", "half"], ["zhang_fei", "open"]]},
				{"text": "\"우리 셋, 오늘부터 형제 하자!\"\n장비 강아지가 꼬리를 붕붕 흔들었어요.", "btn": "좋아!",
					"cast": [["zhang_fei", "squint"], ["liu_bei", "open"], ["guan_yu", "half"]]},
				{"text": "그런데... 누가 형님이지?\n셋은 서로 눈치를 봤어요.", "btn": "누굴까?",
					"cast": [["liu_bei", "line"], ["guan_yu", "line"], ["zhang_fei", "line"]]},
				{"text": "결국 제일 먼저 복숭아를 다 먹은\n유비 강아지가 큰형님이 되었어요!", "btn": "냠냠!",
					"cast": [["liu_bei", "squint"], ["guan_yu", "closed", "tears"], ["zhang_fei", "closed", "tears"]]},
				{"text": "세 강아지는 영원히 함께하기로 약속했어요!", "btn": "멋져!",
					"cast": [["liu_bei", "squint"], ["guan_yu", "squint"], ["zhang_fei", "squint"]], "party": true},
			]}
		"sp_changban":
			return {"title": "장판파의 아기", "faces": ["zhao_yun", "liu_shan"],
				"cond": "조운·유선 하트 가득", "pages": [
				{"text": "장판파에서 아기 유선 강아지가 길을 잃었어요!", "btn": "큰일이다!",
					"cast": [["liu_shan", "closed", "tears"]]},
				{"text": "그때 조운 강아지가 번개처럼 달려왔어요!", "btn": "빨리빨리!",
					"cast": [["zhao_yun", "open"]]},
				{"text": "조운 강아지는 유선 강아지를 품에 꼭 안고 달렸어요.", "btn": "영차영차!",
					"cast": [["zhao_yun", "line"], ["liu_shan", "open"]]},
				{"text": "유선 강아지는 품 안에서 쿨쿨 잠들어 버렸어요.", "btn": "귀여워..",
					"cast": [["zhao_yun", "squint"], ["liu_shan", "closed"]]},
				{"text": "무사히 유비 강아지 품으로 돌아왔어요!", "btn": "다행이다!",
					"cast": [["liu_bei", "squint"], ["zhao_yun", "squint"], ["liu_shan", "squint"]], "party": true},
			]}
		"sp_guagu":
			return {"title": "바둑 두는 관우", "faces": ["guan_yu", "hua_tuo"],
				"cond": "관우·화타 둘 다 어른", "pages": [
				{"text": "관우 강아지가 팔에 화살을 맞았어요.", "btn": "아야!",
					"cast": [["guan_yu", "closed", "tears"]]},
				{"text": "화타 고양이가 달려왔어요.\n\"뼈까지 싹싹 긁어야 해요!\"", "btn": "으악!",
					"cast": [["hua_tuo", "open"], ["guan_yu", "half"]]},
				{"text": "관우 강아지는 바둑을 두며 꾹 참았어요.", "btn": "대단해..",
					"cast": [["guan_yu", "line"], ["hua_tuo", "line"]]},
				{"text": "사실... 발가락이 꼼지락꼼지락 떨리고 있었어요.", "btn": "큭큭큭!",
					"cast": [["guan_yu", "line", "tears"], ["hua_tuo", "squint"]]},
				{"text": "치료 끝! 관우 강아지는 씩씩하게 다 나았어요!", "btn": "잘했어!",
					"cast": [["guan_yu", "squint"], ["hua_tuo", "squint"]], "party": true},
			]}
		"sp_kongcheng":
			return {"title": "텅 빈 성", "faces": ["zhuge_liang", "sima_yi"],
				"cond": "제갈량·사마의 둘 다 어른", "pages": [
				{"text": "사마의 고양이가 서성에 쳐들어왔어요!", "btn": "어떡해!",
					"cast": [["sima_yi", "open"]]},
				{"text": "그런데 성문이 활짝 열려 있고,\n제갈량 고양이가 거문고를 타고 있었어요.", "btn": "띵가띵가~",
					"cast": [["zhuge_liang", "squint"]]},
				{"text": "\"수상해... 분명 함정이야!\"\n사마의 고양이는 꼬리를 바짝 세웠어요.", "btn": "의심 많아!",
					"cast": [["sima_yi", "line"], ["zhuge_liang", "squint"]]},
				{"text": "사마의 고양이는 후다닥 도망쳤어요.\n사실 성은 텅텅 비어 있었답니다!", "btn": "휴우~",
					"cast": [["zhuge_liang", "closed", "tears"]], "party": true},
			]}
		"sp_fengyi":
			return {"title": "봉의정의 약속", "faces": ["lu_bu", "diao_chan"],
				"cond": "여포·초선 커플", "pages": [
				{"text": "여포 강아지는 초선 고양이를 무척 좋아했어요.", "btn": "알콩달콩",
					"cast": [["lu_bu", "squint"], ["diao_chan", "squint"]]},
				{"text": "그런데 동탁 강아지가\n초선 고양이를 데려가 버렸어요!", "btn": "뭐?!",
					"cast": [["dong_zhuo", "open"], ["diao_chan", "closed", "tears"]]},
				{"text": "여포 강아지는 화가 잔뜩 났어요.", "btn": "화났다!",
					"cast": [["lu_bu", "line", "anger"]]},
				{"text": "여포 강아지가 동탁 강아지를 혼내 주고,\n초선 고양이를 되찾았어요!", "btn": "멋져!",
					"cast": [["lu_bu", "squint"], ["diao_chan", "squint"]], "party": true},
			]}
		"sp_wancheng":
			return {"title": "완성의 밤", "faces": ["cao_cao", "dian_wei"],
				"cond": "조조·전위 의형제", "pages": [
				{"text": "깜깜한 밤, 적군이 조조 강아지를 노리고 몰려왔어요!", "btn": "위험해!",
					"cast": [["cao_cao", "closed", "tears"]]},
				{"text": "\"주공은 내가 지킨다!\"\n전위 강아지가 문 앞을 딱 막아섰어요.", "btn": "든든해!",
					"cast": [["dian_wei", "line"]]},
				{"text": "적군이 아무리 밀어도\n전위 강아지는 꿈쩍도 안 했어요.", "btn": "끄떡없어!",
					"cast": [["dian_wei", "line"], ["cao_cao", "open"]]},
				{"text": "아침이 되자 조조 강아지가\n전위 강아지를 꼬옥 안아 줬어요.", "btn": "고마워!",
					"cast": [["cao_cao", "squint", "tears"], ["dian_wei", "squint"]], "party": true},
			]}
		"sp_chengdu":
			return {"title": "누가 먼저 성도에?", "faces": ["deng_ai", "zhong_hui"],
				"cond": "진나라가 열리고 등애·종회 둘 다 어른", "pages": [
				{"text": "등애 강아지와 종회 고양이가 촉으로 출발했어요.", "btn": "출발!",
					"cast": [["deng_ai", "open"], ["zhong_hui", "open"]]},
				{"text": "\"내가 먼저 도착할 거야!\"\n둘은 서로 쌩쌩 달렸어요.", "btn": "경주다!",
					"cast": [["deng_ai", "line"], ["zhong_hui", "line", "anger"]]},
				{"text": "등애 강아지는 음평의 산길을\n데굴데굴 굴러 내려갔어요!", "btn": "데굴데굴~",
					"cast": [["deng_ai", "closed"]]},
				{"text": "1등은 등애 강아지!\n종회 고양이는 뾰로통해졌어요.", "btn": "아쉽다!",
					"cast": [["deng_ai", "squint"], ["zhong_hui", "line", "anger"]], "party": true},
			]}
	if StoryData.BOOKS.has(id):   # 새 이야기들: 주인공 모두 어른이면 열림
		var b: Dictionary = StoryData.BOOKS[id]
		var names: Array[String] = []
		for a in b["adult"]:
			names.append(GameData.DOGS[a]["name"])
		return {"title": b["title"], "faces": b["adult"], "cond": "·".join(PackedStringArray(names)) + " 모두 어른", "pages": b["pages"]}
	return {}


func _adult(id: String) -> bool:
	return GameState.owns(id) and GameState.get_puppy(id).is_adult()


## 이 스페셜 이야기 조건을 채웠는지
func _sp_ready(id: String) -> bool:
	match id:
		"sp_taoyuan":
			return GameState.is_sworn("liu_bei", "guan_yu") and GameState.is_sworn("liu_bei", "zhang_fei") \
				and GameState.is_sworn("guan_yu", "zhang_fei")
		"sp_changban":
			return GameState.owns("zhao_yun") and GameState.owns("liu_shan") and (GameState.is_couple("zhao_yun", "liu_shan") \
				or GameState.affinity_of("zhao_yun", "liu_shan") >= GameData.affinity_max("zhao_yun", "liu_shan"))
		"sp_guagu":
			return _adult("guan_yu") and _adult("hua_tuo")
		"sp_kongcheng":
			return _adult("zhuge_liang") and _adult("sima_yi")
		"sp_fengyi":
			return GameState.is_couple("lu_bu", "diao_chan")
		"sp_wancheng":
			return GameState.is_sworn("cao_cao", "dian_wei")
		"sp_chengdu":
			return GameData.jin_open() and _adult("deng_ai") and _adult("zhong_hui")
	if StoryData.BOOKS.has(id):
		for a in StoryData.BOOKS[id]["adult"]:
			if not _adult(a):
				return false
		return true
	return false


## 스페셜 이야기 목록 화면
func _show_sp_stories() -> void:
	_log("스페셜 이야기 화면")
	var v := _new_page()
	_page_header(v, "← 홈", _show_home, "스페셜 이야기")
	var have := HBoxContainer.new()
	have.alignment = BoxContainer.ALIGNMENT_CENTER
	have.add_theme_constant_override("separation", 8)
	v.add_child(have)
	var mi := TextureRect.new()
	mi.texture = FoodIcon.item_texture("item_merit")
	mi.custom_minimum_size = Vector2(56, 56)
	mi.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mi.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	have.add_child(mi)
	have.add_child(_label("공훈패 %d개" % GameState.merits, 30))
	var hint := _label("대전에서 이기면 공훈패를 받아요!", 20)
	hint.add_theme_color_override("font_color", SUB_COLOR)
	v.add_child(hint)
	var list := _scroll_list(v)
	for id in _sp_list():
		list.add_child(_sp_card(id))


func _sp_card(id: String) -> Control:
	var book := _sp_book(id)
	var row := _card_row()
	var h: HBoxContainer = row.get_child(0)
	var faces := HBoxContainer.new()
	faces.add_theme_constant_override("separation", -18)   # 얼굴끼리 살짝 겹치게
	h.add_child(faces)
	var seen := GameState.story_seen(id)
	var ok_ := _sp_ready(id)
	for f in book["faces"]:
		var t := TextureRect.new()
		t.texture = _centered_tex(_dog_tex(f, 2, "squint" if seen else "open"))
		t.custom_minimum_size = Vector2(78, 78)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if not GameState.owns(f):          # 아직 못 뽑은 애: 회색 단색 그림자
			t.material = _silhouette_mat()
		elif not seen and not ok_:         # 데려왔지만 조건 아직: 흐리게
			t.modulate = Color(0.55, 0.55, 0.55, 0.6)
		faces.add_child(t)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(info)
	var title := _label(book["title"] if seen else "???", 28)   # 제목은 끝까지 봐야 알 수 있음
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(title)
	var cond := _label(("★ " if ok_ or seen else "") + _mask_names(str(book["cond"]), book["faces"]), 18)
	cond.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	cond.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cond.add_theme_color_override("font_color", Color(0.3, 0.6, 0.36) if ok_ or seen else SUB_COLOR)
	info.add_child(cond)
	var cost := GameData.SPECIAL_STORY_COST
	if seen:
		h.add_child(_small_button("다시 보기", _open_sp_story.bind(id, false), "", Color(0.55, 0.45, 0.72)))
	elif GameState.sp_paid.has(id):   # 열어 놓고 끝까지 못 본 이야기
		h.add_child(_small_button("이어 보기", _open_sp_story.bind(id, false), "", Color(0.86, 0.6, 0.2)))
	else:
		var block := ""
		if not ok_:
			block = "조건을 채워요"
		elif GameState.merits < cost:
			block = "공훈패가 모자라요"
		h.add_child(_small_button("열기 (공훈패 %d)" % cost, _open_sp_story.bind(id, true), block, Color(0.86, 0.6, 0.2)))
	return row


func _open_sp_story(id: String, pay: bool) -> void:
	if pay:
		if not _sp_ready(id) or GameState.merits < GameData.SPECIAL_STORY_COST or GameState.story_seen(id) \
				or GameState.sp_paid.has(id):
			return
		GameState.merits -= GameData.SPECIAL_STORY_COST
		GameState.sp_paid[id] = true
		GameState.save_now()
	var book := _sp_book(id)
	_play_story(_sp_title_for_play(id, book), _sp_pages_for_play(id, book), func() -> void:
		GameState.mark_story(id)   # 끝까지 봤으니 제목 공개 + 다시 보기
		_set_busy(false)
		_show_sp_stories())


## 처음 볼 때는 제목이 ??? 였다가 마지막 장에서 공개
func _sp_title_for_play(id: String, book: Dictionary) -> String:
	return book["title"] if GameState.story_seen(id) else "???"


func _sp_pages_for_play(id: String, book: Dictionary) -> Array:
	var pages: Array = (book["pages"] as Array).duplicate(true)
	if not GameState.story_seen(id) and not pages.is_empty():
		(pages[-1] as Dictionary)["reveal"] = book["title"]
	return pages

## 이 멍냥이 이야기를 이미 봤는지 (도감 다시 보기 버튼)
func _story_seen(id: String) -> bool:
	return GameState.story_seen(id) or GameState.has_defected(id)


## 진영 이동 이벤트가 열렸으면 시작 (시작했으면 true)
const SIMA_YI_AFFECTION := 50   # 사마의 진 이야기: 어른 + 친밀도 50


func _story_check() -> bool:
	if overlay.visible or busy or _tut_step >= 0 or _btut_step >= 0 or not GameState.tutorial_done:
		return false
	var who := ""
	# 하후패: 어른이 되면 바로 촉으로
	if GameState.owns("xiahou_ba") and GameState.get_puppy("xiahou_ba").is_adult() and not GameState.has_defected("xiahou_ba"):
		who = "xiahou_ba"
	# 사마의: 어른이 된 뒤 친밀도 50 이 되면 진을 세움
	elif GameState.owns("sima_yi") and GameState.get_puppy("sima_yi").is_adult() \
			and not GameState.has_defected("sima_yi") \
			and GameState.get_puppy("sima_yi").affection >= SIMA_YI_AFFECTION:
		who = "sima_yi"
	# 초한지: 진까지 모든 멍냥이를 모으면 → 한·초 열림 (뽑기에 나옴)
	elif GameData.jin_open() and not GameData.chohan_open() and GameState.unowned().is_empty():
		who = GameData.CHOHAN_STORY
	if who == "":
		return false
	if who == GameData.CHOHAN_STORY:
		var book0 := _story_book(who)
		_play_story(book0["title"], book0["pages"], func() -> void:
			GameState.mark_story(who)   # 한·초 열림 → 뽑기에 나옴
			_after_story())
		return true
	var book := _story_book(who)
	_play_story(book["title"], book["pages"], func() -> void:
		GameState.defect(who)
		GameState.mark_story(who)
		_after_story())
	return true


## 도감에서 다시 보기 (효과 없이 이야기만). 끝나면 그 멍냥이 성장 창으로 돌아감
func _replay_story(id: String) -> void:
	var book := _story_book(id)
	if book.is_empty():
		return
	_play_story(book["title"], book["pages"], func() -> void:
		_set_busy(false)
		_show_growth(id))


## 이야기 끝: 화면 새로 그리기 (옷·진영 바뀜) + 다음 이벤트/튜토리얼
func _after_story() -> void:
	_set_busy(false)
	if raise_screen.visible and puppy:
		_show_raise(puppy.dog_id)
	elif page:
		_show_home()
	if not _story_check():
		_btut_check()


## 헤어지기 → 확인창
var _breakup_target := ""


func _on_breakup(other: String) -> void:
	if not GameState.is_couple(puppy.dog_id, other):
		return
	_breakup_target = other
	var nm: String = GameData.DOGS[other]["name"]
	_open_overlay("헤어지기", "정말 헤어질까요?\n%s %s가 슬퍼할 수도 있어요.." % [nm, GameData.species(other)], "breakup_confirm")
	_overlay_face(other, "open")
	var grey := Color(0.6, 0.58, 0.62)
	confirm_button.text = "헤어지기"
	confirm_button.add_theme_stylebox_override("normal", _box(grey, 18))
	confirm_button.add_theme_stylebox_override("hover", _box(grey.lightened(0.1), 18))
	confirm_button.add_theme_stylebox_override("pressed", _box(grey.darkened(0.15), 18))
	confirm_button.show()
	cancel_button.show()


func _do_breakup() -> void:
	var me := puppy.dog_id
	var other := _breakup_target
	_breakup_target = ""
	if other == "" or not GameState.is_couple(me, other):
		return
	GameState.break_up(me, other)
	var nm: String = GameData.DOGS[other]["name"]
	_open_overlay("토라졌어요..", "%s %s가 토라졌어요.\n클로버를 %d개 선물해야 화해할 수 있어요." % [nm, GameData.species(other), GameData.MAKEUP_CLOVERS], "notice")
	_overlay_face(other, "line", true)   # 화난 얼굴 💢
	confirm_button.show()
	_log("헤어짐: %s - %s" % [me, other])
	rel_msg.text = " "
	_fill_relations()
	_update_relations()


## 클로버 선물 (토라진 애 / 앙숙)
func _on_clover(other: String) -> void:
	var me := puppy.dog_id
	var result: String = GameState.give_clover(me, other)
	if result == "":
		return
	var nm: String = GameData.DOGS[other]["name"]
	if result == "gave":
		rel_msg.text = "%s에게 클로버를 선물했어요! (%d/%d)" % [nm, GameState.clover_count(me, other), GameData.MAKEUP_CLOVERS]
	else:
		rel_msg.text = " "
		_open_overlay("화해했어요!", "%s %s와 화해했어요.\n이제 친하게 지내!" % [nm, GameData.species(other)], "notice")
		_overlay_face(other, "squint")
		confirm_button.show()
		_update_relations()
	_log("클로버: %s -> %s (%s)" % [me, other, result])
	if GameState.item_count("clover") <= 0:
		_fill_relations()
	else:
		_refresh_rel_card(other)


func _on_confess(other: String) -> void:
	var me := puppy.dog_id
	if _confess_block_reason(me, other) != "" or GameState.affinity_of(me, other) < GameData.affinity_max(me, other):
		return
	rel_overlay.hide()
	var me_name: String = GameData.DOGS[me]["name"]
	var other_name: String = GameData.DOGS[other]["name"]
	_set_busy(true)
	_open_overlay("고백 중...", "%s ♥ %s\n\n두근두근..." % [me_name, other_name], "notice")
	_overlay_face(other, "open")
	await get_tree().create_timer(1.0).timeout
	if randf() >= GameData.confess_chance(me, other):
		GameState.reset_affinity(me, other)
		_overlay_sad_face(other)
		overlay_title.text = "고백이 실패했어요.."
		overlay_log.text = "%s%s %s\n\n다른 좋은 털뭉치 만나..\n(하트가 처음으로 돌아갔어요)" % [other_name, _ig(other_name), "고개를 저었어요" ]
		_log("고백 실패: %s - %s" % [me, other])
		_update_relations()
		confirm_button.show()
		return
	GameState.add_couple(me, other)
	_overlay_face(other, "squint")
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
	_overlay_face(other, "open")
	await get_tree().create_timer(1.0).timeout
	if randf() >= GameData.swear_chance(me, other):
		GameState.reset_gifts(me, other)
		_overlay_sad_face(other)
		overlay_title.text = "의형제를 맺지 못했어요.."
		overlay_log.text = "%s%s 아직 마음을 열지 않았어요.\n\n(복숭아가 처음으로 돌아갔어요)" % [other_name, _ig(other_name)]
		_log("의형제 실패: %s - %s" % [me, other])
		_update_relations()
		confirm_button.show()
		return
	GameState.add_sworn(me, other)
	_overlay_face(other, "squint")
	overlay_title.text = "의형제가 되었어요!"
	overlay_log.text = "%s, %s\n\n태어난 날은 달라도\n같은 날 같이 간식 먹자!" % [me_name, other_name]
	celebration.play("의형제!", "%s · %s" % [me_name, other_name],
		puppy_view.global_position + puppy_view.size / 2 - celebration.global_position)
	_log("의형제: %s - %s" % [me, other])
	_update_relations()
	confirm_button.show()


# ═════════════════════════ 대전 (미니게임) ═════════════════════════
## 무장 1 + 책사 1 출전 → 5판 3선승 카드 대결. 관계(신뢰/의형제/커플/같은 진영/앙숙)에 따라 스킬이 달라짐

const CARD_COLORS := {"cav": Color(0.84, 0.42, 0.3), "arc": Color(0.36, 0.62, 0.36),
	"spr": Color(0.32, 0.5, 0.78), "fire": Color(0.93, 0.52, 0.16)}

var _mini_stage := 0
var _mini_war := ""
var _mini_strat := ""
var _mini_cards: Dictionary = {}     # dog_id -> 고르기 카드 버튼
var _mini_go: Button
var _mini_bonus_box: VBoxContainer   # 관계 보너스 줄들 (보너스 있을 때만)
var _mini_bonus_key := ""            # 같은 짝이면 다시 뿅 안 함
var _mb: Dictionary = {}             # 대결 상태
var _mb_ui: Dictionary = {}          # 대결 화면 노드들


func _show_mini() -> void:
	_log("대전")
	var v := _new_page()
	_page_header(v, "← 홈", _show_home, "대전")
	var info := _label("무장 1마리 + 책사 1마리로 출전!\n기병 > 궁병 > 창병 > 기병, 화공은 무조건 승리\n먼저 3번 이기면 승리 · 싸울수록 전공이 쌓여 칭호가 올라가요", 22)
	info.add_theme_color_override("font_color", SUB_COLOR)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(info)
	var list := _scroll_list(v)
	for i in GameData.MINI_STAGES.size():
		var st: Dictionary = GameData.MINI_STAGES[i]
		var locked := i > GameState.mini_cleared
		var status := "잠겨 있어요 (앞 단계를 깨면 열려요)" if locked else ("클리어!" if i < GameState.mini_cleared else "도전!")
		if i >= 3:
			status += "  · 매우 어려움!"
		var b := _button("%d단계  %s\n%s" % [i + 1, st["name"], status], _mini_pick.bind(i))
		b.custom_minimum_size = Vector2(0, 120)
		b.add_theme_font_size_override("font_size", _fs(26))
		b.disabled = locked
		if i < GameState.mini_cleared:
			var gold := Color(0.95, 0.74, 0.22)
			b.add_theme_stylebox_override("normal", _card_box(Color(1.0, 0.97, 0.86), gold, 4))
			b.add_theme_stylebox_override("hover", _card_box(Color(1.0, 0.95, 0.8), gold, 4))
			for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
				b.add_theme_color_override(key, TEXT_COLOR)
		list.add_child(b)


## 출전할 무장·책사 고르기 (어른만)
##   위: 빈 칸 2개 (강아지 그림자 / 고양이 그림자) → 고르면 그 칸에 들어감
##   아래: [무장|책사] 탭 + [위|촉|오|스페셜] 탭 + 목록
const MINI_FAC_ORDER: Array[String] = ["wei", "shu", "wu", "jin", "han", "chu", "special"]
var _mini_role := "war"
var _mini_fac := "wei"
var _mini_slots: Dictionary = {}     # "war"/"strat" -> {"pic": TextureRect, "name": Label}
var _mini_tabs: Dictionary = {}      # "war"/"strat"/진영 -> 탭 버튼
var _mini_list: VBoxContainer


func _mini_pick(stage_i: int) -> void:
	_mini_stage = stage_i
	var v := _new_page()
	_page_header(v, "← 뒤로", _show_mini, GameData.MINI_STAGES[stage_i]["name"])
	if _mini_war != "" and not _mini_ok(_mini_war):
		_mini_war = ""
	if _mini_strat != "" and not _mini_ok(_mini_strat):
		_mini_strat = ""
	# 출전 칸 2개
	var slots := HBoxContainer.new()
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	slots.add_theme_constant_override("separation", 24)
	v.add_child(slots)
	_mini_slots = {}
	for role in ["war", "strat"]:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		slots.add_child(col)
		var box := Button.new()
		box.custom_minimum_size = Vector2(210, 210)
		box.focus_mode = Control.FOCUS_NONE
		var edge := Color(0.86, 0.52, 0.32)
		box.add_theme_stylebox_override("normal", _card_box(Color(1, 0.98, 0.94), edge, 4))
		box.add_theme_stylebox_override("hover", _card_box(Color(1, 0.95, 0.88), edge, 4))
		box.add_theme_stylebox_override("pressed", _card_box(Color(0.98, 0.9, 0.8), edge, 4))
		box.pressed.connect(_mini_set_role.bind(role))
		col.add_child(box)
		var pic := TextureRect.new()
		pic.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		pic.offset_left = 12
		pic.offset_top = 12
		pic.offset_right = -12
		pic.offset_bottom = -12
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.mouse_filter = MOUSE_FILTER_IGNORE
		box.add_child(pic)
		var nm := _label("", 24)
		col.add_child(nm)
		_mini_slots[role] = {"pic": pic, "name": nm}
	_mini_bonus_box = VBoxContainer.new()
	_mini_bonus_box.add_theme_constant_override("separation", 6)
	v.add_child(_mini_bonus_box)
	_mini_bonus_key = ""
	# 무장 / 책사 탭
	_mini_tabs = {}
	var role_row := HBoxContainer.new()
	role_row.add_theme_constant_override("separation", 10)
	v.add_child(role_row)
	for r in [["war", "무장"], ["strat", "책사"]]:
		var t := _button(r[1], _mini_set_role.bind(r[0]))
		t.custom_minimum_size = Vector2(0, 70)
		t.size_flags_horizontal = SIZE_EXPAND_FILL
		t.add_theme_font_size_override("font_size", _fs(26))
		role_row.add_child(t)
		_mini_tabs[r[0]] = t
	# 위 / 촉 / 오 / 스페셜 탭
	var fac_row := HBoxContainer.new()
	fac_row.add_theme_constant_override("separation", 8)
	v.add_child(fac_row)
	for fid in MINI_FAC_ORDER:
		if not GameData.faction_open(fid):
			continue
		var t := _button(GameData.FACTIONS[fid]["name"], _mini_set_fac.bind(fid))
		t.custom_minimum_size = Vector2(0, 60)
		t.size_flags_horizontal = SIZE_EXPAND_FILL
		t.add_theme_font_size_override("font_size", _fs(22))
		fac_row.add_child(t)
		_mini_tabs[fid] = t
	_mini_list = _scroll_list(v)
	_mini_go = _button("출전!", _mini_start)
	_mini_go.custom_minimum_size = Vector2(0, 100)
	_mini_go.add_theme_stylebox_override("disabled", _box(Color(0.72, 0.7, 0.68), 18))
	_mini_go.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.85))
	v.add_child(_mini_go)
	_mini_refresh_pick()


## 고르기 카드: 그림 / (관계 태그) / 이름 / (칭호)
func _mini_pick_card(id: String, ref: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 330)
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	var on: bool = id == _mini_war or id == _mini_strat
	var bg := Color(1.0, 0.93, 0.95) if on else Color(1, 0.98, 0.94)
	var edge := PINK if on else Color(0.86, 0.52, 0.32)
	b.add_theme_stylebox_override("normal", _card_box(bg, edge, 7 if on else 4))
	b.add_theme_stylebox_override("hover", _card_box(bg.darkened(0.03), edge, 7 if on else 4))
	b.add_theme_stylebox_override("pressed", _card_box(bg.darkened(0.08), edge, 7 if on else 4))
	b.pressed.connect(_mini_select.bind(id))
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	box.offset_top = 8
	box.offset_bottom = -8
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = MOUSE_FILTER_IGNORE
	b.add_child(box)
	# 스페셜 칭호를 받을 수 있는 짝꿍이면 오른쪽 위에 불꽃 (아직 안 받았을 때만)
	if ref != "" and ref != id:
		var sp: Dictionary = GameData.special_for(ref, id)
		if not sp.is_empty() and GameState.pair_win_count(ref, id) < int(sp["wins"]):
			var fire = RpsIconScript.new()
			fire.kind = "fire"
			fire.mouse_filter = MOUSE_FILTER_IGNORE
			fire.set_anchors_preset(PRESET_TOP_RIGHT)
			fire.offset_left = -58
			fire.offset_right = -8
			fire.offset_top = 8
			fire.offset_bottom = 58
			fire.pivot_offset = Vector2(25, 50)
			b.add_child(fire)
			# 하트처럼 둥실둥실 + 살랑살랑 흔들림
			var ft: Tween = fire.create_tween().set_loops()
			ft.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			ft.tween_property(fire, "position:y", 5.0, 0.9)
			ft.parallel().tween_property(fire, "rotation", 0.05, 0.9)
			ft.parallel().tween_property(fire, "scale", Vector2(1.03, 1.03), 0.9)
			ft.tween_property(fire, "position:y", 11.0, 0.9)
			ft.parallel().tween_property(fire, "rotation", -0.05, 0.9)
			ft.parallel().tween_property(fire, "scale", Vector2(0.98, 0.98), 0.9)
	var pic := TextureRect.new()
	pic.texture = _centered_tex(_dog_tex(id, 2))
	pic.custom_minimum_size = Vector2(0, 120)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(pic)
	# 고른 애와의 관계
	if ref != "" and ref != id:
		var tags := HBoxContainer.new()
		tags.alignment = BoxContainer.ALIGNMENT_CENTER
		tags.add_theme_constant_override("separation", 3)
		tags.mouse_filter = MOUSE_FILTER_IGNORE
		if GameState.is_sworn(ref, id):
			tags.add_child(_tag("의형제", Color(0.9, 0.7, 0.18)))
		if GameState.is_couple(ref, id):
			tags.add_child(_tag("커플", PINK))
		if GameData.is_trusted(ref, id):
			tags.add_child(_tag("신뢰", Color(0.3, 0.56, 0.78)))
		if GameData.is_family(ref, id):
			tags.add_child(_tag("가족", Color(0.78, 0.56, 0.3)))
		if GameData.is_rival(ref, id):
			tags.add_child(_tag("앙숙", Color(0.56, 0.54, 0.53)))
		if GameState.is_sulky(ref, id):
			tags.add_child(_tag("토라짐", CLOVER_COL))
		for t in tags.get_children():
			(t as Control).mouse_filter = MOUSE_FILTER_IGNORE
		if tags.get_child_count() > 0:
			box.add_child(tags)
	var nm := _label(GameData.DOGS[id]["name"], 24)
	nm.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(nm)
	box.add_child(_rank_panel(id, false))
	return b


## 그림을 모양만 남기고 회색 한 색으로 칠하는 재질 (눈코입 안 보임)
var _sil_mat: ShaderMaterial


func _silhouette_mat() -> ShaderMaterial:
	if _sil_mat == null:
		var sh := Shader.new()
		sh.code = """shader_type canvas_item;
uniform vec4 tint : source_color = vec4(0.78, 0.76, 0.74, 1.0);
void fragment() {
	COLOR = vec4(tint.rgb, texture(TEXTURE, UV).a * tint.a);
}"""
		_sil_mat = ShaderMaterial.new()
		_sil_mat.shader = sh
	return _sil_mat


## 출전할 수 있는 멍냥이 (어른)
func _mini_ok(id: String) -> bool:
	return GameState.owns(id) and GameState.get_puppy(id).is_adult()


func _mini_set_role(role: String) -> void:
	_mini_role = role
	_mini_refresh_pick()


func _mini_set_fac(fid: String) -> void:
	_mini_fac = fid
	_mini_refresh_pick()


var _mini_tapped := ""


## 목록이 다시 그려진 뒤 방금 누른 카드만 살짝 출렁
func _mini_soft_jelly(card: Control) -> void:
	await get_tree().process_frame
	if is_instance_valid(card):
		_jelly(card, 0.3)


func _mini_select(id: String) -> void:
	_mini_tapped = id
	if GameData.is_strategist(id):
		_mini_strat = "" if _mini_strat == id else id
	else:
		_mini_war = "" if _mini_war == id else id
		if _mini_war != "" and _mini_strat == "":
			_mini_role = "strat"      # 무장 골랐으면 책사 탭으로
	_mini_refresh_pick()


func _mini_refresh_pick() -> void:
	# 출전 칸: 고른 애 / 없으면 그림자
	for role in ["war", "strat"]:
		var id: String = _mini_war if role == "war" else _mini_strat
		var pic: TextureRect = _mini_slots[role]["pic"]
		var nm: Label = _mini_slots[role]["name"]
		if id != "":
			pic.texture = _centered_tex(_dog_tex(id, 2))
			pic.modulate = Color.WHITE
			pic.material = null
			nm.text = GameData.DOGS[id]["name"]
		else:
			# 빈 칸: 조운(무장) / 가후(책사) 모양의 회색 단색 실루엣
			pic.texture = _centered_tex(_dog_tex("zhao_yun" if role == "war" else "jia_xu", 2))
			pic.modulate = Color.WHITE
			pic.material = _silhouette_mat()
			nm.text = "무장" if role == "war" else "책사"
	# 탭 색
	for key in _mini_tabs:
		var t: Button = _mini_tabs[key]
		var on: bool = key == _mini_role or key == _mini_fac
		var col: Color = FACTION_COLORS[key] if FACTION_COLORS.has(key) else Color(0.86, 0.52, 0.32)
		if on:
			t.add_theme_stylebox_override("normal", _box(col, 16))
			t.add_theme_stylebox_override("hover", _box(col.lightened(0.08), 16))
			for k in ["font_color", "font_hover_color", "font_focus_color"]:
				t.add_theme_color_override(k, Color.WHITE)
		else:
			t.add_theme_stylebox_override("normal", _card_box(Color(1, 0.98, 0.94), col.lightened(0.3), 3))
			t.add_theme_stylebox_override("hover", _card_box(Color(1, 0.96, 0.9), col, 3))
			for k in ["font_color", "font_hover_color", "font_focus_color"]:
				t.add_theme_color_override(k, col.darkened(0.15))
	# 목록
	for c in _mini_list.get_children():
		_mini_list.remove_child(c)
		c.queue_free()
	var ids: Array[String] = []
	for id in GameState.owned:
		if _mini_ok(id) and GameData.faction_of(id) == _mini_fac \
				and GameData.is_strategist(id) == (_mini_role == "strat"):
			ids.append(id)
	if ids.is_empty():
		var none := _label("어른까지 키운 %s가 없어요" % ("책사" if _mini_role == "strat" else "무장"), 22)
		none.add_theme_color_override("font_color", SUB_COLOR)
		_mini_list.add_child(none)
	else:
		# 관계 태그 기준: 한 마리만 골랐으면 그 애, 둘 다 골랐으면 지금 탭의 짝꿍
		var ref := ""
		if _mini_war != "" and _mini_strat != "":
			ref = _mini_war if _mini_role == "strat" else _mini_strat
		else:
			ref = _mini_war if _mini_war != "" else _mini_strat
		var grid := _grid(_mini_list)
		for id in ids:
			var pc := _mini_pick_card(id, ref)
			grid.add_child(pc)
			if id == _mini_tapped:
				_mini_soft_jelly(pc)
		_mini_tapped = ""
	# 출전 버튼 / 보너스
	_mini_go.disabled = _mini_war == "" or _mini_strat == ""
	_mini_show_bonus()


## 보너스 줄: [관계 태그] 보너스! 효과   (관계 색 글씨, 하나씩 뿅)
func _mini_show_bonus() -> void:
	var key := "%s|%s" % [_mini_war, _mini_strat]
	if key == _mini_bonus_key:
		return
	_mini_bonus_key = key
	for c in _mini_bonus_box.get_children():
		_mini_bonus_box.remove_child(c)
		c.queue_free()
	if _mini_war == "" or _mini_strat == "":
		return
	var rows: Array = _mini_bonus(_mini_war, _mini_strat)["rows"]
	for i in rows.size():
		var r: Array = rows[i]
		var line := HBoxContainer.new()
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		line.add_theme_constant_override("separation", 10)
		_mini_bonus_box.add_child(line)
		var wish: bool = r.size() > 4 and r[4] == "wish"
		if not wish:
			var tag := _tag(r[0], r[1])
			tag.add_theme_font_size_override("font_size", _fs(24))
			line.add_child(tag)
		var txt := _label(r[2] if wish else "%s %s" % ["보너스!" if r[3] else "주의!", r[2]], 24 if wish else 30)
		if wish:
			txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			txt.custom_minimum_size = Vector2(600, 0)
		txt.add_theme_color_override("font_color", (r[1] as Color).darkened(0.12))
		txt.add_theme_color_override("font_outline_color", Color(1, 1, 1))
		txt.add_theme_constant_override("outline_size", 6)
		line.add_child(txt)
		# 뿅! (차례로)
		line.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(0.05 + 0.12 * i)
		tw.tween_callback(func() -> void:
			line.pivot_offset = line.size / 2
			line.scale = Vector2(0.75, 0.75)
			line.modulate.a = 1.0)
		tw.tween_property(line, "scale", Vector2(1.05, 1.05), 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(line, "scale", Vector2.ONE, 0.1)


## 관계 보너스. rows = [[태그, 색, 효과, 좋은지]] (기본 스탯은 안 보여 줌)
func _mini_bonus(w: String, s: String) -> Dictionary:
	var b := {"peek": 1, "duel": true, "double": false, "redraw": false, "extra": 0, "rows": []}
	var rows: Array = b["rows"]
	if GameData.is_trusted(w, s):
		b["peek"] = 2
		rows.append(["신뢰", Color(0.3, 0.56, 0.78), "간파 +1", true])
	if GameState.is_sworn(w, s):
		b["double"] = true
		rows.append(["의형제", Color(0.9, 0.7, 0.18), "협공 (첫 승리 2점)", true])
	if GameState.is_couple(w, s):
		b["redraw"] = true
		rows.append(["커플", PINK, "응원 (손패 다시 받기)", true])
	var fw: String = GameData.faction_of(w)
	if fw == GameData.faction_of(s):
		b["extra"] = 1
		rows.append(["같은 진영", FACTION_COLORS[fw], "손패 +1", true])
	if GameData.is_rival(w, s):
		b["duel"] = false
		rows.append(["앙숙", Color(0.56, 0.54, 0.53), "일기토 못 써요", false])
	# 스페셜 칭호 짝꿍이면 맨 위에 빨간 글씨 (횟수는 안 알려 줌)
	if not GameData.special_for(w, s).is_empty():
		rows.push_front(["", Color(0.85, 0.2, 0.22),
			"%s 강아지는 %s 고양이와 함께 싸우고 싶어해요!" % [GameData.DOGS[w]["name"], GameData.DOGS[s]["name"]], true, "wish"])
	return b


func _mini_deal(n: int) -> Array:
	var hand: Array = []
	for i in n:
		hand.append(["cav", "arc", "spr"].pick_random())
	return hand


## 상대가 이번 판에 낼 카드
func _mini_foe_card() -> String:
	var st: Dictionary = GameData.MINI_STAGES[_mini_stage]
	var plain: Array = []
	for c in _mb["hand"]:
		if c != "fire":
			plain.append(c)
	if not plain.is_empty() and randf() < float(st["smart"]):
		var target: String = plain.pick_random()
		for k in GameData.CARD_BEATS:
			if GameData.CARD_BEATS[k] == target:
				return k
	var w: Array = st["w"]
	var total: float = w[0] + w[1] + w[2]
	var r := randf() * total
	for i in 3:
		r -= float(w[i])
		if r < 0.0:
			return ["cav", "arc", "spr"][i]
	return "spr"


func _mini_start() -> void:
	if _mini_war == "" or _mini_strat == "":
		return
	var bonus := _mini_bonus(_mini_war, _mini_strat)
	var st: Dictionary = GameData.MINI_STAGES[_mini_stage]
	var hand := _mini_deal(GameData.MINI_HAND + int(bonus["extra"]))
	if not st.get("no_fire", false):
		hand.append("fire")
	_mb = {"hand": hand, "me": 0, "foe": int(st.get("head", 0)), "round": 1, "peek": bonus["peek"], "duel": bonus["duel"],
		"armed": false, "double": bonus["double"], "redraw": bonus["redraw"], "foe_card": "", "seen": false, "over": false,
		"busy": false}
	_mb["foe_card"] = _mini_foe_card()
	_log("대전 시작: %s + %s / %d단계" % [_mini_war, _mini_strat, _mini_stage + 1])
	_mini_battle_page()


func _mini_battle_page() -> void:
	var st: Dictionary = GameData.MINI_STAGES[_mini_stage]
	var v := _new_page()
	v.add_theme_constant_override("separation", 8)
	_page_header(v, "← 포기", _ask_forfeit, st["name"])
	_mb_ui = {}
	var score := _label("", 52)
	v.add_child(score)
	_mb_ui["score"] = score
	v.add_child(_mini_gap())

	# ── 위: 상대 진영 ──
	# 상대 진영: 회색 적 무장 + 적 책사 (화난 얼굴), 이기면 씩 웃음
	var foe := HBoxContainer.new()
	foe.alignment = BoxContainer.ALIGNMENT_CENTER
	foe.add_theme_constant_override("separation", 30)
	v.add_child(foe)
	for key in ["foe_war", "foe_strat"]:
		var ff := TextureRect.new()
		ff.custom_minimum_size = Vector2(130, 130)
		ff.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ff.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ff.mouse_filter = MOUSE_FILTER_IGNORE
		foe.add_child(ff)
		_mb_ui[key] = ff
	_mb_ui["foe"] = foe

	# ── 가운데: 상대 카드 / 내 카드 (+ WIN! 뿅) ──
	v.add_child(_mini_gap())
	var mid := Control.new()
	mid.custom_minimum_size = Vector2(0, MINI_SLOT.y * 2 + 26)
	v.add_child(mid)
	for key in ["foe_slot", "my_slot"]:
		var slot := _mini_card_face("", MINI_SLOT.x, MINI_SLOT.y)
		slot.set_anchors_preset(PRESET_CENTER_TOP)
		slot.position = Vector2(-MINI_SLOT.x / 2, 0 if key == "foe_slot" else MINI_SLOT.y + 26)
		mid.add_child(slot)
		_mb_ui[key] = slot
	var pop := Label.new()
	pop.text = "WIN!"
	pop.add_theme_font_size_override("font_size", 64)
	pop.add_theme_color_override("font_color", Color(1.0, 0.84, 0.2))
	pop.add_theme_color_override("font_outline_color", Color(0.5, 0.28, 0.08))
	pop.add_theme_constant_override("outline_size", 16)
	pop.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pop.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pop.size = Vector2(220, 90)
	pop.pivot_offset = pop.size / 2
	pop.mouse_filter = MOUSE_FILTER_IGNORE
	pop.hide()
	mid.add_child(pop)
	_mb_ui["pop"] = pop

	# ── 아래: 우리 진영 (무장 + 책사) ──
	v.add_child(_mini_gap())
	var team := HBoxContainer.new()
	team.alignment = BoxContainer.ALIGNMENT_CENTER
	team.add_theme_constant_override("separation", 40)
	v.add_child(team)
	for key in ["war", "strat"]:
		var face := TextureRect.new()
		face.custom_minimum_size = Vector2(190, 190)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		team.add_child(face)
		_mb_ui[key] = face
	var result := _label("낼 카드를 골라 주세요!", 28)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(result)
	_mb_ui["result"] = result
	var foe_hint := _label("", 22)
	foe_hint.add_theme_color_override("font_color", SUB_COLOR)
	v.add_child(foe_hint)
	_mb_ui["foe_hint"] = foe_hint

	v.add_child(_mini_gap())
	# 스킬
	var skills := HBoxContainer.new()
	skills.alignment = BoxContainer.ALIGNMENT_CENTER   # 쓴 버튼은 사라지고 남은 것끼리 가운데로
	skills.custom_minimum_size = Vector2(0, 76)        # 다 써도 자리 높이는 그대로
	skills.add_theme_constant_override("separation", 10)
	v.add_child(skills)
	for sk in [["peek", "간파"], ["duel", "일기토"], ["redraw", "응원"]]:
		var b := _button(sk[1], _mini_skill.bind(sk[0]))
		b.custom_minimum_size = Vector2(190, 76)
		b.add_theme_font_size_override("font_size", _fs(24))
		skills.add_child(b)
		_mb_ui["sk_" + sk[0]] = b
	# 손패
	var hand := HBoxContainer.new()
	hand.alignment = BoxContainer.ALIGNMENT_CENTER
	hand.add_theme_constant_override("separation", 6)
	v.add_child(hand)
	_mb_ui["hand"] = hand
	_mb["busy"] = false
	_mini_faces("open")
	_mini_reset_slots()
	_mini_refresh()


const MINI_SLOT := Vector2(150, 180)   # 가운데 카드 자리 크기
const MINI_HAND_H := 165.0             # 손패 카드 높이


## 위아래로 고르게 벌려 주는 빈칸
func _mini_gap() -> Control:
	var g := Control.new()
	g.size_flags_vertical = SIZE_EXPAND_FILL
	return g


## 카드 한 장 모양 (kind "" = 빈칸, "?" = 회색 ???). 그림 + 이름
func _mini_card_face(kind: String, w: float, h: float) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(w, h)
	card.size = Vector2(w, h)
	card.pivot_offset = Vector2(w, h) / 2
	card.mouse_filter = MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", int(h * 0.08))   # 그림과 이름 사이 띄우기
	box.mouse_filter = MOUSE_FILTER_IGNORE
	card.add_child(box)
	var icon = RpsIconScript.new()
	icon.custom_minimum_size = Vector2(1, 1) * minf(w * 0.68, h * 0.5)
	box.add_child(icon)
	var nm := _label("", 22)
	nm.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(nm)
	card.set_meta("big", h >= 175.0)
	card.set_meta("icon", icon)
	card.set_meta("name", nm)
	_mini_set_card(card, kind)
	return card


func _mini_set_card(card: PanelContainer, kind: String) -> void:
	var icon = card.get_meta("icon")   # RpsIcon (kind 속성 있음)
	var nm: Label = card.get_meta("name")
	if kind == "" or kind == "?":
		icon.hide()
		nm.text = "???" if kind == "?" else ""
		nm.add_theme_font_size_override("font_size", 34)
		nm.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
		var col := Color(0.66, 0.64, 0.62) if kind == "?" else Color(0, 0, 0, 0.06)
		card.add_theme_stylebox_override("panel", _box(col, 16))
		return
	icon.show()
	icon.kind = kind
	nm.text = GameData.CARD_NAMES[kind]
	nm.add_theme_font_size_override("font_size", _fs(28 if card.get_meta("big", false) else 22))
	nm.add_theme_color_override("font_color", TEXT_COLOR)
	card.add_theme_stylebox_override("panel", _card_box(Color(1, 0.98, 0.94), CARD_COLORS[kind], 5))


func _mini_reset_slots() -> void:
	_mini_set_card(_mb_ui["foe_slot"], "?")
	_mini_set_card(_mb_ui["my_slot"], "")
	(_mb_ui["pop"] as Label).hide()


func _mini_faces(eyes: String) -> void:
	(_mb_ui["war"] as TextureRect).texture = _dog_tex(_mini_war, 2, eyes)
	(_mb_ui["strat"] as TextureRect).texture = _dog_tex(_mini_strat, 2, eyes)
	# 적: 내가 지면(line) 씩 웃고, 나머지는 화난 얼굴
	var sfx := "_squint" if eyes == "line" else ""
	(_mb_ui["foe_war"] as TextureRect).texture = _centered_tex(FoodIcon.item_texture("enemy_war" + sfx))
	(_mb_ui["foe_strat"] as TextureRect).texture = _centered_tex(FoodIcon.item_texture("enemy_strat" + sfx))


func _mini_refresh() -> void:
	var st: Dictionary = GameData.MINI_STAGES[_mini_stage]
	(_mb_ui["score"] as Label).text = "나 %d : %d %s" % [_mb["me"], _mb["foe"], st["enemy"]]
	var hint := "%d번째 판" % _mb["round"]
	if _mb["armed"]:
		hint += " · 일기토 준비!"
	if st["tie_enemy"]:
		hint += " · 비기면 상대 승리"
	if st.get("no_fire", false):
		hint += " · 화공이 막혔어요"
	if int(st.get("head", 0)) > 0 and _mb["round"] == 1:
		hint += " · 상대가 %d점 먼저!" % int(st["head"])
	(_mb_ui["foe_hint"] as Label).text = hint
	var lock: bool = _mb["over"] or _mb["busy"]
	(_mb_ui["sk_peek"] as Button).text = "간파 %d" % _mb["peek"]
	(_mb_ui["sk_peek"] as Button).disabled = lock or _mb["peek"] <= 0 or _mb["seen"]
	(_mb_ui["sk_duel"] as Button).disabled = lock or not _mb["duel"]
	(_mb_ui["sk_redraw"] as Button).disabled = lock or not _mb["redraw"]
	# 다 쓴 (못 쓰는) 보너스 버튼은 숨김 → 남은 버튼끼리 가운데 정렬
	# (대전 튜토리얼 중에는 설명하려고 다 보여 줌)
	var tut_on := _btut_step >= 0
	(_mb_ui["sk_peek"] as Button).visible = tut_on or int(_mb["peek"]) > 0
	(_mb_ui["sk_duel"] as Button).visible = tut_on or bool(_mb["duel"])
	(_mb_ui["sk_redraw"] as Button).visible = tut_on or bool(_mb["redraw"])
	# 간파했으면 상대 카드가 살짝 비쳐 보임
	if not _mb["busy"]:
		if _mb["seen"]:
			_mini_set_card(_mb_ui["foe_slot"], _mb["foe_card"])
			(_mb_ui["foe_slot"] as Control).modulate = Color(1, 1, 1, 0.6)
		else:
			_mini_set_card(_mb_ui["foe_slot"], "?")
			(_mb_ui["foe_slot"] as Control).modulate = Color.WHITE
	var hand_box: HBoxContainer = _mb_ui["hand"]
	for c in hand_box.get_children():
		hand_box.remove_child(c)
		c.queue_free()
	var n := (_mb["hand"] as Array).size()
	var w := minf(150.0, (660.0 - 6.0 * (n - 1)) / maxf(1.0, n))
	for i in n:
		var card: String = _mb["hand"][i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(w, MINI_HAND_H)
		b.focus_mode = Control.FOCUS_NONE
		var col: Color = CARD_COLORS[card]
		b.add_theme_stylebox_override("normal", _card_box(Color(1, 0.98, 0.94), col, 5))
		b.add_theme_stylebox_override("hover", _card_box(Color(1, 0.95, 0.88), col, 5))
		b.add_theme_stylebox_override("pressed", _card_box(Color(0.98, 0.9, 0.8), col, 5))
		b.add_theme_stylebox_override("disabled", _card_box(Color(0.9, 0.88, 0.85), col.lightened(0.4), 5))
		b.disabled = lock
		if _mb.get("tut", false) and _mb["round"] == 1 and card != "fire" \
				and GameData.CARD_BEATS.get(card, "") != _mb["foe_card"]:
			b.disabled = true   # 튜토리얼 첫 판: 이기는 카드만
		b.pressed.connect(_mini_play.bind(i))
		var face := _mini_card_face(card, w, MINI_HAND_H)
		face.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		face.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		b.add_child(face)
		hand_box.add_child(b)


func _mini_skill(kind: String) -> void:
	if _mb.is_empty() or _mb["over"] or _mb["busy"]:
		return
	match kind:
		"peek":
			if _mb["peek"] > 0 and not _mb["seen"]:
				_mb["peek"] -= 1
				_mb["seen"] = true
				_btut_event.call_deferred("peek")
				(_mb_ui["result"] as Label).text = "%s의 간파! 상대의 수가 보여요." % GameData.DOGS[_mini_strat]["name"]
		"duel":
			if _mb["duel"]:
				_mb["duel"] = false
				_mb["armed"] = true
				(_mb_ui["result"] as Label).text = "%s, 일기토 준비! 이번 판은 비겨도 이겨요." % GameData.DOGS[_mini_war]["name"]
		"redraw":
			if _mb["redraw"]:
				_mb["redraw"] = false
				var hand: Array = _mb["hand"]
				var fire := hand.has("fire")
				var n := hand.size() - (1 if fire else 0)
				var fresh := _mini_deal(n)
				if fire:
					fresh.append("fire")
				_mb["hand"] = fresh
				_mb["foe_card"] = _mini_foe_card()
				_mb["seen"] = false
				(_mb_ui["result"] as Label).text = "응원 받아서 손패를 다시 받았어요!"
	_mini_refresh()


## 카드 내기: 내 카드 등장 → 상대 카드 뒤집힘 → 이긴 쪽에 WIN! 뿅 → 점수
func _mini_play(i: int) -> void:
	if _mb.is_empty() or _mb["over"] or _mb["busy"]:
		return
	var st: Dictionary = GameData.MINI_STAGES[_mini_stage]
	var hand: Array = _mb["hand"]
	var mine: String = hand[i]
	hand.remove_at(i)
	var foe: String = _mb["foe_card"]
	if _mb.get("tut", false) and mine != "fire" and GameData.CARD_BEATS.get(mine, "") != foe:
		foe = GameData.CARD_BEATS[mine]   # 튜토리얼: 무조건 이기게
		_mb["foe_card"] = foe
	_mb["busy"] = true
	_mini_refresh()
	_btut_event("card")
	var my_slot: PanelContainer = _mb_ui["my_slot"]
	var foe_slot: PanelContainer = _mb_ui["foe_slot"]
	# 1) 내 카드 등장
	_mini_set_card(my_slot, mine)
	_mini_pop_in(my_slot)
	await get_tree().create_timer(0.35).timeout
	if not is_instance_valid(foe_slot):
		return
	# 2) 상대 카드 뒤집기
	foe_slot.modulate = Color.WHITE
	_mini_set_card(foe_slot, foe)
	_mini_pop_in(foe_slot)
	await get_tree().create_timer(0.3).timeout
	if not is_instance_valid(foe_slot):
		return
	# 3) 판정
	var res := "tie"
	if mine == "fire" or GameData.CARD_BEATS.get(mine, "") == foe:
		res = "win"
	elif mine != foe:
		res = "lose"
	var duel_used := false
	if res == "tie":
		if _mb["armed"]:
			res = "win"
			duel_used = true
		elif st["tie_enemy"]:
			res = "lose"
	_mb["armed"] = false
	var line := "%s vs %s → " % [GameData.CARD_NAMES[mine], GameData.CARD_NAMES[foe]]
	match res:
		"win":
			var pts := 1
			if _mb["double"]:
				_mb["double"] = false
				pts = 2
				line += "의형제 협공! 2점!"
			elif duel_used:
				line += "일기토 승리!"
			elif mine == "fire":
				line += "화공으로 불바다!"
			else:
				line += "이겼어요!"
			_mb["me"] += pts
			_mini_faces("squint")
			_mini_win_pop("WIN!" if pts == 1 else "WIN! ×2", my_slot)
		"lose":
			_mb["foe"] += 1
			line += "졌어요.." if mine != foe else "비겼지만 상대가 가져갔어요.."
			_mini_faces("line")
			_mini_win_pop("WIN!", foe_slot)
		_:
			line += "비겼어요"
			_mini_faces("open")
			_mini_win_pop("DRAW", null)
	(_mb_ui["result"] as Label).text = line
	_mb["round"] += 1
	_mb["seen"] = false
	var done: bool = _mb["me"] >= GameData.MINI_WIN or _mb["foe"] >= GameData.MINI_WIN or hand.is_empty()
	if done:
		_mb["over"] = true
	_mini_refresh_score_only()
	await get_tree().create_timer(1.1).timeout
	if not is_instance_valid(foe_slot):
		return
	if done:
		if _mb.get("tut", false):
			_btut_finish()
		else:
			_mini_end(_mb["me"] > _mb["foe"])
		return
	_mb["foe_card"] = _mini_foe_card()
	_mb["busy"] = false
	_mini_reset_slots()
	_mini_faces("open")
	_mini_refresh()
	_btut_event("play")


func _mini_refresh_score_only() -> void:
	var st: Dictionary = GameData.MINI_STAGES[_mini_stage]
	var score: Label = _mb_ui["score"]
	score.text = "나 %d : %d %s" % [_mb["me"], _mb["foe"], st["enemy"]]
	score.pivot_offset = score.size / 2
	var tw := create_tween()
	tw.tween_property(score, "scale", Vector2(1.15, 1.15), 0.08)
	tw.tween_property(score, "scale", Vector2.ONE, 0.12)


## 카드가 톡 튀어나오는 연출
func _mini_pop_in(c: Control) -> void:
	c.pivot_offset = c.size / 2
	c.scale = Vector2(0.4, 0.4)
	var tw := create_tween()
	tw.tween_property(c, "scale", Vector2(1.1, 1.1), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "scale", Vector2.ONE, 0.08)


## 노란 WIN! 이 이긴 쪽 카드 옆에서 뿅 (비기면 가운데 DRAW)
func _mini_win_pop(text: String, beside: Control) -> void:
	var pop: Label = _mb_ui["pop"]
	var mid: Control = pop.get_parent()
	pop.text = text
	pop.add_theme_color_override("font_color", Color(1.0, 0.84, 0.2) if text != "DRAW" else Color(0.85, 0.83, 0.8))
	var center := mid.size / 2     # 비기면 두 카드 사이 가운데
	if beside:
		center = beside.position + beside.size / 2   # 이긴 쪽 카드 위에
	pop.position = center - pop.size / 2
	pop.rotation = -0.12
	pop.scale = Vector2(0.2, 0.2)
	pop.modulate.a = 1.0
	pop.show()
	var tw := create_tween()
	tw.tween_property(pop, "scale", Vector2(1.25, 1.25), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(pop, "scale", Vector2.ONE, 0.1)
	tw.tween_interval(0.6)
	tw.tween_property(pop, "modulate:a", 0.0, 0.25)


# ── 대전 튜토리얼: 어른 무장+책사가 처음 생기면 (뽑기권 선물 다음) 1단계를 같이 해 봄. 마지막엔 꼭 이김 ──
var _btut_step := -1
var _btut_wait := ""


## 조건이 되면 대전 튜토리얼 시작 (시작했으면 true)
func _btut_check() -> bool:
	if _btut_step >= 0 or _tut_step >= 0 or not GameState.tutorial_done:
		return false
	if GameState.battle_tut_done or not GameState.battle_ready():
		return false
	_btut_start()
	return true


func _btut_start() -> void:
	_log("대전 튜토리얼 시작")
	# 출전: 가장 먼저 어른이 된 무장 1 + 가장 먼저 어른이 된 책사 1
	# (어른 선물 받은 순서 = rewarded 에 들어간 순서. 혹시 없으면 데려온 순서)
	_mini_war = ""
	_mini_strat = ""
	var order: Array[String] = []
	for id in GameState.rewarded:
		order.append(str(id))
	order.append_array(GameState.owned)
	for id in order:
		if not _mini_ok(id):
			continue
		if GameData.is_strategist(id):
			if _mini_strat == "":
				_mini_strat = id
		elif _mini_war == "":
			_mini_war = id
	_mini_stage = 0
	_mini_start()
	_mb["tut"] = true
	_mb["peek"] = maxi(1, int(_mb["peek"]))
	# 첫 판: 상대는 궁병(가위) → 기병(바위)로 이기면 됨. 손패에 기병 꼭 넣기
	_mb["foe_card"] = "arc"
	if not (_mb["hand"] as Array).has("cav"):
		_mb["hand"][0] = "cav"
	_mini_refresh()
	_btut_step = -1
	_btut_next()


func _btut_next() -> void:
	_btut_step += 1
	_btut_wait = ""
	match _btut_step:
		0:
			tut.show_step("대전이 열렸어요!\n무장 1마리와 책사 1마리가 함께 싸워요.", [], false)
		1:
			tut.show_step("카드는 가위바위보예요!\n기병(바위) > 궁병(가위) > 창병(보) > 기병\n화공(불)은 무조건 이겨요.", [_mb_ui["hand"]], false)
		2:
			tut.show_step("상대 카드는 내가 카드를 낼 때까지\n??? 로 가려져 있어요.", [_mb_ui["foe_slot"]], false)
		3:
			_btut_wait = "peek"
			tut.show_step("책사의 간파로 상대 카드를 미리 볼 수 있어요.\n눌러 보세요!", [_mb_ui["sk_peek"]], true)
		4:
			_btut_wait = "play"
			# 손패 + 카드 내는 곳까지 밝게 (WIN! 이 잘 보이게)
			tut.show_step("상대는 %s을(를) 낼 거예요.\n이기는 카드를 내 보세요!" % GameData.CARD_NAMES[_mb["foe_card"]],
				[_mb_ui["hand"], _mb_ui["foe_slot"], _mb_ui["my_slot"]], true)
		5:
			tut.show_step("이기면 점수가 올라가요.\n먼저 3번 이기면 승리!", [_mb_ui["score"]], false)
		6:
			tut.show_step("일기토는 비겨도 이기게 해 주고, 응원은 손패를 다시 받아요.\n신뢰·의형제·커플 사이면 보너스도 있어요!", [_mb_ui["sk_duel"], _mb_ui["sk_redraw"]], false)
		7:
			_btut_wait = "card"
			tut.show_step("다음 판도 이겨 보아요!", [_mb_ui["hand"], _mb_ui["foe_slot"], _mb_ui["my_slot"]], true)
		_:
			tut.finish()   # 카드를 고르면 안내는 사라지고 끝까지 직접


func _btut_event(what: String) -> void:
	if _btut_step >= 0 and _btut_wait == what:
		_btut_next()


## 튜토리얼 대전이 끝남: 보상 없이 안내만
func _btut_finish() -> void:
	tut.finish()
	_btut_wait = ""
	_open_overlay("승리!", "전공을 쌓아\n최고의 영웅 멍냥이가 되어 보아요!", "btut_end")
	_overlay_pair(_mini_war, _mini_strat, "squint")
	confirm_button.text = "좋았어!"
	confirm_button.show()
	celebration.play("", "", get_viewport_rect().size / 2 - celebration.global_position)


## 대전 도중 포기 → 확인창 (끝난 판이면 바로 나감)
func _ask_forfeit() -> void:
	if _mb.is_empty() or _mb.get("over", false):
		_show_mini()
		return
	_open_overlay("포기", "정말 포기하시겠습니까?\n공적을 놓치게 됩니다!", "forfeit")
	var red := Color(0.86, 0.32, 0.32)
	confirm_button.text = "포기하기"
	confirm_button.add_theme_stylebox_override("normal", _box(red, 18))
	confirm_button.add_theme_stylebox_override("hover", _box(red.lightened(0.1), 18))
	confirm_button.add_theme_stylebox_override("pressed", _box(red.darkened(0.15), 18))
	confirm_button.show()
	cancel_button.text = "계속 싸우기"
	cancel_button.show()


func _mini_end(won: bool) -> void:
	var st: Dictionary = GameData.MINI_STAGES[_mini_stage]
	var got: Dictionary = GameState.mini_result(won, _mini_stage, _mini_war, _mini_strat)
	_log("대전 결과: %s" % [got])
	var text: String
	if won:
		text = "첫 클리어 보상!" if got["first"] else "보상"
	else:
		text = "%s에게 졌어요.\n다시 도전해 봐요!" % st["enemy"]
	_open_overlay("승리!" if won else "패배..", text, "mini_end")
	overlay_log.custom_minimum_size = Vector2(560, 0)
	if won:
		_overlay_pair(_mini_war, _mini_strat, "squint")
	else:
		_overlay_pair(_mini_war, _mini_strat, "closed", true)
	# 그림 밑: 이름 + 칭호 + 전공 막대 + "20/170 (+10)"
	for id in [_mini_war, _mini_strat]:
		overlay_stats.add_child(_mini_stat(id, int(got["exp"])))
	overlay_stats.show()
	# 보상: 종류별 그림 + ×개수 (첫 클리어 보너스 + 보상 뽑기 + 공훈패)
	if won:
		var counts := {}
		var order: Array[String] = []
		if str(got.get("reward", "")) != "":
			counts[got["reward"]] = int(got["n"])
			order.append(str(got["reward"]))
		for k in ["ticket", "golden_peach", "pouch", "ginseng", "clover", "peach"]:   # 귀한 것 먼저
			var dn := int((got.get("drops", {}) as Dictionary).get(k, 0))
			if dn > 0:
				if not counts.has(k):
					order.append(k)
				counts[k] = int(counts.get(k, 0)) + dn
		if int(got.get("merit", 0)) > 0:
			counts["merit"] = int(got["merit"])
			order.append("merit")
		drops_box.add_theme_constant_override("separation", 14)
		for k in order:
			var cell := VBoxContainer.new()
			cell.add_theme_constant_override("separation", 0)
			var t := TextureRect.new()
			var icon_id: String = "ticket" if k == "ticket" else ("item_merit" if k == "merit" else str(GameData.ITEMS[k]["icon"]))
			t.texture = FoodIcon.item_texture(icon_id)
			t.custom_minimum_size = Vector2(72, 72)
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			cell.add_child(t)
			var cl := _label("×%d" % int(counts[k]), 22)
			cl.add_theme_color_override("font_color", SUB_COLOR)
			cell.add_child(cl)
			drops_box.add_child(cell)
		drops_box.show()
	# 새 칭호 / 스페셜 칭호 (얻었을 때만)
	overlay_extra.add_theme_constant_override("separation", 14)
	var before: Dictionary = got.get("before", {})
	for id in got["ranked"]:
		var nm: String = GameData.DOGS[id]["name"]
		var old_lv := int(before.get(id, 0))
		var new_lv := GameState.rank_of(id)
		var new_name: String = GameData.rank_name(id, new_lv)
		var parts: Array = []
		if old_lv <= 0:
			parts = ["%s%s " % [nm, _ig(nm)], _rank_tag(id, 24, new_lv), " 칭호를 얻었어요!"]
		else:
			parts = ["%s의 칭호가 " % nm, _rank_tag(id, 24, old_lv), "에서 ", _rank_tag(id, 24, new_lv), "%s 되었어요!" % _ig(new_name)]
		overlay_extra.add_child(_inline_row(parts))
	if got.get("special", "") != "":
		overlay_extra.add_child(_inline_row(["스페셜 칭호 ", _special_tag(got["special"], 24), " 획득!"]))
	for gname in got.get("groups", []):
		overlay_extra.add_child(_inline_row(["단체 칭호 ", _group_tag(gname, 24), " 달성!"]))
	if overlay_extra.get_child_count() > 0:
		overlay_extra.show()
	confirm_button.show()
	if won:
		celebration.play("", "", get_viewport_rect().size / 2 - celebration.global_position)   # 글자 없이 폭죽만


## 글씨와 꼬리표를 한 줄에 (가운데 정렬)
func _inline_row(parts: Array) -> Control:
	var row := HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("h_separation", 0)
	row.add_theme_constant_override("v_separation", 8)
	row.custom_minimum_size = Vector2(560, 0)
	row.mouse_filter = MOUSE_FILTER_IGNORE
	for p in parts:
		if p is String:
			var l := _label(p, 26)
			l.mouse_filter = MOUSE_FILTER_IGNORE
			row.add_child(l)
		elif p is Control:
			row.add_child(p)
	return row


## 대전 결과 그림 밑 작은 상태: 칭호 + 막대 + "20/170 (+10)"
func _mini_stat(id: String, gain: int) -> Control:
	var rp: Dictionary = GameState.rank_progress(id)
	var lv := int(rp["lv"])
	var col: Color = GameData.rank_bar_color(id, lv)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(220, 0)
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = MOUSE_FILTER_IGNORE
	var tag := _rank_tag(id, 18)
	if tag:
		var c := CenterContainer.new()
		c.mouse_filter = MOUSE_FILTER_IGNORE
		c.add_child(tag)
		box.add_child(c)
	else:
		var none := _label("칭호 없음", 18)
		none.add_theme_color_override("font_color", SUB_COLOR)
		box.add_child(none)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(170, 10)
	bar.size_flags_horizontal = SIZE_SHRINK_CENTER
	bar.mouse_filter = MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", _box(_bar_bg(col, lv), 6))
	bar.add_theme_stylebox_override("fill", _box(col.darkened(0.05), 6))
	var num: Label
	if int(rp["next"]) < 0:
		bar.max_value = 1
		bar.value = 1
		num = _label("최고 칭호 (+%d)" % gain, 18)
	else:
		bar.max_value = int(rp["next"]) - int(rp["prev"])
		bar.value = int(rp["exp"]) - int(rp["prev"])
		num = _label("%d/%d (+%d)" % [int(rp["exp"]) - int(rp["prev"]), int(rp["next"]) - int(rp["prev"]), gain], 18)
	num.add_theme_color_override("font_color", SUB_COLOR)
	box.add_child(bar)
	box.add_child(num)
	return box


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
	# 그림 두 장 나란히 (대전 결과에서 둘이 같이)
	var pics := HBoxContainer.new()
	pics.alignment = BoxContainer.ALIGNMENT_CENTER
	pics.add_theme_constant_override("separation", 10)
	v.add_child(pics)
	pics.add_child(overlay_image)
	overlay_image2 = TextureRect.new()
	overlay_image2.custom_minimum_size = Vector2(220, 220)
	overlay_image2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay_image2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	overlay_image2.hide()
	pics.add_child(overlay_image2)
	overlay_image3 = TextureRect.new()   # 이야기 장면: 최대 3마리
	overlay_image3.custom_minimum_size = Vector2(220, 220)
	overlay_image3.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay_image3.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	overlay_image3.hide()
	pics.add_child(overlay_image3)
	for img in [overlay_image, overlay_image2, overlay_image3]:
		var tears := Control.new()      # ㅠㅠ 눈물 (필요할 때만)
		tears.mouse_filter = MOUSE_FILTER_IGNORE
		tears.set_anchors_preset(PRESET_FULL_RECT)
		tears.draw.connect(_draw_tears.bind(tears))
		tears.hide()
		img.add_child(tears)
		_tear_marks.append(tears)
		# 화남 표시 💢 (그림 오른쪽 위, 필요할 때만)
		var anger := Control.new()
		anger.mouse_filter = MOUSE_FILTER_IGNORE
		anger.set_anchors_preset(PRESET_FULL_RECT)
		anger.draw.connect(func() -> void:
			var sz := anger.size
			_draw_anger(anger, Vector2(sz.x * 0.8, sz.y * 0.2), minf(sz.x, sz.y) * 0.1))
		anger.hide()
		img.add_child(anger)
		_anger_marks.append(anger)
	_anger_mark = _anger_marks[0]
	_glow = Control.new()   # 그림 뒤에서 빙글빙글 도는 빛 (두루마리 장면)
	_glow.mouse_filter = MOUSE_FILTER_IGNORE
	_glow.set_anchors_preset(PRESET_FULL_RECT)
	_glow.show_behind_parent = true
	_glow.draw.connect(_draw_glow)
	_glow.hide()
	overlay_image.add_child(_glow)
	overlay_stats = HBoxContainer.new()
	overlay_stats.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay_stats.add_theme_constant_override("separation", 10)
	overlay_stats.hide()
	v.add_child(overlay_stats)
	overlay_log = _label("", 28)
	overlay_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_log.custom_minimum_size = Vector2(560, 120)
	overlay_log.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	v.add_child(overlay_log)

	drops_box = HBoxContainer.new()
	drops_box.alignment = BoxContainer.ALIGNMENT_CENTER
	drops_box.add_theme_constant_override("separation", 4)
	v.add_child(drops_box)

	overlay_extra = VBoxContainer.new()   # 그때그때 덧붙이는 칸 (도감: 칭호·전공)
	overlay_extra.hide()
	v.add_child(overlay_extra)

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
	_fat_scrollbar(scroll)   # 넘치면 오른쪽에 잡기 쉬운 굵은 막대
	outer.add_child(scroll)
	# 오른쪽에 스크롤 막대 자리를 비워 둠 (막대가 버튼을 가리지 않게)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_right", int(REL_BAR_W) + 10)
	scroll.add_child(pad)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	pad.add_child(list)
	_drag_scroll(scroll, pad)
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
	card.mouse_filter = MOUSE_FILTER_PASS   # 카드 위에서 끌어도 목록이 스크롤되게
	var sb := _box(Color(0.97, 0.93, 0.86), 18)
	sb.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	card.add_child(h)
	return card


func _open_overlay(title: String, text: String, mode: String) -> void:
	_stop_glow()
	_overlay_mode = mode
	overlay_title.text = title
	overlay_log.text = text
	overlay_log.show()
	overlay_image.hide()
	overlay_image2.hide()
	overlay_image3.hide()
	for img in [overlay_image, overlay_image2, overlay_image3]:
		img.custom_minimum_size = Vector2(220, 220)
		img.material = null
	for t in _tear_marks + _anger_marks:
		t.hide()
	overlay_image.scale = Vector2.ONE
	overlay_image.rotation = 0.0
	strategy_box.hide()
	confirm_button.hide()
	confirm_button.text = "확인"
	for key in ["normal", "hover", "pressed"]:
		confirm_button.remove_theme_stylebox_override(key)
	cancel_button.hide()
	cancel_button.text = "취소"
	drops_box.hide()
	drops_box.add_theme_constant_override("separation", 4)
	for c in drops_box.get_children():
		c.queue_free()
	overlay_extra.hide()
	for c in overlay_extra.get_children():
		c.queue_free()
	overlay_stats.hide()
	for c in overlay_stats.get_children():
		c.queue_free()
	overlay_log.custom_minimum_size = Vector2(560, 120)
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
		"breakup_confirm":
			_do_breakup()
			return
		"mini_end":
			_show_mini()
			return
		"forfeit":
			_show_mini()
			return
		"btut_end":
			GameState.battle_tut_done = true
			GameState.save_now()
			_btut_step = -1
			_show_mini()
			return
		"gift":
			_set_busy(false)
			if _story_check() or _btut_check():
				return
		"story":
			_story_next()
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


const REL_BAR_W := 20.0       # 스크롤 막대 굵기


## 스크롤 막대: 넘칠 때만 보이고, 손가락으로 잡기 쉽게 굵게 (웹/폰에서 터치 스크롤이 안 될 때 대비)
func _fat_scrollbar(sc: ScrollContainer) -> void:
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var bar := sc.get_v_scroll_bar()
	bar.custom_minimum_size.x = REL_BAR_W
	var track := _box(Color(0.55, 0.42, 0.32, 0.18), 10)
	track.set_content_margin_all(0)
	bar.add_theme_stylebox_override("scroll", track)
	bar.add_theme_stylebox_override("scroll_focus", track)
	for st in ["grabber", "grabber_highlight", "grabber_pressed"]:
		var g := _box(PINK if st == "grabber_pressed" else Color(0.86, 0.52, 0.32, 0.9), 10)
		g.set_content_margin_all(0)
		g.content_margin_top = 18      # 막대 손잡이 최소 길이
		g.content_margin_bottom = 18
		bar.add_theme_stylebox_override(st, g)


## 손가락으로 끌어서 스크롤 (엔진 기본 터치 스크롤이 웹에서 안 먹을 때 대비). 버튼 위가 아닌 곳을 끌면 됨
func _drag_scroll(sc: ScrollContainer, content: Control) -> void:
	content.mouse_filter = MOUSE_FILTER_PASS
	var st := {"from": Vector2.INF, "at": 0}
	content.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			st["from"] = e.global_position if e.pressed else Vector2.INF
			st["at"] = sc.scroll_vertical
		elif e is InputEventMouseMotion and st["from"] != Vector2.INF and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			sc.scroll_vertical = int(st["at"]) - int(e.global_position.y - (st["from"] as Vector2).y)
			content.accept_event())


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
func _jelly(c: Control, k := JELLY) -> void:
	if not is_instance_valid(c):
		return
	c.pivot_offset = c.size / 2
	if c.has_meta("jelly"):              # 연타하면 앞의 출렁임은 끊고 새로
		var old: Tween = c.get_meta("jelly")
		if old and old.is_valid():
			old.kill()
	var tw := c.create_tween()
	c.set_meta("jelly", tw)
	# 출렁임 세기: k(기본 JELLY) 를 키우면 더 보잉, 줄이면 더 얌전
	tw.tween_property(c, "scale", Vector2(1.0 + 0.12 * k, 1.0 - 0.14 * k), 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "scale", Vector2(1.0 - 0.06 * k, 1.0 + 0.07 * k), 0.08).set_trans(Tween.TRANS_SINE)
	tw.tween_property(c, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
