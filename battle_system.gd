class_name BattleSystem 

# --- 枚举定义 (对应 Python Enum) ---
enum Dice { RED = 0, GREEN = 1, BLUE = 2 }
enum Distance { CLOSE = 0, MID = 1, FAR = 2 }
enum Skill { STONE = 0, SCISSOR = 1, CLOTH = 2, MOVE = 3 }
# 动作类型用于前端识别
enum ActionType { ADVANCE, BACK, STONE1, STONE2, SCISSOR1, SCISSOR2, CLOTH1, CLOTH2 }


# --- 数据类 (对应 Python Class) ---
# 每个基础动作都有以下属性
class ActionData:
	var attribute: Skill
	var damage: int
	var range: Array[Distance]
	var longmai_change: int
	var bonus: Array[int] # 对应 Python 的 bonus 列表
	
	func _init(attr: Skill, dmg: int, rng: Array[Distance], lm_change: int, bon: Array[int]):
		attribute = attr
		damage = dmg
		range = rng
		longmai_change = lm_change
		bonus = bon
		
		

class ResultData:
	var hit_player: int = 0 # 1 或 2, 0 表示无人命中。1表示P1命中，2表示P2命中
	var damage: int = 0 # 命中后造成的伤害
	var attribute: Skill = Skill.MOVE # 命中的牌是移动牌还是别的牌
	var longmai_change: int = 0 # 每张牌命中后都有改龙脉的机会
	
	func _init(h: int, d: int, attr: Skill, lm: int):
		hit_player = h
		damage = d
		attribute = attr
		longmai_change = lm


# 牌桌上的信息存储在这里
class LongMaiData:
	var values: Array[int] = [3, 3, 3] # Red, Green, Blue
	var distance: Distance = Distance.MID
	
	func get_distance() -> Distance:
		return distance
	
	func set_distance(d: Distance):
		distance = clamp(d as int, 0, 2) as Distance # 限制 0-2
		
	func get_value(dice: Dice) -> int:
		return values[dice]
	
	func set_value(dice: Dice, val: int):
		values[dice] = clamp(val, 1, 6)
		
	func get_values() -> Array[int]:
		return values.duplicate()
		
		
# --- 游戏状态变量 ---
var longmai_data: LongMaiData
var fighter1: FighterData
var fighter2: FighterData

# 临时存储当前回合出的牌
var current_card1: Variant # 可能是 ActionData 或 int (移动牌)
var current_card2: Variant
var current_result: ResultData


## --- 初始化 ---
#func _ready():
	#reset_game()

func reset_game():
	longmai_data = LongMaiData.new()
	# 从场景二获取英雄信息
	fighter1 = GameManager.p1_fighter_data["fighter"]
	#fighter2 = FighterData.new(10, [1, 1, 1], [0, 0, 0])
	fighter2 = GameManager.p2_fighter_data["fighter"]
	current_card1 = null
	current_card2 = null
	current_result = null
	
# 出牌
func get_card_action(action_type: ActionType) -> Variant:
	if action_type == ActionType.ADVANCE:
		return -1
	elif action_type == ActionType.BACK:
		return 1
	
	# 攻击技能
	match action_type:
		ActionType.STONE1: # 突袭
			return ActionData.new(Skill.STONE, 2, [Distance.CLOSE], 2, [-1, 0, 0, 1, 2, 3])
		ActionType.STONE2: # 强袭
			return ActionData.new(Skill.STONE, 1, [Distance.MID, Distance.FAR], 1, [-1, 0, 0, 0, 1, 2])
		ActionType.SCISSOR1: # 狙击
			return ActionData.new(Skill.SCISSOR, 2, [Distance.MID], 2, [-1, 0, 0, 1, 2, 3])
		ActionType.SCISSOR2: # 爆裂射击
			return ActionData.new(Skill.SCISSOR, 1, [Distance.CLOSE, Distance.FAR], 1, [-1, 0, 0, 0, 1, 2])
		ActionType.CLOTH1: # 古典咏唱
			return ActionData.new(Skill.CLOTH, 2, [Distance.FAR], 2, [-1, 0, 0, 1, 2, 3])
		ActionType.CLOTH2: # 新式咏唱
			return ActionData.new(Skill.CLOTH, 1, [Distance.CLOSE, Distance.MID], 1, [-1, 0, 0, 0, 1, 2])
	
	return null
	
# 距离结算逻辑
func settle_distance(card1: Variant, card2: Variant):
	var distance_amend: int = 0
	if typeof(card1) == TYPE_INT:
		distance_amend += card1
	if typeof(card2) == TYPE_INT:
		distance_amend += card2
	
	var new_dist_val: int = longmai_data.get_distance() as int + distance_amend
	# 更新距离
	longmai_data.set_distance(new_dist_val as Distance)
	print("距离结算: 偏移=%d, 新距离=%s" % [distance_amend, Distance.keys()[longmai_data.get_distance()]])
	

# 伤害结算逻辑
func settle_damage(card1: Variant, card2: Variant) -> ResultData:
	var hit1: int = 0
	var hit2: int = 0
	# 判断是不是行动牌(双行动牌，行动牌和移动牌分开结算)
	var is_action1: bool = (card1 is ActionData)
	var is_action2: bool = (card2 is ActionData)
	var current_dist: Distance = longmai_data.get_distance()
	
	# 1. 范围判定
	if is_action1:
		if card1.range.has(current_dist):
			hit1 = 1
	if is_action2:
		if card2.range.has(current_dist):
			hit2 = 1
			
	# 2. 对战结算 (剪刀石头布)
	if is_action1 and is_action2:
		if hit1 == 1 and hit2 == 1:
			var result_num: int = card1.attribute as int - card2.attribute as int
			# Stone(0) - Scissor(1) = -1 (Stone Win)
			# Scissor(1) - Cloth(2) = -1 (Scissor Win)
			# Cloth(2) - Stone(0) = 2 (Cloth Win)
			if result_num == -1 or result_num == 2:
				hit1 = 1
				hit2 = 0
			elif result_num == -2 or result_num == 1:
				hit1 = 0
				hit2 = 1
	elif is_action1:
		# 只有 P1 出攻击牌，P2是移动
		if hit1 == 1:
			hit2 = 0
		else:
			hit2 = 1 
	elif is_action2:
		if hit2 == 1:
			hit1 = 0
		else:
			hit1 = 1
	else:
		# 双方都移动，视为都不命中
		hit1 = 0
		hit2 = 0
		
	# 3. 伤害计算与结果返回
	var final_result: ResultData = null
	
	# P1 命中结算
	if hit1 == 1:
		if is_action1:
			var action: ActionData = card1
			# 伤害 = 基础 + 龙脉加成 (bonus 数组索引是 longmai 值 -1) + 职业加成
			# 注意 Python: card1.bonus[self.longmai.get_longmai()[card1.attribute.value] - 1]
			var lm_val: int = longmai_data.values[action.attribute as int]
			var lm_bonus: int = action.bonus[lm_val - 1]
			var class_bonus: int = fighter1.bonus[action.attribute as int]
			
			var total_dmg: int = action.damage + lm_bonus + class_bonus
			final_result = ResultData.new(1, total_dmg, action.attribute, action.longmai_change)
		else:
			# 移动牌命中 (Python 逻辑: Result(1, 0, Skill.MOVE, 2))
			final_result = ResultData.new(1, 0, Skill.MOVE, 2)
			
	# P2 命中结算 (如果 P1 没命中 或者 双方都命中但 P2 赢)
	# 注意：Python 逻辑是 if...elif... 所以如果 P1 命中了，P2 就不会再结算伤害了 (除非是特殊规则，但这里看起来是互斥的)
	# 等等，Python 代码里：
	# if hit1 == 1: return Result(1...)
	# elif hit2 == 1: return Result(2...)
	# 这意味着同一回合只有一方能造成伤害？是的，这是该游戏的规则。
	
	elif hit2 == 1:
		if is_action2:
			var action: ActionData = card2
			var lm_val: int = longmai_data.values[action.attribute as int]
			var lm_bonus: int = action.bonus[lm_val - 1]
			var class_bonus: int = fighter2.bonus[action.attribute as int]
			
			var total_dmg: int = action.damage + lm_bonus + class_bonus
			final_result = ResultData.new(2, total_dmg, action.attribute, action.longmai_change)
		else:
			final_result = ResultData.new(2, 0, Skill.MOVE, 2)
			
	return final_result

# --- 应用结果 (扣血、调整龙脉) ---
# 这个函数由主游戏逻辑调用，传入用户的选择 (是否调整龙脉，如何调整)
func apply_result(result: ResultData, adjust_choice: Dictionary) -> void:
	if result == null or result.hit_player == 0:
		return
	
	# 1. 扣血
	if result.hit_player == 1:
		fighter2.health -= result.damage
		print("P1 击中 P2, 造成 %d 点伤害" % result.damage)
	elif result.hit_player == 2:
		fighter1.health -= result.damage
		print("P2 击中 P1, 造成 %d 点伤害" % result.damage)
		
	# 2. 调整龙脉
	# adjust_choice 结构示例: {"do_adjust": true, "type": "+", "dice": 0 (RED), "amount": 2}
	# 或者对于 MOVE 牌: {"do_adjust": true, "type": "+", "dice": 1 (GREEN)...}
	
	if adjust_choice.get("do_adjust", false):
		var dice_idx: int = adjust_choice.get("dice", 0)
		var amount: int = result.longmai_change
		if adjust_choice.get("type") == "-":
			amount = -amount
			
		longmai_data.set_value(dice_idx, longmai_data.values[dice_idx] + amount)
		print("龙脉调整: Dice[%d] 变为 %d" % [dice_idx, longmai_data.values[dice_idx]])

# --- 辅助获取状态 ---
func get_status() -> Dictionary:
	return {
		"longmai": longmai_data.get_values(),
		"distance": longmai_data.get_distance(),
		"p1_health": fighter1.health,
		"p2_health": fighter2.health,
		"p1_bonus": fighter1.bonus,
		"p2_bonus": fighter2.bonus
	}
