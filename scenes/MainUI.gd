extends Control

var db_name := "res://database/Zulu"
var db

# Called when the node enters the scene tree for the first time.
func _ready():
	db = SQLite.new()
	db.path = db_name
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_btn_refresh_question_pressed():
	var wordtype = "noun"
	db.open_db()
	var ans = db.query("select native_word from LanguageWordList where word_types like '%" + 
	 wordtype + "%' limit 10;")
	print(db.query_result)
	#$Question.text = ans 
	pass # Replace with function body.
