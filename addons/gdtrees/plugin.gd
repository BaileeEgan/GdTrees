tool
extends EditorPlugin

var GDTREE = preload("res://addons/gdtrees/scripts/gdtree.gd");
var MAIN_PANEL = preload("res://addons/gdtrees/UI/Main.tscn");
var TREE_DOCK = preload("res://addons/gdtrees/UI/TreeDock.tscn");
var SIDE_DOCK = preload("res://addons/gdtrees/UI/SidePanel.tscn");

var _main_panel:Control;
var _tree_dock:Control;
var _side_dock:Control;

var _tree_data:GdTreeData;

var _editor_interface:EditorInterface;
var _undo_redo:UndoRedo;

func _enter_tree():
	
	_editor_interface = self.get_editor_interface();
	_undo_redo = self.get_undo_redo();
	
	self.add_custom_type("GDTree", "Spatial", GDTREE, null);

	_main_panel = MAIN_PANEL.instance();
	self.get_editor_interface().get_editor_viewport().add_child(_main_panel);
	_main_panel.init();
	_main_panel.connect("data_loaded", self, "load_data");
	_main_panel.connect("data_selected", self, "select_data");
	_main_panel.connect("data_saved", self, "save_data");
	_main_panel.connect("data_changed", self, "change_data");
	
	_side_dock = SIDE_DOCK.instance();
	_side_dock.connect("data_loaded", self, "load_data");
	_side_dock.connect("data_selected", self, "select_data");
	_side_dock.connect("data_changed", self, "change_data");
	
	_tree_dock = TREE_DOCK.instance();
	_tree_dock.connect("data_loaded", self, "load_data");
	_tree_dock.connect("data_selected", self, "select_data");
	_tree_dock.connect("data_changed", self, "change_data");
	
	
	self.make_visible(false);
	
	
func has_main_screen():
	return true
	
func list_children(node:Control, level:int=0):
	if node != null:
		for child in node.get_children():
			print("-".repeat(level), " ", node.name, " ", node)
			self.list_children(child, level + 1);

func make_visible(visible):
	if _main_panel != null:
		_main_panel.visible = visible;
	if visible:
		self.add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UR, _tree_dock);
		self.add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, _side_dock);
		(_side_dock.get_parent() as TabContainer).current_tab = _side_dock.get_index();
		(_tree_dock.get_parent() as TabContainer).current_tab = _tree_dock.get_index();
	elif _tree_dock.get_index() > 0 && _side_dock.get_index() > 0:
		(_side_dock.get_parent() as TabContainer).current_tab = 0
		(_tree_dock.get_parent() as TabContainer).current_tab = 0;
		self.remove_control_from_docks(_tree_dock);
		self.remove_control_from_docks(_side_dock);

func _exit_tree():
	if _main_panel:
		_main_panel.free();
	self.remove_custom_type("GDTree")
	_side_dock.queue_free();
	_tree_dock.queue_free();
	_tree_data = null;

func _on_inspect_object(data:Object):
	if _editor_interface:
		_editor_interface.edit_resource(data);


	
func get_plugin_name():
	 return "GdTrees"
	
func get_plugin_icon():
	# Must return some kind of Texture for the icon.
	return get_editor_interface().get_base_control().get_icon("Node", "EditorIcons")

func select_data(data):
	_tree_dock.select_data(data);
	_main_panel.select_data(data);
	_side_dock.select_data(data);
	
func load_data(data):
	if data is GdTreeData:
		var copy:GdTreeData = data.create_copy();
		_tree_dock.load_data(copy);
		_main_panel.load_data(copy);
		_side_dock.load_data(copy);
		_tree_data = copy;
		_undo_redo.clear_history();
	else:
		_tree_dock.load_data(data);
		_main_panel.load_data(data);
		_side_dock.load_data(data);
		
func change_data (data, propname, value):
	if !(value is Curve3D) and !(value is Curve):
		var old_value = data.get(propname);
		
		_undo_redo.create_action(propname, UndoRedo.MERGE_ALL);
		_undo_redo.add_do_method(self, "do_action", data, propname, value);
		_undo_redo.add_undo_method(self, "do_action", data, propname, old_value);
		_undo_redo.commit_action();
	
	else:
		
		for key in _tree_data.hierarchy:
			if typeof(_tree_data.hierarchy[key]) == TYPE_OBJECT && _tree_data.hierarchy[key] == data:
				if data is GdTreeTrunkData:
					_tree_data.update_mesh("trunk", data);
				elif data is GdTreeBranchData:
					_tree_data.update_mesh("branch", data);
				_tree_data.is_changed = true;
				break;
	
func do_change_curve (data, propname, value):
	data.set(propname, value);
	for key in _tree_data.hierarchy:
		if typeof(_tree_data.hierarchy[key]) == TYPE_OBJECT && _tree_data.hierarchy[key] == data:
			if data is GdTreeTrunkData:
				_tree_data.update_mesh("trunk", data);
			elif data is GdTreeBranchData:
				_tree_data.update_mesh("branch", data);
			_tree_data.is_changed = true;
			break;
	
func do_action (data, propname, value):
	data.set(propname, value);
	for key in _tree_data.hierarchy:
		if typeof(_tree_data.hierarchy[key]) == TYPE_OBJECT && _tree_data.hierarchy[key] == data:
			if data is GdTreeTrunkData:
				_tree_data.update_mesh("trunk", data);
			elif data is GdTreeBranchData:
				_tree_data.update_mesh("branch", data);
			_tree_data.is_changed = true;
			break;

func undo_action (data, propname, value):
	data.set(propname, value);
	for key in _tree_data.hierarchy:
		if typeof(_tree_data.hierarchy[key]) == TYPE_OBJECT && _tree_data.hierarchy[key] == data:
			if data is GdTreeTrunkData:
				_tree_data.update_mesh("trunk", data);
			elif data is GdTreeBranchData:
				_tree_data.update_mesh("branch", data);
			_tree_data.is_changed = true;
			break;
	_side_dock.set_control_value(propname, value);

func save_data (_tree_data:GdTreeData, file_path:String):
	_tree_data.build_meshes();
	var copy = _tree_data.create_copy();
	
	print("Saving tree to " + file_path);
	var dir = Directory.new()
	if dir.file_exists(file_path):
		dir.remove(file_path);
	copy.take_over_path(file_path);
	ResourceSaver.save(file_path, copy, ResourceSaver.FLAG_CHANGE_PATH);
	
	var filesystem = get_editor_interface().get_resource_filesystem();
	filesystem.update_file(file_path);
	get_editor_interface().get_resource_filesystem().scan();
	_tree_data.is_changed = false;
