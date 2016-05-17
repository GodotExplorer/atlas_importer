extends Node2D


var AtlasParser = load("res://addons/atlas_importer/atlas.gd")
var FrameItem = load("res://addons/atlas_importer/frame_item.tscn")
onready var dialog = get_node("Dialog")
onready var listbox = dialog.get_node("Preview/Background/ScrollContainer/VBox")
var fileDialog = FileDialog.new()
var atlas = AtlasParser.new()
var tex = null

func _ready():
	fileDialog.connect("file_selected", self, "_metaFileSelected")
	fileDialog.connect("dir_selected", self, "_tarDirSelected")
	add_child(fileDialog)

	dialog.get_ok().set_text("Import")
	dialog.get_node("Input/Source/Browse").connect("pressed", self, "_selectMetaFile")
	dialog.get_node("Input/Target/Browse").connect("pressed", self, "_selectTargetDir")
	dialog.get_node("Input/Target/TargetDirField").connect("text_changed", self, "_checkPath")
	dialog.get_node("Input/Source/MetaFileField").connect("text_changed", self, "_checkPath")
	dialog.get_node("Input/Type/TypeButton").connect("item_selected", self, "_typeSelected")
	dialog.get_node("Input/Type/TypeButton").select(0)
	dialog.get_node("Preview/SelAll").connect("pressed", self, "_toggleAll")
	dialog.get_node("Preview/Clear").connect("pressed", self, "_untoggleAll")
	dialog.get_node("Preview/Inverse").connect("pressed", self, "_toggleInverse")
	dialog.connect("confirmed", self, "_import")
	dialog.show()

func _selectMetaFile():
	fileDialog.clear_filters()
	if dialog.get_node("Input/Type/TypeButton").get_selected_ID() == 0:
		fileDialog.add_filter("*.xml")
	else:
		fileDialog.add_filter("*.json")
	fileDialog.set_access(FileDialog.ACCESS_FILESYSTEM)
	fileDialog.set_mode(FileDialog.MODE_OPEN_FILE)
	_showFileDialog()

func _showFileDialog():
	fileDialog.set_custom_minimum_size(dialog.get_size() - Vector2(50, 50))
	fileDialog.set_pos(dialog.get_pos() + Vector2(25, 50))

	var file = File.new()
	if fileDialog.get_access() == FileDialog.ACCESS_FILESYSTEM:
		var path = dialog.get_node("Input/Source/MetaFileField").get_text()
		if file.file_exists(path):
			fileDialog.set_current_dir(_getParentDir(path))
	fileDialog.show()
	fileDialog.invalidate()

func _toggleAll():
	for item in listbox.get_children():
		item.selected = true

func _untoggleAll():
	for item in listbox.get_children():
		item.selected = false

func _toggleInverse():
	for item in listbox.get_children():
		item.selected = !item.selected

func _selectTargetDir():
	fileDialog.set_mode(FileDialog.MODE_OPEN_DIR)
	fileDialog.set_access(FileDialog.ACCESS_RESOURCES)
	_showFileDialog()

func _getParentDir(path):
	var fileName = path.substr(0, path.find_last("/"))
	return fileName

func _getFileName(path):
	var fileName = path.substr(path.find_last("/")+1, path.length() - path.find_last("/")-1)
	var dotPos = fileName.find_last(".")
	if dotPos != -1:
		fileName = fileName.substr(0,dotPos)
	return fileName

func _metaFileSelected(path):
	dialog.get_node("Input/Source/MetaFileField").set_text(path)
	_checkPath("")

func _tarDirSelected(path):
	dialog.get_node("Input/Target/TargetDirField").set_text(path)
	_checkPath("")

func _typeSelected(id):
	_checkPath("")

func _checkPath(path):
	# Clear preview list
	tex = null
	for c in listbox.get_children():
		listbox.remove_child(c)
	listbox.update()
	
	# Check input file
	var file = File.new()
	var inpath = dialog.get_node("Input/Source/MetaFileField").get_text()
	if file.file_exists(inpath):
		# Load atlas meta and texture
		atlas.loadFromFile(path, dialog.get_node("Input/Type/TypeButton").get_selected_ID())
		tex = load(str(_getParentDir(path), "/", atlas.imagePath))
		if not _updatePreview(inpath):
			dialog.get_node("Status").set_text("No frame found")
			return false
	else:
		dialog.get_node("Status").set_text("Source meta file does not exists")
		return false
	
	# Check output directory
	var tarDir = dialog.get_node("Input/Target/TargetDirField").get_text()
	if tarDir.substr(0, "res://".length()) != "res://":
		dialog.get_node("Status").set_text("Target directory must under res://")
		return false
	var dir = Directory.new()
	if not dir.open(tarDir) == OK:
		dialog.get_node("Status").set_text("Target directory does not exists")
		return false
	# Check passed
	dialog.get_node("Status").set_text("")
	return true

func _updatePreview(path):
	for i in range(atlas.sprites.size()):
		var item = FrameItem.instance()
		listbox.add_child(item)
		item.texture = tex
		item.frame_meta = atlas.sprites[i]
		item.set_custom_minimum_size(Vector2(0, 80))
	return atlas.sprites.size() > 0

func _import():
	if listbox.get_child_count() > 0:
		var selectedAtlasIndex = []
		for i in range(listbox.get_child_count()):
			if listbox.get_child(i).selected:
				selectedAtlasIndex.append(i)
		# Save files
		if tex != null:
			var tardir = dialog.get_node("Input/Target/TargetDirField").get_text()
			var texPath = str(tardir, "/", _getFileName(dialog.get_node("Input/Source/MetaFileField").get_text()), ".tex")
			ResourceSaver.save(texPath, tex)
			for i in selectedAtlasIndex:
				var atla = atlas.sprites[i]
				var atex = AtlasTexture.new()
				atex.set_atlas(tex)
				atex.set_region(atla.region)
				ResourceSaver.save(str(tardir,"/", _getFileName(atla.name),".atex"), atex)
				
		