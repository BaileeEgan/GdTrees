tool
class_name GdTree
extends Spatial

export (int,0,2) var current_lod:int = 0 setget set_current_lod;
func set_current_lod(val:int):
	if val != current_lod:
		current_lod = val;
		if get_child_count() != 0:
			update_lod();
			
export var _data:Resource = null setget set_data;

func set_data (data):
	_data = data;
	update_lod();
	

func get_class():
	return "GdTree"
	
var mi:MeshInstance;
	
func _init():
	self.mi = MeshInstance.new();
	self.add_child(self.mi);
		

func _ready():	
	self.update_lod();
	
		
func update_lod():
	if _data != null:
		var lod_data:GdTreeLODData = _data.lod_data;
		self.mi.mesh = lod_data.get(str("lod", self.current_lod, "_mesh"));
	else:
		self.mi.mesh = null;
