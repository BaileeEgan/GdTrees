tool
extends Spatial

onready var _camera:Camera = get_node("Camera");

func _ready():
	pass

func focus (aabb:AABB):
	self.transform.basis = Basis();
	_camera.transform.basis = Basis();
	_camera.transform.origin.z = 1.5 * aabb.size.y;
	self.transform.origin.y = aabb.size.y * 0.75;
	

func raycast_mouse (position:Vector2):
	var direct_space_state:PhysicsDirectSpaceState = self.get_world().direct_space_state;
	var origin = _camera.project_ray_origin(position);
	var dir = _camera.project_ray_normal(position) * 2000.0;
	var rayHit:Dictionary = direct_space_state.intersect_ray(origin, origin + dir, []);
	return rayHit;
	
	

func input(event:InputEvent):	
	if event is InputEventMagnifyGesture:
		_camera.transform.origin.z = max(_camera.transform.origin.z + (1.0 - event.factor) * _camera.transform.origin.z, 5);

	if event is InputEventPanGesture:
			
		if !Input.is_key_pressed(KEY_SHIFT):
			if event.delta.x * event.delta.x > event.delta.y * event.delta.y:
				self.rotation_degrees.y -= event.delta.x;
			else:
				self.rotation_degrees.x -= event.delta.y;
		else:
			if event.delta.x * event.delta.x > event.delta.y * event.delta.y:
				self.transform.origin += 0.1 * self.transform.basis.x * event.delta.x;
			else:
				self.transform.origin -= 0.1 * self.transform.basis.y * event.delta.y;
			
			self.transform.origin.y = max(0, self.transform.origin.y);
		
	
