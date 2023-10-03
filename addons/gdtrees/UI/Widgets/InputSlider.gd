tool
extends HBoxContainer


export var label:String = "" setget change_label;
export var value:float = 0;
export var min_value:float = 0 setget change_min_value;
export var max_value:float = 10 setget change_max_value;
export var step:float = 1.0 setget change_step;

var regex = RegEx.new()


onready var empty_stylebox = preload("res://addons/gdtrees/UI/Widgets/empty.stylebox");

signal value_changed(val)


func _ready():
	self.update_all();
	
func set_value(val:float):
	self.value = val;
	self.update_all();
	
	
func update_all():
	if self.has_node("ProgressInput"):
		$ProgressInput.set_min_value(self.min_value);
		$ProgressInput.set_max_value(self.max_value);
		$ProgressInput.set_value(self.value);
		$ProgressInput.set_step(self.step);
	
	
func change_label(val:String):
	if has_node("Label"):
		label = val;
		$Label.text = 	val;
	return label;
	
func change_min_value (val:float):
	if val < max_value:
		min_value = val;
		update_all();
	return min_value;

func change_max_value (val:float):
	if val > min_value:
		max_value = val;
		update_all();
	return max_value;

func change_step (val:float):
	if step > 0:
		step = val;
		update_all();
	return step;


func _on_ProgressInput_value_changed(value):
	self.value = value;
	self.emit_signal("value_changed", value);
