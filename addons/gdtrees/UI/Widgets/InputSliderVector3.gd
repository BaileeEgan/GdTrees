tool
extends HBoxContainer

export var label:String = "" setget change_label;
export var value:Vector3 = Vector3.ZERO;
export var min_value:float = 0 setget change_min_value;
export var max_value:float = 10 setget change_max_value;
export var step:float = 1.0 setget change_step;


signal value_changed(val)


func _ready():
	self.update_all();
	pass
	

func set_value(val:Vector3):
	self.value = val;
	self.update_all();
		
func update_all():
	if self.has_node("GridContainer/X"):
		$GridContainer/X.set_min_value(self.min_value);
		$GridContainer/X.set_max_value(self.max_value);
		$GridContainer/X.set_value(self.value.x);
		$GridContainer/X.set_step(self.step);
	if self.has_node("GridContainer/Y"):
		$GridContainer/Y.set_min_value(self.min_value);
		$GridContainer/Y.set_max_value(self.max_value);
		$GridContainer/Y.set_value(self.value.y);
		$GridContainer/Y.set_step(self.step);	
	
	if self.has_node("GridContainer/Z"):
		$GridContainer/Z.set_min_value(self.min_value);
		$GridContainer/Z.set_max_value(self.max_value);
		$GridContainer/Z.set_value(self.value.z);
		$GridContainer/Z.set_step(self.step);	
	
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

func _on_Z_value_changed(value):
	self.value.z = value;
	self.emit_signal("value_changed", self.value);
