extends Control

var base_db_path := "res://database/Zulu.db"
var db_path := "user://database/Zulu.db"
var db

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
	
	
	# Sort of starting to get the valid list of words, but not complete
	#Select * from LanguageWordList lwl left join (
		#SELECT 
		   #native_language,
	   	   #foreign_language, 
		   #question_word, 
		   #sum(correct) / sum(answered) as correctperc,
		   #max(time_answered) as lastanswered,
		   #JULIANDAY('now') - max(time_answered) as days_since_last_answered
		#from QuestionTransactions qt
		#group by native_language, foreign_language, question_word ) t on t.question_word = lwl.native_word
	
	var wordtypesql = "TRUE" if wordtype == "all" else "word_types like '%" + wordtype + "%'"
	
	db.open_db()
	db.query("select native_word, foreign_word from LanguageWordList where " + wordtypesql + ";")
	print(db.query_result)
	

func _on_btn_exit_pressed():
	get_tree().quit()


func _on_btn_settings_pressed():
	# Open the app settings scene
	pass # Replace with function body.
