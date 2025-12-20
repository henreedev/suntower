extends Node2D
class_name HeadVisual

# Node references (assumes same internal structure as before)
@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var dash_overlay := $Sprite2D/DashOverlay
@onready var storm_light := $StormLight
@onready var dash_spike_sprite := $DashSpikeSprite

@onready var sun_particles: GPUParticles2D = %Sparkles
@onready var lightning_particles: GPUParticles2D = %Lightning
@onready var wind_particles: GPUParticles2D = %WindParticles
@onready var beam_particles: GPUParticles2D = %BeamParticles
@onready var wind_gust_particles: GPUParticles2D = %WindGustParticles
@onready var dash_charge_sparkles: GPUParticles2D = %DashChargeSparkles
@onready var wind_tunnel_extension_particles: GPUParticles2D = %WindTunnelExtensionParticles

# cached process materials
var wind_particles_mat : ParticleProcessMaterial = null
var wind_gust_particles_mat : ParticleProcessMaterial = null
var beam_particles_mat : ParticleProcessMaterial = null
var dash_charge_sparkles_mat : ParticleProcessMaterial = null

func _ready():
	if wind_particles and wind_particles.process_material:
		wind_particles_mat = wind_particles.process_material
	if wind_gust_particles and wind_gust_particles.process_material:
		wind_gust_particles_mat = wind_gust_particles.process_material
	if beam_particles and beam_particles.process_material:
		beam_particles_mat = beam_particles.process_material
	if dash_charge_sparkles and dash_charge_sparkles.process_material:
		dash_charge_sparkles_mat = dash_charge_sparkles.process_material
	

func set_sprite_modulate_invis():
	sprite.modulate = Color(1.0,1.0,1.0,0.0)

# -------------------
# Sprite / overlay helpers
# -------------------
func wiggle_dash_overlay():
	var tween = create_tween().set_loops()
	const DUR = 0.33
	const OFFSET = Vector2(-0.25, -0.25)
	tween.tween_property(dash_overlay, "offset", OFFSET, DUR).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_IN)
	tween.tween_property(dash_overlay, "offset", Vector2.ZERO, DUR).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)

func set_sprite_animation(anim: String, play := true, frame: int = -1):
	if sprite:
		sprite.animation = anim
		if frame >= 0:
			sprite.frame = frame
		if play:
			sprite.play()
		else:
			sprite.stop()

func play_sprite():
	if sprite:
		sprite.play()

func pause_sprite():
	if sprite:
		sprite.pause()

func set_sprite_frame(f: int):
	if sprite:
		sprite.frame = f

func tween_sprite_modulate(color: Color):
	# helper for create_tween().tween_method(...)
	if not sprite: return
	sprite.self_modulate = color

func hide_dash_overlay():
	if dash_overlay:
		dash_overlay.hide()

func set_dash_overlay_visible(v: bool):
	if dash_overlay:
		dash_overlay.visible = v

func set_dash_overlay_animation(anim: String):
	if dash_overlay:
		dash_overlay.animation = anim

func set_dash_overlay_frame(f: int):
	if dash_overlay:
		dash_overlay.frame = f

# -------------------
# Dash spike helpers (sprite only)
# -------------------
func show_dash_spike():
	if not dash_spike_sprite: return
	dash_spike_sprite.show()
	var tween = create_tween()
	tween.tween_property(dash_spike_sprite, "scale", Vector2.ONE, 0.5)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(
		dash_spike_sprite,
		"modulate",
		Color.WHITE * 5,
		0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(
		dash_spike_sprite,
		"modulate",
		Color.WHITE,
		0.5
	).set_trans(Tween.TRANS_BOUNCE)

func hide_dash_spike():
	if not dash_spike_sprite: return
	var tween = create_tween()
	tween.tween_property(
		dash_spike_sprite,
		"scale",
		Vector2.ZERO,
		0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(
		dash_spike_sprite,
		"modulate",
		Color.WHITE,
		0.5
	)
	tween.tween_callback(dash_spike_sprite.hide)

# -------------------
# Sun / lightning visual helpers
# -------------------
func set_sun_particles(on: bool, amount := 0):
	if not sun_particles: return
	sun_particles.emitting = on
	if amount > 0:
		sun_particles.amount = amount

func display_sun_buff():
	# sprite flash
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(4, 4, 4), 0.5)
	tween.tween_property(sprite, "modulate", Color(2.0, 2.0, 2.0), 1.5)

	# particles
	set_sun_particles(true, 125)


func apply_lightning_buff_visuals():
	if lightning_particles:
		lightning_particles.emitting = true
		lightning_particles.amount = 20
	if sun_particles:
		sun_particles.emitting = false
	# tween the storm light; let Head's tweens be minimal — do here
	if storm_light:
		var t = create_tween().set_parallel()
		t.tween_property(storm_light, "texture_scale", 0.85, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(storm_light, "color", Color(0.5,1.0,1.0,1.0), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(storm_light, "energy", 2.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func remove_lightning_buff_visuals():
	if storm_light:
		var t = create_tween().set_parallel()
		t.tween_property(storm_light, "texture_scale", 0.15, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(storm_light, "color", Color(1,1,1,1), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(storm_light, "energy", 0.15, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if lightning_particles:
		# delay turning off to match your original await 0.5
		await get_tree().create_timer(0.5).timeout
		lightning_particles.emitting = false

func lerp_storm_light(goal_scale: float, goal_color: Color, goal_energy: float, delta: float):
	if not storm_light: return
	const STR = 1.0
	storm_light.texture_scale = lerp(storm_light.texture_scale, goal_scale, delta * STR)
	storm_light.color = lerp(storm_light.color, goal_color, delta * STR)
	storm_light.energy = lerp(storm_light.energy, goal_energy, delta * STR)

# sprite shader parameter (electricity)
func set_electricity(val: float):
	if sprite and sprite.material:
		sprite.material.set_shader_parameter("electricity", max(val, 0.0))

# -------------------
# Wind particle helpers
# -------------------
func enable_wind_particles():
	const DUR = 1.0
	if not wind_particles: return
	wind_particles.emitting = true
	wind_particles.visible = true
	if wind_gust_particles:
		wind_gust_particles.emitting = true
		wind_gust_particles.visible = true
	if beam_particles:
		beam_particles.visible = true
	# tween alpha
	if Engine.is_editor_hint() == false: # in editor the particles may behave differently
		var t = create_tween().set_parallel()
		t.tween_property(wind_particles, "modulate:a", 1.0, DUR).set_trans(Tween.TRANS_CUBIC).from(0.0)
		if wind_gust_particles:
			t.tween_property(wind_gust_particles, "modulate:a", 1.0, DUR).set_trans(Tween.TRANS_CUBIC).from(0.0)
		if beam_particles:
			t.tween_property(beam_particles, "modulate:a", 1.0, DUR).set_trans(Tween.TRANS_CUBIC).from(0.0)

func disable_wind_particles():
	const DUR = 1.0
	if not wind_particles: return
	# fade out
	var t = create_tween().set_parallel()
	t.tween_property(wind_particles, "modulate:a", 0.0, DUR).set_trans(Tween.TRANS_CUBIC)
	if wind_gust_particles:
		t.tween_property(wind_gust_particles, "modulate:a", 0.0, DUR).set_trans(Tween.TRANS_CUBIC)
	if beam_particles:
		t.tween_property(beam_particles, "modulate:a", 0.0, DUR).set_trans(Tween.TRANS_CUBIC)
	# after fade
	t.tween_property(wind_particles, "emitting", false, 0.0).set_delay(DUR)
	if wind_gust_particles:
		t.tween_property(wind_gust_particles, "emitting", false, 0.0).set_delay(DUR)
	t.tween_property(wind_particles, "visible", false, 0.0).set_delay(DUR)
	if wind_gust_particles:
		t.tween_property(wind_gust_particles, "visible", false, 0.0).set_delay(DUR)
	if beam_particles:
		t.tween_property(beam_particles, "visible", false, 0.0).set_delay(DUR)

func show_active_wind_particles(amount: int, dir: Vector2):
	spawn_wind_particle(amount, dir)

func spawn_wind_particle(amount: int, dir: Vector2):
	var SPEED = 100.0
	for i in range(amount):
		var origin = global_position + Vector2(randf_range(-5, 5), randf_range(-20, 20)).rotated(dir.angle() + PI / 2)
		var rand_vel := (dir * SPEED * randf_range(0.8, 1.2)).rotated(0)
		if beam_particles:
			beam_particles.emit_particle(Transform2D(0, Vector2.ONE, 0, origin),
				rand_vel, Color.WHITE, Color.WHITE, 5)

func update_wind_particles(new_dir : Vector2i, new_strength : float, color_mod := Color.WHITE):
	const MOD = 2.0
	const GRAVITY_MOD = MOD / 2.0
	var dir = Vector3(new_dir.x, 0, 0)
	if wind_particles:
		wind_particles.modulate = color_mod
	if wind_particles_mat:
		wind_particles_mat.gravity = dir * new_strength * MOD
		wind_particles_mat.direction = dir
		wind_particles_mat.initial_velocity_min = new_strength
		wind_particles_mat.initial_velocity_max = new_strength
		wind_particles_mat.linear_accel_min = new_strength * MOD
		wind_particles_mat.linear_accel_max = new_strength * MOD
	if beam_particles:
		beam_particles.modulate = color_mod
	if beam_particles_mat:
		beam_particles_mat.gravity = dir * new_strength * MOD
		beam_particles_mat.direction = dir
		beam_particles_mat.initial_velocity_min = new_strength
		beam_particles_mat.initial_velocity_max = new_strength
		beam_particles_mat.linear_accel_min = new_strength * MOD
		beam_particles_mat.linear_accel_max = new_strength * MOD
	if wind_gust_particles_mat:
		wind_gust_particles_mat.gravity = dir * new_strength * MOD * 0.8
		wind_gust_particles_mat.direction = dir
		wind_gust_particles_mat.initial_velocity_min = new_strength
		wind_gust_particles_mat.initial_velocity_max = new_strength
		wind_gust_particles_mat.linear_accel_min = new_strength * MOD * 0.5
		wind_gust_particles_mat.linear_accel_max = new_strength * MOD

# -------------------
# Wind tunnel extension particles
# -------------------
func set_wind_tunnel_emitting(on: bool):
	if wind_tunnel_extension_particles:
		wind_tunnel_extension_particles.emitting = on

# -------------------
# Dash charge sparkles
# -------------------
func emit_dash_charge_particle(vel: Vector2, flags := GPUParticles2D.EmitFlags.EMIT_FLAG_VELOCITY):
	if dash_charge_sparkles:
		dash_charge_sparkles.emit_particle(Transform2D.IDENTITY, vel, Color.WHITE, Color.WHITE, flags)

func emit_dash_charge_particles_for_frame(frame: int):
	# helper matching your original behavior: call from Head when frame changes
	const FRAMES = 8
	var particle_angle = -PI / 2 + frame * (PI / 4) + global_rotation
	var particle_direction = Vector2.from_angle(particle_angle)
	const BASE_AMOUNT = 12
	const BASE_SPEED = 50.0
	var amount = BASE_AMOUNT + randi_range(0, 8)
	for i in range(amount):
		var rand_vel = particle_direction.rotated(randf_range(-PI / 8, PI / 8)) * BASE_SPEED * randf_range(0.8, 1.2)
		emit_dash_charge_particle(rand_vel, GPUParticles2D.EmitFlags.EMIT_FLAG_VELOCITY)

# -------------------
# Spawn-time sprite tweens
# -------------------
func play_spawn_sprite_tweens():
	# Mirror the tweens used in Head.play_spawn_animation
	if not sprite: return
	create_tween().tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.4).from(Vector2(0.5, 0.5)).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(sprite, "offset", Vector2(0.0, 0.0), 0.4).from(Vector2(0, 5)).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(sprite, "modulate", Color(1.0,1.0,1.0,1.0), 0.75).from(Color(10, 10, 10, 0.0))

# -------------------
# Utilities
# -------------------
func set_vine_line_modulate(col: Color):
	# optional: if vine Line2D is now inside HeadVisual, implement; otherwise ignore
	pass


# Ensures that spiked and idle forms remain that way after playing once.
func _on_sprite_2d_animation_looped():
	if sprite.animation == "spiked":
		sprite.frame = 3
		sprite.pause()
	elif sprite.animation == "retract":
		sprite.animation = "normal"
