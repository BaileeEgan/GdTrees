tool
extends Control

signal data_selected (data)
signal data_loaded(data)
signal data_changed(data, propname, value)
signal data_saved(data)
signal data_created()

signal save_handled (result)

var _tree_data = null;
export var tree_editor_path:NodePath;
export var context_menu_path:NodePath;

onready var _tree_editor:Editor3D = get_node(tree_editor_path);
onready var _context_menu:PopupMenu = get_node(context_menu_path);

var settings = [
	{ "label": "Enable shadows", "type": "check", "default_value": true },
	{ "label": "Rotate sun", "type": "check", "default_value": false },
	{ "label": "Light settings", "type": "button" }
]

func _ready():
	_tree_data = null;
	var file_button:MenuButton = $VBoxContainer/Menu/FileButton;
	var file_button_menu:PopupMenu = file_button.get_popup();
	file_button_menu.connect("id_pressed", self, "_on_menu_button_pressed", ["file"]);
	
	var editor_popup:PopupMenu = $VBoxContainer/Menu/SettingsButton.get_popup();
	editor_popup.connect("index_pressed", self, "_on_settings_button_index_pressed");
	editor_popup.clear();
	editor_popup.hide_on_checkable_item_selection = false;
	for setting in settings:
		if setting["type"] == "check":
			editor_popup.add_check_item(setting["label"]);
			editor_popup.set_item_checked(editor_popup.get_item_count() - 1, setting["default_value"]);
		else:
			editor_popup.add_item(setting["label"])
	var light_settings = _tree_editor.get_light_settings();
	$LightSettings/VBoxContainer/Container/VBoxContainer/HBoxContainer/ColorPickerButton.color = light_settings["color"];
	$LightSettings/VBoxContainer/Container/VBoxContainer/LightEnergy.set_value(light_settings["energy"]);

func _process(delta):
	if _tree_data != null:
		if _tree_data.is_changed:
			$VBoxContainer/Menu/Filename.text = $VBoxContainer/Menu/Filename.text.replace("*", "") + "*";
		else:
			$VBoxContainer/Menu/Filename.text = $VBoxContainer/Menu/Filename.text.replace("*", "");
	else:
		$VBoxContainer/Menu/Filename.text = "";
		
func _on_settings_button_index_pressed (idx):
	if idx < self.settings.size():
		var editor_popup:PopupMenu = $VBoxContainer/Menu/SettingsButton.get_popup();
		var setting = self.settings[idx];
		if setting["type"] == "check":
			var checked = !editor_popup.is_item_checked(idx);
			editor_popup.set_item_checked(idx, checked);
			if setting["label"] == "Enable shadows":
				_tree_editor.enable_shadows = checked;
			if setting["label"] == "Rotate sun":
				_tree_editor.enable_sun_rotation = checked;
		else:
			if setting["label"] == "Light settings":
				$LightSettings.popup_centered();
		editor_popup.visible = true;
	pass
	
func _on_menu_button_pressed(id:int, menu_name:String):
	match menu_name:
		"file":
			match id:
				0: # New
					self.load_new();
				1: # Open
					$OpenFile.popup();
				2: # Save
					self.save_tree();
				3: # Save as
					$SaveFile.popup();
	
func load_data (data):
	if data is GdTreeData:
		_tree_data = data;
		_tree_data.init();
		_tree_editor.clear();
		$VBoxContainer/Menu/Filename.text = _tree_data.resource_path.replace("__tmp", "");
		if $VBoxContainer/Menu/Filename.text == "":
			$VBoxContainer/Menu/Filename.text = "Unsaved tree"
		print("Loading tree");
		for key in _tree_data.hierarchy:
			var child = _tree_data.hierarchy[key];
			if child is GdTreeTrunkData:
				var is_fixed:bool = (child is GdTreeBranchData) || (!_tree_data.is_subtrunk(child));
				_tree_editor.load_data(child, is_fixed);
	elif data is GdTreeTrunkData && _tree_data != null:
		var is_fixed:bool = _tree_data.is_subtrunk(data);
		_tree_editor.load_data(data, is_fixed);
		_tree_data.update_mesh("trunk", data);
		
	

func select_data(data):
	if data is GdTreeTrunkData:
		_tree_editor.select_curve(data);
	else:
		_tree_editor.select_curve(null);


func init():
	pass
		
		
func load_new ():
	var result:bool = true;
	if _tree_data != null && _tree_data.is_changed:
		$SavePopup.popup_centered();
		result = yield(self, "save_handled");
	if result:
		var new_tree:GdTreeData = GdTreeData.new();
		var trunk:GdTreeTrunkData = GdTreeTrunkData.new();
		new_tree.add_child(trunk);
		self.emit_signal("data_loaded", new_tree);

func load_tree_file(path:String):
	var result:bool = true;
	if self._tree_data != null && _tree_data.is_changed:
		$SavePopup.popup_centered();
		result = yield(self, "save_handled");
	if result:
		var obj = load(path);
		if obj is GdTreeData:
			obj.resource_path = path;
			$SaveFile.current_path = path;
			$SaveFile.current_dir = path.get_base_dir();
			$SaveFile.current_file = path.split(".")[0];
			self.emit_signal("data_loaded", obj);
			
func _on_Editor3D_load_tree_data(data):
	var result:bool = true;
	if _tree_data != null && _tree_data.is_changed:
		$SavePopup.popup_centered();
		result = yield(self, "save_handled");
	if result:
		self.emit_signal("data_loaded", data);
	
	
func save_tree ():
	if _tree_data != null:
		var file_path:String = self._tree_data.resource_path.replace("__tmp", "");
		self.emit_signal("data_saved", _tree_data, file_path);

	
func _on_data_changed(data:Resource, propname:String, value):
	self.emit_signal("data_changed", data, propname, value);
	
	#for key in _tree_data.hierarchy:
	#	if typeof(_tree_data.hierarchy[key]) == TYPE_OBJECT && _tree_data.hierarchy[key] == data:
	#		if data is GdTreeTrunkData:
	#			_tree_data.update_mesh("trunk", data);
	#		elif data is GdTreeBranchData:
	#			_tree_data.update_mesh("branch", data);
	#		_tree_data.is_changed = true;
	#		break;
				

func _on_file_open(path):
	self.load_tree_file(path);
	
func _on_file_save(path):
	self.emit_signal("data_saved", _tree_data, path);

func _on_Filename_gui_input(event):
	if event is InputEventMouseButton:
		if !event.pressed && event.button_index == BUTTON_LEFT:
			$RenameFile.popup();


func _on_file_rename(path):
	if _tree_data:
		var dir:Directory = Directory.new();
		dir.rename(_tree_data.resource_path, path);
		_tree_data.resource_path = path;
		$VBoxContainer/Menu/Filename.text = path;


func _on_DoSave_pressed():
	$SavePopup.visible = false;
	$SaveFile.popup();
	yield($SaveFile, "confirmed");
	self.call_deferred("emit_signal", "save_handled", true);


func _on_NoSave_pressed():
	$SavePopup.visible = false
	self.call_deferred("emit_signal", "save_handled", true);


func _on_CancelSave_pressed():
	$SavePopup.visible = false
	self.call_deferred("emit_signal", "save_handled", false);


func _on_ApplyLight_button_up():
	_tree_editor.set_light_settings($LightSettings/VBoxContainer/Container/VBoxContainer/LightEnergy.value, $LightSettings/VBoxContainer/Container/VBoxContainer/HBoxContainer/ColorPickerButton.color);
	$LightSettings.visible = false;

func _on_CancelLight_button_up():
	$LightSettings.visible = false;
	var light_settings = _tree_editor.get_light_settings();
	$LightSettings/VBoxContainer/Container/VBoxContainer/HBoxContainer/ColorPickerButton.color = light_settings["color"];
	$LightSettings/VBoxContainer/Container/VBoxContainer/LightEnergy.set_value(light_settings["energy"]);


