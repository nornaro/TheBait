extends BoxContainer

@export var points = 0

func _on_name_text_submitted(new_text):
	finalize()
	
func finalize():
	get_tree().call_group("main","write_player_list")
	$Name.focus_mode = FOCUS_NONE
	$Name.focus_mode = FOCUS_CLICK
