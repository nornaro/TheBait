extends Control

@onready var scene = preload("res://player.tscn")
@export_group("internal")
@export var gpt: GPTChatRequest
var state = true
var trivia = JSON.new()
var first = true
var language = "hungarian"
var player_count = 0
var players = {}
var c = 1
signal text_submitted

func _ready():	
	#var player_list = JSON.parse_string(FileAccess.open("res://players.json",FileAccess.READ).get_as_text())["Players"]
	var player_list = read_player_list()
	for pname : String in player_list:
		add_player(pname)
	gpt.gpt_request_completed.connect(_on_gpt_request_completed)
	gpt.api_key = decode_from_base64(FileAccess.open("res://key.cfg",FileAccess.READ).get_line()).substr(8)
	if !gpt.api_key:
		read_api_key()
		return
	querry()
	
func add_player(pname):
		player_count += 1
		var instance = scene.instantiate()
		instance.name = "Player"+str(player_count)
		instance.get_node("Name").text = pname
		%Players.add_child(instance)
		players[player_count] = instance

func encode_to_base64(data: String) -> String:
	var raw_data = data.to_utf8_buffer()
	return Marshalls.raw_to_base64(raw_data)

func decode_from_base64(base64_str: String) -> String:
	var raw_data = Marshalls.base64_to_raw(base64_str)
	return raw_data.get_string_from_utf8()

func read_api_key():
		$"../KeyInput".show()
	
func _on_gpt_request_completed(response_text: String):
	add_text_to_chat(response_text)

func _input(event):
	c = 1
	if Input.is_action_just_released("next"):
		querry()
	if Input.is_physical_key_pressed(KEY_CTRL):
		c = -1
	if Input.is_action_just_released("add"):
		add_player("")
	if Input.is_action_just_released("reset"):
		players.clear()
		write_player_list()
		get_tree().call_group("player","queue_free")
		
	for i in players.keys():
		if Input.is_physical_key_pressed(48+i):
			players[i].points += 1 * c
			players[i].get_node("Points").text = str(players[i].points).pad_zeros(2)
		
func querry():
		if !state && trivia:
			%Answer.text = "[center][color=white]"+trivia["answer"]+"[/color][/center]"
			state = !state
			return
		state = !state
		var err: Error
		if !first:
			err = gpt.gpt_chat_request("Next from different topic in " + language + "language, but not necessarily related to the people/country")
		if first:
			err = gpt.gpt_chat_request("
			Pick a random, weird, less known, unblelievable sounding, but true fact from wikipedia, regarding the picked theme. 
			Form a funy, trivia-like, stiking answer-question pair regarding it.
			Keep the - what is - type of questions to the minimum, more like - what happened, what was the etc. -
			The answer shouldn't be more than few words.
			Using in "+language+" language, return it as 
			dict={
				question:x,
				answer:y,
				source:z
				}
			}
			format, where sourceis a link.
			Don't pick questions, where you'd ask for dates, person or thing names, or values.
			Do not repeat questions.
			It is for a game, where you count on most people not knowing the answer:
				-	One person tells the information you give as the answer
				-	Others have to think of some belieavable lie in a few seconds
				-	One persone, who only knows the question, has to guess the correct answer
			")	
			first = false
		if err:
			add_text_to_chat( "Failed to send request to ChatGPT API")
			read_api_key()

func add_text_to_chat(text) -> void:
	trivia = JSON.parse_string(text)
	if !trivia:
		gpt.gpt_chat_request("Use dict={question:x, answer:y, source:z(link)} format")
		querry()
		return
	while !trivia.has("question") || !trivia.has("answer"):
		querry()
		return
	%Question.text = "[center][color=white]"+trivia["question"]+"[/color][/center]"
	%Answer.text = ""
	%Source.uri = trivia["source"]

func _on_hu_pressed():
	language = "hungarian"

func _on_en_pressed():
	language = "english"

func _on_change_pressed():
	read_api_key()

func _on_key_input_text_submitted(new_text):
	gpt.api_key=new_text
	FileAccess.open("res://key.cfg",FileAccess.WRITE).store_string(encode_to_base64("ragnarok"+gpt.api_key))
	$"../KeyInput".hide()
	querry()
	
func read_player_list() -> Array:
	var file = FileAccess.open("res://players.cfg", FileAccess.ModeFlags.READ)
	var player_list_var = file.get_line().split(",") as Array
	file.close()
	if !player_list_var is Array:
		return []
	return player_list_var

func write_player_list() -> void:
	var players_array = players.keys()
	var file = FileAccess.open("res://players.cfg", FileAccess.ModeFlags.WRITE)
	var players_string = ""
	for player in players_array:
		players_string += str(players[player].get_node("Name").text) + ","
	file.store_string(players_string)
	file.close()
