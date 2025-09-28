extends Node2D

## This is actually attached to the node that rotates the arrows about the head. 
## Its parent (IndicatorArrow) uses the FollowHead.gd script to stay at head level.
class_name IndicatorArrow

@onready var head : Head = get_tree().get_first_node_in_group("flowerhead")
@onready var base_arrow: Sprite2D = $BaseArrow
@onready var dash_arrow: Sprite2D = $DashArrow

## Decide which arrows to show. 
func show_arrows_on_state() -> void:
	# Possible states:
	# 1. Inactive and charging dash. Show only dash arrow and lighten it based on charge amount. 
	# 2. Inactive and not charging dash. Show both
	# 3. Extending and second wind available. Show both
	# 4. Extending by charged dash. Show only dash with unlightening by duration. 
	# 5. Retracting and second wind available. Show dash arrow with max lightness.
	# 6. Retracting and no second wind available. Hide arrows.
	
	# Reset to base state
	base_arrow.show()
	dash_arrow.show()
	_set_dash_arrow_extra_brightness(0.0)
	
	match head._state:
		Head.State.INACTIVE:
			if not head.can_extend:
				base_arrow.modulate.a = 0.3
				dash_arrow.modulate.a = 0.3
			else:
				base_arrow.modulate.a = 1.0
				dash_arrow.modulate.a = 1.0
			if head.dash_charge_amount > 0:
				base_arrow.hide()
				_set_dash_arrow_extra_brightness(head.dash_charge_amount)
		Head.State.EXTENDING:
			if head.is_dashing:
				base_arrow.hide()
		Head.State.RETRACTING:
			base_arrow.hide()
			if head.can_dash:
				_set_dash_arrow_extra_brightness(1.0)
			else:
				dash_arrow.hide()

func _process(delta: float) -> void:
	show_arrows_on_state()

## 0.0 to 1.0 amount of extra brightness on the arrow
func _set_dash_arrow_extra_brightness(amount : float):
	const YELLOW_MOD = Color(2.0, 2.0, 1.0, 1.0)
	dash_arrow.modulate = lerp(Color.WHITE, YELLOW_MOD, amount)
