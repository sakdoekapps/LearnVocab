extends Control

var base_db_path := "res://database/Zulu.db"
var db_path := "user://database/Zulu.db"
var db
var settingsUIscene = load("res://scenes/SettingsUI.tscn")
var native_language
var foreign_language
var native_word_list = []
var foreign_word_list = []
var question_word
var answer_word
var correctUI = load("res://assetsetc/kenneyUI-green.tres")
var normalUI = load("res://assetsetc/kenneyUI-blue.tres")
var wrongUI = load("res://assetsetc/kenneyUI-red.tres")
var timeasked
var submit_answer_list = []

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
	
	# give us a question right away?
	_on_btn_refresh_question_pressed()
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func init_button_themes():
	$BaseHBox/BaseVBox/A1.text = ""
	$BaseHBox/BaseVBox/A2.text = ""
	$BaseHBox/BaseVBox/A3.text = ""
	$BaseHBox/BaseVBox/A1.theme = normalUI
	$BaseHBox/BaseVBox/A2.theme = normalUI
	$BaseHBox/BaseVBox/A3.theme = normalUI
	

func _on_btn_refresh_question_pressed():
	init_button_themes()
	var wordtype = "noun"
	# ISSUE: where pronouns are also included as nouns, adverbs in verbs etc. data cleansing might help this?
	# maybe verb should become "verbs". It looks like nouns are already nouns but verb is not verbs
	# another solution is to when looking for verb, look for like %verb% and not like %adverb%? Maybe add lots of options
	# auxiliary verbs, do they go into that list? Maybe add all this into options
	
	var wordtypesql = "TRUE" if wordtype == "all" else "word_types like '%" + wordtype + "%'"
	# Sort of starting to get the valid list of words, but not complete
	# TODO: Add ways to ignore "known" words
	var sql = "Select * from LanguageWordList lwl left join ( " + \
		"SELECT " + \
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

	native_word_list = []
	foreign_word_list = []
	
	# load words into arrays (might be a way to just do this in one go?)
	for i in db.query_result:
		native_word_list.append(i["native_word"])
		foreign_word_list.append(i["foreign_word"])
	
	native_language = db.query_result[0]["native_language"]
	foreign_language = db.query_result[0]["foreign_language"]
	
	var q = randi_range(0,9)
	var answerindex = q
	question_word = foreign_word_list[answerindex]
	answer_word = native_word_list[answerindex]
	foreign_word_list.remove_at(q)
	native_word_list.remove_at(q)
	
	var answer_list = []
	answer_list.append(answer_word)
	
	# Add 2 wrong answers
	answer_list.append(get_and_remove_random_item(native_word_list))
	answer_list.append(get_and_remove_random_item(native_word_list))
	
	
	submit_answer_list = []
	submit_answer_list = answer_list.duplicate()
	var button_answer_list = answer_list.duplicate()

	# Assign text to buttons without modifying the original answer_list
	$BaseHBox/BaseVBox/A1.text = get_and_remove_random_item(button_answer_list)
	$BaseHBox/BaseVBox/A2.text = get_and_remove_random_item(button_answer_list)
	$BaseHBox/BaseVBox/A3.text = get_and_remove_random_item(button_answer_list)
	# Debug
	$BaseHBox/BaseVBox/VSpace2.text = str(submit_answer_list)
	
	$BaseHBox/BaseVBox/Question.text = '\n[center]' + question_word + '\n [font_size=30]' + db.query_result[answerindex]["word_types"] + "[/font_size][/center]"
	timeasked = Time.get_datetime_string_from_system(true)
	


	# ... (remaining code)

# Helper function to get and remove a random item from a list
func get_and_remove_random_item(list):
	var index = randi_range(0, list.size() - 1)
	var item = list[index]
	list.remove_at(index)
	return item
	


func _on_btn_exit_pressed():
	get_tree().quit()


func _on_btn_settings_pressed():
	# Try not to unload this scene, we want the DB to stay in memory, 
	# we don't want to constantly close/open the DB
	get_tree().change_scene_to_packed(settingsUIscene)


func answer_pressed(caller):
	var correct
	print(question_word + " : \t Answer pressed : \t" + caller.text + " Correct Answer: \t" + answer_word)
	if answer_word == caller.text:
		caller.theme = correctUI
		correct = true
	else:
		correct = false
		caller.theme = wrongUI
		if $BaseHBox/BaseVBox/A1.text == answer_word:
			$BaseHBox/BaseVBox/A1.theme = correctUI
		if $BaseHBox/BaseVBox/A2.text == answer_word:
			$BaseHBox/BaseVBox/A2.theme = correctUI
		if $BaseHBox/BaseVBox/A3.text == answer_word:
			$BaseHBox/BaseVBox/A3.theme = correctUI

	submit_transaction_data("Normal", native_language, foreign_language, question_word, answer_word, \
		submit_answer_list, true, correct, timeasked, Time.get_datetime_string_from_system(true))
	

	await get_tree().create_timer(10.0)
	caller.release_focus()
	_on_btn_refresh_question_pressed()

		

# Function to submit data to the database
func submit_transaction_data(question_type, native_language, foreign_language, question_word, answer_word, answer_list, answered, correct, time_asked, time_answered):
	var insertRowQuery = "INSERT INTO QuestionTransactions (\
		question_type, native_language, foreign_language,\
		question_word, answer_word, answer_list,\
		answered, correct, time_asked, time_answered\
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"

	var insertRowParams = [question_type, native_language, foreign_language, question_word, answer_word, str(answer_list), answered, correct, time_asked, time_answered]

	db.query_with_bindings(insertRowQuery, insertRowParams)

func _on_a_1_pressed():
	answer_pressed($BaseHBox/BaseVBox/A1)


func _on_a_2_pressed():
	answer_pressed($BaseHBox/BaseVBox/A2)


func _on_a_3_pressed():
	answer_pressed($BaseHBox/BaseVBox/A3)
