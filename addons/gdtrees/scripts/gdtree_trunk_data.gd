tool
class_name GdTreeTrunkData
extends Resource

signal update_mesh (type)

var curve:Curve3D = Curve3D.new();
var material_bark;
export var inherit_properties:bool = true;

var leaf_surface:int = -1;
var branch_surface:int = -1;

var lod0_trunk_mesh:ArrayMesh = ArrayMesh.new();
var lod0_branch_mesh:ArrayMesh = ArrayMesh.new();
var lod1_trunk_mesh:ArrayMesh = ArrayMesh.new();
var lod1_branch_mesh:ArrayMesh = ArrayMesh.new();
var lod2_trunk_mesh:ArrayMesh = ArrayMesh.new();
var lod2_branch_mesh:ArrayMesh = ArrayMesh.new();

var trunk_radius:float = 1.0;
var trunk_radial_segments:int = 8;
var trunk_radius_curve:Curve = Curve.new();
var trunk_interval:float = 0.5;
var trunk_simplify:float = 0.25;
var trunk_truncation:float = 0.0;
var trunk_bumpiness:float = 0.0;

var branch_display:bool = true;
var branch_spacing:int = 16;
var branch_spacing_multiplier:float = 1.0;
var branch_num_per_node:int = 1;
var branch_size_curve:Curve = Curve.new();

var branch_angle:Vector3 = Vector3.ZERO;
var branch_nodes_per_turn:float = 1.0;

var branch_angle_x_curve:Curve = Curve.new();
var branch_angle_y_curve:Curve = Curve.new();
var branch_angle_z_curve:Curve = Curve.new();

var leaf_doublesided:bool = true;

var radial_vertices:PoolVector3Array = PoolVector3Array();

func create_copy() -> GdTreeTrunkData:
	var res:GdTreeTrunkData = self.duplicate();
	res.curve = self.curve.duplicate();
	for key in ["trunk_radius_curve", "branch_size_curve", "branch_angle_x_curve", "branch_angle_y_curve", "branch_angle_z_curve"]:
		res.set(key, self.get(key).duplicate());
	for i in range(3):
		var mesh = self.get(str("lod", i, "_branch_mesh"));
		res.set(str("lod", i, "_branch_mesh"), mesh.duplicate());
		mesh = self.get(str("lod", i, "_trunk_mesh"));
		res.set(str("lod", i, "_trunk_mesh"), mesh.duplicate());
	return res;

func _get_property_list():
	var properties = []
	var usage_saved:int = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
	
	properties.append(Utils.new_prop("curve", TYPE_OBJECT));
	
	properties.append(Utils.new_prop_group("Trunk options", "trunk_"))
	properties.append(Utils.new_prop("trunk_radial_segments", TYPE_INT));
	properties.append(Utils.new_prop("trunk_radius", TYPE_REAL));
	properties.append(Utils.new_prop("trunk_radius_curve", TYPE_OBJECT));
	properties.append(Utils.new_prop("trunk_interval", TYPE_REAL, "0.1,2.0", PROPERTY_HINT_RANGE));
	properties.append(Utils.new_prop("trunk_simplify", TYPE_REAL, "0.0,1.0", PROPERTY_HINT_RANGE));
	properties.append(Utils.new_prop("trunk_truncation", TYPE_REAL, "0.0,1000.0", PROPERTY_HINT_EXP_RANGE));
	

	properties.append(Utils.new_prop_group("Branch options", "branch_"))
	properties.append(Utils.new_prop("branch_display", TYPE_BOOL));
	properties.append(Utils.new_prop("branch_spacing", TYPE_INT));
	properties.append(Utils.new_prop("branch_spacing_multiplier", TYPE_REAL, "0.5,2.0", PROPERTY_HINT_RANGE));
	properties.append(Utils.new_prop("branch_num_per_node", TYPE_INT));
	properties.append(Utils.new_prop("branch_nodes_per_turn", TYPE_REAL, "0.0,10.0", PROPERTY_HINT_RANGE));
	properties.append(Utils.new_prop("branch_size_curve", TYPE_OBJECT));
	properties.append(Utils.new_prop("branch_angle", TYPE_VECTOR3));
	properties.append(Utils.new_prop("branch_angle_x_curve", TYPE_OBJECT));
	properties.append(Utils.new_prop("branch_angle_y_curve", TYPE_OBJECT));
	properties.append(Utils.new_prop("branch_angle_z_curve", TYPE_OBJECT));
	
	#properties.append(Utils.new_prop_group("Saved Data", "lod"))
	#for i in range(3):
	#	properties.append(Utils.new_prop("lod" + str(i) + "_trunk_mesh", TYPE_OBJECT));
	#	properties.append(Utils.new_prop("lod" + str(i) + "_branch_mesh", TYPE_OBJECT));
	
	properties.append(Utils.new_prop_group("Materials", "material"));
	properties.append(Utils.new_prop("material_bark", TYPE_OBJECT));
	
	return properties
	

func _init():
	
	self.resource_name = "GdTreeTrunk";
	self.update_radial_vertices();
	
	if self.curve.get_point_count() == 0:
		self.curve.add_point(Vector3.ZERO);
		self.curve.add_point(Vector3(0, 10, 0));
	
	Utils.init_curve(self.trunk_radius_curve, 1.0);
	Utils.init_curve(self.branch_size_curve, 1.0);
	Utils.init_curve(self.branch_angle_x_curve, 0.0, -1.0, 1.0);
	Utils.init_curve(self.branch_angle_y_curve, 0.0, -1.0, 1.0);
	Utils.init_curve(self.branch_angle_z_curve, 0.0, -1.0, 1.0);

func update_radial_vertices(n:int=-1):
	if n < 0:
		n = self.trunk_radial_segments;
	if n != self.radial_vertices.size():	
		self.radial_vertices.resize(n);
		for i in range(n):
			var a = deg2rad((360 / n) * i);
			var cos_a = cos(a);
			var sin_a = sin(a);
			self.radial_vertices[i] = Vector3(cos_a, 0, sin_a);

func notify_update_trunk():
	if self.radial_vertices.size() == 0:
		self.update_radial_vertices();
	self.emit_signal("update_mesh", "trunk")
	pass
	
func copy_parent_properties(parent:GdTreeTrunkData):
	# Copy properties
	if self.inherit_properties:
		self.trunk_truncation = parent.trunk_truncation;
		self.trunk_bumpiness = parent.trunk_bumpiness;
		self.trunk_simplify = parent.trunk_simplify;
		self.trunk_interval = parent.trunk_interval;
		self.branch_display = parent.branch_display;
		self.branch_spacing_multiplier = parent.branch_spacing_multiplier;
		self.branch_spacing = parent.branch_spacing;
		self.branch_num_per_node = parent.branch_num_per_node;
		self.branch_nodes_per_turn = parent.branch_nodes_per_turn;
		self.branch_angle = parent.branch_angle;
		
		Utils.copy_curve(self.branch_size_curve, parent.branch_size_curve);
		Utils.copy_curve(self.trunk_radius_curve, parent.trunk_radius_curve);
		Utils.copy_curve(self.branch_angle_x_curve, parent.branch_angle_x_curve);
		Utils.copy_curve(self.branch_angle_y_curve, parent.branch_angle_y_curve);
		Utils.copy_curve(self.branch_angle_z_curve, parent.branch_angle_z_curve);
		
		self.property_list_changed_notify();

func notify_update_branches():
	self.emit_signal("update_mesh", "branches");
	
func get_transform_from_up_vector(up_vector:Vector3):
	var y = Vector3.FORWARD.cross(up_vector);
	return Transform(Basis(y, up_vector, y.cross(up_vector)));
	
func generate_trunk(lod_data, max_lod:int=1):
	
	for current_lod in range(max_lod):
		# Adjust the base radius to the parent trunk's current radius
		#if self.get_parent().get_class() == "GdTreeTrunk":
		#	self.copy_parent_properties()
		
		var trunk_mesh:ArrayMesh = self.get(str("lod", current_lod, "_trunk_mesh"));
		trunk_mesh.clear_surfaces();
		
		var trunk_simplify:float = self.trunk_simplify;
		
		var lod:String = str("lod", current_lod, "_");
		var lod_trunk_simplify:float = lod_data.get(lod + "trunk_simplify");
		if lod_trunk_simplify >= 0.0:
			trunk_simplify = lod_trunk_simplify;
		self.update_radial_vertices(lod_data.get(lod + "trunk_radial_segments"));
		
		var curve_len:float = self.curve.get_baked_length();
		var curve_len_truncated:float = max(0.0, curve_len - curve_len * self.trunk_truncation);
		var curve_step:float = curve_len * max(0.1 * self.trunk_interval, 0.01);
		var offset:float = 0.0;
		
		# Compute the radius and transform of mesh loops
		var baked_radius = [];
		var baked_transforms = [];
		var baked_offset = [];
		var baked_up = Vector3.ZERO;
		
		while offset < curve_len_truncated:
			var i:float = offset / curve_len;
			var p1 = self.curve.interpolate_baked(offset);
			var p2 = self.curve.interpolate_baked(offset + curve_step);
			
			var up = (p2 - p1).normalized();
			var t = self.get_transform_from_up_vector(up);
			t.origin = p1;
			if baked_up.length_squared() < 0.0001 || baked_up.angle_to(up) > deg2rad(45.0 * trunk_simplify + 1.0):
				baked_transforms.append(t);
				baked_radius.append(self.trunk_radius  * self.trunk_radius_curve.interpolate(i) * (self.trunk_bumpiness * 0.5 * sin(i * 200.0) + 1.0) * (0.25 * randf() + 0.75));
				baked_up = up;
				baked_offset.append(i);
				
			offset += curve_step;
			
			if offset >= curve_len_truncated:
				offset = curve_len_truncated;
				i = 1.0;
				p1 = self.curve.interpolate_baked(offset);
				p2 = self.curve.interpolate_baked(offset - curve_step * 0.5);
				
				up = (p1 - p2).normalized();
				t = self.get_transform_from_up_vector(up);
				t.origin = p1;
				baked_radius.append(self.trunk_radius  * self.trunk_radius_curve.interpolate(i));
				baked_transforms.append(t);
				baked_offset.append(i);
		
		var st:SurfaceTool = SurfaceTool.new();
		st.clear();
		st.begin(Mesh.PRIMITIVE_TRIANGLES);
		st.add_smooth_group(true);
		
		if baked_transforms.size() > 0:
			
			for i in range(baked_transforms.size() - 1):
				var t1:Transform = baked_transforms[i];
				var t2:Transform = baked_transforms[i + 1];
				var p1 = t1.origin;
				var p2 = t2.origin;
				var i1:float = baked_offset[i]  * curve_len / 10.0;
				var i2:float = baked_offset[i + 1]  * curve_len / 10.0;
				t1.origin = Vector3.ZERO;
				t2.origin = Vector3.ZERO;
				
				
				var c1:Color = Color(max(baked_offset[i] - 0.25, 0.0), 0, 0);
				var c2:Color = Color(max(baked_offset[i + 1] - 0.25, 0.0), 0, 0);
				
				
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
			
		
			var last_t = baked_transforms[baked_transforms.size() - 1];
			var last_radius = baked_radius[baked_radius.size() - 1];
			var last_origin = last_t.origin;
			last_t.origin = Vector3.ZERO;
			for r in range(self.radial_vertices.size()):
				var next = r + 1;
				if next == self.radial_vertices.size():
					next = 0;
					
				st.add_uv(0.5 * Vector2(self.radial_vertices[r].x + 1.0, self.radial_vertices[r].z + 1.0));
				st.add_vertex(last_radius * last_t.xform(self.radial_vertices[r]) + last_origin);
				st.add_uv(0.5 * Vector2(self.radial_vertices[next].x + 1.0, self.radial_vertices[next].z + 1.0));
				st.add_vertex(last_radius * last_t.xform(self.radial_vertices[next]) + last_origin);
				st.add_uv(Vector2(0.5, 0.5));
				st.add_vertex(last_origin + last_t.basis.y);
					
			st.index();
			st.generate_normals();
			
		st.commit(trunk_mesh);
		trunk_mesh.surface_set_material(0, material_bark);

func generate_branches(branch_data:GdTreeBranchData, lod_data=null, max_lod:int=1):
	if branch_data == null:
		return;
		
	var branch_origin:Vector3 = branch_data.curve.get_point_position(0);
	var curve_len:float = self.curve.get_baked_length();
	var curve_step:float = curve_len * 0.1;
	var rot_y = 0.0;
	
	var branch_spacing:float = max(self.branch_spacing, curve_len * 0.025);
	
	# These values are filled in below to be used for branch generation
	var node_origins:Array = [];
	var node_xforms:Array = [];
	var node_offsets:Array = [];
	var branch_count:int = 0;
	var spacing_multiplier = 1.0;
	
	var offset = curve_len - curve_step * 0.5;
	while offset > 0.0:
		
		var i:float = offset / curve_len;
		var branch_size = self.branch_size_curve.interpolate(i);
		var x_curve = self.branch_angle_x_curve.interpolate(i);
		var y_curve = self.branch_angle_y_curve.interpolate(i);
		var z_curve = self.branch_angle_z_curve.interpolate(i);
		
		if branch_size > 0.0:
			
			var p1:Vector3 = self.curve.interpolate_baked(offset);
			var p2:Vector3 = self.curve.interpolate_baked(offset - 0.5);
			var trunk_xform:Transform = self.get_transform_from_up_vector(p1 - p2).orthonormalized();
			
			
			node_origins.append(p1);
			var branch_group:Array = [];
			
			# For each branch at the node, calculate the transform
			for n in range(self.branch_num_per_node):
				 # Shift branch to origin for rotations
				var branch_xform = Transform(Basis(), -branch_origin);
				
				# Rotations along each axis
				branch_xform = branch_xform.rotated(Vector3.RIGHT, deg2rad(self.branch_angle.x + 180 * x_curve)); 
				branch_xform = branch_xform.rotated(Vector3.FORWARD, deg2rad(self.branch_angle.z + 180 * z_curve));
				branch_xform= branch_xform.rotated(Vector3.UP, deg2rad(self.branch_angle.y + 180 * y_curve) + rot_y + 2.0 * PI * float(n) / float(self.branch_num_per_node));
				
				# Scale branch by size
				branch_xform = Transform(trunk_xform.basis.scaled(Vector3.ONE * branch_size), p1) * branch_xform;
				
				# Append to branch gorup
				branch_group.append(branch_xform);
				branch_count += 1;
			
			# Append branch_group to node_xforms	
			node_xforms.append(branch_group);
			node_offsets.append(i);
			
			# Increase rotation along Y-axis (ie trunk)
			if self.branch_nodes_per_turn > 0.0:
				rot_y += PI / self.branch_nodes_per_turn;
		
		offset -= max(branch_spacing * spacing_multiplier, curve_len * 0.025);
		spacing_multiplier = max(spacing_multiplier * self.branch_spacing_multiplier, 0.1);
	
	var mdt:MeshDataTool = MeshDataTool.new();
	
	# Adjust the base radius to the parent trunk's current radius
	#if self.get_parent() &&  self.get_parent().get_class() == "GdTreeTrunk":
	#	self.copy_parent_properties();
	for current_lod in range(max_lod):
		var branch_mesh:ArrayMesh = self.get(str("lod", current_lod, "_branch_mesh"));
		branch_mesh.clear_surfaces();
				
		var branch_min_size:float = 0.0;
		var branch_display:bool = branch_data.branch_display;
		var leaf_doublesided:bool = true;

		# LOD overrides
		var lod:String = str("lod", current_lod, "_");
		var lod_branch_display = lod_data.get(lod + "branch_display");
		if lod_branch_display > -1:
			branch_display = lod_branch_display == 1;
		leaf_doublesided = lod_data.get(lod + "leaf_doublesided");
		

		# Material overrides
		#if self.material_bark == null:
		#	self.bark_material = self.bark_material;
			
			
		if branch_data != null && self.branch_display:
			var branch_data_mesh:ArrayMesh = branch_data.get(str("lod", current_lod, "_branch_mesh"));
			var branch_mesh_surface_count = branch_data_mesh.get_surface_count();
			
			self.leaf_surface = branch_data.get_leaf_surface();
			self.branch_surface = branch_data.get_branch_surface();
			
			var st:SurfaceTool = SurfaceTool.new();
			
			# For branches, copy and transform the branch mesh
			if self.branch_surface > -1 &&  branch_data_mesh.surface_get_arrays(self.branch_surface).size() > 0:

				# For each node on the trunk, set the branch mesh's vertex color and append to surface
				st.begin(Mesh.PRIMITIVE_TRIANGLES);
				for i in range(node_xforms.size()):
					mdt.clear();
					mdt.create_from_surface(branch_data_mesh, self.branch_surface);
					var mesh:ArrayMesh = ArrayMesh.new();
					for v in mdt.get_vertex_count():
						var c:Color = mdt.get_vertex_color(v);
						mdt.set_vertex_color(v, Color(max(node_offsets[i] - 0.25, 0.0), c.r, 0, 0));
					mdt.commit_to_surface(mesh);
					
					var xforms = node_xforms[i];
					for t in xforms:
						st.append_from(mesh, 0, t);
						
				st.commit(branch_mesh);
				branch_mesh.surface_set_material(self.branch_surface, material_bark);
			
			if self.leaf_surface > -1 && branch_data_mesh.surface_get_arrays(self.leaf_surface).size() > 0:
				var trunk_center = self.curve.interpolate_baked(0.5);
				var mesh_vertices = branch_data_mesh.surface_get_arrays(self.leaf_surface)[0];
				var mesh_uvs = branch_data_mesh.surface_get_arrays(self.leaf_surface)[4];
				var mesh_indices = branch_data_mesh.surface_get_arrays(self.leaf_surface)[8];
				var mesh_colors = branch_data_mesh.surface_get_arrays(self.leaf_surface)[3];
				var mesh_normals = branch_data_mesh.surface_get_arrays(self.leaf_surface)[1];
				
				var leaf_mesh = branch_data.get(str("lod", current_lod, "_leaf_mesh"));
				
				var v_weight = (1.0 / float(mesh_indices.size() * self.branch_num_per_node));
				var verts = [];
				var uvs = [];
				var normals = [];
				var colors = [];
				var centroids = [];
				var centroid_radii = [];
					
				for i in range(node_xforms.size()):
				
					var xforms:Array = node_xforms[i];
					var node_origin = node_origins[i];
					var centroid:Vector3 = Vector3.ZERO;
					var verts_tmp = [];
					var r:float = max(0.0, node_offsets[i] - 0.25);
					
					for t in xforms:
						for index in mesh_indices:
							var vert:Vector3 = t.xform(mesh_vertices[index]);
							centroid += v_weight * vert;
							verts_tmp.append(vert);
							uvs.append(mesh_uvs[index]);
							var color:Color = mesh_colors[index];
							color.r = max(node_offsets[i] - 0.25, 0.0);
							colors.append(color);
							if !branch_data.branch_blob_normals:
								normals.append(mesh_normals[index]);
				
					var centroid_radius:float = 0.0;
					for vert_tmp in verts_tmp:
						verts.append(vert_tmp);
						
						if branch_data.branch_blob_normals:
							centroid_radius = max(centroid_radius, vert_tmp.distance_squared_to(centroid));
							var normal:Vector3 = (0.5 * (vert_tmp - centroid) + 0.5 * (vert_tmp - node_origin)).normalized();
							normals.append(normal);
						#normals.append(Vector3(max(normal.x, 0),max(normal.y, 0),max(normal.z, 0)));
						#normals.append((vert_tmp -centroid).normalized());
					
					if branch_data.branch_blob_normals:
						centroids.append(centroid);
						centroid_radii.append(centroid_radius);	
					
				if branch_data.branch_blob_normals:
					for i in range(verts.size()):
						var vert:Vector3 = verts[i];
						var weighted_normal:Vector3 = Vector3.ZERO;
						var m:int = 0;
						for n in range(centroids.size()):
							var centroid:Vector3 = centroids[n];
							var centroid_radius:float = centroid_radii[n];
							var diff:Vector3 = vert - centroid;
							var length:float = diff.length_squared();
							if length < centroid_radius:
								weighted_normal += diff.normalized() * length / centroid_radius;
								m += 1;
						
						weighted_normal /= float(m) * weighted_normal.length();
						normals[i] = branch_data.branch_normal_adjust * weighted_normal + (1.0 - branch_data.branch_normal_adjust) * normals[i];
					#normals[i] = Vector3(max(normals[i].x, 0),max(normals[i].y, 0),max(normals[i].z, 0));
				
				
				st.clear();
				st.begin(Mesh.PRIMITIVE_TRIANGLES);
				st.add_smooth_group(true);
				# Front face
				for i in range(verts.size()):
					st.add_uv(uvs[i]);
					st.add_normal(normals[i]);
					st.add_color(colors[i]);
					st.add_vertex(verts[i]);
				
				if leaf_doublesided && branch_data.branch_blob_normals:
					# Backface
					for i in range(verts.size() - 1, -1, -1):
						st.add_uv(uvs[i]);
						st.add_normal(normals[i]);
						st.add_color(colors[i]);
						st.add_vertex(verts[i]);
				
				
				if !branch_data.branch_blob_normals:
					st.generate_normals();
					
				st.commit(branch_mesh);
				branch_mesh.surface_set_material(self.leaf_surface, branch_data.leaf_material);
		
