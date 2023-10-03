class_name EditorCurve
extends Spatial

signal curve_changed(curve)

var curve:Curve3D;

var data:Resource = null;

var fixed:bool = false;
var active:bool = false;

var LINE_MATERIAL = preload("Curve.material");
var RED_LINE_MATERIAL = preload("Curve_red.material");

var ig:ImmediateGeometry;
var points:Spatial;
var rings:Spatial;
var mi:MeshInstance = MeshInstance.new();
var mi2:MeshInstance = MeshInstance.new();

var ring_data_name:String = "";
var ring_scale_data_name:String = "";
var ring_curve:Curve = null;
var selected_ring:EditorCurveRing;



func set_active (val:bool):
	self.active = val;
	for child in self.points.get_children():
		child.active = val;
	self.rings.visible = val;
	self.ig.visible = val;


func _ready():
	self.add_to_group("EditorCurve")


func _init():
	self.points = Spatial.new();
	self.add_child(self.points);
	
	self.ig = ImmediateGeometry.new();
	ig.material_override = LINE_MATERIAL;
	self.add_child(self.ig);
	self.add_child(self.mi);
	self.add_child(self.mi2);
	
	self.rings = Spatial.new();
	self.add_child(rings);
	
	
func set_mesh(mesh:Mesh):
	self.mi.mesh = mesh;


func set_mesh2(mesh:Mesh):
	self.mi2.mesh = mesh;


func init(data:Resource):
	for child in self.points.get_children():
		child.queue_free();
		#self.points.remove_child(child);
		
	self.data = data;
		
	self.curve = data.curve;
	self.set_mesh(data.lod0_branch_mesh);
	if data.resource_name == "GdTreeTrunk":
		self.set_mesh2(data.lod0_trunk_mesh);
	
	#self.curve = Curve3D.new();
	#self.curve.add_point(Vector3.ZERO, Vector3(1, 0, 0), Vector3(-1, 0, 0));
	#self.curve.add_point(Vector3.UP * 5.0);
	#self.curve.add_point(Vector3.UP * 10.0);
	
	for i in self.curve.get_point_count():
		var point:EditorCurvePoint = EditorCurvePoint.new();
		var point_fixed:bool = (i == 0 && self.fixed);
		if point_fixed:
			self.curve.set_point_position(0, Vector3.ZERO);
		point.init(self.curve.get_point_position(i), self.curve.get_point_in(i), self.curve.get_point_out(i));
		self.points.add_child(point);
	self.update_ig();
	
	


func update():
	self.update_ig();
	self.emit_signal("curve_changed", self.curve);
	
	
func update_ig():
	var curve_len:float = self.curve.get_baked_length();
	self.ig.clear();
	self.ig.begin(Mesh.PRIMITIVE_LINE_STRIP);
	for point in self.curve.tessellate():
		self.ig.add_vertex(point);
	self.ig.end();
	self.update_rings();
	
func get_ring_scale_factor() -> float:
	if self.data != null:
		if self.data is GdTreeBranchData:
			return (self.data as GdTreeBranchData).branch_radius;
		elif self.data is GdTreeTrunkData:
			return (self.data as GdTreeTrunkData).trunk_radius;
	return 1.0;
	
	
func update_rings():
	var curve_len:float = self.curve.get_baked_length();
	var scale_factor:float = self.get_ring_scale_factor();
	for ring in self.rings.get_children():
		self.update_ring(ring, curve_len, scale_factor);
		


	
		
func get_closest_index(position:Vector3, min_dist:float=-1.0):
	var closest_index:int = -1;
	var closest_distance:float = 999999999;
	if min_dist > 0.0:
		closest_distance = min_dist;
	for i in range(self.curve.get_point_count()):
		var d = self.curve.get_point_position(i).distance_squared_to(position);
		if d < closest_distance:
			closest_distance = d;
			closest_index = i;
	return closest_index;


func get_closest_control_point(position:Vector3, min_dist:float = -1.0):
	var i = self.get_closest_index(position);
	if i > -1:
		return(self.points.get_child(i));
	return null;
	
	
func get_closest_control_point_by_offset (offset:float, min_diff_perc:float = -1.0):
	if offset < -1.0:
		return null;
		
	var closest_point:EditorCurvePoint = null;
	var closest_diff:float = 99999999;
	if min_diff_perc > 0.0:
		closest_diff = min_diff_perc * self.curve.get_baked_length();
	for i in range(self.curve.get_point_count()):
		var point_offset:float = self.curve.get_closest_offset(self.curve.get_point_position(i));
		var offset_diff = abs(point_offset - offset);
		if offset_diff < closest_diff:
			closest_diff = offset_diff;
			closest_point = self.points.get_child(i);
	return closest_point;


func insert_point(offset:float):
	var new_position:Vector3 = self.curve.interpolate_baked(offset);
	for i in range(self.curve.get_point_count()):
		var point_offset = self.curve.get_closest_offset(self.curve.get_point_position(i));
		if point_offset > offset:
			self.add_point(new_position, Vector3.ZERO, Vector3.ZERO, i);
			break;


func add_point(position:Vector3, _in:Vector3=Vector3.ZERO, _out:Vector3=Vector3.ZERO, at:int=-1):
	self.curve.add_point(position, _in, _out, at);
	var point:EditorCurvePoint = EditorCurvePoint.new();
	self.points.add_child(point);
	point.init(position, _in, _out);
	if at > -1:
		self.points.move_child(point, at);
	self.update_ig();
	
	
func remove_point (index:int):
	self.curve.remove_point(index);
	self.points.get_child(index).queue_free();
	self.update_ig();
	
	
func get_basis_from_offset (offset:float):
	var curve_len:float = self.curve.get_baked_length();
	if offset > curve_len:
		offset = curve_len - 0.1;
	var forward:Vector3 = self.curve.interpolate_baked(offset + 0.1) - self.curve.interpolate_baked(offset);
	var up:Vector3 = self.curve.interpolate_baked_up_vector(offset);
	return Basis(forward, up, forward.cross(up));
	
	
func load_ring_data(ring_data_name:String):
	if self.data != null:
		self.ring_curve = self.data.get(ring_data_name);
		
		if self.ring_curve != null:
			self.ring_data_name = ring_data_name;
			for child in self.rings.get_children():
				child.queue_free();
			var scale_factor:float = self.get_ring_scale_factor();
			for i in range(self.ring_curve.get_point_count()):
				var point:Vector2 = self.ring_curve.get_point_position(i);
				self._add_ring(point, scale_factor);


func update_ring(ring:EditorCurveRing, curve_len:float, scale_factor:float):
	self.update_ring_position(ring, curve_len, scale_factor);
	self.update_ring_scale(ring, scale_factor);

func update_ring_scale (ring:EditorCurveRing, scale_factor:float):
	var radius:float = (ring.value - self.ring_curve.min_value) / (self.ring_curve.max_value - self.ring_curve.min_value);
	ring.scale = 2.0 * scale_factor * (radius + 0.1) * Vector3.ONE;
	
func update_ring_position (ring:EditorCurveRing, curve_len:float, scale_factor:float):
	var abs_offset = ring.offset * curve_len;
	ring.transform.origin = self.curve.interpolate_baked(abs_offset);
	ring.transform.basis =  self.get_basis_from_offset(abs_offset);
	
func _add_ring (point:Vector2, scale_factor:float, at:int=-1):
	var curve_len:float = self.curve.get_baked_length();
	var ring:EditorCurveRing = EditorCurveRing.new();
	var radius:float = (point.y - self.ring_curve.min_value) / (self.ring_curve.max_value - self.ring_curve.min_value);
	self.rings.add_child(ring);
	if at > -1:
		self.rings.move_child(ring, at);
	ring.offset = point.x;
	ring.value = point.y;
	self.update_ring(ring, curve_len, scale_factor);
	return ring;

func add_ring (point:Vector2, at:int=-1):
	var ring:EditorCurveRing = self._add_ring(point, self.get_ring_scale_factor(), at);
	return ring;
	
func remove_ring (ring:EditorCurveRing):
	if self.rings.get_child_count() > 2:
		var i:int = ring.get_index();
		self.ring_curve.remove_point(i);
		ring.queue_free();
	
func insert_ring (abs_offset:float=0.0):
	if self.ring_curve != null:
		var rel_offset:float = abs_offset / self.curve.get_baked_length();
		var scale_factor:float = self.get_ring_scale_factor();
		var radius = self.ring_curve.max_value;
		var new_index:int = -1;
		var values = [];
		
		for i in range(self.ring_curve.get_point_count() - 1, -1, -1):
			var pos:Vector2 = self.ring_curve.get_point_position(i);
			if pos.x > rel_offset:
				new_index = i;
				values.insert(0, pos);
				self.ring_curve.remove_point(i);
			else:
				break;
				
		self.ring_curve.add_point(Vector2(rel_offset, radius));
		for val in values:
			self.ring_curve.add_point(val);
		self._add_ring(Vector2(rel_offset, self.ring_curve.max_value), scale_factor, new_index);
	
	
func change_ring_value (ring:EditorCurveRing, change_perc:float):
	var scale_factor:float = self.get_ring_scale_factor();
	var curve_range:float = self.ring_curve.max_value - self.ring_curve.min_value;
	var new_value = clamp(ring.value + change_perc * (curve_range), self.ring_curve.min_value, self.ring_curve.max_value);
	var new_radius = self.ring_curve.min_value + new_value / (self.ring_curve.max_value - self.ring_curve.min_value);
	ring.value = new_value;
	
	ring.scale = 2.0 * scale_factor * (new_radius + 0.1) * Vector3.ONE;
	var i = ring.get_index();
	self.ring_curve.set_point_value(i, new_value);
	self.update_ring_scale(ring, scale_factor);
	
func change_ring_offset (ring:EditorCurveRing, rel_offset:float):
	var scale_factor:float = self.get_ring_scale_factor();
	var old_index:int = ring.get_index();
	
	self.ring_curve.remove_point(old_index);
	
	var new_index:int = -1;
	var values = [];
	
	for i in range(self.ring_curve.get_point_count() - 1, -1, -1):
		var pos:Vector2 = self.ring_curve.get_point_position(i);
		if pos.x > rel_offset:
			new_index = i;
			values.insert(0, pos);
			self.ring_curve.remove_point(i);
		else:
			break;
			
	self.ring_curve.add_point(Vector2(rel_offset, ring.value));
	for val in values:
		self.ring_curve.add_point(val);
	
	ring.offset = rel_offset;
	self.rings.move_child(ring, new_index);
	self.update_ring(ring, self.curve.get_baked_length(), scale_factor);
	

func is_ring_selected ():
	return self.selected_ring != null;
	
	
func change_selected_ring_value (change_perc:float): # change amount between 0 and 1.0
	if self.selected_ring != null:
		self.change_ring_value(self.selected_ring, change_perc);
		return true;
	return false;


func set_selected_ring_offset (abs_offset:float):
	var curve_len = self.curve.get_baked_length();
	if self.selected_ring != null && abs_offset > -1.0 && abs_offset <= curve_len:
		var rel_offset:float = abs_offset / curve_len;
		self.change_ring_offset(self.selected_ring, rel_offset);
		return true;
	return false;


func highlight_ring (offset:float):
	var curve_len:float = self.curve.get_baked_length();
	var closest_ring:EditorCurveRing = null;
	var closest_dist:float = 0.01 * curve_len;
	for ring in self.rings.get_children():
		ring.material_override = LINE_MATERIAL;
		var d:float = abs(curve_len * ring.offset - offset);
		if d < closest_dist:
			closest_dist = d;
			closest_ring = ring;
	self.selected_ring = closest_ring;
	if closest_ring != null:
		closest_ring.material_override = RED_LINE_MATERIAL;
	return(closest_ring)
