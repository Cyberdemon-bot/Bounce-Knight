@tool
class_name UpgradeSlot
extends VBoxContainer

signal show_info(text: String)
signal upgrade_clicked(slot: UpgradeSlot)

@export var skill_name: String = "SKILL"
@export var skill_desc: String = "Basic description."
@export var icon_texture: Texture2D:
	set(value):
		icon_texture = value
		if is_node_ready():
			icon_box.texture = value
@export var current_level: int = 1
@export var max_level: int = 5
@export var base_cost: int = 20
@export var cost_increase: int = 15

@onready var icon_box: TextureRect = $IconBox
@onready var level_up_btn: Button = %LevelUpButton

func _ready() -> void:
	if icon_texture:
		icon_box.texture = icon_texture

	icon_box.mouse_entered.connect(_on_icon_hovered)
	
	level_up_btn.mouse_entered.connect(_on_button_hovered)
	level_up_btn.pressed.connect(func(): upgrade_clicked.emit(self))
	_update_button_state()

func get_current_cost() -> int:
	return base_cost + (current_level - 1) * cost_increase

func _on_icon_hovered() -> void:
	show_info.emit("%s: %s" % [skill_name.to_upper(), skill_desc])

func _on_button_hovered() -> void:
	if current_level >= max_level:
		show_info.emit("%s: MAX LEVEL (Lv.%d)" % [skill_name.to_upper(), current_level])
	else:
		show_info.emit("UPGRADE %s: Lv.%d -> Lv.%d  |  COST: %d RUNES" % [
			skill_name.to_upper(), current_level, current_level + 1, get_current_cost()
		])

func level_up_success() -> void:
	current_level += 1
	_update_button_state()
	_on_button_hovered()

func _update_button_state() -> void:
	if current_level >= max_level:
		level_up_btn.text = "MAX"
		level_up_btn.disabled = true
