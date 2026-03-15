extends Node2D

# 导出变量
@export var card_scene: PackedScene # 卡牌的预制体场景
@export var dice_textures: Array[Texture2D] # [红, 绿, 蓝] 骰子纹理



# --- 节点引用 ---
@onready var camera: Camera2D = $"../Camera2D"
@onready var p1_hero_pos: Node2D = $"../GameWorld/P1_HeroContainer"
@onready var p2_hero_pos: Node2D = $"../GameWorld/P2_HeroContainer"
@onready var center_pos: Node2D = $"../GameWorld/CenterInfo"
@onready var p1_info: Label = $"../GameWorld/P1_HeroContainer/P1_Info"
@onready var p2_info: Label = $"../GameWorld/P2_HeroContainer/P2_Info"
@onready var p1_hand_container: HFlowContainer = $"../GameWorld/P1_HeroContainer/P1_HandContainer"
@onready var p2_hand_container: HFlowContainer = $"../GameWorld/P2_HeroContainer/P2_HandContainer"

@onready var turn_button: Button = $"../UI_Layer/TurnButton"
@onready var message_label: Label = $"../UI_Layer/MessageLabel"
@onready var distance_label: Label = $"../GameWorld/CenterInfo/DistanceLabel"
@onready var dice_nodes: Array[TextureRect] = [
	$"../GameWorld/CenterInfo/DiceContainer/DiceRed", 
	$"../GameWorld/CenterInfo/DiceContainer/DiceGreen", 
	$"../GameWorld/CenterInfo/DiceContainer/DiceBlue"
]

# --- 游戏状态 ---
enum TurnState { P1_TURN, P2_TURN, RESOLVING, GAME_OVER }
var current_state: TurnState = TurnState.P1_TURN
var round_number: int = 1
# 工具类
var bs: BattleSystem = BattleSystem.new() 
# 手牌数据 (示例)
var p1_hand: Array = []
var p2_hand: Array = []
var p1_played_card: Dictionary = {} # 记录打出的牌
var p2_played_card: Dictionary = {}

# 配置
const HAND_SIZE = 8
const CAMERA_ZOOM_PAN = Vector2(0.4, 0.0) # 聚焦时的缩放偏移
const CAMERA_DEFAULT_POS = Vector2(0, 0)
const CAMERA_SPEED = 1.0

func _ready() -> void:
	# 初始化游戏
	bs.reset_game()
	init_game_data()
	setup_ui()
	start_round()

# --- 初始化 ---
func init_game_data() -> void:
	# 生成手牌数据
	p1_hand.append({"name": "前进", "action_type": bs.ActionType.ADVANCE})
	p1_hand.append({"name": "后退", "action_type": bs.ActionType.BACK})
	p1_hand.append({"name": "突袭", "action_type": bs.ActionType.STONE1})
	p1_hand.append({"name": "强袭", "action_type": bs.ActionType.STONE2})
	p1_hand.append({"name": "狙击", "action_type": bs.ActionType.SCISSOR1})
	p1_hand.append({"name": "爆裂射击", "action_type": bs.ActionType.SCISSOR2})
	p1_hand.append({"name": "古典咏唱", "action_type": bs.ActionType.CLOTH1})
	p1_hand.append({"name": "新式咏唱", "action_type": bs.ActionType.CLOTH2})
	
	# p2_hand.append({"id": i, "name": "P2_卡%d" % i, "power": randi_range(1, 10)})
	p2_hand.append({"name": "前进", "action_type": bs.ActionType.ADVANCE})
	p2_hand.append({"name": "后退", "action_type": bs.ActionType.BACK})
	p2_hand.append({"name": "突袭", "action_type": bs.ActionType.STONE1})
	p2_hand.append({"name": "强袭", "action_type": bs.ActionType.STONE2})
	p2_hand.append({"name": "狙击", "action_type": bs.ActionType.SCISSOR1})
	p2_hand.append({"name": "爆裂射击", "action_type": bs.ActionType.SCISSOR2})
	p2_hand.append({"name": "古典咏唱", "action_type": bs.ActionType.CLOTH1})
	p2_hand.append({"name": "新式咏唱", "action_type": bs.ActionType.CLOTH2})
	
	# 更新距离和骰子 (示例)
	update_distance(bs.longmai_data.distance)

func setup_ui() -> void:
	turn_button.text = "过"
	turn_button.pressed.connect(_on_turn_button_pressed)
	turn_button.disabled = false
	# 初始隐藏手牌容器，等轮到谁再显示/聚焦
	p1_hand_container.visible = false
	p2_hand_container.visible = false

# 回合流程控制
func start_round() -> void:
	round_number += 1
	print("回合数: ", round_number - 1)
	turn_button.text = "过"
	p1_played_card.clear()
	p2_played_card.clear()
	# 渲染角色
	render_hero_data(p1_info, bs.fighter1)
	render_hero_data(p2_info, bs.fighter2)
	# 重置手牌显示 (如果需要每回合抽牌，在这里逻辑)
	render_hand(p1_hand_container, p1_hand, true) # P1 可见
	render_hand(p2_hand_container, p2_hand, true) # P2 背面
	
	current_state = TurnState.P1_TURN
	update_ui_text("玩家 1 (P1) 请出牌")
	move_camera_to(p1_hero_pos.global_position)

	# P2 手牌此时应该不可交互或隐藏
	set_hand_interactive(p1_hand_container, true)
	set_hand_interactive(p2_hand_container, false)

func _on_turn_button_pressed() -> void:
	match current_state:
		TurnState.P1_TURN:
			# P1 出牌后，切换到 P2
			if p1_played_card.is_empty():
				message_label.text = "请先选择一张卡牌！"
				return
			
			current_state = TurnState.P2_TURN
			update_ui_text("玩家 2 (P2) 请出牌")
			move_camera_to(p2_hero_pos.global_position)
			set_hand_interactive(p1_hand_container, false)
			set_hand_interactive(p2_hand_container, true)
			
		TurnState.P2_TURN:
			# P2 出牌后，进入结算
			if p2_played_card.is_empty():
				message_label.text = "请先选择一张卡牌！"
				return
			
			current_state = TurnState.RESOLVING
			update_ui_text("双方出牌完毕，盖牌中...")
			turn_button.disabled = true # 结算期间禁用按钮
			# 隐藏P1，P2的手牌
			set_hand_interactive(p1_hand_container, false)
			set_hand_interactive(p2_hand_container, false)
			
			# 镜头移向中间
			move_camera_to(center_pos.global_position)
			play_card_animation_and_resolve()
			
		TurnState.RESOLVING:
			update_distance(bs.longmai_data.distance)
			# 结算完毕，下一回合
			start_round()

# 核心逻辑：出牌与动画
func play_card_animation_and_resolve() -> void:
	# 这里简化为：隐藏手牌区的牌，在中间生成盖住的牌
	await move_cards_to_table()
	
	# 等待一小会儿，然后亮牌
	await get_tree().create_timer(1.0).timeout
	reveal_cards()
	
	# 3结算逻辑
	resolve_combat()
	
	# 恢复按钮，等待玩家点击“下一回合”
	current_state = TurnState.RESOLVING # 保持状态直到点击按钮
	update_ui_text("结算完成！点击按钮进入下一回合")

	turn_button.disabled = false
	turn_button.text = "下一回合"
	
	# 镜头回到中间
	move_camera_to(center_pos.global_position)

func move_cards_to_table() -> void:
	# 使用 Tween 将具体的卡牌节点飞到中间
	# 这里做逻辑示意：
	print("P1 打出:", p1_played_card.get("name"))
	print("P2 打出:", p2_played_card.get("name"))
	
	# 隐藏手牌中的对应卡牌（模拟拿走）
	hide_played_card_in_hand(p1_hand_container, p1_played_card)
	hide_played_card_in_hand(p2_hand_container, p2_played_card)
	
	# 在中间生成“背面”卡牌
	create_face_down_card_at_center()
	
	await get_tree().create_timer(0.5).timeout

func reveal_cards() -> void:
	# 将中间的背面卡牌翻转为正面
	print("亮牌！")
	# 修改中间卡牌节点的 texture 为正面图
	flip_center_cards_to_face_up()


func resolve_combat() -> void:
	var p1_action = bs.get_card_action(p1_played_card.get("action_type"))
	var p2_action = bs.get_card_action(p2_played_card.get("action_type"))
	# 距离结算
	bs.settle_distance(p1_action, p2_action)
	# 伤害结算
	var result_data: BattleSystem.ResultData = bs.settle_damage(p1_action, p2_action)
	print("结算结果", result_data)
	# 更新血量状态
	if result_data is BattleSystem.ResultData and  result_data.hit_player == 1:
		bs.fighter2.health -= result_data.damage
	elif result_data is BattleSystem.ResultData and result_data.hit_player == 2:
		bs.fighter2.health -= result_data.damage
		
# 辅助功能

# 角色数据显示函数
func render_hero_data(player_info: Label, fighter: FighterData):
	# 1. 安全检查：防止传入空对象导致崩溃
	if player_info == null or fighter == null:
		push_warning("render_hero_data: 传入的 Label 或 FighterData 为空！")
		return

	# 2. 获取数据
	var p_name: String = fighter.get_name()
	var hp: int = fighter.get_health()
	var bonuses: Array[int] = fighter.get_bonus()
	var longmai: Array[int] = fighter.get_longmai_set()

	# 3. 格式化字符串 (使用 \n 换行)
	# 假设 bonus 顺序是：石头(0), 剪刀(1), 布(2)
	var text_content: String = ""
	text_content += "【%s】\n" % p_name
	text_content += "HP: %d / 10\n" % hp 
	text_content += "加成: ⚒️%d  ✂️%d  📄%d\n" % [bonuses[0], bonuses[1], bonuses[2]]
	text_content += "龙脉: [%d, %d, %d]" % [longmai[0], longmai[1], longmai[2]]

	# 4. 赋值给 Label
	player_info.text = text_content
	

# 渲染手牌
func render_hand(container: HFlowContainer, hand_data: Array, is_visible_face: bool) -> void:
	# 清空旧牌
	for child in container.get_children():
		child.queue_free()

	for card_data in hand_data:
		var card_btn = Button.new()
		card_btn.custom_minimum_size = Vector2(80, 120)
		card_btn.text = card_data["name"]
		
		# 如果是背面 (P2 的牌给 P1 看时)，不显示内容或显示背面图
		if not is_visible_face:
			card_btn.text = "???"
			card_btn.disabled = true
		
		# 连接点击事件
		if is_visible_face:
			card_btn.pressed.connect(_on_card_selected.bind(card_data, container))
		
		container.add_child(card_btn)

func _on_card_selected(card_data: Dictionary, container: HFlowContainer) -> void:
	print("ddddddddddd点击")
	if current_state == TurnState.P1_TURN and container == p1_hand_container:
		p1_played_card = card_data.duplicate(true)
		highlight_selected_card(container, card_data)
		message_label.text = "P1 已选牌，请点击过回合让 P2 出牌"
		
	elif current_state == TurnState.P2_TURN and container == p2_hand_container:
		p2_played_card = card_data.duplicate(true)
		highlight_selected_card(container, card_data)
		message_label.text = "P2 已选牌，请点击过回合进行结算"

func highlight_selected_card(container: HFlowContainer, data: Dictionary) -> void:
	# 简单的高亮逻辑：改变按钮颜色或边框
	for child in container.get_children():
		if child.text == data["name"]:
			child.modulate = Color(0.5, 1.0, 0.5) # 变绿
		else:
			child.modulate = Color(1, 1, 1)

func set_hand_interactive(container: HFlowContainer, active: bool) -> void:
	container.visible = active
	for child in container.get_children():
		if child is Button:
			child.disabled = not active

# 镜头平滑移动
func move_camera_to(target_pos: Vector2) -> void:
	var tween = create_tween()
	# 稍微加一点缩放效果，增强聚焦感
	tween.parallel().tween_property(camera, "position", target_pos, CAMERA_SPEED).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(camera, "zoom", Vector2(1.2, 1.2), CAMERA_SPEED).set_trans(Tween.TRANS_QUAD)

func update_distance(dist: BattleSystem.Distance) -> void:
	if dist == bs.Distance.CLOSE:
		distance_label.text = "距离：" + "近"
	elif dist == bs.Distance.MID:
		distance_label.text = "距离：" + "中"
	elif dist == bs.Distance.FAR:
		distance_label.text = "距离：" + "远"
# 占位函数 (实现具体的节点操作)
func hide_played_card_in_hand(container: HFlowContainer, data: Dictionary): pass
func create_face_down_card_at_center(): pass
func flip_center_cards_to_face_up(): pass
func update_ui_text(text: String): message_label.text = text
