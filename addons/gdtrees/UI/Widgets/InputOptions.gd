tool
extends HBoxContainer

signal value_changed(val)
export var label:String = "" setget change_label;
export var options:Array = [];
export var value:int = 0;

func _ready():
	$OptionButton.clear();
	for item in options:
		$OptionButton.add_item(item);
	
func set_options (new_options):
	self.options = new_options;
	self.value = 0;
	$OptionButton.clear();
	for item in options:
		$OptionButton.add_item(item);
	
func change_label(val:String):
	if has_node("Label"):
		label = val;
		$Label.text = 	val;
	return label;

func _on_OptionButton_item_selected(index):
	self.value = index;
	self.emit_signal("value_changed", index);
	

func set_value (val:int):
	$OptionButton.select(val);
