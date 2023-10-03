tool
extends ViewportContainer


onready var _viewport:Viewport = $Viewport;
onready var _mi:MeshInstance = $Viewport/Spatial/MeshInstance;
onready var _camera_hinge:Spatial = $Viewport/Spatial/Spatial;

func _ready():
	_viewport.size = self.rect_size;
	pass

func load_mesh(mesh:Mesh):
	_mi.mesh = mesh;
	var aabb:AABB = mesh.get_aabb();
	_camera_hinge.get_child(0).transform.origin.y = aabb.size.y / 2.0;
	_camera_hinge.get_child(0).transform.origin.z = aabb.size.x * 1.5;

func _on_Previewer3D_resized():
	if _viewport:
		_viewport.size = self.rect_size;
		pass
	
	
	pass # Replace with function body.


func _process(delta):
	$Viewport/Spatial/Spatial.rotation_degrees.y += 0.1;


