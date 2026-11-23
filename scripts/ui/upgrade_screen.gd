extends Control

@export_file("*.tscn") var game_scene: String

@onready var rune_label: Label = %RuneLabel
@onready var info_label: Label = %InfoLabel
@onready var slot_grid: GridContainer = %SlotGrid
@onready var retry_button: Button = %RetryButton

func _ready() -> void:
	_update_runes_display()
	
	for child in slot_grid.get_children():
		if child is UpgradeSlot:
			child.show_info.connect(_on_show_info)
			child.upgrade_clicked.connect(_on_upgrade_clicked)
			
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)

func _on_show_info(text: String) -> void:
	info_label.text = text

func _on_upgrade_clicked(slot: UpgradeSlot) -> void:
	if GameManager.buy_upgrade(slot.stat_id):
		slot.refresh()
		slot._on_button_hovered()
		_update_runes_display()
	else:
		info_label.text = "Not enough Runes! (Need %d Runes)" % GameManager.get_cost(slot.stat_id)

func _update_runes_display() -> void:
	rune_label.text = "Runes: %d" % GameManager.runes

func _on_retry_pressed() -> void:
	if game_scene != "":
		get_tree().change_scene_to_file(game_scene)
