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
## 진(jin)은 사마의가 진영을 옮기기 전까지 탭·뽑기에 안 나옴 (jin_open())
const FACTION_ORDER: Array[String] = ["shu", "wei", "wu", "jin", "han", "chu", "special"]
const FACTIONS := {
	"shu": {"name": "촉", "lord": "liu_bei"},
	"wei": {"name": "위", "lord": "cao_cao"},
	"wu":  {"name": "오", "lord": "sun_quan"},
	"jin": {"name": "진", "lord": "sima_yi"},     # 사마의가 어른 + 친밀도 50 → 이벤트로 세움
	"han": {"name": "한", "lord": "liu_bang"},   # 초한지: 진까지 다 모으면 이벤트로 열림 (chohan_open)
	"chu": {"name": "초", "lord": "xiang_yu"},
	"special": {"name": "스페셜", "lord": ""},   # 진영 없는 영웅들 (주군 없음)
}

## 진영을 옮기는 멍냥이: id -> 옮겨 갈 진영. 옮긴 뒤엔 그림도 바뀜 (ALT_SPRITE)
const DEFECTORS := {"xiahou_ba": "shu", "sima_yi": "jin"}
const ALT_SPRITE := {"xiahou_ba": "xiahou_ba_shu", "sima_yi": "sima_yi_jin"}


## 지금 진영 (옮겼으면 옮긴 진영)
func faction_of(dog_id: String) -> String:
	if DEFECTORS.has(dog_id) and GameState.has_defected(dog_id):
		return DEFECTORS[dog_id]
	return DOGS[dog_id]["faction"]


## 그림 파일 이름 (진영 옮긴 뒤엔 어른 모습만 새 옷)
func sprite_id(dog_id: String, form := 2) -> String:
	if form == 2 and ALT_SPRITE.has(dog_id) and GameState.has_defected(dog_id):
		return ALT_SPRITE[dog_id]
	return dog_id


## 진나라가 열렸는지 (사마의가 진영을 옮김)
func jin_open() -> bool:
	return GameState.has_defected("sima_yi")


## 초한지 진영(한·초)이 열렸는지 (진까지 모두 모으면 나오는 이야기를 봄)
func chohan_open() -> bool:
	return GameState.story_seen(CHOHAN_STORY)

const CHOHAN_STORY := "liu_bang"   # 이야기 id (유방 도감에서 다시 보기)


## 진영이 지금 게임에 나오는지
func faction_open(f: String) -> bool:
	if f == "jin":
		return jin_open()
	if f == "han" or f == "chu":
		return chohan_open()
	return true


## 지금 게임에 나오는 진영들 (진·한·초는 열린 뒤에만)
func faction_order() -> Array[String]:
	var out: Array[String] = []
	for f in FACTION_ORDER:
		if faction_open(f):
			out.append(f)
	return out


## 이 멍냥이가 지금 게임에 나오는지 (진·한·초 멍냥이는 열린 뒤에만)
func available(dog_id: String) -> bool:
	return faction_open(DOGS[dog_id]["faction"])

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
	"xu_huang":    {"name": "서황",   "faction": "wei", "role": "warrior",    "color": Color(0.45, 0.49, 0.55)},
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
	"hua_tuo":     {"name": "화타",   "faction": "special", "role": "strategist", "color": Color(0.97, 0.96, 0.94)},
	"dong_zhuo":   {"name": "동탁",   "faction": "special", "role": "warrior",    "color": Color(0.8, 0.63, 0.43)},
	# 추가: 위
	"zhang_he":    {"name": "장합",   "faction": "wei", "role": "warrior",    "color": Color(0.96, 0.94, 0.89)},
	"li_dian":     {"name": "이전",   "faction": "wei", "role": "warrior",    "color": Color(0.84, 0.63, 0.36)},
	"yue_jin":     {"name": "악진",   "faction": "wei", "role": "warrior",    "color": Color(0.98, 0.97, 0.95)},
	"xiahou_ba":   {"name": "하후패", "faction": "wei", "role": "warrior",    "color": Color(0.63, 0.61, 0.62)},   # 어른 되면 촉으로
	# 추가: 촉
	"guan_ping":   {"name": "관평",   "faction": "shu", "role": "warrior",    "color": Color(0.84, 0.41, 0.27)},
	"ma_dai":      {"name": "마대",   "faction": "shu", "role": "warrior",    "color": Color(0.59, 0.38, 0.22)},
	"zhou_cang":   {"name": "주창",   "faction": "shu", "role": "warrior",    "color": Color(0.2, 0.17, 0.18)},
	# 추가: 오
	"cheng_pu":    {"name": "정보",   "faction": "wu",  "role": "warrior",    "color": Color(0.67, 0.57, 0.47)},
	"zhou_tai":    {"name": "주태",   "faction": "wu",  "role": "warrior",    "color": Color(0.18, 0.16, 0.17)},
	"han_dang":    {"name": "한당",   "faction": "wu",  "role": "warrior",    "color": Color(0.67, 0.49, 0.29)},
	# 진 (사마의가 진영을 옮긴 뒤에 열림)
	"sima_shi":    {"name": "사마사", "faction": "jin", "role": "strategist", "color": Color(0.66, 0.41, 0.26)},
	"sima_zhao":   {"name": "사마소", "faction": "jin", "role": "strategist", "color": Color(0.73, 0.47, 0.3)},
	"sima_yan":    {"name": "사마염", "faction": "jin", "role": "strategist", "color": Color(0.77, 0.53, 0.35)},
	"deng_ai":     {"name": "등애",   "faction": "jin", "role": "warrior",    "color": Color(0.17, 0.16, 0.17)},
	"zhong_hui":   {"name": "종회",   "faction": "jin", "role": "strategist", "color": Color(0.18, 0.17, 0.2)},
	"wen_yang":    {"name": "문앙",   "faction": "jin", "role": "warrior",    "color": Color(0.87, 0.66, 0.42)},
	# 한 (초한지 · 유방 편)
	"liu_bang":    {"name": "유방",   "faction": "han", "role": "lord",       "color": Color(0.93, 0.82, 0.60)},
	"han_xin":     {"name": "한신",   "faction": "han", "role": "warrior",    "color": Color(0.77, 0.75, 0.73)},
	"fan_kuai":    {"name": "번쾌",   "faction": "han", "role": "warrior",    "color": Color(0.98, 0.96, 0.93)},
	"ying_bu":     {"name": "영포",   "faction": "han", "role": "warrior",    "color": Color(0.59, 0.42, 0.28)},
	"cao_can":     {"name": "조참",   "faction": "han", "role": "warrior",    "color": Color(0.84, 0.62, 0.41)},
	"zhang_liang": {"name": "장량",   "faction": "han", "role": "strategist", "color": Color(0.96, 0.94, 0.90)},
	"xiao_he":     {"name": "소하",   "faction": "han", "role": "strategist", "color": Color(0.69, 0.67, 0.64)},
	"lu_zhi":      {"name": "여치",   "faction": "han", "role": "strategist", "color": Color(0.17, 0.16, 0.19)},
	# 초 (초한지 · 항우 편)
	"xiang_yu":    {"name": "항우",   "faction": "chu", "role": "lord",       "color": Color(0.84, 0.73, 0.55)},
	"zhongli_mo":  {"name": "종리매", "faction": "chu", "role": "warrior",    "color": Color(0.80, 0.59, 0.34)},
	"long_ju":     {"name": "용저",   "faction": "chu", "role": "warrior",    "color": Color(0.72, 0.36, 0.20)},
	"yu_ji":       {"name": "우희",   "faction": "chu", "role": "strategist", "color": Color(0.99, 0.97, 0.96)},
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
	["zhang_he", "zhuge_liang"],    # 목문도에서 제갈량의 매복에
	["li_dian", "sun_quan"],        # 합비 전투
	["xiahou_ba", "sima_yi"],       # 고평릉 사변 → 촉으로 망명
	["sima_shi", "xiahou_ba"],
	["guan_ping", "lu_meng"],       # 맥성에서 사로잡힘
	["zhou_cang", "lu_meng"],
	["ma_dai", "wei_yan"],          # "누가 감히 나를 죽이랴!" "여기 있다!"
	["cheng_pu", "zhou_yu"],        # 처음엔 젊은 주유를 무시함
	["han_dang", "dong_zhuo"],      # 손견과 함께 동탁 토벌
	["zhou_tai", "zhang_liao"],     # 합비
	["hua_tuo", "cao_cao"],         # 머리 수술 하자니까 화가 난 조조
	["dong_zhuo", "lu_bu"],         # 봉의정 / 연환계
	["dong_zhuo", "cao_cao"],       # 칠성검 암살 시도
	["dong_zhuo", "yuan_shao"],     # 반동탁 연합 맹주
	["deng_ai", "zhong_hui"],       # 촉 정벌 공 다툼
	["deng_ai", "jiang_wei"],
	["zhong_hui", "sima_zhao"],     # 사마소에게 반기를 듦
	["wen_yang", "sima_shi"],       # 문앙의 야습에 놀란 사마사
	["yue_jin", "guan_yu"],         # 번성 전투
	["yue_jin", "gan_ning"],        # 유수구에서 감녕의 화살에
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
	# 초한지 (유방–항우는 주군끼리라 자동 앙숙)
	["han_xin", "long_ju"],         # 유수 전투
	["lu_zhi", "han_xin"],          # 여치가 한신을 함정에 빠뜨림
	["fan_kuai", "han_xin"],        # "번쾌 따위와 같은 급이라니"
	["ying_bu", "xiang_yu"],        # 초를 버리고 한으로
]

# ── 희귀 아이템 (전투·책략에서 가끔, 한 번 쓰면 사라짐) ──
const SPECIAL_DROP_CHANCE := 0.10     # 전투·책략 한 번마다 10%
const LUCKY_DROP_CHANCE := 0.35       # 네잎클로버 효과 중에는 35%
const CLOVER_BATTLES := 5             # 네잎클로버 하나 = 전투·책략 5번 동안 효과
const GOLDEN_PEACH_EXP := 400       # 황금복숭아 (대전에서만)
const PEACH_EXP := 300              # 먹으면: 아직 크는 중이면 경험치, 어른이면 친밀도
## 희귀템이 나왔을 때 무엇이 나올지 (숫자 = 비율). 복숭아는 선물에 많이 필요해서 제일 잘 나옴
const SPECIAL_WEIGHTS := {"peach": 40, "ginseng": 25, "pouch": 20, "clover": 15}
## 복주머니를 열면 (뽑기권이 제일 귀함, 나머지 셋은 똑같이)
const POUCH_WEIGHTS := {"ginseng": 32, "peach": 33, "clover": 32, "ticket": 3}   # 뽑기권 3%
const ITEM_ORDER: Array[String] = ["peach", "golden_peach", "ginseng", "clover", "pouch"]
const ITEMS := {
	"peach":   {"name": "천도복숭아", "icon": "item_peach",   "desc": "먹으면 경험치 +300 (어른은 친밀도 +300)\n관계도에서 선물하면 의형제에 한 걸음"},
	"golden_peach": {"name": "황금복숭아", "icon": "item_golden_peach", "desc": "대전에서만 얻는 귀한 복숭아\n먹으면 경험치 +400 (어른은 친밀도 +400)\n관계도에서 선물하면 의형제에 한 걸음"},
	"ginseng": {"name": "산삼",       "icon": "item_ginseng", "desc": "피로도가 싹 풀려요 (잠 안 자도 됨)"},
	"clover":  {"name": "네잎클로버", "icon": "item_clover",  "desc": "전투·책략 5번 동안 희귀템이 훨씬 잘 나와요"},
	"pouch":   {"name": "복주머니",   "icon": "item_pouch",   "desc": "열면 산삼·천도복숭아·네잎클로버 중 하나\n아주 가끔 뽑기권!"},
}

# ── 계책 대전 (미니게임, 엔드콘텐츠) ──────────────
## 무장(강아지) 1 + 책사(고양이) 1 이 출전. 기병 > 궁병 > 창병 > 기병, 화공은 무조건 승리. 5판 3선승
const CARD_NAMES := {"cav": "기병", "arc": "궁병", "spr": "창병", "fire": "화공"}
const CARD_BEATS := {"cav": "arc", "arc": "spr", "spr": "cav"}   # 왼쪽이 오른쪽을 이김
const MINI_WIN := 3          # 먼저 3승
const MINI_HAND := 5         # 기본 손패 (+ 화공 1장)
## w = 상대가 내는 [기병, 궁병, 창병] 비율 / tie_enemy = 비기면 상대 승 / smart = 내 손패를 읽고 내는 확률
## head = 상대가 먼저 갖고 시작하는 점수 / no_fire = 화공 카드가 안 나옴 / exp = 이기면 받는 전공
## (보통 실력 기준 승률: 1단계 84% · 2단계 80% · 3단계 74% · 4단계 44% · 5단계 14%, 신뢰·같은 진영이면 5단계도 40%쯤)
## 이길 때마다 보상 뽑기: rolls 번 뽑고, 한 번마다 MINI_DROP 확률표에서 하나 (확률은 모든 단계 같음, 1000 = 100%)
const MINI_DROP := {"peach": 450, "golden_peach": 150, "clover": 150, "ginseng": 145, "pouch": 100, "ticket": 5}
## reward / n = 처음 깼을 때만 주는 보너스. merit = 이기면 받는 공훈패 (어려울수록 많이)
const MINI_STAGES: Array = [
	{"name": "황건적 토벌", "enemy": "황건적", "w": [1, 1, 1], "tie_enemy": false, "smart": 0.0, "reward": "peach", "n": 3, "exp": 30, "merit": 1, "rolls": 1},
	{"name": "동탁 토벌", "enemy": "동탁군", "w": [1, 1, 2], "tie_enemy": false, "smart": 0.15, "reward": "clover", "n": 2, "exp": 40, "merit": 1, "rolls": 1},
	{"name": "여포 격파", "enemy": "여포군", "w": [3, 1, 1], "tie_enemy": false, "smart": 0.3, "reward": "ginseng", "n": 2, "exp": 50, "merit": 1, "rolls": 2},
	{"name": "원소 결전", "enemy": "원소군", "w": [1, 2, 1], "tie_enemy": true, "smart": 0.7, "head": 1, "reward": "pouch", "n": 2, "exp": 90, "merit": 3, "rolls": 3},
	{"name": "천하쟁패", "enemy": "천하의 강적", "w": [1, 1, 1], "tie_enemy": true, "smart": 0.85, "no_fire": true, "reward": "ticket", "n": 2, "exp": 150, "merit": 5, "rolls": 4},
]
## 칭호 = 전공(대전 경험치)이 쌓이면 올라감. 무장·책사 따로, 주군(+여포·원소·원술·공손찬)은 맨 위 "황제"까지
const WAR_RANKS: Array[String] = ["병졸", "백인장", "교위", "장군", "대장군", "황제"]
const STRAT_RANKS: Array[String] = ["서생", "주부", "참군", "군사", "승상"]
const RANK_EXP: Array[int] = [40, 250, 700, 1500, 2600, 4000]   # 각 칭호에 필요한 전공 (마지막 = 황제)
const EMPEROR_OK: Array[String] = ["liu_bei", "cao_cao", "sun_quan", "lu_bu", "yuan_shao", "yuan_shu", "gongsun_zan", "liu_bang", "xiang_yu"]
const MINI_EXP_WIN_BASE := 20     # 이기면 전공 20 + 단계×10
const MINI_EXP_WIN_STEP := 10
const MINI_EXP_LOSE := 8          # 져도 조금


## 칭호 색: 1 회색(병졸) → 동 → 은 → 금 → 다이아 → 무지개(황제, 화면에서 따로 처리)
const RANK_COLORS: Array[Color] = [Color(0.62, 0.6, 0.58), Color(0.72, 0.45, 0.25), Color(0.74, 0.77, 0.82),
	Color(0.93, 0.72, 0.16), Color(0.55, 0.85, 0.96), Color(0.9, 0.5, 0.8)]

## 스페셜 칭호: 이 무장 + 책사가 함께 N번 이기면 둘 다 받음
const SPECIAL_TITLES: Array = [
	{"a": "liu_bei", "b": "zhuge_liang", "name": "수어지교", "wins": 10},
	{"a": "zhao_yun", "b": "zhuge_liang", "name": "너는 내 사람", "wins": 10},
	{"a": "jiang_wei", "b": "zhuge_liang", "name": "당신을 따를게요", "wins": 10},
	{"a": "liu_bei", "b": "pang_tong", "name": "봉추가 왔다!", "wins": 10},
	{"a": "liu_bei", "b": "xu_shu", "name": "가기 전에 추천!", "wins": 10},
	{"a": "huang_zhong", "b": "fa_zheng", "name": "할아버지 출동!", "wins": 10},
	{"a": "cao_cao", "b": "xun_yu", "name": "우리 집 장자방", "wins": 10},
	{"a": "cao_cao", "b": "guo_jia", "name": "곽가만 있었어도..", "wins": 10},
	{"a": "cao_pi", "b": "sima_yi", "name": "태자의 친구", "wins": 10},
	{"a": "sun_ce", "b": "zhou_yu", "name": "단금지교", "wins": 10},
	{"a": "huang_gai", "b": "zhou_yu", "name": "고육지계", "wins": 10},
	{"a": "sun_quan", "b": "lu_su", "name": "둘만의 비밀 작전", "wins": 10},
	{"a": "lu_meng", "b": "lu_xun", "name": "몰래 강 건너기", "wins": 10},
	{"a": "lu_bu", "b": "chen_gong", "name": "끝까지 함께", "wins": 10},
	{"a": "lu_bu", "b": "diao_chan", "name": "연환계", "wins": 10},
	{"a": "zhou_tai", "b": "hua_tuo", "name": "호~ 다 나았다!", "wins": 10},
	{"a": "zhang_he", "b": "sima_yi", "name": "가정에서의 승리", "wins": 10},
	{"a": "deng_ai", "b": "sima_zhao", "name": "데굴데굴 산길", "wins": 10},
	{"a": "xiang_yu", "b": "yu_ji", "name": "사면초가", "wins": 10},
	{"a": "liu_bang", "b": "zhang_liang", "name": "하늘이 내린 당신", "wins": 10},
	{"a": "han_xin", "b": "xiao_he", "name": "달밤의 추격전", "wins": 10},
	{"a": "guan_yu", "b": "hua_tuo", "name": "바둑 두면 안 아파", "wins": 10},
	{"a": "zhang_fei", "b": "pang_tong", "name": "반나절 만에?!", "wins": 10},
	{"a": "liu_shan", "b": "zhuge_liang", "name": "출사표", "wins": 10},
	{"a": "wei_yan", "b": "zhuge_liang", "name": "내 작전 써 줘요!", "wins": 10},
	{"a": "jiang_wei", "b": "zhong_hui", "name": "가짜 항복 작전", "wins": 10},
	{"a": "sun_shangxiang", "b": "zhou_yu", "name": "상향아 너만 믿는다", "wins": 10},
	{"a": "cheng_pu", "b": "zhou_yu", "name": "좋은 술 같은 친구", "wins": 10},
	{"a": "sun_quan", "b": "zhuge_jin", "name": "믿고 맡겨!", "wins": 10},
	{"a": "cao_cao", "b": "xun_you", "name": "십이지계", "wins": 10},
	{"a": "cao_pi", "b": "jia_xu", "name": "가후의 한마디", "wins": 10},
	{"a": "deng_ai", "b": "zhong_hui", "name": "촉 정벌", "wins": 10},
	{"a": "fan_kuai", "b": "zhang_liang", "name": "홍문연", "wins": 10},
	{"a": "cao_can", "b": "xiao_he", "name": "소규조수", "wins": 10},
	{"a": "liu_bang", "b": "lu_zhi", "name": "패현의 부부", "wins": 10},
	{"a": "sun_quan", "b": "zhou_yu", "name": "삼대의 무게", "wins": 10},
	{"a": "ma_chao", "b": "jia_xu", "name": "이간질은 싫어!", "wins": 10},
	{"a": "xiahou_dun", "b": "xun_yu", "name": "연주를 지켜라", "wins": 10},
	{"a": "zhang_liao", "b": "chen_gong", "name": "하비의 옛 동료", "wins": 10},
	{"a": "dian_wei", "b": "jia_xu", "name": "완성의 함정", "wins": 10},
	{"a": "gan_ning", "b": "lu_su", "name": "관우를 막아라", "wins": 10},
	{"a": "sun_quan", "b": "lu_xun", "name": "이릉대전", "wins": 10},
	{"a": "yuan_shao", "b": "xun_yu", "name": "떠나간 순욱", "wins": 10},
	{"a": "dong_zhuo", "b": "diao_chan", "name": "봉의정의 소동", "wins": 10},
	{"a": "wen_yang", "b": "sima_shi", "name": "한밤의 야습", "wins": 10},
	{"a": "wen_yang", "b": "sima_yan", "name": "진나라를 지켜라", "wins": 10},
	{"a": "ying_bu", "b": "zhang_liang", "name": "한나라로 오세요", "wins": 10},
	{"a": "zhongli_mo", "b": "yu_ji", "name": "항우를 지켜라", "wins": 10},
	{"a": "long_ju", "b": "yu_ji", "name": "초나라의 맹장", "wins": 10},
]


## 이 둘이 받을 수 있는 스페셜 칭호 ({} = 없음)
func special_for(a: String, b: String) -> Dictionary:
	for sp in SPECIAL_TITLES:
		if (sp["a"] == a and sp["b"] == b) or (sp["a"] == b and sp["b"] == a):
			return sp
	return {}


## 이 멍냥이가 이 칭호 단계면 무슨 색? (lv 1부터)
func rank_color(lv: int) -> Color:
	return RANK_COLORS[clampi(lv, 1, RANK_COLORS.size()) - 1]


## 이 멍냥이가 오를 수 있는 마지막 칭호 단계
func rank_max(dog_id: String) -> int:
	if is_strategist(dog_id):
		return STRAT_RANKS.size()
	return WAR_RANKS.size() if EMPEROR_OK.has(dog_id) else WAR_RANKS.size() - 1


## 전공 → 칭호 단계 (0 = 없음)
func rank_level(dog_id: String, exp: int) -> int:
	var top := rank_max(dog_id)
	var lv := 0
	for i in top:
		if exp >= RANK_EXP[i]:
			lv = i + 1
	return lv


## 황제가 되면 "황제" 대신 각자의 이름 + 꼬리표 색
const EMPEROR_NAMES := {
	"liu_bei": ["소열황제", "gold"], "cao_cao": ["위 무제", "gold"], "sun_quan": ["오 대제", "gold"],
	"yuan_shu": ["중가 황제", "red"], "lu_bu": ["비장", "red"], "yuan_shao": ["하북의 패왕", "red"], "gongsun_zan": ["백마장군", "red"],
	"liu_bang": ["한 고조", "black"], "xiang_yu": ["서초패왕", "black"],
}


func is_emperor_lv(dog_id: String, lv: int) -> bool:
	return not is_strategist(dog_id) and lv >= WAR_RANKS.size()


## 전공 막대 색 = 지금 칭호 색 (황제는 꼬리표 색: 금 / 빨강 / 검정)
func rank_bar_color(dog_id: String, lv: int) -> Color:
	if lv <= 0:
		return Color(0.7, 0.68, 0.65)
	if is_emperor_lv(dog_id, lv):
		match emperor_theme(dog_id):
			"red":
				return Color(0.82, 0.22, 0.26)
			"black":
				return Color(0.22, 0.2, 0.26)
		return Color(0.93, 0.72, 0.16)
	return rank_color(lv)


func emperor_theme(dog_id: String) -> String:
	return EMPEROR_NAMES[dog_id][1] if EMPEROR_NAMES.has(dog_id) else "gold"


func rank_name(dog_id: String, lv: int) -> String:
	if lv <= 0:
		return ""
	if is_emperor_lv(dog_id, lv) and EMPEROR_NAMES.has(dog_id):
		return EMPEROR_NAMES[dog_id][0]
	var ranks: Array[String] = STRAT_RANKS if is_strategist(dog_id) else WAR_RANKS
	return ranks[mini(lv, ranks.size()) - 1]


# ── 선물 / 의형제 ──────────────────────────────
## 관계도에서 천도복숭아를 4번 선물하면 의형제 가능. 놀기·고백(커플)과는 따로 셈
const GIFT_MAX := 4
## 칸을 다 채운 뒤 고백 / 의형제 맺기 성공률. 실패하면 그 칸(하트 / 복숭아)이 처음부터
const CONFESS_CHANCE_SAME := 0.55
const CONFESS_CHANCE_OTHER := 0.10
const SWEAR_CHANCE_SAME := 0.60
const SWEAR_CHANCE_OTHER := 0.10
const SWORN_MAX := 3                  # 한 멍냥이당 의형제 최대 3명 (주군도 똑같이)

# ── 신뢰 / 가족 ──────────────────────────────────
## 신뢰 관계: 고백(하트)·의형제(복숭아)에 필요한 칸이 각각 하나씩 줄어듦 (4 → 3). 한 멍냥이당 최대 2명 (강유 4명, 장료 3명은 예외)
const TRUST_BONUS := 1
const TRUST := [
	["zhang_he", "xiahou_yuan"],    # 한중에서 함께 싸움
	["li_dian", "yue_jin"],         # 합비 3인방
	["yue_jin", "zhang_liao"],
	["xiahou_ba", "liu_shan"],      # 망명한 하후패를 반겨 줌
	["guan_ping", "zhou_cang"],     # 관우 곁을 끝까지 지킴
	["cheng_pu", "han_dang"],       # 손견 때부터의 오나라 원로
	["zhou_tai", "gan_ning"],
	["zhou_tai", "hua_tuo"],        # 온몸의 상처를 화타가 치료
	["deng_ai", "sima_zhao"],
	["ma_dai", "jiang_wei"],        # 강유만 예외로 신뢰 4명 (마대·종회는 늦게 만나는 짝)
	["zhong_hui", "jiang_wei"],     # 촉 정벌 뒤 함께 일을 꾸밈
	["wen_yang", "deng_ai"],        # 진의 무장끼리
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
	["xu_huang", "zhang_liao"],       # 위의 명장끼리 (장료는 예외로 3명)
	# 초한지
	["liu_bang", "zhang_liang"],      # 군신의 정석
	["xiao_he", "han_xin"],           # 달밤에 쫓아가 붙잡아 옴
	["han_xin", "zhongli_mo"],        # 진영은 달라도 오랜 친구
	["xiao_he", "cao_can"],           # 소규조수
	["xiang_yu", "yu_ji"],            # 사면초가
]
## 크면 풀리는 앙숙: {"a|b": 이 멍냥이가 어른이 되면 화해 / "both" = 둘 다 어른이 되면 화해}
## 화해한 뒤로는 놀기·고백·의형제 다 가능. (제갈량 ↔ 주유는 일부러 영원히 앙숙)
## 키는 "이름순 앞|뒤" (예: wei_yan < zhuge_liang)
## 단체 칭호: 멤버를 모두 데려와서 모두 칭호 3단계(무장 교위 · 책사 참군) 이상이면 멤버 전원이 받음
const GROUP_RANK := 3
const GROUP_TITLES: Array = [
	{"name": "오호대장군", "members": ["guan_yu", "zhang_fei", "zhao_yun", "ma_chao", "huang_zhong"]},
	{"name": "오자양장", "members": ["zhang_liao", "yue_jin", "yu_jin", "zhang_he", "xu_huang"]},
	{"name": "합비 삼인방", "members": ["zhang_liao", "li_dian", "yue_jin"]},
	{"name": "하후 형제", "members": ["xiahou_dun", "xiahou_yuan"]},
	{"name": "호위 듀오", "members": ["xu_chu", "dian_wei"]},
	{"name": "강동 노장", "members": ["cheng_pu", "huang_gai", "han_dang"]},
	{"name": "한초삼걸", "members": ["zhang_liang", "xiao_he", "han_xin"]},
	# 책사가 들어간 단체 칭호
	{"name": "와룡봉추", "members": ["zhuge_liang", "pang_tong"]},
	{"name": "제갈 형제", "members": ["zhuge_liang", "zhuge_jin"]},
	{"name": "조조의 책사들", "members": ["xun_yu", "xun_you", "guo_jia", "jia_xu"]},
	{"name": "순씨 가문", "members": ["xun_yu", "xun_you"]},
	{"name": "손오의 사대도독", "members": ["zhou_yu", "lu_su", "lu_meng", "lu_xun"]},
	{"name": "사마 가문", "members": ["sima_yi", "sima_shi", "sima_zhao", "sima_yan"]},
	{"name": "하비 삼총사", "members": ["lu_bu", "chen_gong", "diao_chan"]},
	# 단체 칭호 없던 애들 (무장 + 책사 섞어서)
	{"name": "유비의 책사들", "members": ["liu_bei", "zhuge_liang", "xu_shu", "fa_zheng"]},
	{"name": "검각의 대치", "members": ["jiang_wei", "deng_ai", "zhong_hui"]},
	{"name": "강동 평정", "members": ["sun_ce", "taishi_ci", "zhou_yu"]},
	{"name": "손씨 가문", "members": ["sun_jian", "sun_ce", "sun_quan", "sun_shangxiang"]},
	{"name": "화타의 환자들", "members": ["hua_tuo", "guan_yu", "zhou_tai"]},
	{"name": "패현 사람들", "members": ["liu_bang", "fan_kuai", "cao_can", "lu_zhi"]},
	{"name": "서초패왕과 친구들", "members": ["xiang_yu", "yu_ji", "zhongli_mo", "long_ju"]},
	{"name": "해하 포위전", "members": ["han_xin", "ying_bu", "zhang_liang"]},
	{"name": "군웅할거", "members": ["yuan_shao", "yuan_shu", "gongsun_zan", "dong_zhuo"]},
	{"name": "합비 탈출 대작전", "members": ["sun_quan", "gan_ning", "ling_tong", "zhou_tai"]},
	{"name": "관우의 그림자", "members": ["guan_yu", "guan_ping", "zhou_cang"]},
	{"name": "한중 공방전", "members": ["huang_zhong", "wei_yan", "fa_zheng"]},
	{"name": "진의 맹장", "members": ["deng_ai", "wen_yang", "sima_zhao"]},
	{"name": "조씨 부자", "members": ["cao_cao", "cao_pi"]},
	{"name": "촉의 마지막 불꽃", "members": ["jiang_wei", "xiahou_ba", "ma_dai", "liu_shan"]},
]


## 이 멍냥이가 들어 있는 단체 칭호들 (아직 안 열린 진영 멤버가 있으면 뺌)
func groups_of(dog_id: String) -> Array:
	var out: Array = []
	for g in GROUP_TITLES:
		if (g["members"] as Array).has(dog_id):
			var ok := true
			for m in g["members"]:
				if not available(m):
					ok = false
			if ok:
				out.append(g)
	return out


const SPECIAL_STORY_COST := 10   # 스페셜 이야기 하나 여는 데 드는 공훈패
const MAKEUP_CLOVERS := 3     # 토라진 애 / 앙숙과 화해하려면 클로버 몇 개

const GROW_OUT_HATES := {
	"gan_ning|ling_tong": "ling_tong",    # 아버지의 원수 → 능통이 크면 화해
	"gan_ning|zhang_liao": "both",        # 합비 맞수 → 서로 인정
	"ma_chao|xu_chu": "both",             # 동관 맨몸 일기토 → 싸우다 정듦
	"wei_yan|zhuge_liang": "both",        # 반골상이라 미워했지만 → 둘 다 크면 화해
}

## 가족: 아무리 친해도 고백(커플) 불가. 놀기·의형제는 가능
const FAMILY := [
	["guan_yu", "guan_ping"],       # 아버지 - 아들
	["ma_chao", "ma_dai"],          # 사촌
	["xiahou_yuan", "xiahou_ba"],   # 아버지 - 아들
	["sima_yi", "sima_shi"],        # 사마의 - 아들
	["sima_yi", "sima_zhao"],
	["sima_shi", "sima_zhao"],      # 형제
	["sima_zhao", "sima_yan"],      # 아버지 - 아들
	["sima_yi", "sima_yan"],        # 할아버지 - 손자
	["sun_jian", "sun_ce"], ["sun_jian", "sun_quan"], ["sun_jian", "sun_shangxiang"],
	["sun_ce", "sun_quan"], ["sun_ce", "sun_shangxiang"], ["sun_quan", "sun_shangxiang"],
	["zhuge_liang", "zhuge_jin"],
	["cao_cao", "cao_pi"],
	["xiahou_dun", "xiahou_yuan"],
	["xun_yu", "xun_you"],
	["liu_bei", "liu_shan"],
	["yuan_shao", "yuan_shu"],
	["liu_bang", "fan_kuai"],       # 동서
	["liu_bang", "lu_zhi"],         # 부부
]


func is_lord(dog_id: String) -> bool:
	if dog_id == "sima_yi" and jin_open():   # 진을 세우면 진의 주군
		return true
	return DOGS[dog_id]["role"] == "lord"


## 앙숙 = 싫어하는 사이 or 주군끼리
func is_rival(a: String, b: String) -> bool:
	if a == b:
		return false
	if GameState.is_made_up(a, b):   # 클로버로 화해함
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


func confess_chance(a: String, b: String) -> float:
	return CONFESS_CHANCE_SAME if same_faction(a, b) else CONFESS_CHANCE_OTHER


func swear_chance(a: String, b: String) -> float:
	return SWEAR_CHANCE_SAME if same_faction(a, b) else SWEAR_CHANCE_OTHER


func same_faction(a: String, b: String) -> bool:
	return faction_of(a) == faction_of(b)


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
