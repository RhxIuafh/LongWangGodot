class_name FighterData

var name: String = ""
var health: int = 10
var bonus: Array[int] = [1, 1, 1] # 对应 Stone, Scissor, Cloth 的固定加成
var longmai_set: Array[int] = [0, 0, 0] # 不同英雄初始设置的龙脉不一样
	
func _init(p_name: String, hp: int, bon: Array[int], lm_set: Array[int]):
	name = p_name
	health = hp
	bonus = bon
	longmai_set = lm_set
	
func get_name():
	return name

func set_name(p_name: String):
	name = p_name

func get_health():
	return health

func set_health(hp: int):
	health = hp

func get_bonus():
	return bonus

func set_bonus(bu: Array[int]):
	bonus = bu

func get_longmai_set():
	return longmai_set

func set_longmai_set(lms: Array[int]):
	longmai_set = lms
	
