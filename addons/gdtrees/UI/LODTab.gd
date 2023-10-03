extends Tabs

signal previewed (lod)
signal lod_value_changed (lod, propname, val)

export var lod:int = 0;

func _ready():
	for child in $ScrollContainer/VBoxContainer.get_children():
		if child.has_signal("value_changed"):
			if !child.is_connected("value_changed", self, "_on_value_changed"):
				child.connect("value_changed", self, "_on_value_changed", [child.name]);
		
func _on_value_changed (val, propname):
	self.emit_signal("lod_value_changed", self.lod, propname, val);
	
func _on_PreviewLOD_button_up():
	self.emit_signal("previewed", self.lod)
