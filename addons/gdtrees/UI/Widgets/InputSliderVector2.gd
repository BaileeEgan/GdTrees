tool
extends HBoxContainer

export var label:String = "" setget change_label;
export var value:Vector2 = Vector2.ZERO;
export var min_value:float = 0 setget change_min_value;
export var max_value:float = 10 setget change_max_value;
export var step:float = 1.0 setget change_step;


signal value_changed(val)


func _ready():
	self.update_all();
	
func set_value(val:Vector2):
	self.value = val;
	self.update_all();
	
func update_all():
	if self.has_node("HBoxContainer/X"):
		$HBoxContainer/X.set_min_value(self.min_value);
		$HBoxContainer/X.set_max_value(self.max_value);
		$HBoxContainer/X.set_value(self.value.x);
		$HBoxContainer/X.set_step(self.step);
	if self.has_node("HBoxContainer/Y"):
		$HBoxContainer/Y.set_min_value(self.min_value);
		$HBoxContainer/Y.set_max_value(self.max_value);
		$HBoxContainer/Y.set_value(self.value.y);
		$HBoxContainer/Y.set_step(self.step);	
	
		
	
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
	
func _on_X_value_changed(value):
	self.value.x = value;
	self.emit_signal("value_changed", self.value);

func _on_Y_value_changed(value):
	self.value.y = value;
	self.emit_signal("value_changed", self.value);
