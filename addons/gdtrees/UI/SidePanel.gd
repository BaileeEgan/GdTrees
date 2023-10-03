tool
extends Control

signal data_selected (data)
signal data_loaded(data)
signal data_changed (data, propname, value)

export var path_editor:NodePath;
onready var _editor:Editor3D = get_node(path_editor);

export var leaf_options_path:NodePath;
export var branch_options_path:NodePath;
export var trunk_options_path:NodePath;
export var trunk_branch_options_path:NodePath;


onready var branch_options = self.get_node(self.branch_options_path);
onready var leaf_options = self.get_node(self.leaf_options_path);
onready var trunk_options = self.get_node(self.trunk_options_path);
onready var trunk_branch_options = self.get_node(self.trunk_branch_options_path);

var _tree_data:GdTreeData = null;
var _selected_data:Resource = null;

func _ready():
	$"VBoxContainer/BranchOptions".visible = false;
	$"VBoxContainer/TrunkOptions".visible = false;
	$"VBoxContainer/TreeOptions".visible = false;
	
	for child in branch_options.get_children() + leaf_options.get_children() + trunk_options.get_children() + trunk_branch_options.get_children():
		if child.has_signal("value_changed"):
			if !child.is_connected("value_changed", self, "_on_value_changed"):
				child.connect("value_changed", self, "_on_value_changed", [child.name]);
		

func load_data (data):
	if data is GdTreeData:
		_tree_data = data;
		_selected_data = null;
		_editor.clear();
		for key in _tree_data.hierarchy:
			if _tree_data.hierarchy[key] is GdTreeBranchData:
				_editor.load_data(_tree_data.hierarchy[key], true);
	
	elif data is GdTreeBranchData and _tree_data != null :
		_editor.load_data(data);
		_tree_data.update_mesh("branch", data);

func set_control_value (propname, value):
	var node = self.find_node(propname);
	node.set_value(value);	
				

func select_data(data:Resource):
	self._selected_data = null;
	
	$"VBoxContainer/BranchOptions".visible = false;
	$"VBoxContainer/TrunkOptions".visible = false;
	$"VBoxContainer/TreeOptions".visible = false;
	
	if data is GdTreeBranchData:
		_editor.select_curve(data);
		$"VBoxContainer/BranchOptions".visible = true;
		for child in self.branch_options.get_children() + self.leaf_options.get_children():
			var val = data.get(child.name);
			if val != null:
				child.set_value(val);
		
	elif data is GdTreeTrunkData:
		_editor.select_curve(null);
		$"VBoxContainer/TrunkOptions".visible = true;
		for child in self.trunk_options.get_children() + self.trunk_branch_options.get_children():
			var val = data.get(child.name);
			if val != null:
				child.set_value(val);
		
	elif data is GdTreeData:
		$"VBoxContainer/TreeOptions".visible = true;
	
	
	self._selected_data = data;
		
func _on_data_changed(data:Resource, propname:String, value):
	self.emit_signal("data_changed", data, propname, value)
	#for key in _tree_data.hierarchy:
	#	if typeof(_tree_data.hierarchy[key]) == TYPE_OBJECT && _tree_data.hierarchy[key] == data:
	#		if data is GdTreeBranchData:
	#			_tree_data.update_mesh("branch", data);
	#			_tree_data.is_changed = true;
	#		break;

func _on_value_changed (val, propname):
	if _selected_data is GdTreeTrunkData && propname == "material_bark":
		self.emit_signal("data_changed", _selected_data, "material_bark", val);
	
	if _selected_data is GdTreeBranchData && propname == "leaf_material":
		self.emit_signal("data_changed", _selected_data, "leaf_material", val);
	
	elif _selected_data != null && _selected_data.get(propname) != null:
		self.emit_signal("data_changed", _selected_data, propname, val);


func _on_BranchEditOptions_value_changed(val):
	if val == 0:
		_editor.set_mode(Editor3D.MODE_CURVES);
		
	else:
		var full_string = $VBoxContainer/BranchOptions/BranchEditOptions.options[val];
		match full_string:
			"Branch radius scaling":
				pass
			"Leaf size scaling":
				pass
			
	pass # Replace with function body.

func _on_PreviewLOD_button_up(lod):
	pass # Replace with function body.
