extends Node

signal runes_changed(new_amount: int)
signal stats_upgraded

const UPGRADES := {
	&"max_hp": { "base": 5.0, "step": 1.0, "max": 5, "cost": 20, "cost_step": 15 },
	&"speed": { "base": 100.0, "step": 15.0, "max": 5, "cost": 20, "cost_step": 15 },
	&"jump_power": { "base": -270.0, "step": -10.0, "max": 5, "cost": 20, "cost_step": 15 },
	&"dash_speed": { "base": 350.0, "step": 35.0, "max": 5, "cost": 25, "cost_step": 20 },
	&"dash_bounce_mult": { "base": 1.3, "step": 0.12,  "max": 5, "cost": 25, "cost_step": 20 },
	&"skill_cooldown": { "base": 20.0, "step": -2, "max": 5, "cost": 30, "cost_step": 25},
}

var runes: int = 100
var levels: Dictionary = {}



func get_level(id: StringName) -> int:
	return levels.get(id, 0)

func get_max_level(id: StringName) -> int:
	return UPGRADES[id].max
	
func get_cost(id: StringName) -> int:
	var cfg: Dictionary = UPGRADES[id]
	return cfg.cost + get_level(id)*cfg.cost_step

func stat(id: StringName) -> float:
	var cfg: Dictionary = UPGRADES[id]
	return cfg.base + get_level(id)*cfg.step

func add_runes(amount: int) -> void:
	runes += amount
	runes_changed.emit(runes)

func buy_upgrade(id: StringName) -> bool:
	var lvl := get_level(id)
	var cost := get_cost(id)
	if runes < cost or lvl >= get_max_level(id):
		return false
	add_runes(-cost)
	levels[id] = lvl+1
	return true
