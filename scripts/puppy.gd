class_name Puppy
extends RefCounted
## 강아지 한 마리의 진행 상태 (경험치, 행동 횟수, 가방)

signal stage_changed(stage: int)

var dog_id: String
var total_exp := 0
var fatigue := 0
var affection := 0              # 어른 된 뒤 밥/쓰다듬기로 오르는 친밀도
var inventory: Dictionary = {}  # food_id -> 개수

var stage: int:
	get:
		return GameData.stage_for_exp(total_exp)


func _init(id: String = "") -> void:
	dog_id = id
	inventory = GameData.STARTING_FOOD.duplicate()


func is_adult() -> bool:
	return stage >= GameData.STAGE_NAMES.size() - 1


func food_count(food_id: String) -> int:
	return int(inventory.get(food_id, 0))


func feed(food_id: String) -> bool:
	if food_count(food_id) <= 0:
		return false
	inventory[food_id] = food_count(food_id) - 1
	if is_adult():
		affection += 1
	else:
		_add_exp(int(GameData.FOODS[food_id]["exp"]))
	return true


func add_foods(foods: Array[String]) -> void:
	for f in foods:
		inventory[f] = food_count(f) + 1


## 음수면 피로도 회복
func add_fatigue(amount: int) -> void:
	fatigue = clampi(fatigue + amount, 0, GameData.FATIGUE_MAX)


## 피로도가 꽉 차면 잠자기 말고 아무것도 못 함
func is_exhausted() -> bool:
	return fatigue >= GameData.FATIGUE_MAX


func rest() -> void:
	fatigue = 0


## 천도복숭아 등 바로 경험치 주기
func add_exp(amount: int) -> void:
	_add_exp(amount)


func _add_exp(amount: int) -> void:
	var before := stage
	total_exp = mini(total_exp + amount, GameData.STAGE_EXP[-1])
	if stage != before:
		stage_changed.emit(stage)


func to_dict() -> Dictionary:
	return {
		"dog_id": dog_id,
		"exp": total_exp,
		"fatigue": fatigue,
		"affection": affection,
		"inventory": inventory,
	}


static func from_dict(d: Dictionary, fallback_id := "") -> Puppy:
	# 세이브 값 검사: 숫자가 아니거나 범위 밖이면 고쳐서 넣음
	var id := str(d.get("dog_id", fallback_id))
	if not GameData.DOGS.has(id):
		id = fallback_id
	var p := Puppy.new(id)
	p.total_exp = clampi(_num(d.get("exp"), 0), 0, GameData.STAGE_EXP[-1])
	p.fatigue = clampi(_num(d.get("fatigue"), 0), 0, GameData.FATIGUE_MAX)
	p.affection = maxi(_num(d.get("affection"), 0), 0)
	var inv = d.get("inventory", {})
	if inv is Dictionary:
		p.inventory = {}
		for k in inv:
			if GameData.FOODS.has(str(k)):
				p.inventory[str(k)] = clampi(_num(inv[k], 0), 0, 9999)
	return p


static func _num(v, fallback: int) -> int:
	if v is int or v is float:
		return int(v)
	return fallback
