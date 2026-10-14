extends Node

var demons_killed: int = 0
var required_demons: int = 2
var required_coins: int = 100
var coins_offered: int = 0
var quest_complete: bool = false

signal demon_slain(current: int, target: int)
signal quest_updated(objective_text: String)
signal gate_unsealed

func record_demon_kill() -> void:
	demons_killed += 1
	demon_slain.emit(demons_killed, required_demons)
	quest_updated.emit(get_objective_text())

func can_offer() -> bool:
	return (not quest_complete) and (GameManager.player_coins >= required_coins)

func offer_coins() -> bool:
	if can_offer():
		if GameManager.spend_coins(required_coins):
			coins_offered += required_coins
			quest_complete = true
			gate_unsealed.emit()
			quest_updated.emit(get_objective_text())
			return true
	return false

func get_objective_text() -> String:
	if not GameManager.has_armor or not GameManager.has_sword:
		return "Visit Swordsmith Torren and equip your gear"
	
	if not quest_complete:
		if demons_killed < required_demons:
			return "Slay gate demons (%d/%d) near South Gate" % [demons_killed, required_demons]
		elif GameManager.player_coins < required_coins:
			return "Collect dropped gold (%d/%d)" % [GameManager.player_coins, required_coins]
		else:
			return "Offer %d gold at Central Altar" % required_coins
	else:
		return "South Gate unsealed! March into the Demon Lord's Domain"

func reset_quest() -> void:
	demons_killed = 0
	coins_offered = 0
	quest_complete = false
	quest_updated.emit(get_objective_text())
