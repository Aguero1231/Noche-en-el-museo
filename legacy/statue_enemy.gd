extends CharacterBody3D

## Prototipo de la mecánica central: la criatura permanece quieta mientras
## está dentro de la línea de visión de la cámara del jugador.
@export var move_speed := 2.8
@export var player_path: NodePath
var frozen := true

func _physics_process(_delta: float) -> void:
	if player_path.is_empty():
		return
	var player := get_node_or_null(player_path) as Node3D
	if player == null:
		return
	var camera := player.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	if camera == null:
		return
	frozen = _is_visible_to_camera(camera)
	if frozen:
		velocity = Vector3.ZERO
	else:
		var dir := (player.global_position - global_position)
		dir.y = 0
		if dir.length() > 0.1:
			velocity = dir.normalized() * move_speed
			look_at(global_position + Vector3(velocity.x, 0, velocity.z), Vector3.UP)
			move_and_slide()

func _is_visible_to_camera(camera: Camera3D) -> bool:
	var point := global_position + Vector3.UP * 1.0
	if camera.is_position_behind(point):
		return false
	var screen := camera.unproject_position(point)
	var viewport_size := camera.get_viewport().get_visible_rect().size
	if screen.x < 0 or screen.y < 0 or screen.x > viewport_size.x or screen.y > viewport_size.y:
		return false
	var origin := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(origin, point)
	query.collide_with_areas = true
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == self
