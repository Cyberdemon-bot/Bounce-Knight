extends Node

signal runes_changed(new_amount: int)
signal stats_upgraded

var runes: int = 0

var hp_level: int = 0
var damage_level: int = 0
var cooldown_level: int = 0

func get_hp_cost() -> int: return 5 + hp_level * 5
func get_damage_cost() -> int: return 8 + damage_level * 7
func get_cooldown_cost() -> int: return 6 + cooldown_level * 6

func get_max_hp() -> int:
	return 5 + hp_level * 2

func get_damage() -> int:
	return 1 + damage_level

func get_cooldown_multiplier() -> float:
	return max(0.4, 1.0 - cooldown_level * 0.12)

func add_runes(amount: int) -> void:
	runes += amount
	runes_changed.emit(runes)

func upgrade_hp() -> bool:
	var cost := get_hp_cost()
	if runes >= cost:
		runes -= cost
		hp_level += 1
		runes_changed.emit(runes)
		stats_upgraded.emit()
		return true
	return false

func upgrade_damage() -> bool:
	var cost := get_damage_cost()
	if runes >= cost:
		runes -= cost
		damage_level += 1
		runes_changed.emit(runes)
		stats_upgraded.emit()
		return true
	return false

func upgrade_cooldown() -> bool:
	var cost := get_cooldown_cost()
	if runes >= cost:
		runes -= cost
		cooldown_level += 1
		runes_changed.emit(runes)
		stats_upgraded.emit()
		return true
	return false
