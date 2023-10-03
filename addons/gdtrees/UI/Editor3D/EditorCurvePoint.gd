class_name EditorCurvePoint
extends Spatial

const CONTROL_MATERIAL = preload("ControlPoint.material");
const HANDLE_MATERIAL = preload("ControlHandle.material");
const CONTROL_TEXTURE = preload("control_point.png");
const HANDLE_TEXTURE = preload("handle_point.png");


var LINE_MATERIAL = preload("CurvePoints.material");

var control:Sprite3D;
var in_handle:Sprite3D;
var out_handle:Sprite3D;
var ig:ImmediateGeometry;

var fixed:bool = false;

var handles_enabled:bool = false setget set_handles_enabled;
func set_handles_enabled (val:bool):
	if handles_enabled != val && self.in_handle:
		in_handle.visible = val && in_handle.transform.origin.length_squared() > 0.0001;
		out_handle.visible = val && out_handle.transform.origin.length_squared() > 0.0001;
		ig.visible = val;
	handles_enabled = val;

var selected:bool = false setget set_selected;
func set_selected (val:bool):
	selected = val;
	if in_handle != null:
		in_handle.visible = val && in_handle.transform.origin.length_squared() > 0.0001;
		out_handle.visible = val && out_handle.transform.origin.length_squared() > 0.0001;
		ig.visible = val;


var active:bool = true setget set_active;
func set_active (val:bool):
	visible = val;
	active = val;

var symmetric:bool = true;

func get_class():
	return "EditorCurvePoint"

func _ready():
	pass

func get_parent_curve():
	return self.get_parent().get_parent();	

	
func init(position:Vector3, _in:Vector3, _out:Vector3):
	
	var sphere_shape:SphereShape = SphereShape.new();
	sphere_shape.radius = 0.4;
	
	self.transform.origin = position;
	
	self.control = Sprite3D.new();
	self.control.visible = true;
	self.control.billboard = SpatialMaterial.BILLBOARD_ENABLED;
	self.control.pixel_size = 0.001;
	self.control.name = "control";
	self.control.texture = CONTROL_TEXTURE;
	self.control.material_override = CONTROL_MATERIAL;
	self.add_child(self.control);
	
	self.in_handle = Sprite3D.new();
	self.in_handle.visible = self.selected;
	self.in_handle.billboard = SpatialMaterial.BILLBOARD_ENABLED;
	self.in_handle.pixel_size = 0.001;
	self.in_handle.name = "in";
	self.in_handle.material_override = HANDLE_MATERIAL;
	self.in_handle.texture = HANDLE_TEXTURE;
	self.in_handle.transform.origin = _in;
	self.add_child(self.in_handle);
	self.in_handle.visible = false;
	
	self.out_handle = Sprite3D.new();
	self.out_handle.visible = self.selected;
	self.out_handle.billboard = SpatialMaterial.BILLBOARD_ENABLED;
	self.out_handle.pixel_size = 0.001;
	self.out_handle.name = "out";
	self.out_handle.material_override = HANDLE_MATERIAL;
	self.out_handle.texture = HANDLE_TEXTURE;
	self.out_handle.transform.origin = _out;
	self.add_child(self.out_handle);
	self.out_handle.visible = false;
	
	self.ig = ImmediateGeometry.new();
	self.ig.visible = self.selected;
	ig.material_override = LINE_MATERIAL;
	self.ig.name = "ig";
	self.add_child(self.ig);
	self.update_ig();
	
func update_ig():
	self.ig.clear();
	self.ig.begin(Mesh.PRIMITIVE_LINE_STRIP);
	self.ig.add_vertex(in_handle.transform.origin);
	self.ig.add_vertex(Vector3.ZERO);
	self.ig.add_vertex(out_handle.transform.origin);
	self.ig.end();
	
	
func update(moved_object, new_position):
	var parent_curve = self.get_parent_curve();
	
	var idx:int = self.get_index();
	if moved_object == control:
		if idx == 0 && self.fixed:
			return;
		self.global_transform.origin = new_position;
		parent_curve.curve.set_point_position(idx, new_position);
	else:
		moved_object.transform.origin = new_position - self.global_transform.origin;
		moved_object.visible = moved_object.transform.origin.length_squared() > 0.0001;
		if symmetric:
			if moved_object == self.in_handle:
				self.out_handle.transform.origin = -self.in_handle.transform.origin;
				self.out_handle.visible = moved_object.visible;
				
			else:
				self.in_handle.transform.origin = -self.out_handle.transform.origin;
				self.in_handle.visible = moved_object.visible;
		
		parent_curve.curve.set_point_in(idx, self.in_handle.transform.origin);
		parent_curve.curve.set_point_out(idx, self.out_handle.transform.origin);
		
	self.update_ig();
	parent_curve.update();
	
	
	
	
