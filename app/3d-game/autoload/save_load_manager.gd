extends Node

# Singleton for saving and loading game data.
# We'll save to user://saves/

const SAVE_DIR = "user://saves/"
const SAVE_EXTENSION = ".save"
const SAVE_VERSION = "1.0.0"

# Returns a list of available save slots.
# Each slot is a dictionary: { "id": String, "timestamp": int, "display_name": String, "playtime": int }
func get_save_slots() -> Array:
	var slots = []
	var dir = Directory.new()
	if dir.open(SAVE_DIR) == OK:
		dir.list_begin(true)
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(SAVE_EXTENSION):
				var file = FileAccess.new()
				if file.open(SAVE_DIR + file_name, FileAccess.READ) == OK:
					var save_game = parse_json(file.get_as_text())
					if save_game and save_game.has("version"):
						var slot_id = file_name[:-SAVE_EXTENSION.length()]  # Remove extension
						var timestamp = int(save_game.get("timestamp", 0))
						var display_name = save_game.get("player_name", "Unknown")
						var playtime = int(save_game.get("playtime_seconds", 0))
						slots.append({
							"id": slot_id,
							"timestamp": timestamp,
							"display_name": display_name,
							"playtime": playtime
						})
				file.close()
			}
			file_name = dir.get_next()
		dir.list_end()
	dir.close()
	# Sort by timestamp, newest first
	slots.sort(func(a, b):
		return b.timestamp - a.timestamp
	)
	return slots

# Save the game state to a slot.
# Returns true if successful.
func save_game(slot_id: String, player_name: String, game_state: Dictionary) -> bool:
	var save_data = {
		"version": SAVE_VERSION,
		"timestamp": OS.get_unix_time(),
		"player_name": player_name,
		"playtime_seconds": game_state.get("playtime_seconds", 0),
		"game_state": game_state
	}
	var json_string = to_json(save_data)
	var dir = Directory.new()
	if dir.open(SAVE_DIR) != OK:
		dir.make_dir_recursive(SAVE_DIR)
	var file = FileAccess.new()
	if file.open(SAVE_DIR + slot_id + SAVE_EXTENSION, FileAccess.WRITE) == OK:
		file.store_string(json_string)
		file.close()
		return true
	return false

# Load the game state from a slot.
# Returns the game state dictionary if successful, or null on failure.
func load_game(slot_id: String) -> Dictionary:
	var file = FileAccess.new()
	if file.open(SAVE_DIR + slot_id + SAVE_EXTENSION, FileAccess.READ) != OK:
		push_error("Could not open save file: " + slot_id)
		return null
	var json_string = file.get_as_text()
	file.close()
	var save_game = parse_json(json_string)
	if save_game == null:
		push_error("Failed to parse save file: " + slot_id)
		return null
	if save_game.get("version") != SAVE_VERSION:
		push_warning("Save file version mismatch: " + save_game.get("version") + " expected " + SAVE_VERSION)
	# We still return the game state, but the caller should handle version differences.
	return save_game.get("game_state", {})

# Delete a save slot.
func delete_save(slot_id: String) -> bool:
	var dir = Directory.new()
	if dir.remove(SAVE_DIR + slot_id + SAVE_EXTENSION) == OK:
		return true
	return false