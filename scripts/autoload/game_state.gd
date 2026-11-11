extends Node
## 저장되는 전체 진행 상황: 데리고 있는 멍냥이, 뽑기권, 호감도, 커플, 희귀템 가방
## 웹에서는 user:// 가 브라우저 IndexedDB에 저장돼서 새로고침해도 유지됨
## 저장 방식은 아래 "저장 / 불러오기" 설명 참고

const SAVE_PATH := "user://save.json"

var owned: Array[String] = []     # 데리고 있는 멍냥이 (= 도감에 모은 멍냥이)
var tickets := 0                  # 뽑기권
var start_bonus := false          # 처음 뽑기권(STARTING_TICKETS)을 이미 받았는지
var tutorial_done := false        # 처음 튜토리얼을 끝냈는지 (새 게임 / 초기화 후엔 false)
var rewarded: Dictionary = {}     # dog_id -> true (어른 선물 이미 받음)
var current := ""                 # 홈 화면에 나와 있는 멍냥이
var progress: Dictionary = {}     # dog_id -> Puppy
var affinity: Dictionary = {}     # "a|b" (이름순) -> 0 ~ AFFINITY_MAX
var couples: Dictionary = {}      # dog_id -> Array[String] 애인 목록 (양쪽 다 기록)
var gifts: Dictionary = {}        # "a|b" -> 천도복숭아 선물 횟수 0 ~ GIFT_MAX
var sworn: Dictionary = {}        # dog_id -> Array[String] 의형제 (양쪽 다 기록, 최대 SWORN_MAX)
var items: Dictionary = {}        # item_id -> 개수 (희귀템 가방, 모든 멍냥이 공용)
var luck := 0                     # 네잎클로버 효과 남은 전투·책략 횟수
var sulky: Dictionary = {}        # "a|b" -> 토라진 멍냥이 id (헤어진 뒤, 클로버로 달래야 함)
var clover_gifts: Dictionary = {} # "a|b" -> 화해용 클로버 받은 개수 (토라짐 / 앙숙)
var made_up: Dictionary = {}      # "a|b" -> true  클로버로 화해한 앙숙 (기본 관계로 돌아감)
var mini_cleared := 0             # 계책 대전에서 깬 가장 높은 단계 (0 = 아직, 다음 단계가 열림)
var battle_exp: Dictionary = {}   # dog_id -> 전공 (대전할수록 쌓임 → 칭호)
var stories: Dictionary = {}      # dog_id -> true  본 이야기 (도감에서 다시 보기)
var defected: Dictionary = {}     # dog_id -> true  진영을 옮김 (하후패 → 촉, 사마의 → 진)
var pair_wins: Dictionary = {}    # "a|b" -> 함께 이긴 횟수 (스페셜 칭호용)
var sp_paid: Dictionary = {}       # 공훈패를 내고 연 스페셜 이야기 (끝까지 봐야 stories 에 들어감)
var merits := 0                   # 공훈패 (대전에서 이기면 받음 → 스페셜 이야기 열기)
var battle_tut_done := false      # 대전 튜토리얼을 봤는지 (보기 전엔 홈의 대전 버튼이 잠김)


func _ready() -> void:
	_setup_timers()
	load_game()
	if owned.is_empty():
		for id in GameData.STARTERS:
			owned.append(id)
	if current == "" or not owns(current):
		current = owned[0]
	if not start_bonus and tutorial_done:   # 예전 세이브: 처음 뽑기권을 한 번 챙겨 줌 (새 게임은 튜토리얼에서 줌)
		give_start_bonus()


## 처음 뽑기권 (딱 한 번). 받았으면 true
func give_start_bonus() -> bool:
	if start_bonus:
		return false
	start_bonus = true
	tickets += GameData.STARTING_TICKETS
	save_now()
	return true


# ── 데리고 있는 멍냥이 ──
func owns(dog_id: String) -> bool:
	return owned.has(dog_id)


func get_puppy(dog_id: String) -> Puppy:
	if not progress.has(dog_id):
		progress[dog_id] = Puppy.new(dog_id)
	return progress[dog_id]


func stage_of(dog_id: String) -> int:
	return (progress[dog_id] as Puppy).stage if progress.has(dog_id) else 0


func owned_in(faction: String) -> Array[String]:
	var list: Array[String] = []
	for id in GameData.DOGS:
		if owns(id) and GameData.faction_of(id) == faction:
			list.append(id)
	return list


# ── 이야기 ──
func story_seen(dog_id: String) -> bool:
	return stories.has(dog_id)


func mark_story(dog_id: String) -> void:
	stories[dog_id] = true
	save_now()


# ── 진영 옮기기 ──
func has_defected(dog_id: String) -> bool:
	return defected.has(dog_id)


func defect(dog_id: String) -> void:
	defected[dog_id] = true
	save_now()


## 도감 전체 수 (진이 안 열렸으면 진 멍냥이는 빼고)
func dex_total() -> int:
	var n := 0
	for id in GameData.DOGS:
		if GameData.available(id):
			n += 1
	return n


# ── 뽑기 ──
func unowned() -> Array[String]:
	var list: Array[String] = []
	for id in GameData.DOGS:
		if not owns(id) and GameData.available(id):   # 진 멍냥이는 진이 열린 뒤에만
			list.append(id)
	return list


## 뽑기권 1장 써서 아직 없는 멍냥이 중 하나를 똑같은 확률로. 못 뽑으면 ""
func draw_gacha() -> String:
	var pool := unowned()
	if tickets <= 0 or pool.is_empty():
		return ""
	tickets -= 1
	var id: String = pool.pick_random()
	owned.append(id)
	save_now()
	return id


## 어른이 됐을 때 선물(뽑기권). 이미 받았으면 0
func grant_adult_reward(dog_id: String) -> int:
	if rewarded.has(dog_id):
		return 0
	rewarded[dog_id] = true
	tickets += GameData.ADULT_TICKETS
	save_now()
	return GameData.ADULT_TICKETS


# ── 호감도 / 커플 ──
func _pair_key(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a


func affinity_of(a: String, b: String) -> int:
	return int(affinity.get(_pair_key(a, b), 0))


## 같이 놀기. 오르면 true
func play_together(a: String, b: String) -> bool:
	if GameData.is_rival(a, b) or is_sulky(a, b) or affinity_of(a, b) >= GameData.affinity_max(a, b):
		return false
	var chance: float = GameData.PLAY_CHANCE_SAME if GameData.same_faction(a, b) else GameData.PLAY_CHANCE_OTHER
	if randf() >= chance:
		return false
	affinity[_pair_key(a, b)] = affinity_of(a, b) + 1
	save_game()
	return true


## 고백 실패: 하트가 처음부터
func reset_affinity(a: String, b: String) -> void:
	affinity.erase(_pair_key(a, b))
	save_now()


func partners(dog_id: String) -> Array:
	return couples.get(dog_id, [])


func is_couple(a: String, b: String) -> bool:
	return partners(a).has(b)


## 주군은 애인 여러 명 OK, 나머지는 1명만
func can_take_partner(dog_id: String) -> bool:
	return GameData.is_lord(dog_id) or partners(dog_id).is_empty()


func add_couple(a: String, b: String) -> void:
	for pair in [[a, b], [b, a]]:
		var list: Array = couples.get(pair[0], [])
		if not list.has(pair[1]):
			list.append(pair[1])
		couples[pair[0]] = list
	save_now()


# ── 계책 대전 ──
## 칭호 글자 (없으면 "")
func title_of(dog_id: String) -> String:
	return GameData.rank_name(dog_id, rank_of(dog_id))


## 칭호 진행: {"exp", "lv", "max", "prev" (지금 칭호 기준 전공), "next" (다음 칭호 전공, 최고면 -1)}
func rank_progress(dog_id: String) -> Dictionary:
	var e := int(battle_exp.get(dog_id, 0))
	var lv := rank_of(dog_id)
	var top := GameData.rank_max(dog_id)
	return {"exp": e, "lv": lv, "max": top,
		"prev": GameData.RANK_EXP[lv - 1] if lv > 0 else 0,
		"next": GameData.RANK_EXP[lv] if lv < top else -1}


## 단체 칭호: 조건을 채운 멤버 수
func group_count(g: Dictionary) -> int:
	var n := 0
	for m in g["members"]:
		if owns(m) and rank_of(m) >= GameData.GROUP_RANK:
			n += 1
	return n


func group_done(g: Dictionary) -> bool:
	return group_count(g) >= (g["members"] as Array).size()


## 이 멍냥이가 받은 단체 칭호 이름들
func groups_done_of(dog_id: String) -> Array:
	var out: Array = []
	for g in GameData.groups_of(dog_id):
		if group_done(g):
			out.append(g["name"])
	return out


## 이 멍냥이가 받은 스페셜 칭호 이름들
func specials_of(dog_id: String) -> Array:
	var out: Array = []
	for sp in GameData.SPECIAL_TITLES:
		if (sp["a"] == dog_id or sp["b"] == dog_id) and pair_win_count(sp["a"], sp["b"]) >= int(sp["wins"]):
			out.append(sp["name"])
	return out


func pair_win_count(a: String, b: String) -> int:
	return int(pair_wins.get(_pair_key(a, b), 0))


## 대전 열림 조건: 어른 무장 1 + 어른 책사 1 이 있음
func battle_ready() -> bool:
	var war := false
	var strat := false
	for id in owned:
		if get_puppy(id).is_adult():
			if GameData.is_strategist(id):
				strat = true
			else:
				war = true
	return war and strat


func rank_of(dog_id: String) -> int:
	return GameData.rank_level(dog_id, int(battle_exp.get(dog_id, 0)))


## 대전 끝: 둘 다 전공 + (이기면) 보상.
## {"won", "first", "reward", "n", "exp", "ranked": [칭호 오른 id]}
func mini_result(won: bool, stage_i: int, war: String, strat: String) -> Dictionary:
	var out := {"won": won, "first": false, "reward": "", "n": 0, "ranked": [], "special": "", "before": {}, "merit": 0, "drops": {}}
	var gain := GameData.MINI_EXP_LOSE
	if won:
		var lv := stage_i + 1
		out["first"] = lv > mini_cleared
		# 처음 깼을 때만 단계 보너스
		if out["first"]:
			var reward: String = GameData.MINI_STAGES[stage_i]["reward"]
			var n: int = int(GameData.MINI_STAGES[stage_i]["n"])
			if reward == "ticket":
				tickets += n
			else:
				items[reward] = item_count(reward) + n
			out["reward"] = reward
			out["n"] = n
		# 보상 뽑기 (어려운 단계일수록 많이 뽑음)
		var drops: Dictionary = out["drops"]
		for i in int(GameData.MINI_STAGES[stage_i].get("rolls", 1)):
			var got: String = GameData.roll_weighted(GameData.MINI_DROP)
			drops[got] = int(drops.get(got, 0)) + 1
			if got == "ticket":
				tickets += 1
			else:
				items[got] = item_count(got) + 1
		mini_cleared = maxi(mini_cleared, lv)
		out["merit"] = int(GameData.MINI_STAGES[stage_i].get("merit", 1))
		merits += int(out["merit"])
		gain = int(GameData.MINI_STAGES[stage_i].get("exp", GameData.MINI_EXP_WIN_BASE + GameData.MINI_EXP_WIN_STEP * lv))
		# 함께 이긴 횟수 → 스페셜 칭호
		var key := _pair_key(war, strat)
		pair_wins[key] = int(pair_wins.get(key, 0)) + 1
		var sp: Dictionary = GameData.special_for(war, strat)
		if not sp.is_empty() and int(pair_wins[key]) == int(sp["wins"]):
			out["special"] = sp["name"]
	out["exp"] = gain
	var groups_before: Array = groups_done_of(war) + groups_done_of(strat)
	for id in [war, strat]:
		var before := rank_of(id)
		(out["before"] as Dictionary)[id] = before
		battle_exp[id] = int(battle_exp.get(id, 0)) + gain
		if rank_of(id) > before:
			(out["ranked"] as Array).append(id)
	# 이번 판으로 새로 완성된 단체 칭호
	var new_groups: Array = []
	for name_ in groups_done_of(war) + groups_done_of(strat):
		if not groups_before.has(name_) and not new_groups.has(name_):
			new_groups.append(name_)
	out["groups"] = new_groups
	save_now()
	return out


# ── 헤어지기 / 토라짐 / 클로버 화해 ──
func is_sulky(a: String, b: String) -> bool:
	return sulky.has(_pair_key(a, b))


## 토라진 쪽 id (없으면 "")
func sulker(a: String, b: String) -> String:
	return str(sulky.get(_pair_key(a, b), ""))


func is_made_up(a: String, b: String) -> bool:
	return made_up.has(_pair_key(a, b))


func clover_count(a: String, b: String) -> int:
	return int(clover_gifts.get(_pair_key(a, b), 0))


## me 가 other 와 헤어짐 → other 가 토라짐. 하트도 처음부터
func break_up(me: String, other: String) -> void:
	for pair in [[me, other], [other, me]]:
		var list: Array = couples.get(pair[0], [])
		list.erase(pair[1])
		if list.is_empty():
			couples.erase(pair[0])
		else:
			couples[pair[0]] = list
	var key := _pair_key(me, other)
	affinity.erase(key)
	sulky[key] = other
	clover_gifts.erase(key)
	save_now()


## 화해용 클로버 하나 주기. 다 채우면 화해 → "done", 하나 줬으면 "gave", 못 주면 ""
func give_clover(a: String, b: String) -> String:
	if item_count("clover") <= 0 or not (is_sulky(a, b) or GameData.is_rival(a, b)):
		return ""
	items["clover"] = item_count("clover") - 1
	var key := _pair_key(a, b)
	var n := clover_count(a, b) + 1
	if n < GameData.MAKEUP_CLOVERS:
		clover_gifts[key] = n
		save_now()
		return "gave"
	clover_gifts.erase(key)
	if sulky.has(key):
		sulky.erase(key)
	else:
		made_up[key] = true
	save_now()
	return "done"


# ── 선물 / 의형제 ──
func gift_count(a: String, b: String) -> int:
	return int(gifts.get(_pair_key(a, b), 0))


## 천도복숭아 하나를 선물. 가방에서 빠지고 선물 횟수 +1
## 선물할 수 있는 복숭아 (천도 + 황금)
func peach_total() -> int:
	return item_count("peach") + item_count("golden_peach")


var last_gift := "peach"   # 방금 선물한 복숭아 종류 (천도복숭아 먼저, 없으면 황금복숭아)


func give_peach(a: String, b: String) -> bool:
	if GameData.is_rival(a, b) or is_sulky(a, b) or gift_count(a, b) >= GameData.gift_max(a, b) or peach_total() <= 0:
		return false
	last_gift = "peach" if item_count("peach") > 0 else "golden_peach"
	items[last_gift] = item_count(last_gift) - 1
	gifts[_pair_key(a, b)] = gift_count(a, b) + 1
	save_now()
	return true


## 의형제 실패: 복숭아가 처음부터
func reset_gifts(a: String, b: String) -> void:
	gifts.erase(_pair_key(a, b))
	save_now()


func sworn_of(dog_id: String) -> Array:
	return sworn.get(dog_id, [])


func is_sworn(a: String, b: String) -> bool:
	return sworn_of(a).has(b)


func can_take_sworn(dog_id: String) -> bool:
	return sworn_of(dog_id).size() < GameData.SWORN_MAX


func add_sworn(a: String, b: String) -> void:
	for pair in [[a, b], [b, a]]:
		var list: Array = sworn.get(pair[0], [])
		if not list.has(pair[1]):
			list.append(pair[1])
		sworn[pair[0]] = list
	save_now()


# ── 희귀템 가방 ──
func item_count(item_id: String) -> int:
	return int(items.get(item_id, 0))


func add_item(item_id: String) -> void:
	items[item_id] = item_count(item_id) + 1
	save_game()


func take_item(item_id: String) -> bool:
	if item_count(item_id) <= 0:
		return false
	items[item_id] = item_count(item_id) - 1
	save_game()
	return true


# ── 저장 / 불러오기 ──
## 튼튼한 저장:
##  1) 임시 파일(save.json.tmp)에 다 쓴 다음 이름을 바꿔서 교체 → 쓰다가 꺼져도 원래 파일은 멀쩡
##  2) 바로 전 저장본을 save.json.bak 으로 남겨 둠 → 본 파일이 깨져도 백업에서 복구
##  3) 불러올 때 값 하나하나 검사 (없는 멍냥이·음수·이상한 값은 버리거나 고침) → 세이브 때문에 튕기지 않음
##  4) 자주 누르는 행동(밥·쓰다듬기)은 모아서 잠깐 뒤에 한 번만 저장, 중요한 순간(뽑기·선물·커플)·종료 때는 바로 저장
const SAVE_VERSION := 3
const TMP_PATH := SAVE_PATH + ".tmp"
const BAK_PATH := SAVE_PATH + ".bak"
const CORRUPT_PATH := "user://save.corrupt.json"
const SAVE_DELAY := 0.5        # 마지막 변경 후 이만큼 지나면 저장
const AUTOSAVE_EVERY := 15.0   # 혹시 몰라 주기적으로도 저장

var _dirty := false
var _save_timer: Timer
var _loaded_from := ""         # 디버그용: "main" / "tmp" / "backup" / "new"


func _setup_timers() -> void:
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = SAVE_DELAY
	_save_timer.timeout.connect(save_now)
	add_child(_save_timer)
	var auto := Timer.new()
	auto.wait_time = AUTOSAVE_EVERY
	auto.autostart = true
	auto.timeout.connect(func() -> void:
		if _dirty:
			save_now())
	add_child(auto)


const _SAVE_NOW_ON := [
	NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT,
	NOTIFICATION_WM_GO_BACK_REQUEST, NOTIFICATION_PREDELETE,
]


func _notification(what: int) -> void:
	# 창 닫기 / 모바일 백그라운드 / 웹 탭 전환 / 종료 → 바로 저장
	if what in _SAVE_NOW_ON and _dirty:
		save_now()


## 저장 요청 (잠깐 모았다가 한 번에). 대부분 이걸 쓰면 됨
func save_game() -> void:
	_dirty = true
	if _save_timer and _save_timer.is_inside_tree():
		_save_timer.start()
	else:
		save_now()


## 지금 바로 저장. 성공하면 true
func save_now() -> bool:
	if _save_timer:
		_save_timer.stop()
	var prog := {}
	for id in progress:
		prog[id] = (progress[id] as Puppy).to_dict()
	var data := {
		"version": SAVE_VERSION,
		"saved_at": Time.get_unix_time_from_system(),
		"owned": owned,
		"tickets": tickets,
		"start_bonus": start_bonus,
		"tutorial_done": tutorial_done,
		"rewarded": rewarded.keys(),
		"current": current,
		"progress": prog,
		"affinity": affinity,
		"couples": couples,
		"gifts": gifts,
		"sworn": sworn,
		"items": items,
		"luck": luck,
		"sulky": sulky,
		"clover_gifts": clover_gifts,
		"made_up": made_up.keys(),
		"mini_cleared": mini_cleared,
		"merits": merits,
		"sp_paid": sp_paid.keys(),
		"battle_exp": battle_exp,
		"battle_tut_done": battle_tut_done,
		"pair_wins": pair_wins,
		"defected": defected.keys(),
		"stories": stories.keys(),
	}
	var text := JSON.stringify(data)
	# 1) 임시 파일에 쓰기
	var f := FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("저장 실패(임시 파일 열기): %s" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(text)
	f.flush()
	var write_err := f.get_error()
	f.close()
	if write_err != OK or not _read_ok(TMP_PATH):
		push_warning("저장 실패(쓰기 확인): %s" % error_string(write_err))
		return false
	# 2) 지금 저장본 → 백업, 임시 → 저장본
	var dir := DirAccess.open("user://")
	if dir == null:
		push_warning("저장 실패(폴더 열기)")
		return false
	if dir.file_exists(SAVE_PATH.get_file()):
		if dir.file_exists(BAK_PATH.get_file()):
			dir.remove(BAK_PATH.get_file())
		dir.rename(SAVE_PATH.get_file(), BAK_PATH.get_file())
	var err := dir.rename(TMP_PATH.get_file(), SAVE_PATH.get_file())
	if err != OK:
		# 이름 바꾸기가 안 되는 환경이면 직접 덮어쓰기
		var g := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if g == null:
			push_warning("저장 실패(본 파일): %s" % error_string(FileAccess.get_open_error()))
			return false
		g.store_string(text)
		g.close()
	_dirty = false
	return true


## 파일이 읽히고 JSON 딕셔너리로 풀리는지
func _read_ok(path: String) -> bool:
	return _read_json(path) is Dictionary


func _read_json(path: String):
	if not FileAccess.file_exists(path):
		return null
	var raw := FileAccess.get_file_as_string(path)
	if raw.strip_edges() == "":
		return null
	var parsed = JSON.parse_string(raw)
	return parsed if parsed is Dictionary else null


func load_game() -> void:
	var data = null
	# 본 파일 → (저장 도중 꺼졌을 때 남는) 다 쓴 임시 파일 → 바로 전 백업 순서로 시도
	for pair in [[SAVE_PATH, "main"], [TMP_PATH, "tmp"], [BAK_PATH, "backup"]]:
		data = _read_json(pair[0])
		if data != null:
			_loaded_from = pair[1]
			break
		if pair[0] == SAVE_PATH and FileAccess.file_exists(SAVE_PATH):
			# 깨진 본 파일은 지우지 않고 따로 보관 (원인 확인용)
			var dir := DirAccess.open("user://")
			if dir:
				if dir.file_exists(CORRUPT_PATH.get_file()):
					dir.remove(CORRUPT_PATH.get_file())
				dir.copy(SAVE_PATH, CORRUPT_PATH)
			push_warning("세이브 파일이 깨져서 백업에서 불러옵니다")
	if data == null:
		_loaded_from = "new"
		return
	_apply(data)
	print("[세이브] 불러옴: %s (멍냥이 %d마리, 뽑기권 %d)" % [_loaded_from, owned.size(), tickets])
	if _loaded_from != "main":
		save_game()   # 복구했으면 바로 정상 파일로 다시 저장


## 읽은 데이터를 검사하면서 적용 (이상한 값은 버리거나 고침)
func _apply(d: Dictionary) -> void:
	progress.clear()
	var prog = d.get("progress", {})
	if prog is Dictionary:
		for id in prog:
			var key := str(id)
			if GameData.DOGS.has(key) and prog[id] is Dictionary:
				progress[key] = Puppy.from_dict(prog[id], key)

	owned.clear()
	rewarded.clear()
	tickets = 0
	if d.has("owned"):
		for id in _arr(d.get("owned")):
			var key := str(id)
			if GameData.DOGS.has(key) and not owned.has(key):
				owned.append(key)
		for id in _arr(d.get("rewarded")):
			if GameData.DOGS.has(str(id)):
				rewarded[str(id)] = true
		tickets = _int(d.get("tickets"), 0)
	else:
		# 예전 세이브(진영 해금 방식): 키우던 애들은 그대로, 어른까지 키운 애들은 뽑기권 2장씩
		for id in progress:
			owned.append(id)
		for id in _arr(d.get("dex")):
			if GameData.DOGS.has(str(id)) and not rewarded.has(str(id)):
				rewarded[str(id)] = true
				tickets += GameData.ADULT_TICKETS
	for id in GameData.STARTERS:   # 주군 셋은 항상
		if not owned.has(id):
			owned.append(id)
	tickets = clampi(tickets, 0, 999)
	start_bonus = d.get("start_bonus", false) == true
	tutorial_done = d.get("tutorial_done", true) == true   # 튜토리얼 생기기 전 세이브는 이미 한 걸로
	current = str(d.get("current", ""))

	affinity.clear()
	var aff = d.get("affinity", {})
	if aff is Dictionary:
		for k in aff:
			var parts := str(k).split("|")
			if parts.size() == 2 and GameData.DOGS.has(parts[0]) and GameData.DOGS.has(parts[1]) and parts[0] != parts[1]:
				affinity[_pair_key(parts[0], parts[1])] = clampi(_int(aff[k], 0), 0, GameData.affinity_max(parts[0], parts[1]))

	# 진영 옮긴 기록 (주군·앙숙 판정에 쓰여서 맨 먼저)
	stories.clear()
	for k in _arr(d.get("stories", [])):
		if GameData.DOGS.has(str(k)):
			stories[str(k)] = true
	defected.clear()
	for k in _arr(d.get("defected", [])):
		if GameData.DEFECTORS.has(str(k)):
			defected[str(k)] = true
	# 클로버 화해 (앙숙 판정에 쓰여서 커플보다 먼저)
	made_up.clear()
	for k in _arr(d.get("made_up", [])):
		var parts := str(k).split("|")
		if parts.size() == 2 and GameData.DOGS.has(parts[0]) and GameData.DOGS.has(parts[1]) and parts[0] != parts[1]:
			made_up[_pair_key(parts[0], parts[1])] = true
	sulky.clear()
	var sk = d.get("sulky", {})
	if sk is Dictionary:
		for k in sk:
			var parts := str(k).split("|")
			var who := str(sk[k])
			if parts.size() == 2 and GameData.DOGS.has(parts[0]) and GameData.DOGS.has(parts[1]) and parts[0] != parts[1] and who in parts:
				sulky[_pair_key(parts[0], parts[1])] = who
	clover_gifts.clear()
	var cg = d.get("clover_gifts", {})
	if cg is Dictionary:
		for k in cg:
			var parts := str(k).split("|")
			if parts.size() == 2 and GameData.DOGS.has(parts[0]) and GameData.DOGS.has(parts[1]) and parts[0] != parts[1]:
				var n := clampi(_int(cg[k], 0), 0, GameData.MAKEUP_CLOVERS - 1)
				if n > 0:
					clover_gifts[_pair_key(parts[0], parts[1])] = n

	couples.clear()
	var cp = d.get("couples", {})
	if cp is Dictionary:
		for id in cp:
			for other in _arr(cp[id]):
				var a := str(id)
				var b := str(other)
				if a == b or not GameData.DOGS.has(a) or not GameData.DOGS.has(b) or is_couple(a, b):
					continue
				if GameData.is_rival(a, b) or GameData.is_family(a, b) or is_sulky(a, b) or not can_take_partner(a) or not can_take_partner(b):
					continue
				for pair in [[a, b], [b, a]]:
					var list: Array = couples.get(pair[0], [])
					list.append(pair[1])
					couples[pair[0]] = list

	gifts.clear()
	var gf = d.get("gifts", {})
	if gf is Dictionary:
		for k in gf:
			var parts := str(k).split("|")
			if parts.size() == 2 and GameData.DOGS.has(parts[0]) and GameData.DOGS.has(parts[1]) and parts[0] != parts[1]:
				gifts[_pair_key(parts[0], parts[1])] = clampi(_int(gf[k], 0), 0, GameData.gift_max(parts[0], parts[1]))

	sworn.clear()
	var sw = d.get("sworn", {})
	if sw is Dictionary:
		for id in sw:
			for other in _arr(sw[id]):
				var a := str(id)
				var b := str(other)
				if a == b or not GameData.DOGS.has(a) or not GameData.DOGS.has(b) or is_sworn(a, b):
					continue
				if GameData.is_rival(a, b) or not can_take_sworn(a) or not can_take_sworn(b):
					continue
				for pair in [[a, b], [b, a]]:
					var list: Array = sworn.get(pair[0], [])
					list.append(pair[1])
					sworn[pair[0]] = list

	luck = clampi(_int(d.get("luck"), 0), 0, 999)
	mini_cleared = clampi(_int(d.get("mini_cleared"), 0), 0, GameData.MINI_STAGES.size())
	merits = clampi(_int(d.get("merits"), 0), 0, 99999)
	sp_paid.clear()
	var spp = d.get("sp_paid", [])
	if spp is Array:
		for k in spp:
			sp_paid[str(k)] = true
	battle_tut_done = d.get("battle_tut_done", false) == true
	pair_wins.clear()
	var pw = d.get("pair_wins", {})
	if pw is Dictionary:
		for k in pw:
			var parts := str(k).split("|")
			if parts.size() == 2 and GameData.DOGS.has(parts[0]) and GameData.DOGS.has(parts[1]) and parts[0] != parts[1]:
				var n := clampi(_int(pw[k], 0), 0, 99999)
				if n > 0:
					pair_wins[_pair_key(parts[0], parts[1])] = n
	battle_exp.clear()
	var be = d.get("battle_exp", {})
	if be is Dictionary:
		for k in be:
			if GameData.DOGS.has(str(k)):
				var e := clampi(_int(be[k], 0), 0, 999999)
				if e > 0:
					battle_exp[str(k)] = e
	items.clear()
	var it = d.get("items", {})
	if it is Dictionary:
		for k in it:
			if GameData.ITEMS.has(str(k)):
				var n := clampi(_int(it[k], 0), 0, 999)
				if n > 0:
					items[str(k)] = n


static func _arr(v) -> Array:
	return v if v is Array else []


## 숫자가 아니면 기본값
static func _int(v, fallback: int) -> int:
	if v is int or v is float:
		return int(v)
	if v is String and (v as String).is_valid_int():
		return (v as String).to_int()
	return fallback


## 테스트용 전체 초기화
func reset_all() -> void:
	owned.clear()
	for id in GameData.STARTERS:
		owned.append(id)
	tickets = 0
	start_bonus = false     # 처음 뽑기권은 튜토리얼에서 다시 줌
	tutorial_done = false
	rewarded.clear()
	current = owned[0]
	progress.clear()
	affinity.clear()
	couples.clear()
	gifts.clear()
	sworn.clear()
	items.clear()
	luck = 0
	sulky.clear()
	clover_gifts.clear()
	made_up.clear()
	mini_cleared = 0
	merits = 0
	sp_paid.clear()
	battle_exp.clear()
	battle_tut_done = false
	pair_wins.clear()
	defected.clear()
	stories.clear()
	save_now()
	# 백업에 예전 진행이 남아 있으면 나중에 복구될 수 있으니 같이 지움
	var dir := DirAccess.open("user://")
	if dir:
		for path in [BAK_PATH, TMP_PATH, CORRUPT_PATH]:
			if dir.file_exists(path.get_file()):
				dir.remove(path.get_file())
