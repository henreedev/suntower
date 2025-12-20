extends Node
class_name FullVine

const VINE_SCENE : PackedScene = preload("res://scenes/character/Vine.tscn")

# Children we expect in FullVine:
# - Line2D (named "Line2D")
# FullVine will be the parent of all actual vine segments.

@onready var vine_line : Line2D = $Line2D
@onready var head : Head = get_tree().get_first_node_in_group("flowerhead")

# Vine state owned by this node
var _root_seg: Vine = null
var _first_seg: Vine = null
var _segs := 0
var base_segments := 15
var _len_per_seg := 0.0

# Full replacement for spawn_vine in FullVine.gd
@onready var vine_creator : Vine = VINE_SCENE.instantiate()

func spawn_vine(pot, head_pos : Vector2, vine_root_offset : Vector2, b_segments : int) -> void:
	base_segments = b_segments
	var first_vine_pos = pot.position + pot.VINE_ROOT_OFFSET
	var final_vine_pos = head_pos + vine_root_offset
	var diff = final_vine_pos - first_vine_pos

	_len_per_seg = diff.length() / base_segments

	var created := []
	var curr_seg : Vine = null
	var last_seg : Vine = null

	for i in range(base_segments):
		# Use the original factory create(owner) so any internal wiring the Vine factory does still happens.
		if i == 0:
			curr_seg = vine_creator.create(pot)
			_first_seg = curr_seg
		else:
			curr_seg = vine_creator.create(last_seg)
		var progress = diff * float(i) / base_segments
		var seg_pos = first_vine_pos + progress
		curr_seg.position = seg_pos
		add_child(curr_seg)
		curr_seg.make_self_exception()
		curr_seg.add_to_group("vine")

		created.append(curr_seg)
		last_seg = curr_seg

	# --- Fallback explicit wiring (ensures PinJoint paths / child relationships even if factory doesn't fully do it) ---
	# created[0] should be the segment closest to the pot, created[last] is root near head.
	for i in range(created.size()):
		var seg : Vine = created[i]
		if i == 0:
			# child is pot
			seg.set_child(pot)
			# ensure its pin points to the pot path if it has a pin
			if seg.has_node("PinJoint2D"):
				seg.get_node("PinJoint2D").node_b = pot.get_path()
		else:
			var child_seg : Vine = created[i - 1]
			seg.set_child(child_seg)
			if seg.has_node("PinJoint2D"):
				seg.get_node("PinJoint2D").node_b = child_seg.get_path()

	# Set internal root / counts
	_root_seg = created.back() if created.size() > 0 else null
	_first_seg = created.front() if created.size() > 0 else null
	_segs = created.size()


# Expose accessors
func get_root_seg():
	return _root_seg

func get_first_seg():
	return _first_seg

func get_segments_count() -> int:
	return _segs

func get_len_per_seg() -> float:
	return _len_per_seg

# Draw the line connecting vines. Accepts the root-pin global position (from Head).
func draw_line(root_pin_global_pos : Vector2):
	if not vine_line:
		return
	vine_line.clear_points()
	vine_line.add_point(root_pin_global_pos)
	var vine_seg = _root_seg
	while vine_seg:
		if not vine_seg.has_method("get_avg_pos"):
			# fallback: use position
			vine_line.add_point(vine_seg.global_position)
		else:
			vine_line.add_point(vine_seg.get_avg_pos())
		var next_seg = vine_seg.get_child_seg() if vine_seg.has_method("get_child_seg") else null
		if next_seg == null:
			break
		if next_seg is Pot:
			break
		vine_seg = next_seg

# Add a new segment near the root (migrated from Head._add_seg())
func add_seg():
	if not _root_seg:
		return
	var child = _root_seg.get_child_seg()
	var new_child : Vine = vine_creator.create(child)
	# Place child and new child correctly
	var adj = Vector2(0, get_len_per_seg()).rotated(head.global_rotation)
	new_child.position = _root_seg.position + adj
	new_child._set_pos = new_child.position if new_child.has_node("_set_pos") else null
	new_child.rotation = head.global_rotation
	new_child._set_rot = new_child.rotation if new_child.has_node("_set_rot") else null

	child.position = _root_seg.position + adj * 2
	child._set_pos = child.position if child.has_node("_set_pos") else null
	child.rotation = head.global_rotation
	child._set_rot = child.rotation if child.has_node("_set_rot") else null

	add_child(new_child)
	new_child.add_collision_exception_with(child)
	new_child.make_self_exception()
	# Re-pin the new child to the root
	var pin = _root_seg.get_node("PinJoint2D")
	if pin:
		pin.node_b = new_child.get_path()
	_segs += 1

	# If root seg was on sunlight vfx cooldown, propagate to child
	if _root_seg and _root_seg.is_on_sunlight_vfx_cooldown():
		child.trigger_sunlight_vfx_chain()

# Fix the small gap between the root seg and its child (migrated from Head._fix_gap)
func fix_gap():
	# This function may be awaited by caller
	if not _root_seg:
		return
	const MAX_GAP = 3.0
	var child = _root_seg.get_child_seg()
	if not child:
		return
	var gap = _root_seg.position - child.position
	if gap.length() > MAX_GAP:
		var pin = _root_seg.get_node("PinJoint2D")
		if pin:
			pin.node_b = ""
		child.position += gap
		# preserve custom set flags if children expect them
		child._set_pos = child.position
		child._set_rot = head.global_rotation
		child.rotation = head.global_rotation
		_root_seg.set_child(child)

	# Wait 0.1s (same semantics as previous Head._fix_gap)
	await get_tree().create_timer(0.1).timeout
	# No explicit resetting flag here — caller (Head) can flip its fixing_gap flag.

# Simple helper to set line modulate (immediate)
func set_line_modulate(col: Color):
	if vine_line:
		vine_line.modulate = col

# Return a Tween for the caller to chain (similar semantics to create_tween() use in Head)
func tween_line_modulate(target_col: Color, dur: float):
	if not vine_line:
		return null
	var t = create_tween()
	return t.tween_property(vine_line, "modulate", target_col, dur)

func set_electricity(val: float):
	vine_line.material.set_shader_parameter("electricity", val)
