tool
extends Resource
class_name GdTreeBranchData

signal update_mesh (type)

enum LeafType { FLAT, BENT, CROSS }

const QUAD_INDICES = [0, 0, 1, 0, 1, 1];
const QUAD_OFFSET = [
	Vector3(0, 0, 0),
	Vector3(1, 0, 0),
	Vector3(1, 0, 0),
	
	Vector3(0, 0, 0),
	Vector3(1, 0, 0),
	Vector3(0, 0, 0)
];

var lod0_leaf_mesh:ArrayMesh = ArrayMesh.new();
var lod0_branch_mesh:ArrayMesh = ArrayMesh.new();
var lod1_leaf_mesh:ArrayMesh = ArrayMesh.new();
var lod1_branch_mesh:ArrayMesh = ArrayMesh.new();
var lod2_leaf_mesh:ArrayMesh = ArrayMesh.new();
var lod2_branch_mesh:ArrayMesh = ArrayMesh.new();

var curve:Curve3D = Curve3D.new();

var branch_display:bool = true;
var branch_radius:float = 1.0;
var branch_radius_curve:Curve = Curve.new();
var branch_radial_segments:int = 4;
var branch_interval:float = 0.5;
var branch_simplify:float = 0.5;
var branch_normal_adjust:float = 0.5;
var branch_blob_normals:bool = false;

var leaf_display:bool = true;
var leaf_only:bool = false;
var leaf_type:int = LeafType.CROSS;
var leaf_size:Vector2 = Vector2(1.0, 1.0);
var leaf_size_curve:Curve = Curve.new();
var leaf_subdivisions:int = 0;
var leaf_num_per_node:int = 1;
var leaf_nodes_per_turn:float = 3.0;
var leaf_spacing:float = 2;
var leaf_angle:Vector3 = Vector3.ZERO;
var leaf_origin_shift:Vector3 = Vector3.ZERO;
var leaf_scale:float = 1.0;
var leaf_curvature:float = 0;
export var leaf_bend_angle:float = 0;
export var leaf_material:Material = null;

var radial_vertices:PoolVector3Array = PoolVector3Array();

func create_copy() -> GdTreeBranchData:
	var res:GdTreeBranchData = self.duplicate();
	res.curve = self.curve.duplicate();
	res.branch_radius_curve = self.branch_radius_curve.duplicate();
	res.leaf_size_curve = self.leaf_size_curve.duplicate();
	for i in range(3):
		var mesh = self.get(str("lod", i, "_branch_mesh"));
		res.set(str("lod", i, "_branch_mesh"), mesh.duplicate());
	return res;

func _get_property_list():
	var properties = []
	var usage_saved:int = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
	
	properties.append(Utils.new_prop("curve", TYPE_OBJECT));
	
	properties.append(Utils.new_prop_group("Branch options", "branch_"))
	properties.append(Utils.new_prop("branch_display", TYPE_BOOL));
	properties.append(Utils.new_prop("branch_radial_segments", TYPE_INT));
	properties.append(Utils.new_prop("branch_radius", TYPE_REAL));
	properties.append(Utils.new_prop("branch_radius_curve", TYPE_OBJECT));
	properties.append(Utils.new_prop("branch_interval", TYPE_REAL, "0.1,1.0", PROPERTY_HINT_RANGE));
	properties.append(Utils.new_prop("branch_simplify", TYPE_REAL, "0.1,1.0", PROPERTY_HINT_RANGE));
	properties.append(Utils.new_prop("branch_normal_adjust", TYPE_REAL, "0.0,1.0", PROPERTY_HINT_RANGE));
	properties.append(Utils.new_prop("branch_blob_normals", TYPE_BOOL));
	
	properties.append(Utils.new_prop_group("Leaf options", "leaf_"))
	properties.append(Utils.new_prop("leaf_display", TYPE_BOOL));
	properties.append(Utils.new_prop("leaf_only", TYPE_BOOL));
	properties.append(Utils.new_prop_enum("leaf_type", {"Flat": 0, "Bent": 1, "Cross": 2 }));
	properties.append(Utils.new_prop("leaf_spacing", TYPE_INT));
	properties.append(Utils.new_prop("leaf_num_per_node", TYPE_INT));
	properties.append(Utils.new_prop("leaf_nodes_per_turn", TYPE_REAL, "0.0,10.0", PROPERTY_HINT_RANGE));
	properties.append(Utils.new_prop("leaf_size", TYPE_VECTOR2));
	properties.append(Utils.new_prop("leaf_size_curve", TYPE_OBJECT));
	properties.append(Utils.new_prop("leaf_curvature", TYPE_REAL));
	properties.append(Utils.new_prop("leaf_subdivisions", TYPE_INT));
	properties.append(Utils.new_prop("leaf_angle", TYPE_VECTOR3));
	properties.append(Utils.new_prop("leaf_origin_shift", TYPE_VECTOR3));
	properties.append(Utils.new_prop("leaf_material", TYPE_OBJECT));
	

	#properties.append(Utils.new_prop_group("Saved Data", "lod"))
	#for i in range(3):
	#	properties.append(Utils.new_prop("lod" + str(i) + "_leaf_mesh", TYPE_OBJECT));
	#	properties.append(Utils.new_prop("lod" + str(i) + "_branch_mesh", TYPE_OBJECT));
	
	return properties


func _init():
	self.resource_name = "GdTreeBranch";
	if self.radial_vertices.size() == 0:
		self.update_radial_vertices();
	
	if self.curve.get_point_count() == 0:
		self.curve.add_point(Vector3.ZERO);
		self.curve.add_point(Vector3(0, 1, 0));
		
	Utils.init_curve(self.branch_radius_curve, 1.0);
	Utils.init_curve(self.leaf_size_curve, 1.0);
	
func _ready():
	pass
	
func get_leaf_surface() -> int:
	if self.branch_display && self.leaf_display:
		return 1;
	elif !self.branch_display && self.leaf_display:
		return 0;
	return -1;
	
func get_branch_surface() -> int:
	if self.branch_display:
		return 0;
	return -1;
	
"""
	Generates the base leaf mesh
"""
func create_leaf_mesh (leaf_type:int=-1):
	# Creates a temporary leaf_type variable if supplied a different leaf type (ie for lods)
	if leaf_type == -1:
		leaf_type = self.leaf_type;
		
	# Generates points along the leaf curve, calculated using the curvature
	var t:Transform = Transform(Basis.rotated(Vector3(1, 0, 0), -0.25 * PI * self.leaf_curvature), Vector3.ZERO);
	var points = [Vector3.ZERO];
	for i in range(self.leaf_subdivisions + 1):
		var p = t.xform(self.leaf_size.y * t.basis.z / float(self.leaf_subdivisions + 1)); 
		points.append(p);
		t.origin = p;
		t.basis = t.basis.rotated(Vector3.RIGHT, PI * self.leaf_curvature / (self.leaf_subdivisions + 1));
	
	# Also generate up-vectors for cross type leaves
	var up_vectors = []
	if leaf_type == LeafType.CROSS:
		for i in range(points.size()):
			var current_point:Vector3 = points[i];
			var up_vector:Vector3 = Vector3.UP;
			if i < points.size() - 1:
				var next_point:Vector3 = points[i + 1];
				up_vector = (next_point - current_point).cross(Vector3.RIGHT);
				if i > 0:
					var prev_point:Vector3 = points[i - 1]
					var up2:Vector3 = (current_point - prev_point).cross(Vector3.RIGHT);
					up_vector = 0.5 * (up_vector + up2);
			else:
				var prev_point:Vector3 = points[i - 1];
				up_vector = (current_point - prev_point).cross(Vector3.RIGHT);
			up_vectors.append(0.5 * self.leaf_size.x * up_vector.normalized());
	
	# Rotation transforms for bent-type leaves
	var t1 =  Transform(Basis().rotated(Vector3.BACK, deg2rad(self.leaf_bend_angle)), Vector3.ZERO);
	var t2 =  Transform(Basis().rotated(Vector3.BACK, -deg2rad(self.leaf_bend_angle)), Vector3.ZERO);
	
	# Signs of the up-vectors for generating perpendicular quads
	var perp_offset = [1, -1, -1, 1, -1, 1];
	var step_amount:float = 1.0 / float(self.leaf_subdivisions + 1);
	
	# Empty lists to hold mesh information
	var verts = [];
	var uvs = [];
	var colors = [];
	
	for i in range(points.size() - 1):
		var current_point:Vector3 = points[i];
		var next_point:Vector3 = points[i + 1];
		
		var quad_uv = [
			Vector2(0, i * step_amount),
			Vector2(1, i * step_amount),
			Vector2(1, (i + 1) * step_amount),
			Vector2(0, i * step_amount),
			Vector2(1, (i + 1) * step_amount),
			Vector2(0, (i + 1) * step_amount)
		]
		
		match leaf_type:
			LeafType.FLAT:
				for p in range(6):
					var n = i + QUAD_INDICES[p];
					var v:Vector3 = points[n] + QUAD_OFFSET[p] - Vector3(0.5, 0, 0);
					uvs.append(quad_uv[p]);
					verts.append(Vector3(self.leaf_size.x, 1, 1) * v);
				
			LeafType.BENT:
				# Generate left side (negative X)
				for p in range(6):
					var n = i + QUAD_INDICES[p];
					var v:Vector3 = points[n];
					var voffset:Vector3 = self.leaf_size.x * (Vector3(0.5, 1, 1) * QUAD_OFFSET[p] + Vector3(-0.5, 0, 0));
					if !is_zero_approx(voffset.x):
						voffset = t1.xform(voffset);
					uvs.append(quad_uv[p] * Vector2(0.5, 1));
					verts.append(v + voffset);
				
				# Generate right side (positive X)
				for p in range(6):
					var n = i + QUAD_INDICES[p];
					var v:Vector3 = points[n];
					var voffset:Vector3 = self.leaf_size.x * (Vector3(0.5, 1, 1) * QUAD_OFFSET[p]);
					if !is_zero_approx(voffset.x):
						voffset = t2.xform(voffset);
					uvs.append(quad_uv[p] * Vector2(0.5, 1) + Vector2(0.5, 0));
					verts.append(v + voffset);
					
			LeafType.CROSS:
				# Horizontal card
				for p in range(6):
					var n = i + QUAD_INDICES[p];
					var v:Vector3 = points[n] + QUAD_OFFSET[p] - Vector3(0.5, 0, 0);
					uvs.append(quad_uv[p]);
					verts.append(Vector3(self.leaf_size.x, 1, 1) * v);
				
				# Vertical card
				for p in range(6):
					var n = i + QUAD_INDICES[p];
					var qcenter = points[n];
					var qoffset = up_vectors[n] * perp_offset[p];
					uvs.append(quad_uv[p]);
					verts.append(qcenter + qoffset)
	
	# Transforms for leaf rotation
	var leaf_rotation = Transform(
		Basis().rotated(Vector3.FORWARD, deg2rad(self.leaf_angle.z)).rotated(Vector3.RIGHT, deg2rad(self.leaf_angle.x)).rotated(Vector3.UP, deg2rad(self.leaf_angle.y)),
		Vector3.ZERO);
		
	# Generate and return mesh
	var st:SurfaceTool = SurfaceTool.new();
	st.begin(Mesh.PRIMITIVE_TRIANGLES);
	st.add_smooth_group(true);
	for i in range(verts.size()):
		st.add_uv(uvs[i]);	
		st.add_color(Color(uvs[i].y, 0, 0));
		var v:Vector3 = leaf_rotation.xform(verts[i]) + self.leaf_origin_shift;
		st.add_vertex(v);
	st.index();
	st.generate_normals();
	return(st.commit(null));
	
# Helper function for getting 
func get_transform_from_up_vector(up_vector:Vector3):
	var y = Vector3.FORWARD.cross(up_vector);
	return Transform(Basis(y, up_vector, y.cross(up_vector)));
	
func notify_update():
	self.emit_signal("update_mesh", "branch");

func generate_branch(lod_data, max_lod:int=1):
	self.update_radial_vertices();
	
	if self.curve.get_point_count() == 0:
		self.curve.add_point(Vector3.ZERO);
		self.curve.add_point(Vector3(0, 1, 0));
		
	var curve_len:float = self.curve.get_baked_length() - 0.5;
		
	for current_lod in range(max_lod):
		var branch_mesh:ArrayMesh = self.get(str("lod", current_lod, "_branch_mesh"));
		branch_mesh.clear_surfaces();
			
		var leaf_type:int = self.leaf_type;
		var branch_simplify:float = self.branch_simplify;
		var leaf_min_size:float = 0.0;
		var leaf_scale:float = 1.0;
		self.branch_display = self.branch_display && !self.leaf_only;
		self.leaf_display = self.leaf_display || self.leaf_only;
		
		# LOD overwrites
		var lod:String = str("lod", current_lod, "_");
		var lod_branch_display:int = lod_data.get(lod + "branch_display");
		var lod_branch_simplify:float = lod_data.get(lod + "branch_simplify");
		
		# Material overrides
		#if self.bark_material == null:
		#	self.bark_material = tree.bark_material;
		#if self.leaf_material == null:
		#	self.leaf_material = tree.leaf_material;
		
		leaf_type = lod_data.get(lod + "leaf_type");
		leaf_min_size = lod_data.get(lod + "leaf_min_size");
		leaf_scale = lod_data.get(lod + "leaf_scale");
		if lod_branch_simplify >= 0.0:
			branch_simplify = lod_branch_simplify;
		if lod_branch_display != -1:
			self.branch_display = (lod_branch_display == 1) && !self.leaf_only;
				
		
		var curve_step:float = curve_len * max(0.1 * self.branch_interval, 0.01);
		var st:SurfaceTool = SurfaceTool.new();
		
		if self.branch_display:
			st.begin(Mesh.PRIMITIVE_TRIANGLES);
			st.add_smooth_group(true);
			
			var offset:float = 0.0;
			
			var baked_offset = []
			var baked_radius = [];
			var baked_transforms = [];
			var baked_up:Vector3 = Vector3.ZERO;
			while offset < curve_len:
				var i:float = offset / curve_len;
				var p1 = self.curve.interpolate_baked(offset);
				var p2 = self.curve.interpolate_baked(offset + curve_step);
				
				var up = (p2 - p1).normalized();
				var t = self.get_transform_from_up_vector(up);
				t.origin = p1;
				
				if baked_up.length_squared() < 0.001 || baked_up.angle_to(up) > deg2rad(45.0 * branch_simplify + 1.0):
					baked_up = up;
					baked_radius.append(self.branch_radius  * self.branch_radius_curve.interpolate(i));
					baked_transforms.append(t);
					baked_offset.append(i);
				
				offset += curve_step;
				
				if offset >= curve_len:
					offset = curve_len;
					i = 1.0;
					p1 = self.curve.interpolate_baked(offset);
					p2 = self.curve.interpolate_baked(offset - curve_step * 0.5);
					
					up = (p1 - p2).normalized();
					t = self.get_transform_from_up_vector(up);
					t.origin = p1;
					baked_radius.append(self.branch_radius  * self.branch_radius_curve.interpolate(i));
					baked_transforms.append(t);
					baked_offset.append(i);
				
			
			for i in range(baked_transforms.size() - 1):
				
				var t1:Transform = baked_transforms[i];
				var t2:Transform = baked_transforms[i + 1];
				
				var p1:Vector3 = t1.origin;
				var p2:Vector3 = t2.origin;
				var c1:Color = Color(max(baked_offset[i] - 0.25, 0.0), 0, 0);
				var c2:Color = Color(max(baked_offset[i + 1] - 0.25, 0.0), 0, 0);
				
				
				var i1:float = baked_offset[i]  * curve_len / 10.0;
				var i2:float = baked_offset[i + 1]  * curve_len / 10.0;
				
				t1.origin = Vector3.ZERO;
				t2.origin = Vector3.ZERO;
				
				var r1 = baked_radius[i];
				var r2 = baked_radius[i + 1];

				var segment_width = 1.0 / float(self.radial_vertices.size());
				
				for r in range(self.radial_vertices.size()):
					var next = r + 1;
					if next == self.radial_vertices.size():
						next = 0;
						
					var uvs = [
						Vector2(r * segment_width, i1),
						Vector2((r + 1) * segment_width, i1),
						Vector2((r + 1) * segment_width, i2),
						Vector2(r * segment_width, i2),
					]
					
					st.add_uv(uvs[0]);
					st.add_color(c1);	
					st.add_vertex(r1 * t1.xform(self.radial_vertices[r]) + p1);
					
					st.add_uv(uvs[1]);
					st.add_color(c1);	
					st.add_vertex(r1 * t1.xform(self.radial_vertices[next]) + p1);
					
					st.add_uv(uvs[2]);
					st.add_color(c2);	
					st.add_vertex(r2 * t2.xform(self.radial_vertices[next]) + p2);
					
					
					st.add_uv(uvs[3]);
					st.add_color(c2);	
					st.add_vertex(r2 * t2.xform(self.radial_vertices[r]) + p2);
					
					st.add_uv(uvs[0]);
					st.add_color(c1);	
					st.add_vertex(r1 * t1.xform(self.radial_vertices[r]) + p1);
					
					st.add_uv(uvs[2]);
					st.add_color(c2);	
					st.add_vertex(r2* t2.xform(self.radial_vertices[next]) + p2);
					
				offset += curve_step;
			
			st.generate_normals();
			st.commit(branch_mesh);
			#branch_mesh.surface_set_material(0, material_bark);
		
		if self.leaf_display:
			
			var leaf_spacing = max(self.leaf_spacing, 0.025 * curve_len);
			
			var origin = self.curve.get_point_position(0);
			var leaf_rotation = 0.0;
			var leaf_mesh:ArrayMesh = self.create_leaf_mesh(leaf_type);
			
			var mesh_vertices = leaf_mesh.surface_get_arrays(0)[0];
			var mesh_uvs = leaf_mesh.surface_get_arrays(0)[4];
			var mesh_colors = leaf_mesh.surface_get_arrays(0)[3];
			var mesh_indices = leaf_mesh.surface_get_arrays(0)[8];
			
			var mdt:MeshDataTool = MeshDataTool.new();
			
			var end_added:bool = false;
			
			var node_xforms = [];
			var verts:Array = [];
			
			st.clear();
			st.begin(Mesh.PRIMITIVE_TRIANGLES);
			st.add_smooth_group(true);
			
			var offset = curve_len;
			if self.leaf_only:
				offset = 0.0;
				
			while offset > 0.0:
				
				var leaf_size:float = self.leaf_size_curve.interpolate(offset / curve_len) * self.leaf_scale * leaf_scale;
				if leaf_size > leaf_min_size:
					var p1 = self.curve.interpolate_baked(offset);
					var p2 = self.curve.interpolate_baked(offset - 0.5);
					var t = self.get_transform_from_up_vector(p1 - p2);
					var branch_xform = Transform(t.basis * Vector3.ONE * leaf_size, p1 - origin);
					
					mdt.clear();
					mdt.create_from_surface(leaf_mesh, 0);
					for i in range(mdt.get_vertex_count()):
						var col:Color = mdt.get_vertex_color(i);
						col.g = offset / curve_len;
						mdt.set_vertex_color(i, col);
					leaf_mesh.surface_remove(0);
					mdt.commit_to_surface(leaf_mesh);
					
					for n in range(self.leaf_num_per_node):
						
						var leaf_xform:Transform = Transform();
						leaf_xform = leaf_xform.rotated(Vector3.UP, leaf_rotation + PI * 2.0 * float(n) / float(self.leaf_num_per_node)); # Rotates leaf along the Y-axis
						leaf_xform = leaf_xform.translated(Vector3(0, 0, self.branch_radius_curve.interpolate(offset / curve_len) * self.branch_radius * 0.5) + self.leaf_origin_shift); # Offsets leaf on Z-axis by the radius of the branch)
						leaf_xform = branch_xform * leaf_xform.scaled(Vector3.ONE * leaf_size);
						leaf_xform.origin += origin;
						node_xforms.append(leaf_xform);
						st.append_from(leaf_mesh, 0, leaf_xform);
						
					if self.leaf_nodes_per_turn > 0.0:
						leaf_rotation += PI / (self.leaf_nodes_per_turn);
				
				offset -= leaf_spacing;
				
			st.index();
			st.generate_normals();
			st.commit(branch_mesh);
			branch_mesh.surface_set_material(branch_mesh.get_surface_count() - 1, leaf_material);
		
		
					
func update_radial_vertices(n:int=-1):
	if n < 0:
		n = self.branch_radial_segments;
	
	self.radial_vertices.resize(n);
	for i in range(n):
		var a = deg2rad((360 / n) * i);
		var cos_a = cos(a);
		var sin_a = sin(a);
		self.radial_vertices[i] = Vector3(cos_a, 0, sin_a);
