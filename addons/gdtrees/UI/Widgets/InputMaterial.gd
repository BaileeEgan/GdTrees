tool
extends HBoxContainer


onready var mi:MeshInstance = self.get_node("ViewportContainer/Viewport/Spatial");

signal value_changed(val)

func _ready():
	pass



func can_drop_data(position, data):
	if data is Dictionary && data.has("files"):
		return true;
	return false;
	
func drop_data(position, data):
	if data is Dictionary && data.has("files"):
		var obj = load(data.files[0]);
		if obj is SpatialMaterial || obj is ShaderMaterial:
			self.emit_signal("value_changed", obj);
			print("Material changed")
			mi.material_override = obj;

func set_value (val):
	mi.material_override = val;
	self.emit_signal("value_changed", val);
