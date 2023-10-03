tool
extends ProgressBar

var is_dragging:bool = false;

onready var spinbox:SpinBox = get_node("SpinBox");
onready var line_edit:LineEdit;
onready var empty_stylebox = preload("res://addons/gdtrees/UI/Widgets/empty.stylebox");

export var text:String = "" setget change_text
func change_text (val:String):
	if val != text:
		text = val;
		if has_node("Label"):
			$Label.text = text;
	return text;
		

func _ready():
	self.line_edit = self.spinbox.get_line_edit();
	self.line_edit.add_stylebox_override("normal", empty_stylebox);
	self.line_edit.add_stylebox_override("focus", empty_stylebox);
	self.line_edit.add_stylebox_override("read_only", empty_stylebox);
	self.line_edit.connect("gui_input", self, "_on_gui_input")
	
func set_min_value (min_val):
	min_val = min(min_val, self.max_value);
	self.min_value = min_val;
	if self.spinbox != null:
		self.spinbox.min_value = min_val;
	self.adjust_value();
	
	
func set_max_value (max_val):
	max_val = max(max_val, self.min_value);
	self.max_value = max_val;
	if self.spinbox != null:
		self.spinbox.max_value = max_val;
	self.adjust_value();
	
func set_step (step_val):
	self.step = step_val;
	if self.spinbox != null:
		self.spinbox.step = step_val;
	
func set_value (val):
	if self.spinbox != null:
		self.spinbox.value = val;
	self.value = val;

func adjust_value ():
	var new_value = clamp(self.value, self.min_value, self.max_value);
	self.set_value(new_value);

func _on_gui_input(event):
	if event is InputEventMouseButton && event.button_index == BUTTON_LEFT:
		if event.pressed:
			self.line_edit.select_all();
		else:
			if !self.is_dragging:
				self.line_edit.select_all();
			else:
				self.line_edit.deselect();
				self.line_edit.editable = true;
				self.is_dragging = false;
				self.line_edit.release_focus();
	
	if event is InputEventMouseMotion && Input.is_mouse_button_pressed(BUTTON_LEFT):
		if !self.is_dragging:
			self.is_dragging = abs(event.relative.x) > 2;
		if self.is_dragging:
			var new_val:float = (self.max_value - self.min_value) * (event.position.x / (self.rect_size.x - 5)) + self.min_value;
			self.value = new_val;
			self.spinbox.value = new_val;
			self.line_edit.deselect();
			self.line_edit.editable = false;


func _on_SpinBox_value_changed(value):
	if !self.is_dragging:
		self.value = value;
