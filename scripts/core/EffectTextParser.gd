extends RefCounted

static func parse_enemy_flee_effects(text):
	var source = _normalize_text(text)
	var effects: Array = []
	if source.is_empty():
		return effects
	if source.contains("-4 p.v") or source.contains("-4 pv"):
		effects.append({
			"type": "lose_hp",
			"amount": 4
		})
	if source.contains("per 3 turni") and source.contains("dado casuale") and source.contains("inutilizzabile"):
		effects.append({
			"type": "disable_random_die_for_turns",
			"turns": 3,
			"target": "random_die"
		})
	if source.contains("rimuovi un simbolo da un dado"):
		effects.append({
			"type": "remove_symbol_from_die",
			"amount": 1,
			"target": "chosen_die"
		})
	return effects

static func parse_enemy_reward_effects(text):
	var source = _normalize_text(text)
	var effects: Array = []
	if source.is_empty():
		return effects
	if source.contains("10 monete"):
		effects.append({
			"type": "gain_coins",
			"amount": 10
		})
	if source.contains("15 monete"):
		effects.append({
			"type": "gain_coins",
			"amount": 15
		})
	if source.contains("5 exp"):
		effects.append({
			"type": "gain_exp",
			"amount": 5
		})
	if source.contains("aggiungi un dado vuoto al tuo zaino"):
		effects.append({
			"type": "add_blank_die",
			"amount": 1
		})
	if source.contains("raddoppia un simbolo ad una faccia di un dado"):
		effects.append({
			"type": "double_symbol_on_die_face",
			"target": "chosen_die_face"
		})
	return effects

static func parse_character_ability_effects(text):
	var source = _normalize_text(text)
	var effects: Array = []
	if source.is_empty():
		return effects
	if source.contains("paga un punto vita") or source.contains("paga 1 punto vita"):
		effects.append({
			"type": "pay_hp_cost",
			"amount": 1
		})
	if source.contains("riattiva un dado esausto"):
		effects.append({
			"type": "reactivate_exhausted_die",
			"target": "chosen_die"
		})
	if source.contains("creare un simbolo effimero") or source.contains("crea un simbolo effimero"):
		effects.append({
			"type": "create_ephemeral_symbol",
			"lifetime": "until_used"
		})
	if source.contains("setta un dado esausto sul simbolo che preferisci"):
		effects.append({
			"type": "set_exhausted_die_symbol",
			"target": "chosen_die",
			"symbol": "chosen_symbol"
		})
	if source.contains("scegliere una riga/colonna in piu oltre alla prima") or source.contains("scegliere una riga/colonna in più oltre alla prima"):
		effects.append({
			"type": "select_extra_line",
			"amount": 1
		})
	return effects

static func _normalize_text(text):
	var source = str(text).to_lower().strip_edges()
	source = source.replace("è", "e")
	source = source.replace("é", "e")
	source = source.replace("più", "piu")
	source = source.replace("Ã¨", "e")
	source = source.replace("piÃ¹", "piu")
	source = source.replace("golonna", "colonna")
	return source
