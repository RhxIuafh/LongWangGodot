# GameManager.gd
# 管理全局的游戏数据
extends Node

# 存储

# 存储 P1 和 P2 的战斗数据
var p1_fighter_data: Dictionary = {}
var p2_fighter_data: Dictionary = {}

# 存储其他全局状态（如当前关卡、难度等）
var game_settings: Dictionary = {}

#func set_p1_data(data: Dictionary):
	#p1_fighter_data = data.duplicate() # 深度复制，防止意外修改
#
#func set_p2_data(data: Dictionary):
	#p2_fighter_data = data.duplicate()
#
#func get_p1_data() -> Dictionary:
	#return p1_fighter_data.duplicate()
#
#func get_p2_data() -> Dictionary:
	#return p2_fighter_data.duplicate()
#
#func clear_data():
	#p1_fighter_data.clear()
	#p2_fighter_data.clear()
