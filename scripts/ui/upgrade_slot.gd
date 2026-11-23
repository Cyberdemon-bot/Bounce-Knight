@tool
class_name UpgradeSlot
extends VBoxContainer

signal show_info(text: String)
signal upgrade_clicked(slot: UpgradeSlot)

@export var stat_id: StringName = &"max_hp"
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
@onready var level_up_btn: Button = $LevelUpButton

func _ready() -> void:
	if icon_texture:
		icon_box.texture = icon_texture
	if Engine.is_editor_hint():
		return
	icon_box.mouse_entered.connect(_on_icon_hovered)
	
	level_up_btn.mouse_entered.connect(_on_button_hovered)
	level_up_btn.pressed.connect(func(): upgrade_clicked.emit(self))
	refresh()

func get_current_cost() -> int:
	return base_cost + (current_level - 1) * cost_increase

func _on_icon_hovered() -> void:
	show_info.emit("%s: %s" % [skill_name.to_upper(), skill_desc])

func refresh() -> void:
	var maxed := GameManager.get_level(stat_id) >= GameManager.get_max_level(stat_id)
	level_up_btn.text = "Max" if maxed else "Level up"
	level_up_btn.disabled = maxed

func _on_button_hovered() -> void:
	var lvl := GameManager.get_level(stat_id)
	var max_lvl := GameManager.get_max_level(stat_id)
	if lvl >= max_lvl:
		show_info.emit("%s: Max level (Lv.%d)" % [skill_name.to_upper(), current_level])
	else:
		show_info.emit("Upgrade %s: Lv.%d -> Lv.%d  |  Cost: %d Runes" % [
			skill_name.to_upper(), lvl, lvl + 1, GameManager.get_cost(stat_id)
		])
