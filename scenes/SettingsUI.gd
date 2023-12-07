extends Control

var db_path := "user://database/Zulu.db"
var db
var MainUIscene = load("res://scenes/MainUI.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	# Read all settings and put them in the 
	db = SQLite.new()
	db.path = db_path
	db.open_db()
	db.query("select * from Settings")
	
	$Tree.set_column_title(0,"Setting")
	$Tree.set_column_title(1,"Value")
	var root = $Tree.create_item()
	
	for setting in db.query_result:
		var asetting = $Tree.create_item(root)
		asetting.set_text(0,setting["SettingString"])
		asetting.set_text(1,setting["SettingValue"])
	
		
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_btn_exit_no_save_pressed():
	# Try not to unload this scene, we want the DB to stay in memory, 
	# we don't want to constantly close/open the DB
	get_tree().change_scene_to_packed(MainUIscene) # this throws a bug at the moment...
	
