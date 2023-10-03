class_name Utils
tool




static func init_curve (curve:Curve, base_value:float=0.0, min_value:float=0.0, max_value:float=1.0):
	if curve.get_point_count() == 0:
		curve.min_value = min_value;
		curve.max_value = max_value;
		curve.add_point(Vector2(0.0, base_value));
		curve.add_point(Vector2(1.0, base_value));


static func copy_curve(base:Curve, to_copy:Curve):
	base.clear_points();
	for p in range(to_copy.get_point_count()):
		var point:Vector2 = to_copy.get_point_position(p);
		var l_tangent = to_copy.get_point_left_tangent(p);
		var r_tangent = to_copy.get_point_right_tangent(p);
		var l_mode = to_copy.get_point_left_mode(p);
		var r_mode = to_copy.get_point_right_mode(p);
		base.add_point(point, l_tangent, r_tangent, l_mode, r_mode);

static func new_prop(_name:String, _type:int, _hint_string="", _hint_type:int=PROPERTY_HINT_NONE):
	return {
		name = _name,
		type = _type,
		usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE,
		hint_string = _hint_string,
		hint = _hint_type
	}
	
static func new_prop_enum(_name:String, _enum:Dictionary):
	return {
		name = _name,
		type = TYPE_INT,
		usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE,
		hint_string = enum_to_string(_enum),
		hint = PROPERTY_HINT_ENUM
	}

static func new_prop_group(_name:String, _hint_string:String):
	return {
		name = _name,
		type = TYPE_NIL,
		hint_string = _hint_string,
		usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
	}

static func enum_to_string (_enum:Dictionary) -> String:
	var string = ""
	for key in _enum:
		string += str(key.capitalize(), ":", _enum[key], ",")
	return string.substr(0, max(0, string.length() - 1))
