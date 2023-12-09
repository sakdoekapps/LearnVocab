extends Control

var base_db_path := "res://database/Zulu.db"
var db_path := "user://database/Zulu.db"
var db
var settingsUIscene = load("res://scenes/SettingsUI.tscn")
var native_word_list = []
var foreign_word_list = []
var question_word
var answer_word


# Called when the node enters the scene tree for the first time.
func _ready():
	
	# First time check if the DB is in the user folder, as android cannot write to res://
	if not FileAccess.file_exists(db_path):
		var src_file_bytes = FileAccess.get_file_as_bytes(base_db_path)
	
		# The folder also probably doesn't exist
		var dirs = DirAccess.open("user://")
		if not dirs.dir_exists("user://database"):
			dirs.make_dir("database")
		
		var dest_file = FileAccess.open(db_path, FileAccess.WRITE)
		dest_file.store_buffer(src_file_bytes)
		dest_file.close()


	db = SQLite.new()
	db.path = db_path
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_btn_refresh_question_pressed():
	var wordtype = "noun"
	# ISSUE: where pronouns are also included as nouns, adverbs in verbs etc. data cleansing might help this?
	# maybe verb should become "verbs". It looks like nouns are already nouns but verb is not verbs
	# another solution is to when looking for verb, look for like %verb% and not like %adverb%? Maybe add lots of options
	# auxiliary verbs, do they go into that list? Maybe add all this into options
	
	var wordtypesql = "TRUE" if wordtype == "all" else "word_types like '%" + wordtype + "%'"
	# Sort of starting to get the valid list of words, but not complete
	# TODO: Add ways to ignore "known" words
	var sql = "Select * from LanguageWordList lwl left join ( " + \
		"SELECT native_language, " + \
		"   foreign_language, " + \
		"   question_word, " + \
		"   sum(correct) / sum(answered) as correctperc, " + \
		"   max(time_answered) as lastanswered, " + \
		"   JULIANDAY('now') - max(time_answered) as days_since_last_answered " + \
		"from QuestionTransactions qt " + \
		"group by native_language, foreign_language, question_word ) t on t.question_word = lwl.native_word " + \
		"WHERE " + wordtypesql + \
		"limit 10"
	
	db.open_db()
	db.query(sql)

	
	# load words into arrays (might be a way to just do this in one go?)
	for i in db.query_result:
		native_word_list.append(i["native_word"])
		foreign_word_list.append(i["foreign_word"])
	
	var q = randi_range(0,9)
	question_word = foreign_word_list[q]
	answer_word = native_word_list[q]
	
	foreign_word_list.remove_at(q)
	native_word_list.remove_at(q)
	
	var answer_list = []
	answer_list.append(answer_word)
	
	# in 1 means 0 and 1 I think...
	for i in 2:
		q = randi_range(0,native_word_list.size()-1)
		answer_list.append(native_word_list[q])
		native_word_list.remove_at(q)
	
	$BaseHBox/BaseVBox/Question.text = question_word
	
	q = randi_range(0,answer_list.size()-1)
	$BaseHBox/BaseVBox/A1.text = answer_list[q]
	answer_list.remove_at(q)
	q = randi_range(0,answer_list.size()-1)
	$BaseHBox/BaseVBox/A2.text = answer_list[q]
	answer_list.remove_at(q)
	$BaseHBox/BaseVBox/A3.text = answer_list[0]

	
	

func _on_btn_exit_pressed():
	get_tree().quit()


func _on_btn_settings_pressed():
	# Try not to unload this scene, we want the DB to stay in memory, 
	# we don't want to constantly close/open the DB
	get_tree().change_scene_to_packed(settingsUIscene)



func answer_pressed(caller):
	print(caller.text + " " + answer_word)
	pass # Replace with function body.


func _on_a_1_pressed():
	answer_pressed($BaseHBox/BaseVBox/A1)


func _on_a_2_pressed():
	answer_pressed($BaseHBox/BaseVBox/A2)


func _on_a_3_pressed():
	answer_pressed($BaseHBox/BaseVBox/A3)
