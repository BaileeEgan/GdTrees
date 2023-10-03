tool
extends HBoxContainer

signal value_changed(val)
export var label:String = "" setget change_label;
export var value:bool = true;

func _ready():
	$CheckBox.pressed = self.value;
	
	
func set_value(val:float):
	self.value = val;
	$CheckBox.pressed = self.value;
	
func change_label(val:String):
	if has_node("Label"):
		label = val;
		$Label.text = 	val;
	return label;


func _on_CheckBox_button_up():
	self.value = $CheckBox.pressed;
	self.emit_signal("value_changed", self.value);
