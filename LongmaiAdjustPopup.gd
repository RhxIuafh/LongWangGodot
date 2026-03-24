class_name LongmaiAdjustPopup extends Control

signal adjustment_confirmed(attribute: String, change_amount: int, is_positive: bool)

var current_attribute: String = ""
var change_amount: int = 0

func setup(attribute: String, amount: int, player: int) -> void:
	current_attribute = attribute
	change_amount = amount
	
	# 更新UI文本
	var info_label = $Panel/VBoxContainer/InfoLabel
	info_label.text = "玩家p[%d]龙脉 [%s] 发生变动！\n变动数值：%d" % [player, attribute, amount]
	

func _on_btn_plus_pressed() -> void:
	# 发送信号：确认增加
	adjustment_confirmed.emit(current_attribute, change_amount, true)
	queue_free() # 关闭弹窗

func _on_btn_minus_pressed() -> void:
	# 发送信号：确认减少 (注意：这里传入的 amount 是绝对值，逻辑层会处理负号)
	adjustment_confirmed.emit(current_attribute, change_amount, false)
	queue_free() # 关闭弹窗

# 记得在编辑器里连接按钮的 pressed 信号到这两个函数
