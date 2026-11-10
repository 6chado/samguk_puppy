extends Node
## 게임 데이터 & 밸런스 수치. 숫자 조절은 전부 여기서.

# ── 성장 ─────────────────────────────────────────
const STAGE_NAMES: Array[String] = ["새끼강아지", "개초딩", "개청소년", "어른강아지"]
const CAT_STAGE_NAMES: Array[String] = ["새끼고양이", "캣초딩", "캣청년", "어른고양이"]
## 각 단계에 도달하는 "누적" 경험치. 마지막 값이 어른.
## 행동 5번(전투1 + 밥4) ≈ 75exp ≈ 13~14초 → 1700이면 대략 5분 30초
const STAGE_EXP: Array[int] = [0, 250, 800, 1700]

# ── 피로도 / 잠 ──────────────────────────────────
const FATIGUE_MAX := 100
const FATIGUE_PER_FOOD := 5      # 밥 한 입마다
const FATIGUE_PER_BATTLE := 20   # 전투/책략 한 번마다
const SLEEP_SECONDS := 1.5       # 잠자기 누르면 자는 시간 → 피로도 0
const EAT_ANIM_SECONDS := 0.5

# ── 쓰다듬기 ─────────────────────────────────────
## 강아지: 쓰다듬으면 피로도가 아주 조금 내려감 (잠자기보다 훨씬 비효율적이어야 함)
##   2로 잡은 이유: 밥 한 입(+5)과 번갈아 해도 피로도는 계속 쌓이게 (+5 -2 = +3)
##   잠: 1.5초에 100 회복 / 쓰다듬기: 0.4초에 최대 2 → 1초에 5 정도
const PET_DOG_RELIEF := 2
## 고양이(책사): 쓰다듬으면 오히려 피곤해함, 연속 5번부터 화내면서 +10
const PET_CAT_FATIGUE := 5
const PET_CAT_ANGRY_FATIGUE := 10
const PET_CAT_ANGRY_STREAK := 5
const PET_COOLDOWN := 0.4      # 이보다 빨리 연타하면 하트만 나오고 피로도는 안 바뀜
const PET_STREAK_GAP := 1.5    # 이 시간 안에 다시 쓰다듬어야 "연속"    # 먹는 모션 길이 (연타하면 계속 이어짐)
const BATTLE_LINE_SECONDS := 0.12  # 전투 대사 한 줄 나오는 간격
const STARTING_FOOD := {"rice": 3}

# ── 음식 ─────────────────────────────────────────
const FOOD_ORDER: Array[String] = ["rice", "meat", "sweet_potato", "dumpling"]
const FOODS := {
	"rice":         {"name": "사료",   "exp": 10, "weight": 50},
	"meat":         {"name": "고기",   "exp": 20, "weight": 30},
	"sweet_potato": {"name": "고고마", "exp": 35, "weight": 15},   # 고구마 귀엽게. 고양이는 캣그라스로 보임
	"dumpling":     {"name": "만두",   "exp": 50, "weight": 5},
}

# ── 전투 / 책략 보상 (최소, 최대 개수) ───────────
const BATTLE_WIN_DROPS := Vector2i(3, 5)
const BATTLE_LOSE_DROPS := Vector2i(1, 2)
const BATTLE_BASE_WIN_RATE := 0.55
const BATTLE_WIN_RATE_PER_STAGE := 0.1   # 클수록 잘 이김

const STRATEGY_WIN_DROPS := Vector2i(4, 6)
const STRATEGY_DRAW_DROPS := Vector2i(2, 3)
const STRATEGY_LOSE_DROPS := Vector2i(1, 1)

# ── 진영 / 강아지 ────────────────────────────────
## role: "lord"(군주, 처음부터 데리고 있음) / "warrior"(전투) / "strategist"(책략 내기)
const FACTION_ORDER: Array[String] = ["shu", "wei", "wu", "special"]
const FACTIONS := {
	"shu": {"name": "촉", "lord": "liu_bei"},
	"wei": {"name": "위", "lord": "cao_cao"},
	"wu":  {"name": "오", "lord": "sun_quan"},
	"special": {"name": "스페셜", "lord": ""},   # 진영 없는 영웅들 (주군 없음)
}

const DOGS := {
	# 촉
	"liu_bei":     {"name": "유비",   "faction": "shu", "role": "lord",       "color": Color(0.93, 0.80, 0.55)},
	"guan_yu":     {"name": "관우",   "faction": "shu", "role": "warrior",    "color": Color(0.60, 0.33, 0.22)},
	"zhang_fei":   {"name": "장비",   "faction": "shu", "role": "warrior",    "color": Color(0.30, 0.26, 0.24)},
	"zhao_yun":    {"name": "조운",   "faction": "shu", "role": "warrior",    "color": Color(0.96, 0.95, 0.92)},
	"jiang_wei":   {"name": "강유",   "faction": "shu", "role": "warrior",    "color": Color(0.82, 0.62, 0.36)},
	"zhuge_liang": {"name": "제갈량", "faction": "shu", "role": "strategist", "color": Color(0.98, 0.96, 0.90)},
	"pang_tong":   {"name": "방통",   "faction": "shu", "role": "strategist", "color": Color(0.62, 0.52, 0.38)},
	"ma_chao":     {"name": "마초",   "faction": "shu", "role": "warrior",    "color": Color(0.69, 0.44, 0.24)},
	"fa_zheng":    {"name": "법정",   "faction": "shu", "role": "strategist", "color": Color(0.42, 0.46, 0.55)},
	"liu_shan":    {"name": "유선",   "faction": "shu", "role": "warrior",    "color": Color(0.94, 0.81, 0.55)},
	"huang_zhong": {"name": "황충",   "faction": "shu", "role": "warrior",    "color": Color(0.77, 0.52, 0.31)},
	"wei_yan":     {"name": "위연",   "faction": "shu", "role": "warrior",    "color": Color(0.59, 0.44, 0.31)},
	"xu_shu":      {"name": "서서",   "faction": "shu", "role": "strategist", "color": Color(0.98, 0.97, 0.96)},
	# 위
	"cao_cao":     {"name": "조조",   "faction": "wei", "role": "lord",       "color": Color(0.38, 0.38, 0.44)},
	"xiahou_dun":  {"name": "하후돈", "faction": "wei", "role": "warrior",    "color": Color(0.52, 0.42, 0.32)},
	"xu_chu":      {"name": "허저",   "faction": "wei", "role": "warrior",    "color": Color(0.86, 0.72, 0.52)},
	"zhang_liao":  {"name": "장료",   "faction": "wei", "role": "warrior",    "color": Color(0.70, 0.55, 0.40)},
	"sima_yi":     {"name": "사마의", "faction": "wei", "role": "strategist", "color": Color(0.30, 0.30, 0.36)},
	"xun_yu":      {"name": "순욱",   "faction": "wei", "role": "strategist", "color": Color(0.90, 0.86, 0.76)},
	"cao_pi":      {"name": "조비",   "faction": "wei", "role": "warrior",    "color": Color(0.38, 0.42, 0.55)},
	"jia_xu":      {"name": "가후",   "faction": "wei", "role": "strategist", "color": Color(0.34, 0.34, 0.39)},
	"xun_you":     {"name": "순유",   "faction": "wei", "role": "strategist", "color": Color(0.80, 0.69, 0.56)},
	"guo_jia":     {"name": "곽가",   "faction": "wei", "role": "strategist", "color": Color(0.93, 0.88, 0.78)},
	"xiahou_yuan": {"name": "하후연", "faction": "wei", "role": "warrior",    "color": Color(0.73, 0.75, 0.78)},
	"dian_wei":    {"name": "전위",   "faction": "wei", "role": "warrior",    "color": Color(0.63, 0.43, 0.30)},
	"yu_jin":      {"name": "우금",   "faction": "wei", "role": "warrior",    "color": Color(0.57, 0.58, 0.62)},
	# 오
	"sun_quan":    {"name": "손권",   "faction": "wu",  "role": "lord",       "color": Color(0.88, 0.56, 0.30)},
	"gan_ning":    {"name": "감녕",   "faction": "wu",  "role": "warrior",    "color": Color(0.72, 0.46, 0.26)},
	"taishi_ci":   {"name": "태사자", "faction": "wu",  "role": "warrior",    "color": Color(0.62, 0.56, 0.50)},
	"zhou_yu":     {"name": "주유",   "faction": "wu",  "role": "strategist", "color": Color(0.96, 0.90, 0.84)},
	"lu_xun":      {"name": "육손",   "faction": "wu",  "role": "strategist", "color": Color(0.76, 0.66, 0.50)},
	"sun_jian":    {"name": "손견",   "faction": "wu",  "role": "warrior",    "color": Color(0.74, 0.40, 0.20)},
	"sun_ce":      {"name": "손책",   "faction": "wu",  "role": "warrior",    "color": Color(0.96, 0.75, 0.43)},
	"sun_shangxiang": {"name": "손상향", "faction": "wu", "role": "warrior",  "color": Color(0.94, 0.60, 0.29)},
	"ling_tong":   {"name": "능통",   "faction": "wu",  "role": "warrior",    "color": Color(0.91, 0.59, 0.30)},
	"lu_meng":     {"name": "여몽",   "faction": "wu",  "role": "warrior",    "color": Color(0.84, 0.59, 0.33)},
	"huang_gai":   {"name": "황개",   "faction": "wu",  "role": "warrior",    "color": Color(0.82, 0.65, 0.38)},
	"lu_su":       {"name": "노숙",   "faction": "wu",  "role": "strategist", "color": Color(0.93, 0.65, 0.35)},
	"zhuge_jin":   {"name": "제갈근", "faction": "wu",  "role": "strategist", "color": Color(0.69, 0.71, 0.75)},
	# 스페셜
	"lu_bu":       {"name": "여포",   "faction": "special", "role": "warrior",    "color": Color(0.27, 0.26, 0.29)},
	"chen_gong":   {"name": "진궁",   "faction": "special", "role": "strategist", "color": Color(0.52, 0.36, 0.28)},
	"yuan_shao":   {"name": "원소",   "faction": "special", "role": "warrior",    "color": Color(0.93, 0.85, 0.69)},
	"yuan_shu":    {"name": "원술",   "faction": "special", "role": "warrior",    "color": Color(0.94, 0.81, 0.55)},
	"gongsun_zan": {"name": "공손찬", "faction": "special", "role": "warrior",    "color": Color(0.97, 0.97, 0.98)},
	"diao_chan":   {"name": "초선",   "faction": "special", "role": "strategist", "color": Color(0.98, 0.91, 0.89)},
}


# ── 시작 / 뽑기 ─────────────────────────────────
## 처음부터 데리고 있는 멍냥이 (주군 셋)
const STARTERS: Array[String] = ["liu_bei", "cao_cao", "sun_quan"]
## 처음 시작할 때 주는 뽑기권 (예전 세이브에도 한 번 챙겨 줌)
const STARTING_TICKETS := 3
## 한 마리를 어른까지 키우면 받는 뽑기권 (마리당 한 번). 3 + 3장씩 → 13마리 키우면 45마리 다 모음 (약 1시간 10분)
const ADULT_TICKETS := 3
## 뽑기: 아직 없는 멍냥이 중에서 똑같은 확률로 한 마리

# ── 호감도 / 커플 ─────────────────────────────────
const AFFINITY_MAX := 4               # 하트 4개 = 고백하기 열림
const PLAY_CHANCE_SAME := 1.0         # 같은 진영: 놀 때마다 하트 +1 (4번이면 MAX)
const PLAY_CHANCE_OTHER := 0.35       # 다른 진영: 35% 확률로만 +1 (평균 11번 정도)
## 앙숙 (서로 싫어하는 사이): 호감도·선물이 안 오르고 고백·의형제 불가
## 주군(유비·조조·손권)끼리는 따로 적지 않아도 자동으로 앙숙
const HATES := [
	["zhuge_liang", "zhou_yu"],     # 제갈량 ↔ 주유 (기생유 하생량)
	["zhuge_liang", "wei_yan"],     # 반골상
	["guan_yu", "lu_xun"],          # 형주를 빼앗김
	["guan_yu", "yu_jin"],          # 번성 수공에 항복
	["guan_yu", "zhuge_jin"],       # 혼담 거절 ("범의 딸을 개의 아들에게?")
	["gan_ning", "zhang_liao"],     # 합비 맞수
	["gan_ning", "ling_tong"],      # 아버지의 원수 (능통이 어른이 되면 화해 ↓)
	["ling_tong", "zhang_liao"],    # 합비에서 죽을 뻔
	["ma_chao", "xu_chu"],          # 동관 일기토
	["jia_xu", "dian_wei"],         # 완성의 밤
	["xiahou_yuan", "huang_zhong"], # 정군산
	["xu_shu", "cao_cao"],          # 어머니를 볼모로
	["sun_shangxiang", "liu_shan"], # 아두를 데려가려다 조운에게 막힘
	# 스페셜
	["lu_bu", "cao_cao"],           # 백문루에서 처형
	["lu_bu", "zhang_fei"],         # "삼성가노!"
	["chen_gong", "cao_cao"],       # 여백사 사건 뒤 조조를 떠남
	["yuan_shao", "yuan_shu"],      # 형제지만 서로 무시
	["yuan_shao", "cao_cao"],       # 관도대전
	["yuan_shao", "gongsun_zan"],   # 하북 패권 다툼
	["yuan_shu", "sun_ce"],         # 옥새 맡기고 독립해 버림
	["diao_chan", "cao_cao"],       # 여포를 죽인 원수
]

# ── 희귀 아이템 (전투·책략에서 가끔, 한 번 쓰면 사라짐) ──
const SPECIAL_DROP_CHANCE := 0.10     # 전투·책략 한 번마다 10%
const LUCKY_DROP_CHANCE := 0.35       # 네잎클로버 효과 중에는 35%
const CLOVER_BATTLES := 5             # 네잎클로버 하나 = 전투·책략 5번 동안 효과
const PEACH_EXP := 300              # 먹으면: 아직 크는 중이면 경험치, 어른이면 친밀도
## 희귀템이 나왔을 때 무엇이 나올지 (숫자 = 비율). 복숭아는 선물에 많이 필요해서 제일 잘 나옴
const SPECIAL_WEIGHTS := {"peach": 40, "ginseng": 25, "pouch": 20, "clover": 15}
## 복주머니를 열면 (뽑기권이 제일 귀함, 나머지 셋은 똑같이)
const POUCH_WEIGHTS := {"ginseng": 30, "peach": 30, "clover": 30, "ticket": 10}
const ITEM_ORDER: Array[String] = ["peach", "ginseng", "clover", "pouch"]
const ITEMS := {
	"peach":   {"name": "천도복숭아", "icon": "item_peach",   "desc": "먹으면 경험치 +300 (어른은 친밀도 +300)\n관계도에서 선물하면 의형제에 한 걸음"},
	"ginseng": {"name": "산삼",       "icon": "item_ginseng", "desc": "피로도가 싹 풀려요 (잠 안 자도 됨)"},
	"clover":  {"name": "네잎클로버", "icon": "item_clover",  "desc": "전투·책략 5번 동안 희귀템이 훨씬 잘 나와요"},
	"pouch":   {"name": "복주머니",   "icon": "item_pouch",   "desc": "열면 산삼·천도복숭아·네잎클로버 중 하나\n아주 가끔 뽑기권!"},
}

# ── 선물 / 의형제 ──────────────────────────────
## 관계도에서 천도복숭아를 4번 선물하면 의형제 가능. 놀기·고백(커플)과는 따로 셈
const GIFT_MAX := 4
const SWORN_MAX := 3                  # 한 멍냥이당 의형제 최대 3명 (주군도 똑같이)

# ── 신뢰 / 가족 ──────────────────────────────────
## 신뢰 관계: 고백(하트)·의형제(복숭아)에 필요한 칸이 각각 하나씩 줄어듦 (4 → 3). 한 멍냥이당 최대 2명
const TRUST_BONUS := 1
const TRUST := [
	# 촉
	["liu_bei", "guan_yu"], ["liu_bei", "zhang_fei"], ["guan_yu", "zhang_fei"],   # 도원 삼형제
	["zhuge_liang", "jiang_wei"],     # 후계자
	["zhuge_liang", "zhao_yun"],      # 유비가 맡긴 뒷일을 함께 지킨 두 충신
	["pang_tong", "xu_shu"],          # 함께 제갈량을 아는 벗
	["zhao_yun", "liu_shan"],         # 장판파에서 구한 아두
	["huang_zhong", "fa_zheng"],      # 정군산 콤비
	# 위
	["cao_cao", "xiahou_dun"], ["cao_cao", "cao_pi"],
	["xiahou_dun", "xiahou_yuan"],
	["guo_jia", "xun_yu"],            # 순욱이 곽가를 추천
	["xun_yu", "xun_you"],
	["dian_wei", "xu_chu"],           # 조조의 두 호위무사
	["zhang_liao", "yu_jin"],
	["cao_pi", "sima_yi"],
	# 오
	["sun_quan", "zhou_yu"], ["sun_quan", "lu_xun"],
	["zhou_yu", "sun_ce"],            # 단금지교
	["sun_ce", "taishi_ci"],          # 맞짱 뜨고 친구
	["lu_xun", "lu_meng"],            # 여몽이 육손을 추천
	["lu_meng", "lu_su"],             # 괄목상대
	["lu_su", "zhuge_jin"],
	["huang_gai", "sun_jian"],        # 손견 때부터의 노장
	["jiang_wei", "ma_chao"],         # 서량 출신 두 장수
	["huang_zhong", "wei_yan"],       # 장사에서 함께 유비에게
	["pang_tong", "fa_zheng"],        # 익주 공략의 두 책사
	["sima_yi", "jia_xu"],            # 노련한 두 책략가
	["xun_you", "guo_jia"],           # 조조의 책사 동료
	["taishi_ci", "huang_gai"],       # 오의 노익장 무장들
	["sun_jian", "sun_shangxiang"],   # 아빠와 딸
	["lu_bu", "chen_gong"],           # 끝까지 함께한 책사
	["lu_bu", "diao_chan"],           # 연환계 그 후
	["yuan_shu", "gongsun_zan"],      # 원소를 견제하는 동맹
]
## 크면 풀리는 앙숙: {"a|b": 이 멍냥이가 어른이 되면 화해 / "both" = 둘 다 어른이 되면 화해}
## 화해한 뒤로는 놀기·고백·의형제 다 가능. (제갈량 ↔ 주유는 일부러 영원히 앙숙)
## 키는 "이름순 앞|뒤" (예: wei_yan < zhuge_liang)
const GROW_OUT_HATES := {
	"gan_ning|ling_tong": "ling_tong",    # 아버지의 원수 → 능통이 크면 화해
	"gan_ning|zhang_liao": "both",        # 합비 맞수 → 서로 인정
	"ma_chao|xu_chu": "both",             # 동관 맨몸 일기토 → 싸우다 정듦
	"wei_yan|zhuge_liang": "both",        # 반골상이라 미워했지만 → 둘 다 크면 화해
}

## 가족: 아무리 친해도 고백(커플) 불가. 놀기·의형제는 가능
const FAMILY := [
	["sun_jian", "sun_ce"], ["sun_jian", "sun_quan"], ["sun_jian", "sun_shangxiang"],
	["sun_ce", "sun_quan"], ["sun_ce", "sun_shangxiang"], ["sun_quan", "sun_shangxiang"],
	["zhuge_liang", "zhuge_jin"],
	["cao_cao", "cao_pi"],
	["xiahou_dun", "xiahou_yuan"],
	["xun_yu", "xun_you"],
	["liu_bei", "liu_shan"],
	["yuan_shao", "yuan_shu"],
]


func is_lord(dog_id: String) -> bool:
	return DOGS[dog_id]["role"] == "lord"


## 앙숙 = 싫어하는 사이 or 주군끼리
func is_rival(a: String, b: String) -> bool:
	if a == b:
		return false
	if is_lord(a) and is_lord(b):
		return true
	return _pair_in(HATES, a, b) and not reconciled(a, b)


## 크면 풀리는 앙숙이 이미 풀렸는지
func reconciled(a: String, b: String) -> bool:
	var who := grow_out_by(a, b)
	var adult := STAGE_EXP.size() - 1
	if who == "both":
		return GameState.stage_of(a) >= adult and GameState.stage_of(b) >= adult
	return who != "" and GameState.stage_of(who) >= adult


## 이 둘의 앙숙을 풀어 줄 멍냥이 ("both" = 둘 다, 없으면 "")
func grow_out_by(a: String, b: String) -> String:
	var key := a + "|" + b if a < b else b + "|" + a
	return str(GROW_OUT_HATES.get(key, ""))


static func _pair_in(list: Array, a: String, b: String) -> bool:
	for pair in list:
		if (pair[0] == a and pair[1] == b) or (pair[0] == b and pair[1] == a):
			return true
	return false


func is_trusted(a: String, b: String) -> bool:
	return _pair_in(TRUST, a, b)


func is_family(a: String, b: String) -> bool:
	return _pair_in(FAMILY, a, b)


## 이 둘이 고백하려면 하트 몇 칸 (신뢰 관계면 하나 적음)
func affinity_max(a: String, b: String) -> int:
	return AFFINITY_MAX - (TRUST_BONUS if is_trusted(a, b) else 0)


## 이 둘이 의형제하려면 복숭아 몇 개 (신뢰 관계면 하나 적음)
func gift_max(a: String, b: String) -> int:
	return GIFT_MAX - (TRUST_BONUS if is_trusted(a, b) else 0)


func same_faction(a: String, b: String) -> bool:
	return DOGS[a]["faction"] == DOGS[b]["faction"]


## 전투·책략 후 희귀템 (lucky = 네잎클로버 효과 중). 안 나오면 ""
func roll_special(lucky := false) -> String:
	if randf() < (LUCKY_DROP_CHANCE if lucky else SPECIAL_DROP_CHANCE):
		return roll_weighted(SPECIAL_WEIGHTS)
	return ""


## {"id": 비율} 중에서 비율대로 하나
func roll_weighted(weights: Dictionary) -> String:
	var total := 0
	for k in weights:
		total += int(weights[k])
	var r := randi_range(1, total)
	for k in weights:
		r -= int(weights[k])
		if r <= 0:
			return k
	return weights.keys()[0]


func stage_for_exp(total_exp: int) -> int:
	var stage := 0
	for i in STAGE_EXP.size():
		if total_exp >= STAGE_EXP[i]:
			stage = i
	return stage


func is_strategist(dog_id: String) -> bool:
	return DOGS[dog_id]["role"] == "strategist"


## 책사 = 고양이
func is_cat(dog_id: String) -> bool:
	return is_strategist(dog_id)


func species(dog_id: String) -> String:
	return "고양이" if is_cat(dog_id) else "강아지"


func stage_name(stage: int, dog_id: String) -> String:
	return (CAT_STAGE_NAMES if is_cat(dog_id) else STAGE_NAMES)[stage]


## 화면에 보이는 음식 그림 id (고양이는 고고마 자리에 캣그라스)
func food_icon_id(food_id: String, dog_id: String) -> String:
	if food_id == "sweet_potato" and dog_id != "" and is_cat(dog_id):
		return "cat_grass"
	return food_id


func food_name(food_id: String, dog_id: String) -> String:
	if food_icon_id(food_id, dog_id) == "cat_grass":
		return "캣그라스"
	return FOODS[food_id]["name"]


func roll_food() -> String:
	var total := 0
	for id in FOOD_ORDER:
		total += int(FOODS[id]["weight"])
	var r := randi_range(1, total)
	for id in FOOD_ORDER:
		r -= int(FOODS[id]["weight"])
		if r <= 0:
			return id
	return FOOD_ORDER[0]


func roll_drops(amount: Vector2i) -> Array[String]:
	var result: Array[String] = []
	for i in randi_range(amount.x, amount.y):
		result.append(roll_food())
	return result
