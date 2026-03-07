extends Node2D

#导出变量
@export var settings_scene: PackedScene # 设置场景
@export var longwang_battle: PackedScene   # 第三个场景（战斗场景）

# 这里用占位符，实际使用时替换为真实资源
var heroes_data = [
	{"name": "高尔", "texture": preload("res://icon.svg")}, 
	{"name": "伊莱恩", "texture": preload("res://icon.svg")},
	{"name": "多萝西", "texture": preload("res://icon.svg")},
	# ... 添加更多英雄
]

# --- 状态变量 ---
var current_player = 1 # 1 代表 P1, 2 代表 P2
var p1_selection = null
var p2_selection = null

@onready var root = get_parent() # 获取父节点 (即 CharacterSelect)

@onready var title_label: Label = root.get_node("TitleLabel")
@onready var p1_sprite: TextureRect = root.get_node("VS_Container/P1_Display/P1_Sprite")
@onready var p2_sprite: TextureRect = root.get_node("VS_Container/P2_Display/P2_Sprite")
@onready var hero_list: HFlowContainer = root.get_node("HeroGrid/HeroList")
@onready var confirm_button: Button = root.get_node("Footer/ConfirmButton")
@onready var settings_button: Button = root.get_node("Footer/Settings")

func _ready() -> void:
	_setup_signals()
	update_title()
	setup_hero_cards()
	confirm_button.disabled = true # 初始禁用确定按钮

# 更新标题提示当前该谁选
func update_title() -> void:
	if p1_selection and p2_selection:
		title_label.text = "准备就绪！"
	elif current_player == 1:
		title_label.text = "玩家 1 (P1): 请选择你的英雄"
	else:
		title_label.text = "玩家 2 (P2): 请选择你的英雄"

# 动态生成英雄卡片
func setup_hero_cards() -> void:
	# 清空现有卡片（防止重复）
	for child in hero_list.get_children():
		child.queue_free()
		
	for data in heroes_data:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(100, 140) # 卡片大小
		
		btn.icon = data["texture"]
		btn.tooltip_text = data["name"]
		
		# 关键：连接悬停信号实现放大效果
		btn.mouse_entered.connect(_on_card_mouse_entered.bind(btn))
		btn.mouse_exited.connect(_on_card_mouse_exited.bind(btn))
		btn.pressed.connect(_on_card_pressed.bind(data))
		
		hero_list.add_child(btn)

# --- 悬停放大效果 ---
func _on_card_mouse_entered(btn: Button) -> void:
	# 使用 Tween 实现平滑放大
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.15)
	# 确保放大后仍在最上层显示，不被遮挡
	btn.z_index = 10 

func _on_card_mouse_exited(btn: Button) -> void:
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)
	btn.z_index = 0

# --- 选择逻辑 ---
func _on_card_pressed(data: Dictionary) -> void:
	if p1_selection and p2_selection:
		return # 都已经选好了，忽略点击

	if current_player == 1:
		# P1 选择
		p1_selection = data
		p1_sprite.texture = data["texture"]
		current_player = 2 # 切换到 P2
	elif current_player == 2:
		# P2 选择
		p2_selection = data
		p2_sprite.texture = data["texture"]
		# 两人都选好了
		confirm_button.disabled = false
		current_player = 0 # 标记结束
		
	update_title()


func _on_confirm_button_pressed() -> void:
	print("按下")
	if p1_selection and p2_selection:
		# 传递数据到战斗场景（可选）
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.3).finished.connect(
			func(): get_tree().change_scene_to_packed(longwang_battle)
		)

func _on_settings_button_pressed() -> void:
	print("按下")
	if settings_scene:
		get_tree().change_scene_to_packed(settings_scene)



func _setup_signals() -> void:
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
