extends Control

var db_path := "user://database/Zulu.db"
var db

# Called when the node enters the scene tree for the first time.
func _ready():
	# Read all settings and put them in the 
	db = SQLite.new()
	db.path = db_path
	db.open_db()
	db.query("select * from Settings")
	
	for setting in db.query_result:
		$SettingsTable.add_item(setting)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
