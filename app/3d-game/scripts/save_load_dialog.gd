extends WindowDialog

# Signal emitted when a save slot is selected for loading.
signal load_requested(save_slot)

# Reference to the SaveLoadManager autoload.
var save_load : Node

func _ready() -> void:
    save_load = get_node("/root/save_load")
    $SlotList.clear()
    $LoadButton.disabled = true
    $SlotList.item_selected.connect(_on_slot_selected)
    $LoadButton.pressed.connect(_on_load_pressed)
    $CancelButton.pressed.connect(_on_cancel_pressed)
    _populate_slot_list()

func _populate_slot_list() -> void:
    var slots = save_load.call("get_save_slots")
    $SlotList.clear()
    for slot in slots:
        var display = slot["display_name"]
        var time = slot["timestamp"]
        # Convert timestamp to a readable string.
        var time_str = OS.get_time_string_from_unix_time(time)
        $SlotList.add_item("%s (%s)" % [display, time_str])
        $SlotList.set_item_metadata($SlotList.get_item_count() - 1, slot["id"])

func _on_slot_selected(index: int) -> void:
    $LoadButton.disabled = (index < 0)

func _on_load_pressed() -> void:
    var selected = $SlotList.get_selected_item()
    if selected >= 0:
        var slot_id = $SlotList.get_item_metadata(selected)
        emit_signal("load_requested", slot_id)
        hide()

func _on_cancel_pressed() -> void:
    hide()

# When the popup is about to be shown, refresh the list.
func _popup_popup() -> void:
    _populate_slot_list()
    $LoadButton.disabled = true
    $SlotList.deselect_all()