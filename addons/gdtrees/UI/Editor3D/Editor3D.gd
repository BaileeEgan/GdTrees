tool
extends Control
class_name Editor3D

signal data_changed (data, propname, value)
signal load_tree_data (data)


const MODE_VIEW = "view";
const MODE_CURVES = "edit_curves";
const MODE_RINGS = "edit_rings";

export var editing_options = ["Curves"];

var mode:String = MODE_CURVES;
var mode_ring_propname = "";


onready var _viewport:Viewport = $ViewportContainer/Viewport;
onready var _camera:Camera = $ViewportContainer/Viewport/Spatial/CameraHinge/Camera;
onready var _cursor:ImmediateGeometry = $ViewportContainer/Viewport/Spatial/EditorCursor;
onready var curves:Spatial = $ViewportContainer/Viewport/Spatial/Curves;

export var enable_shadows:bool = true setget _change_enable_shadows;
func _change_enable_shadows (val:bool):
	if val != enable_shadows:
		enable_shadows = val;
		if has_node("ViewportContainer/Viewport/Spatial/DirectionalLight"):
			$ViewportContainer/Viewport/Spatial/DirectionalLight.shadow_enabled = val;
	return enable_shadows;
	
export var enable_sun_rotation:bool = true;

var update_counter:int = 0;

var curve_aabb:AABB = AABB();

var cursor_offset:float = 0.0;
var cursor_position:Vector3;

var active_curve:EditorCurve;

var dragged_object = null;
var dragged_object_depth:float = 0.0;
var collision_mask:int = 1;

onready var mouse_caption:Label = get_node("MouseCaption")

func _ready():
	_cursor.visible = false;
	var ig:ImmediateGeometry = $ViewportContainer/Viewport/Spatial/DirectionalLight/ImmediateGeometry;
	ig.clear();
	ig.begin(Mesh.PRIMITIVE_LINE_STRIP);
	ig.add_vertex(Vector3.ZERO);
	ig.add_vertex(Vector3(0, 0, -20));
	ig.end();
	
	$EditingMode.set_options(self.editing_options);
	for child in self.curves.get_children():
		child.queue_free();
	_viewport.size = self.rect_size;
	
	if !self.is_connected("resized", self, "_on_Editor3D_resized"):
		self.connect("resized", self, "_on_Editor3D_resized");
		
	if !self.is_connected("gui_input", self, "_on_Editor3D_gui_input"):
		self.connect("gui_input", self, "_on_Editor3D_gui_input");
	
	$EditingMode.visible = false;
	
func _process(delta):
	if self.enable_sun_rotation:
		$ViewportContainer/Viewport/Spatial/DirectionalLight.rotation_degrees.y += 30.0 * delta;
		$ViewportContainer/Viewport/Spatial/DirectionalLight.rotation_degrees.x += 10.0 * delta;
		$ViewportContainer/Viewport/Spatial/DirectionalLight.rotation_degrees.z += -20.0 * delta;

func get_light_settings ():
	return { 
		"energy": $ViewportContainer/Viewport/Spatial/DirectionalLight.light_energy,
		"color": $ViewportContainer/Viewport/Spatial/DirectionalLight.light_color
	}

func set_light_settings (energy:float, color:Color):
	$ViewportContainer/Viewport/Spatial/DirectionalLight.light_energy = energy;
	$ViewportContainer/Viewport/Spatial/DirectionalLight.light_color = color;
	$ViewportContainer/Viewport/Spatial/DirectionalLight/Sun.modulate = color;
	var mat:SpatialMaterial = $ViewportContainer/Viewport/Spatial/DirectionalLight/ImmediateGeometry.material_override
	mat.albedo_color = color;

func can_drop_data(position, data):
	if data is Dictionary && data.has("files"):
		return true;
	return false;
	
func drop_data(position, data):
	if data is Dictionary && data.has("files"):
		var obj = load(data.files[0])
		if obj is GdTreeData:
			self.emit_signal("load_tree_data", obj);
			
func clear():
	self.active_curve = null;
	_cursor.visible = false;
	self.curve_aabb = AABB();
	$EditingMode.visible = false;
	for child in self.curves.get_children():
		child.queue_free();	

func load_data(data:Resource, is_fixed:bool=false):
	if !self.is_data_loaded(data):
		var editor_curve:EditorCurve = EditorCurve.new();
		editor_curve.fixed = is_fixed;
		editor_curve.connect("curve_changed", self, "_on_curve_changed", [data]);
		editor_curve.init(data);
		self.curves.add_child(editor_curve);
		editor_curve.set_active(false);
		
		var curve:Curve3D = data.curve;
		self.curve_aabb = AABB();
		for i in range(curve.get_point_count()):
			self.curve_aabb = self.curve_aabb.expand(curve.get_point_position(i));
		_camera.get_parent().focus(self.curve_aabb);
		self.active_curve = null;
		$EditingMode.visible = false;
	
func is_data_loaded (data:Resource):
	if data.get("curve") != null:
		for editor_curve in self.curves.get_children():
			if editor_curve.curve == data.curve:
				return true;
	return false;
	

func select_curve(data:Resource):
	self.active_curve = null;
	self.cursor_offset = -1;
	self.cursor_position = Vector3.ZERO;
	$EditingMode.visible = data != null;
	
	if data != null:
		$EditingMode.visible = true;
		for editor_curve in self.curves.get_children():
			if editor_curve.curve != data.curve:
				editor_curve.set_active(false);
			else:
				editor_curve.set_active(true);
				self.active_curve = editor_curve;
				self.active_curve.load_ring_data(self.mode_ring_propname);
				self.active_curve.rings.visible = self.mode == MODE_RINGS;
				self.active_curve.points.visible = self.mode == MODE_CURVES;
	else:
		for editor_curve in self.curves.get_children():
			editor_curve.set_active(false);
		$EditingMode.visible = false;
			
	
	
func _on_curve_changed (curve:Curve3D, data:Resource):
	self.emit_signal("data_changed", data, "curve", curve);
	


func raycast_mouse (position:Vector2):
	if _camera:
		return _camera.get_parent().raycast_mouse(position);
	return {}
	
func _on_Editor3D_resized():
	if _viewport:
		_viewport.size = self.rect_size;

func update_cursor(position):
	if self.active_curve != null:
		var origin = _camera.project_ray_origin(position);
		var dir = _camera.project_ray_normal(position);
		var closest_dist = 99999999999
		var closest_on_curve:Vector3
		var on_curve:bool = false;
		
		for i in range(200):
			var step = 5 * i;
			var projected_point:Vector3 = origin + step * dir;
			var closest_point:Vector3 = self.active_curve.curve.get_closest_point(origin + step * dir);
			var dist_sq = projected_point.distance_squared_to(closest_point);
			
			if dist_sq < closest_dist && dist_sq < 25:
				closest_dist = dist_sq;
				closest_on_curve = closest_point;
				on_curve = true;
			
		if on_curve:
			self.cursor_offset = self.active_curve.curve.get_closest_offset(closest_on_curve);
			self.cursor_position = closest_on_curve;
			_cursor.global_transform.origin = self.cursor_position;
			_cursor.visible = true;
			#
			
		else:
			self.cursor_offset = -1.0;
			self.cursor_position = Vector3.ZERO;
			_cursor.visible = false;

func _on_Editor3D_gui_input(event):
	if self.visible:
		
		_camera.get_parent().input(event);
		
		if event is InputEventMouseMotion:
			
			if !Input.is_mouse_button_pressed(BUTTON_LEFT):
				
				self.update_cursor(event.position);
				
				
				if self.mode == MODE_RINGS && self.active_curve != null:
					self.active_curve.highlight_ring(self.cursor_offset);
							
			if Input.is_mouse_button_pressed(BUTTON_LEFT):
				if self.active_curve != null:
					
					match self.mode:
						
						MODE_VIEW:
							pass
							
						MODE_CURVES:
							
							self.mouse_caption.visible = true;
							if self.cursor_offset > -1.0:
								if self.dragged_object == null:
									var point:EditorCurvePoint = self.active_curve.get_closest_control_point_by_offset(self.cursor_offset, 0.1);
									if point != null:
										self.dragged_object = point;
										self.dragged_object.selected = true;
										self.update_counter = 3;
										dragged_object_depth = point.global_transform.origin.distance_to(_camera.global_transform.origin);
								else:
									if self.update_counter <= 0:
										var new_position:Vector3 = _camera.project_position(event.position, dragged_object_depth);
										_cursor.global_transform.origin = new_position;
										if Input.is_key_pressed(KEY_SHIFT):
											self.dragged_object.handles_enabled = true;
											self.dragged_object.update(self.dragged_object.in_handle, new_position);
										else:
											self.dragged_object.handles_enabled = false;
											self.dragged_object.update(self.dragged_object.control, new_position);
										self.update_counter = 3;
									self.update_counter -= 1;
							
						MODE_RINGS:
							
							if self.active_curve.is_ring_selected():
								if !Input.is_key_pressed(KEY_SHIFT):
									var change_amt = event.relative.x / self.rect_size.x;
									self.active_curve.change_selected_ring_value(change_amt);
									self.mouse_caption.text = "%.2f" % self.active_curve.selected_ring.value;
								
								else:
									var ring = self.active_curve.selected_ring.global_transform.origin;	
									var origin = _camera.project_ray_origin(event.position);
									var dir = _camera.project_ray_normal(event.position);
									var projected_point:Vector3 = origin + dir * ring.distance_to(origin);
									var closest_offset = self.active_curve.curve.get_closest_offset(projected_point);
									self.active_curve.set_selected_ring_offset(closest_offset);
									
								self.emit_signal("data_changed", self.active_curve.data, self.active_curve.ring_data_name, self.active_curve.ring_curve);
							
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT:
				if !event.pressed:
					if self.dragged_object != null:
						self.dragged_object.handles_enabled = false;
						self.dragged_object.selected = false;
						self.dragged_object = null;
					
					self.mouse_caption.text = "";
				else:
					self.mouse_caption.rect_position = event.position;
					
			elif event.button_index == BUTTON_RIGHT && !event.pressed:
				
				if self.active_curve != null:
					
					match self.mode:
						MODE_VIEW:
							pass
						
						MODE_CURVES:
					
							var point_on_cursor:EditorCurvePoint = self.active_curve.get_closest_control_point_by_offset(self.cursor_offset, 0.1);
						
							if self.cursor_offset > -1.0:
								if point_on_cursor != null:
									self.active_curve.remove_point(point_on_cursor.get_index());
								else:
									self.active_curve.insert_point(self.cursor_offset);
									
							else:
								var last_point:Vector3 = self.active_curve.curve.get_point_position(self.active_curve.curve.get_point_count() - 1);
								var depth:float = last_point.distance_to(_camera.global_transform.origin);
								self.active_curve.add_point(_camera.project_position(event.position, depth));
							
							self.emit_signal("data_changed", self.active_curve.data, self.active_curve.ring_data_name, self.active_curve.ring_curve);
						
						MODE_RINGS:
							
							if self.active_curve.is_ring_selected():
								self.active_curve.remove_ring(self.active_curve.selected_ring);
							elif self.cursor_offset > -1.0:
								self.active_curve.insert_ring(self.cursor_offset);
							
							self.emit_signal("data_changed", self.active_curve.data, self.active_curve.ring_data_name, self.active_curve.ring_curve);
				
			
				
		
					


func _on_mode_button_up(mode_name):
	self.mode = mode_name;
	

func update_mode_controls():
	match self.mode:
		MODE_VIEW:
			pass
		MODE_CURVES:
			$Control/Controls.text = """
			
			"""
			pass
		MODE_RINGS:
			pass

func _on_EditingMode_value_changed(val):
	
	if val == 0:
		self.mode = MODE_CURVES;
		self.mode_ring_propname = "";
		if self.active_curve != null:
			self.active_curve.rings.visible = false;
			self.active_curve.points.visible = true;
	else:
		self.mode = MODE_RINGS;
		if self.active_curve != null:
			
			self.active_curve.rings.visible = true;
			self.active_curve.points.visible = false;
			
			self.mode_ring_propname = "";
			
			var full_string = self.editing_options[val];
			match full_string:
				"Branch radius scaling":
					self.mode_ring_propname = "branch_radius_curve";
				"Leaf size scaling":
					self.mode_ring_propname = "leaf_size_curve";
				"Trunk radius scaling":
					self.mode_ring_propname = "trunk_radius_curve";
				"Branch size scaling":
					self.mode_ring_propname = "branch_size_curve";
				"Branch X rotation":
					self.mode_ring_propname = "branch_angle_x_curve";
				"Branch Y rotation":
					self.mode_ring_propname = "branch_angle_y_curve";
				"Branch Z rotation":
					self.mode_ring_propname = "branch_angle_z_curve";
			
			self.active_curve.load_ring_data(self.mode_ring_propname);
