class_name EditorCurveRing
extends ImmediateGeometry

var value:float = 1.0;
var offset:float = 0.0;
var LINE_MATERIAL = preload("Curve.material");

func _ready():
	pass

func _init():
	self.material_override = LINE_MATERIAL;
	self.begin(Mesh.PRIMITIVE_LINE_STRIP);
	for i in range(16) + [0]:
		var angle = i * PI / 8;
		var sin_a = sin(angle);
		var cos_a = cos(angle);
		var point:Vector3 = Vector3(0, cos_a, sin_a);
		self.add_vertex(point);
	self.end();
	
