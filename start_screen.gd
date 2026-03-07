extends Control

# 导出变量，方便在编辑器中拖拽赋值场景
@export var next_scene: PackedScene 

# 当节点进入场景树时运行（）
func _ready() -> void:
	# 连接按钮的 pressed 信号到对应的函数
	$ButtonContainer/StartButton.pressed.connect(_on_start_game_pressed)
	$ButtonContainer/ExitButton.pressed.connect(_on_exit_game_pressed)

# “开始游戏”按钮被点击时的逻辑
func _on_start_game_pressed() -> void:
	if next_scene:
		# 切换到下一个场景
		get_tree().change_scene_to_packed(next_scene)
	else:
		push_warning("未在 Inspector 中分配 next_scene 变量！无法跳转。")
		# get_tree().change_scene_to_file("res://Scene2.tscn") 

# “退出游戏”按钮被点击时的逻辑
func _on_exit_game_pressed() -> void:
	# 请求退出游戏
	get_tree().quit()
