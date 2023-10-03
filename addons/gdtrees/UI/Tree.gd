tool
extends Tree

signal tree_item_selected(id)
signal reparent_data (child_id, parent_id)

var selected_item:TreeItem = null;

var _hierarchy:Dictionary = {};

func _ready():
	pass
	
func select_by_key (key):
	var queue:Array = [self.get_root()];
	while queue.size() > 0:
		var current:TreeItem = queue.pop_front();
		
		if current.get_metadata(0) == key:
			current.select(0);
			break;
		
		else:
			var child = current.get_children();
			if child != null && !queue.has(child):
				queue.append(child);
			var next:TreeItem = current.get_next();
			if next != null && !queue.has(next):
				queue.append(next);
	
	
func load_tree_data (tree_data):
	_hierarchy = {};
	self.clear();
	var keys = tree_data.hierarchy.keys();
	keys.sort();
	for key in keys:
		if key == "0":
			_hierarchy["0"] = self.create_item(null);
			_hierarchy["0"].set_text(0, "Tree");
			_hierarchy["0"].set_metadata(0, "0");
			#_hierarchy["0"].set_selectable(0, false);
			
		else:
			var spl:PoolStringArray = key.split(".");
			var parent_key = ""
			for i in range(spl.size() - 1):
				if i > 0:
					parent_key += "."
				parent_key += spl[i];
			var parent_item:TreeItem = _hierarchy[parent_key];
			_hierarchy[key] = self.create_item(parent_item);
			_hierarchy[key].set_text(0, tree_data.hierarchy[key].resource_name.replace("GdTree", "") + " " + key);
			_hierarchy[key].set_metadata(0, key);
			
func get_item_index (item:TreeItem):
	var i:int = -1;
	if item:
		var parent:TreeItem = item.get_parent();
		if parent:
			var first_child:TreeItem = parent.get_children();
			while first_child:
				i += 1;
				if first_child == item:
					return i;
				first_child = first_child.get_next();
	return i;

func _on_Tree_button_pressed(item, column, id):
	print(item);
	pass # Replace with function body.


func _on_Tree_item_selected():
	var selected = self.get_selected();
	self.emit_signal("tree_item_selected", selected.get_metadata(0));

func _on_gui_input(event):
		
	if event is InputEventMouseMotion:
		var selected_item:TreeItem = self.get_selected();
		var item_at_position:TreeItem = self.get_item_at_position(event.position);
		if Input.is_mouse_button_pressed(BUTTON_LEFT) && selected_item != item_at_position:
			self.drop_mode_flags = DROP_MODE_ON_ITEM;
		else:
			self.drop_mode_flags = DROP_MODE_DISABLED;
			
	elif event is InputEventMouseButton:
		if !event.pressed:
			var selected_item:TreeItem = self.get_selected();
			var item_at_position:TreeItem = self.get_item_at_position(event.position);
			if item_at_position && selected_item && item_at_position != selected_item:
				var drop_position:int = self.get_drop_section_at_position(event.position);
				if drop_position == 0:
					self.emit_signal("reparent_data", selected_item.get_metadata(0), item_at_position.get_metadata(0));
