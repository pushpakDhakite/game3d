extends Control

# Signal emitted when new game is requested with a player name
signal new_game_requested(player_name)
# Signal emitted when continue is requested with a save slot
signal continue_requested(save_slot)
# Signal emitted when settings is requested
signal settings_requested
# Signal emitted when exit is requested
signal exit_requested

# References to the dialogs
var name_input_dialog : AcceptDialog
var save_load_dialog : WindowDialog
var settings_dialog : AcceptDialog

func _ready() -> void:
    $NewGameButton.pressed.connect(_on_new_game_pressed)
    $ContinueButton.pressed.connect(_on_continue_pressed)
    $SettingsButton.pressed.connect(_on_settings_pressed)
    $ExitButton.pressed.connect(_on_exit_pressed)
    
    # Load the dialogs (we'll instance them as children)
    name_input_dialog = preload("res://scenes/name_input_dialog.tscn").instantiate()
    add_child(name_input_dialog)
    name_input_dialog.name_submitted.connect(_on_name_submitted)
    
    save_load_dialog = preload("res://scenes/save_load_dialog.tscn").instantiate()
    add_child(save_load_dialog)
    save_load_dialog.load_requested.connect(_on_load_requested)
    
    settings_dialog = preload("res://scenes/settings_dialog.tscn").instantiate()
    add_child(settings_dialog)
    
    # Check for save slots to enable/disable continue button
    _update_continue_button()

func _on_new_game_pressed() -> void:
    name_input_dialog.popup_centered()

func _on_continue_pressed() -> void:
    save_load_dialog.popup_centered()

func _on_settings_pressed() -> void:
    settings_dialog.popup_centered()

func _on_exit_pressed() -> void:
    get_tree().quit()

func _on_name_submitted(player_name: String) -> void:
    # Reset the game state for a new game
    var game_state = get_node("/root/game_state")
    game_state.reset()
    game_state.player_name = player_name
    # Change to the gameplay scene
    get_tree().change_scene_to_file("res://scenes/gameplay.tscn")
    emit_signal("new_game_requested", player_name)

func _on_load_requested(save_slot: String) -> void:
    var save_load = get_node("/root/save_load")
    var game_state = get_node("/root/game_state")
    var loaded_state = save_load.call("load_game", save_slot)
    if loaded_state != null:
        game_state.from_dict(loaded_state)
        get_tree().change_scene_to_file("res://scenes/gameplay.tscn")
        emit_signal("continue_requested", save_slot)
    else:
        print("Failed to load save slot: " + save_slot)

func _update_continue_button() -> void:
    var save_load = get_node("/root/save_load")
    var slots = save_load.call("get_save_slots")
    $ContinueButton.disabled = (slots.size() == 0)