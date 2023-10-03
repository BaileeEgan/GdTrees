tool
class_name GdTreeLODData
extends Resource

var lod0_simplify:float = 0.0;
var lod0_trunk_simplify:float = 0.0;
var lod0_branch_simplify:float = 0.0;

var lod0_trunk_radial_segments:int = -1;
var lod0_branch_radial_segments:int = -1;
var lod0_branch_display:int = -1;
var lod0_leaf_display:int = -1;

var lod0_branch_min_size:float = 0.0;
var lod0_leaf_min_size:float = 0.0;

var lod0_leaf_num_per_node:int = 0;
var lod0_branch_num_per_node:int = 0;

var lod0_leaf_type:int = -1;
var lod0_leaf_doublesided:bool = true;
var lod0_leaf_subdivision_perc:float = 1.0;
var lod0_leaf_scale:float = 1.0;




var lod1_trunk_radial_segments:int = 4;
var lod1_trunk_simplify:float = 0.75;
var lod1_branch_radial_segments:int = 4;
var lod1_branch_display:int = -1;
var lod1_branch_min_size:float = 0.25;
var lod1_branch_simplify:float = 0.5;
var lod1_leaf_type:int = -1;
var lod1_leaf_scale:float = 1.0;
var lod1_leaf_doublesided:bool = false;
var lod1_leaf_min_size:float = 0.25;
var lod1_leaf_subdivision_perc:float = 0.5;


var lod2_trunk_radial_segments:int = 3;
var lod2_trunk_simplify:float = 0.5;
var lod2_branch_display:int = -1;
var lod2_branch_min_size:float = 0.5;
var lod2_branch_simplify:float = 0.25;
var lod2_branch_radial_segments:int = 3;
var lod2_leaf_type:int = -1;
var lod2_leaf_scale:float = 1.0;
var lod2_leaf_doublesided:bool = false;
var lod2_leaf_min_size:float = 0.4;
var lod2_leaf_subdivision_perc:float = 0.0;

var lod0_mesh:ArrayMesh = ArrayMesh.new();
var lod1_mesh:ArrayMesh = ArrayMesh.new();
var lod2_mesh:ArrayMesh = ArrayMesh.new();

func create_copy() -> GdTreeLODData:
	var res:GdTreeLODData = self.duplicate();
	res.lod0_mesh = self.lod0_mesh.duplicate();
	res.lod1_mesh = self.lod1_mesh.duplicate();
	res.lod2_mesh = self.lod2_mesh.duplicate();
	return res;

func _get_property_list():
	var properties = []
	var usage_saved:int = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
	
	for i in range(3):
		var lod:String = str("lod", i, "_");
	
		properties.append(Utils.new_prop_group(str("LOD ", i), lod));
		properties.append(Utils.new_prop(lod + "trunk_radial_segments", TYPE_INT));
		properties.append(Utils.new_prop(lod + "trunk_simplify", TYPE_REAL, "0.0,1.0", PROPERTY_HINT_RANGE));
		
		properties.append(Utils.new_prop_enum(lod + "branch_display", {"INHERIT": -1, "TRUE": 1, "FALSE": 0}));
		properties.append(Utils.new_prop(lod + "branch_min_size", TYPE_REAL, "0.0,5.0", PROPERTY_HINT_RANGE));
		properties.append(Utils.new_prop(lod + "branch_radial_segments", TYPE_INT));
		properties.append(Utils.new_prop(lod + "branch_simplify", TYPE_REAL, "0.0,1.0", PROPERTY_HINT_RANGE));
	
		properties.append(Utils.new_prop_enum(lod + "leaf_type", {"INHERIT": -1, "FLAT": 0, "BENT": 1, "CROSS": 2}));
		properties.append(Utils.new_prop(lod + "leaf_scale", TYPE_REAL, "0.1,2.0", PROPERTY_HINT_RANGE));
		properties.append(Utils.new_prop(lod + "leaf_min_size", TYPE_REAL, "0.0,5.0", PROPERTY_HINT_RANGE));
		properties.append(Utils.new_prop(lod + "leaf_doublesided", TYPE_BOOL));
		properties.append(Utils.new_prop(lod + "mesh", TYPE_OBJECT));
		
	return properties;
