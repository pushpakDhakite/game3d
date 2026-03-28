extends AcceptDialog

signal name_submitted(player_name: String)

func _ready() -> void:
	$VBoxContainer/NameEdit.text_submitted.connect(_on_name_entered)
	confirmed.connect(_on_confirmed)

func _on_name_entered(new_text: String) -> void:
	if new_text.strip_edges() != "":
		emit_signal("name_submitted", new_text.strip_edges())
		hide()

func _on_confirmed() -> void:
	var name = $VBoxContainer/NameEdit.text.strip_edges()
	if name != "":
		emit_signal("name_submitted", name)
		hide()
