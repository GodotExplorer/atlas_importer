tool
extends Panel

func _set_title(text):
	get_node("HBox/Title").set_text(text)
	title = text

func _selectChanged(toggled):
	selected = toggled
	get_node("HBox/CheckBox").set_pressed(toggled)

func _setFrameMeta(frame):
	frame_meta = frame
	invalidate()

func _setTexture(tex):
	texture = tex
	invalidate()

func invalidate():
	if frame_meta != null:
		# print( inst2dict(frame_meta))
		self.title = frame_meta.name
		if texture != null:
			_set_icon(texture, frame_meta.region, frame_meta.rotation)
	if texture == null:
		get_node("HBox/Icon/Sprite").set_texture(null)
	update()

var title = "" setget _set_title
var selected  = false setget _selectChanged
var frame_meta = null setget _setFrameMeta
var texture = null setget _setTexture

func _set_icon(tex, region, rotation):
	var sprite = get_node("HBox/Icon/Sprite")
	sprite.set_texture(tex)
	sprite.set_region(true)
	sprite.set_region_rect(region)
	sprite.set_rot(rotation)
	var scale = 1.0
	if region.size.width > 70 or region.size.height > 70:
		if region.size.width >= region.size.height:
			scale = 70.0 / region.size.width
		else:
			scale = 70.0 / region.size.height
	sprite.set_scale(Vector2(scale, scale))
	sprite.update()

func _ready():
	self.selected = false
	self.texture = null
	self.title = ""
	get_node("HBox/CheckBox").connect("toggled", self, "_selectChanged")
