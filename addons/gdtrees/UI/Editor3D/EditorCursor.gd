tool
extends ImmediateGeometry


func _ready():
	self.clear();
	self.begin(Mesh.PRIMITIVE_LINE_STRIP);
	for i in range(16) + [0]:
		var a:float = 2.0 * PI * i / (16.0);
		self.add_vertex(0.02 * Vector3(cos(a), sin(a), 0));
	self.end();
