extends Control

@export_file("*.tscn") var game_scene: String

var current_RUNES: int = 100

@onready var coin_label: Label = %CoinLabel
@onready var info_label: Label = %InfoLabel
@onready var slot_grid: GridContainer = %SlotGrid
@onready var retry_button: Button = %RetryButton

func _ready() -> void:
	_update_coin_display()
	
	for child in slot_grid.get_children():
		if child is UpgradeSlot:
			child.show_info.connect(_on_show_info)
			child.upgrade_clicked.connect(_on_upgrade_clicked)
			
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)

func _on_show_info(text: String) -> void:
	info_label.text = text

func _on_upgrade_clicked(slot: UpgradeSlot) -> void:
	var cost := slot.get_current_cost()
	if slot.current_level >= slot.max_level:
		return
		
	if current_RUNES >= cost:
		current_RUNES -= cost
		_update_coin_display()
		slot.level_up_success()
	else:
		info_label.text = "NOT ENOUGH RUNES! (NEED %d RUNES)" % cost

func _update_coin_display() -> void:
	coin_label.text = "RUNES: %d" % current_RUNES

func _on_retry_pressed() -> void:
	if game_scene != "":
		get_tree().change_scene_to_file(game_scene)
