extends Control

@export_group("internal")
@export var gpt: GPTChatRequest
var state = true
var trivia = JSON.new()
var first = true
var language = "english"

var points = [0,0,0,0,0,0]
var c = 1
func _ready():
	gpt.gpt_request_completed.connect(_on_gpt_request_completed)
	gpt.api_key = decode_from_base64(FileAccess.open("res://key.cfg",FileAccess.READ).get_line()).substr(8)

	if !gpt.api_key:
		read_api_key()
		return
	querry()

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

func _input(_event):
	c = 1
	if Input.is_physical_key_pressed(KEY_SPACE):
		querry()
	if Input.is_physical_key_pressed(KEY_CTRL):
		c = -1
	for i in [1,2,3,4,5]:
		if Input.is_physical_key_pressed(48+i):
			points[i] += 1 * c
			get_node("../Control/Panel/Players/Points"+str(i)).text = str(points[i]).pad_zeros(2)
		
func querry():
		if !state && trivia:
			%Answer.text = "[center][color=white]"+trivia["answer"]+"[/color][/center]"
			state = !state
			return
		state = !state
		var err: Error
		if !first:
			err = gpt.gpt_chat_request("Next from different topic in " + language)
		if first:
			err = gpt.gpt_chat_request("Pick a random theme ftom: weird history, weird universe, weird science. Pick a new, less known, unblelievable sounding, but true fact from wikipedia, regarding the picked one. Form a funy trivia-like stiking answer-question pair regarding it and the answer shouldn't be more than few words in "+language+", return it as dict={question:x., answer:y, source:z} format - don't ask for dates, names, or values, do not repeat a question")
			first = false
		if err:
			add_text_to_chat( "Failed to send request to ChatGPT API")
			read_api_key()

func add_text_to_chat(text) -> void:
	trivia = JSON.parse_string(text)
	if !trivia:
		querry()
		return
	while !trivia.has("question") || !trivia.has("answer"):
		querry()
		return
	%Question.text = "[center][color=white]"+trivia["question"]+"[/color][/center]"
	%Answer.text = ""
	$"../Control/Panel/Menu/Source".text = trivia["source"]
	

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
	
