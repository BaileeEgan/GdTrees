tool
extends Control


signal data_selected (data)
signal data_loaded(data)
signal data_changed (data, propname, value)

export var tree_node_path:NodePath;
onready var _tree_node:Tree = get_node(tree_node_path);
var _tree_data;

export var context_menu_path:NodePath;
onready var _context_menu:PopupMenu = get_node(context_menu_path);

func _ready():
	$VBoxContainer/HBoxContainer/AddBranch.disabled = _tree_data == null;
	$VBoxContainer/HBoxContainer/AddTrunk.disabled = _tree_data == null;
	pass
	
func load_data (data):
	if data is GdTreeData:
		_tree_data = data
		_tree_node.load_tree_data(_tree_data);
	$VBoxContainer/HBoxContainer/AddBranch.disabled = _tree_data == null;
	$VBoxContainer/HBoxContainer/AddTrunk.disabled = _tree_data == null;

func select_data(data):
	if _tree_data != null:
		for key in _tree_data.hierarchy:
			if _tree_data.hierarchy[key] == data:
				_tree_node.select_by_key(key);
				break;
				

func show_tree_context_menu(position:Vector2):
	_context_menu.rect_position = position;
	_context_menu.visible = true;
	_context_menu.clear();
	_context_menu.add_item("Add branch");
	_context_menu.add_item("Add trunk");
	_context_menu.add_separator();
	_context_menu.add_item("Delete");

func _on_Tree_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT && !event.pressed:
			var item:TreeItem = _tree_node.get_item_at_position(event.position);
			if item != null:
				item.select(0);
			self.show_tree_context_menu(self.get_global_mouse_position());
		elif event.button_index == BUTTON_LEFT:
			_context_menu.visible = false;

func _on_add_trunk():
	var selected_item:TreeItem = _tree_node.get_selected();
	var is_fixed:bool = false;
	if _tree_data && selected_item:
		var id:String = selected_item.get_metadata(0);
		if id in _tree_data.hierarchy:
			var trunk:GdTreeTrunkData = GdTreeTrunkData.new();
			if id == "0":
				is_fixed = true;
				_tree_data.add_child(trunk);
			else:
				if _tree_data.hierarchy[id] is GdTreeTrunkData:
					trunk = _tree_data.hierarchy[id].create_copy();
				_tree_data.add_child(trunk, _tree_data.hierarchy[id]);
			
			_tree_node.load_tree_data(_tree_data);
			self.select_data(trunk);
			self.emit_signal("data_loaded", trunk);
			self.emit_signal("data_selected", trunk);
		


func _on_add_branch():
	var selected_item:TreeItem = _tree_node.get_selected();
	if _tree_data && selected_item:
		var id:String = selected_item.get_metadata(0);
		if id in _tree_data.hierarchy:
			var branch:GdTreeBranchData = GdTreeBranchData.new();
			if id == "0":
				_tree_data.add_child(branch);
			elif _tree_data.hierarchy[id] is GdTreeTrunkData:
				_tree_data.add_child(branch, _tree_data.hierarchy[id]);
			
			_tree_node.load_tree_data(_tree_data);
			self.select_data(branch);
			self.emit_signal("data_loaded", branch);
			self.emit_signal("data_selected", branch);

func _on_tree_item_selected(id):
	var data = _tree_data.get_data_by_id(id);
	self.emit_signal("data_selected", data);


func _on_tree_reparent_data(child_id, parent_id):
	if _tree_data:
		_tree_data.reparent(child_id, parent_id);
		_tree_node.load_tree_data(_tree_data);
