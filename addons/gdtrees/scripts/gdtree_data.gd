tool
class_name GdTreeData
extends Resource

signal data_changed (data)

export var lod_data:Resource = null;
export var hierarchy:Dictionary = {};
export var leaf_material:Material;
export var bark_material:Material;

var is_changed:bool = false;

func _init():
	self.resource_name = "GdTree"
	if self.lod_data == null:
		self.lod_data = GdTreeLODData.new();
	if self.hierarchy.empty():
		self.hierarchy = { "0": null }
		


func create_copy() -> GdTreeData:
	var res:GdTreeData = self.duplicate(false);
	res.resource_name = self.resource_name;
	res.take_over_path(self.resource_path + "__tmp");
	res.lod_data = self.lod_data.create_copy();
	res.hierarchy = { "0": null };
	for key in self.hierarchy:
		var data = self.hierarchy[key];
		if data is Resource:
			res.hierarchy[key] = data.create_copy();
	return res;
		
func copy_from (tree:GdTreeData):
	self.leaf_material = tree.leaf_material;
	self.bark_material = tree.bark_material;
	self.lod_data = tree.lod_data.create_copy();
	self.hierarchy = { "0": null };
	for key in tree.hierarchy:
		var data = tree.hierarchy[key];
		if data is Resource:
			self.hierarchy[key] = data.create_copy();
	
func clear():
	self.hierarchy = { "0": null };

	
	
func init():
	if self.hierarchy['0'] == "root":
		self.hierarchy['0'] = null;
	for key in self.hierarchy:
		if self.hierarchy[key] is Resource:
			var data:Resource = self.hierarchy[key];
			if !data.is_connected("update_mesh", self, "_on_update_mesh"):
				data.connect("update_mesh", self, "_on_update_mesh", [data]);
			
	self.update_all_meshes();
	
func is_subtrunk(trunk):
	var parent_data = self.get_parent_data(trunk);
	return (parent_data is GdTreeTrunkData);

func get_data_by_id (id:String):
	if id == "0":
		return self;
	elif self.hierarchy.has(id):
		return self.hierarchy[id];
		
func get_id_by_data (data:Resource):
	if data == self:
		return "0";
	for key in self.hierarchy:
		if self.hierarchy[key] == data:
			return key;
	return "";
	
func get_parent_id (child) -> String:
	var child_id:String = "";
	if typeof(child) == TYPE_OBJECT:
		child_id = self.get_id_by_data(child);
	else:
		child_id = child;
		
	var spl:PoolStringArray = child_id.split(".");
	var parent_id:String = "";
	for i in range(spl.size() - 1):
		if i > 0:
			parent_id += "."
		parent_id += spl[i];
	return parent_id;
	
func get_parent_data (child):
	var parent_id = self.get_parent_id(child);
	if parent_id == "0":
		return self;
	return self.hierarchy[parent_id];
	
func get_children_id (parent):
	var children:Array = [];
	var parent_id:String = "";
	if typeof(parent) == TYPE_STRING:
		parent_id = parent;
	else:
		parent_id = self.get_id_by_data(parent);
	
	var re:RegEx = RegEx.new();
	re.compile("^" + parent_id + "[.][0-9]+$");
	for child_id in self.hierarchy:
		var result:RegExMatch = re.search(child_id);
		if result:
			children.append(child_id);
	children.sort();
	return children;
		
func get_children_data (parent):
	var children:Array = self.get_children_id(parent);
	var children_data:Array = [];
	for id in children:
		children_data.append(self.get_data_by_id(id));
	return children_data;
	

			
func get_parent_key(current:Resource):
	for key in self.hierarchy:
		if (current == self && key == "0") || (key != "0" && self.hierarchy[key] == current):
			var spl:PoolStringArray = key.split(".");
			var parent_key:String = "";
			for i in range(spl.size() - 1):
				if i > 0:
					parent_key += "."
				parent_key += spl[i];
			return parent_key;
	return "";
	

func get_nearest (current, type):
	var children = self.get_children_data(current);
	for child in children:
		if child is type:
			return child;
	
	var parent = self.get_parent_data(current);
	if parent:
		while true:
			children = self.get_children_data(parent);
			for child in children:
				if child is type:
					return child;
			if parent == self:
				break
			else:
				parent = self.get_parent_data(parent);
	return null;
	
func get_nearest_branch(current):
	return self.get_nearest(current, GdTreeBranchData);
	
func get_nearest_trunk(current):
	return self.get_nearest(current, GdTreeTrunkData);

func reparent (child, parent):
	print("Reparenting ", child, " to ", parent);
	var child_data:Resource;
	var parent_data:Resource;
	if typeof(child) == TYPE_STRING:
		child_data = self.hierarchy[child];
	else:
		child_data = child;
	
	if parent == "0":
		parent_data = null;
	if typeof(parent) == TYPE_STRING:
		parent_data = self.hierarchy[parent];
	else:
		parent_data = parent;
		
	var removed:Dictionary = {};
	var current_id = "";
	if typeof(child) == TYPE_STRING:
		current_id = child;
	else:
		current_id = self.get_id_by_data(child);
	var current_index:int = String(Array(current_id.split(".")).pop_back()).to_int();
	

	print("Start ", self.hierarchy);
	var parent_id = self.get_parent_id(child);
	var siblings_id = self.get_children_id(parent_id);
	
	for key in self.hierarchy.keys():
		if key.begins_with(current_id + "."):
			removed[key] = self.hierarchy[key];
			self.hierarchy.erase(key);
	self.hierarchy.erase(current_id);
	
	print("Curent id ", current_id, " ", self.hierarchy);
	print("Removed ", removed);
	
	for i in range(current_index + 1, siblings_id.size()):
		var sib_id:String = siblings_id[i];
		var data = self.hierarchy[sib_id];
		self.hierarchy.erase(sib_id);
		var new_id = str(parent_id, ".", i - 1);
		self.hierarchy[new_id] = data;
		
		
	self.add_child(child_data, parent_data);
	
	var new_current_id = self.get_id_by_data(child_data);
	for key in removed:
		var new_key = key.replace(current_id, new_current_id);
		self.hierarchy[new_key] = removed[key];
		
	
	
func remove_child(child):
	
	var current_id = "";
	if typeof(child) == TYPE_STRING:
		current_id = child;
	else:
		current_id = self.get_id_by_data(child);
		
	print("Start ", self.hierarchy);
	var parent_id = self.get_parent_id(child);
	var siblings_id = self.get_children_id(parent_id);
	var children_id = self.get_children_id(current_id);
	
	var current_index:int = String(Array(current_id.split(".")).pop_back()).to_int();
	self.hierarchy.erase(current_id);
	
	print("Erase 1 ", self.hierarchy);
	
	for i in range(current_index + 1, siblings_id.size()):
		var sib_id:String = siblings_id[i];
		var data = self.hierarchy[sib_id];
		self.hierarchy.erase(sib_id);
		var new_id = str(parent_id, ".", i - 1);
		self.hierarchy[new_id] = data;
	
	var re:RegEx = RegEx.new();
	re.compile("^" + current_id + "[.].+");
	for key in self.hierarchy:
		var result:RegExMatch = re.search(key);
		if result:
			self.hierarchy.erase(key);
		

func add_child (child:Resource, parent:Resource=null):
	if child == self:
		return;
	
	if parent == null:
		parent = self;
		
	var parent_id:String = self.get_id_by_data(parent);
	var children:Array = self.get_children_id(parent_id);
	var new_key:String = str(parent_id, ".", len(children));
	self.hierarchy[new_key] = child;
	
	if child is GdTreeBranchData || child is GdTreeTrunkData:
		child.connect("update_mesh", self, "_on_update_mesh", [child]);


func snap_curve (parent:Curve3D, child:Curve3D):
	var first_point:Vector3 = child.get_point_position(0);
	var closest_point:Vector3 = parent.get_closest_point(first_point);
	child.set_point_position(0, closest_point);
	

func update_mesh(type:String, data:Resource, max_lod:int=1):
	var parent = self.get_parent_data(data);
	if data is GdTreeBranchData:
		data.call("generate_branch", self.lod_data, max_lod);
		
		if parent == self:
			for child in self.get_children_data("0"):
				if child is GdTreeTrunkData:
					self.update_mesh("branches", child);
	
	elif data is GdTreeTrunkData:
		
		if parent is GdTreeTrunkData:
			self.snap_curve(parent.curve, data.curve);
			data.copy_parent_properties(parent);
		
		var queue = [data];
		while queue.size() > 0:
			var current:Resource = queue.pop_back();
			if type == "trunk":
				current.call("generate_" + type, self.lod_data, max_lod);
			current.call("generate_branches",  self.get_nearest_branch(current), self.lod_data, max_lod);
			
			for child in self.get_children_data(current):
				if child is GdTreeTrunkData:
					self.snap_curve(current.curve, child.curve);
					child.copy_parent_properties(current);
					queue.append(child);
			
				
func _on_update_mesh (type:String, data:Resource=null):
	self.update_mesh(type, data);
	
func update_all_meshes(max_lod:int = 1):
	for current in self.hierarchy.values():
		if current is GdTreeBranchData:
			self.update_mesh("branch", current, max_lod);
	for current in self.hierarchy.values():
		if current is GdTreeTrunkData:
			self.update_mesh("trunk", current, max_lod);
	
			
	
func build_meshes():
	self.update_all_meshes(3);
	
	for lod in range(3):
		var st1:SurfaceTool = SurfaceTool.new();
		var st2:SurfaceTool = SurfaceTool.new();
		
		var mesh:ArrayMesh = self.lod_data.get(str("lod", lod, "_mesh"));
		mesh.clear_surfaces();
		
		for current in self.hierarchy.values():
			if typeof(current) == TYPE_OBJECT && current.resource_name == "GdTreeTrunk":
				var trunk_mesh:ArrayMesh = current.get(str("lod", lod, "_trunk_mesh"));
				var branch_mesh:ArrayMesh = current.get(str("lod", lod, "_branch_mesh"));
				st1.append_from(trunk_mesh, 0, Transform());
				if current.branch_surface > -1:
					st1.append_from(branch_mesh, current.branch_surface, Transform());
				
				if current.leaf_surface > -1:
					st2.append_from(branch_mesh, current.leaf_surface, Transform());
			
		st1.commit(mesh);
		st2.commit(mesh);
		mesh.surface_set_material(0, self.bark_material);
		mesh.surface_set_material(1, self.leaf_material);
		
	self.property_list_changed_notify();
	

