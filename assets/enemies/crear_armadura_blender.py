"""Create a first editable, stylized enemy armor for Turno de Noche.

Run from Blender's Scripting workspace. The saved .blend is the editable source;
the exported .glb is the Godot import asset.
"""

import bpy
import math
from mathutils import Matrix, Vector
from pathlib import Path


PROJECT = Path(r"C:\Users\angel\OneDrive\Documents\noche-en-el-museo-3d")
OUT_DIR = PROJECT / "assets" / "enemies"
BLEND_PATH = OUT_DIR / "armadura_orden_acero.blend"
GLB_PATH = OUT_DIR / "armadura_orden_acero.glb"


def material(name, color, metallic=0.0, roughness=0.6, emission=None, strength=0.0):
	mat = bpy.data.materials.new(name)
	mat.diffuse_color = (*color, 1.0)
	mat.use_nodes = True
	# Rebuild the node graph explicitly. Blender may localize default node names,
	# which otherwise leaves its default white shader as the exported material.
	nodes = mat.node_tree.nodes
	nodes.clear()
	bsdf = nodes.new("ShaderNodeBsdfPrincipled")
	output = nodes.new("ShaderNodeOutputMaterial")
	mat.node_tree.links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
	bsdf.inputs["Base Color"].default_value = (*color, 1.0)
	bsdf.inputs["Metallic"].default_value = metallic
	bsdf.inputs["Roughness"].default_value = roughness
	if emission is not None:
		bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
		bsdf.inputs["Emission Strength"].default_value = strength
	return mat


def finish(obj, name, mat, parts, bevel=0.025):
	obj.name = name
	obj.data.materials.append(mat)
	if bevel > 0 and obj.type == "MESH":
		mod = obj.modifiers.new("Bordes gastados", "BEVEL")
		mod.width = bevel
		mod.segments = 2
		obj.select_set(True)
		bpy.context.view_layer.objects.active = obj
		bpy.ops.object.modifier_apply(modifier=mod.name)
		normal = obj.modifiers.new("Normales ponderadas", "WEIGHTED_NORMAL")
		bpy.ops.object.modifier_apply(modifier=normal.name)
	parts.append(obj)
	return obj


def cube(name, loc, dims, mat, parts, bevel=0.025, rot=None):
	bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
	obj = bpy.context.object
	obj.dimensions = dims
	bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
	if rot:
		obj.rotation_euler = [math.radians(v) for v in rot]
	return finish(obj, name, mat, parts, min(bevel, min(dims) * 0.24))


def sphere(name, loc, scale, mat, parts, segments=16, rings=10):
	bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=loc)
	obj = bpy.context.object
	obj.name = name
	obj.scale = scale
	bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
	for face in obj.data.polygons:
		face.use_smooth = True
	return finish(obj, name, mat, parts, 0.0)


def cylinder(name, loc, radius, depth, mat, parts, vertices=12, rot=None, radius_top=None):
	if radius_top is None:
		bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc)
	else:
		bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius, radius2=radius_top, depth=depth, location=loc)
	obj = bpy.context.object
	if rot:
		obj.rotation_euler = [math.radians(v) for v in rot]
	return finish(obj, name, mat, parts, min(0.012, radius * 0.12))


def join_parts(parts, name):
	if not parts:
		return None
	bpy.ops.object.select_all(action="DESELECT")
	for obj in parts:
		obj.select_set(True)
	bpy.context.view_layer.objects.active = parts[0]
	bpy.ops.object.join()
	obj = bpy.context.object
	obj.name = name
	return obj


def main():
	OUT_DIR.mkdir(parents=True, exist_ok=True)
	bpy.ops.object.select_all(action="SELECT")
	bpy.ops.object.delete(use_global=False)
	scene = bpy.context.scene
	scene.render.engine = "BLENDER_EEVEE"
	scene.unit_settings.system = "METRIC"

	# Metal menos especular para que las caras traseras sigan leyendo con poca luz.
	steel = material("Acero azulado", (0.31, 0.39, 0.43), 0.62, 0.43)
	steel_light = material("Acero en los bordes", (0.58, 0.65, 0.66), 0.68, 0.34)
	steel_dark = material("Juntas oscuras", (0.045, 0.060, 0.068), 0.45, 0.72)
	rust = material("Oxido antiguo", (0.25, 0.085, 0.038), 0.28, 0.88)
	bronze = material("Bronce de la Orden", (0.54, 0.31, 0.10), 0.72, 0.32)
	cloth = material("Tabardo granate", (0.25, 0.025, 0.045), 0.0, 0.9)
	black = material("Interior del yelmo", (0.006, 0.009, 0.012), 0.12, 0.85)
	eye = material("Ojos del enemigo", (0.12, 0.004, 0.002), 0.1, 0.25, (1.0, 0.025, 0.008), 0.0)

	body_parts = []
	head_parts = []
	shield_parts = []
	sword_parts = []

	# Pies, grebas y rodilleras. El personaje mide aproximadamente 1.9 m.
	for side in (-1, 1):
		x = side * 0.15
		cube("Sabaton", (x, -0.035, 0.09), (0.22, 0.38, 0.17), steel, body_parts, 0.045, (0, 0, side * -5))
		cube("Borde del pie", (x, -0.045, 0.17), (0.20, 0.22, 0.035), steel_light, body_parts, 0.014)
		cube("Greba", (x, 0.0, 0.37), (0.17, 0.26, 0.48), steel, body_parts, 0.035, (side * 3, 0, 0))
		cube("Refuerzo de greba", (x, -0.142, 0.38), (0.105, 0.035, 0.34), steel_light, body_parts, 0.012)
		cylinder("Rodillera", (x, -0.12, 0.66), 0.105, 0.09, steel_light, body_parts, 10)
		cube("Muslera", (x, 0.0, 0.86), (0.21, 0.29, 0.37), steel, body_parts, 0.04)
		for z in (0.28, 0.48, 0.78, 0.96):
			sphere("Remache", (x, -0.165, z), (0.018, 0.012, 0.018), bronze, body_parts, 10, 6)

	# Faldellín de láminas, cinturón y tabardo dividido en dos colas.
	cube("Cadera", (0.0, 0.0, 1.12), (0.49, 0.36, 0.28), steel_dark, body_parts, 0.05)
	for z in (1.00, 1.07, 1.14):
		for side in (-1, 1):
			cube("Lamina del faldon", (side * 0.13, -0.19, z), (0.25, 0.055, 0.11), steel, body_parts, 0.018, (0, side * 7, side * -4))
	cube("Cinturon", (0.0, -0.204, 1.22), (0.53, 0.075, 0.09), steel_light, body_parts, 0.018)
	cube("Hebilla", (0.0, -0.252, 1.22), (0.13, 0.025, 0.105), bronze, body_parts, 0.018)
	sphere("Sello", (0.0, -0.27, 1.22), (0.027, 0.014, 0.032), steel_dark, body_parts, 12, 8)
	for side in (-1, 1):
		cube("Tabardo", (side * 0.14, -0.228, 0.91), (0.14, 0.035, 0.40), cloth, body_parts, 0.018, (0, 0, side * 5))
		cube("Ribete dorado", (side * 0.14, -0.25, 0.91), (0.018, 0.012, 0.34), bronze, body_parts, 0.005)

	# Torso en capas, con peto, costillas, emblema y hombreras grandes.
	cube("Torso interior", (0.0, 0.0, 1.46), (0.53, 0.35, 0.52), steel_dark, body_parts, 0.09)
	sphere("Peto", (0.0, -0.105, 1.48), (0.31, 0.13, 0.31), steel, body_parts)
	cube("Peto central", (0.0, -0.222, 1.47), (0.25, 0.045, 0.39), steel_light, body_parts, 0.055)
	for z in (1.31, 1.39, 1.47, 1.55, 1.63):
		cube("Nervadura del peto", (0.0, -0.25, z), (0.24, 0.018, 0.018), steel_dark, body_parts, 0.006)
	sphere("Medallon", (0.0, -0.274, 1.48), (0.065, 0.022, 0.078), bronze, body_parts)
	for side in (-1, 1):
		sphere("Hombrera base", (side * 0.37, -0.015, 1.66), (0.24, 0.24, 0.18), steel_dark, body_parts)
		sphere("Hombrera", (side * 0.37, -0.09, 1.69), (0.22, 0.22, 0.15), steel, body_parts)
		cube("Borde hombrera", (side * 0.37, -0.20, 1.65), (0.31, 0.032, 0.055), steel_light, body_parts, 0.014, (0, side * 4, 0))
		# Brazos segmentados y guanteletes.
		cube("Brazo superior", (side * 0.43, 0.0, 1.42), (0.17, 0.22, 0.34), steel, body_parts, 0.04, (0, 0, side * 6))
		if side == 1:
			# Codo desplazado hacia afuera y antebrazo inclinado para despejar el peto.
			cylinder("Codo articulado", (0.51, -0.015, 1.27), 0.105, 0.10, steel_dark, body_parts, 10)
			cube("Antebrazo", (0.55, -0.025, 1.13), (0.16, 0.22, 0.31), steel, body_parts, 0.035, (20, 0, -4))
			cube("Brazalete", (0.56, -0.15, 1.13), (0.17, 0.035, 0.12), steel_light, body_parts, 0.012, (20, 0, 0))
		else:
			cylinder("Codo articulado", (side * 0.45, -0.01, 1.22), 0.105, 0.10, steel_dark, body_parts, 10)
			cube("Antebrazo", (side * 0.46, -0.025, 1.05), (0.16, 0.22, 0.31), steel, body_parts, 0.035, (0, 0, side * -4))
			cube("Brazalete", (side * 0.46, -0.15, 1.10), (0.17, 0.035, 0.12), steel_light, body_parts, 0.012)
		if side == 1:
			# La mano derecha cierra sobre la empuñadura, delante del torso.
			sphere("Palma derecha", (0.60, -0.12, 1.03), (0.095, 0.075, 0.105), steel_dark, body_parts)
			cube("Placa de mano derecha", (0.60, -0.195, 1.04), (0.14, 0.035, 0.13), steel_light, body_parts, 0.018, (0, 0, 18))
			for finger in range(4):
				cube("Dedos cerrados sobre empuñadura", (0.60 + (finger - 1.5) * 0.035, -0.247, 1.03), (0.031, 0.045, 0.075), steel_light, body_parts, 0.01, (0, 0, 18))
			cube("Pulgar sobre empuñadura", (0.515, -0.235, 1.06), (0.07, 0.045, 0.035), steel_light, body_parts, 0.01, (0, -18, -15))
		else:
			cube("Guantelete", (side * 0.46, -0.06, 0.88), (0.18, 0.22, 0.17), steel_dark, body_parts, 0.035)
			for finger in range(4):
				cube("Dedos de placa", (side * 0.46 + (finger - 1.5) * 0.036, -0.17, 0.81), (0.032, 0.045, 0.095), steel_light, body_parts, 0.01)

	# Placas posteriores: silueta y detalles visibles también al rodear la armadura.
	cube("Placa dorsal", (0.0, 0.185, 1.47), (0.39, 0.075, 0.43), steel, body_parts, 0.045)
	cube("Espina dorsal", (0.0, 0.232, 1.47), (0.075, 0.025, 0.37), steel_light, body_parts, 0.014)
	for z in (1.32, 1.40, 1.48, 1.56, 1.64):
		cube("Nervio dorsal", (0.0, 0.231, z), (0.31, 0.018, 0.025), steel_dark, body_parts, 0.008)
	for side in (-1, 1):
		sphere("Placa escapular", (side * 0.22, 0.13, 1.61), (0.17, 0.12, 0.12), steel, body_parts)
		for z in (1.37, 1.57):
			sphere("Remache dorsal", (side * 0.145, 0.237, z), (0.018, 0.012, 0.018), bronze, body_parts, 10, 6)

	# Cuello y yelmo separado sobre un pivote para girar la cabeza en el juego.
	cylinder("Gorjal", (0, 0.0, 1.74), 0.16, 0.11, steel_dark, body_parts, 12)
	root = bpy.data.objects.new("ArmaduraVisual", None)
	scene.collection.objects.link(root)
	head_pivot = bpy.data.objects.new("Cabeza", None)
	scene.collection.objects.link(head_pivot)
	head_pivot.location = (0, 0, 1.82)
	head_pivot.parent = root

	sphere("Casco interior", (0.0, 0.0, 1.88), (0.16, 0.17, 0.22), steel_dark, head_parts)
	sphere("Casco acero", (0.0, -0.015, 1.90), (0.15, 0.16, 0.20), steel, head_parts)
	cube("Visera oscura", (0.0, -0.172, 1.88), (0.235, 0.035, 0.075), black, head_parts, 0.012)
	for side in (-1, 1):
		cube("Ojo rojo", (side * 0.057, -0.195, 1.89), (0.055, 0.012, 0.012), eye, head_parts, 0.004)
		cube("Mejilla de casco", (side * 0.105, -0.12, 1.78), (0.085, 0.11, 0.17), steel, head_parts, 0.02, (0, side * 7, side * 5))
		cube("Remache casco", (side * 0.13, -0.155, 1.83), (0.025, 0.018, 0.025), bronze, head_parts, 0.007)
	cube("Babera", (0.0, -0.16, 1.78), (0.14, 0.045, 0.105), steel_dark, head_parts, 0.018)
	cube("Puente nasal", (0.0, -0.19, 1.825), (0.026, 0.025, 0.11), steel_light, head_parts, 0.008)
	cube("Cresta del yelmo", (0.0, 0.005, 2.105), (0.045, 0.23, 0.045), bronze, head_parts, 0.012)
	cube("Banda frontal", (0.0, -0.12, 2.03), (0.20, 0.035, 0.035), steel_light, head_parts, 0.01)

	# Espada vertical con punta y empuñadura en mano derecha.
	# La empuñadura atraviesa el centro del puño; guarda, hoja y pomo quedan unidos.
	cube("Hoja de espada", (0.46, -0.205, 1.43), (0.09, 0.028, 0.72), steel_light, sword_parts, 0.012, (0, 0, -4))
	cube("Canal de espada", (0.46, -0.224, 1.43), (0.016, 0.008, 0.58), steel_dark, sword_parts, 0.003, (0, 0, -4))
	cylinder("Punta espada", (0.46, -0.205, 1.82), 0.05, 0.15, steel_light, sword_parts, 4, radius_top=0.0)
	cube("Guarda espada", (0.46, -0.205, 1.045), (0.31, 0.045, 0.05), bronze, sword_parts, 0.012, (0, 0, -4))
	cube("Empunadura", (0.46, -0.205, 0.91), (0.055, 0.055, 0.22), rust, sword_parts, 0.012, (0, 0, -4))
	for z in (0.84, 0.89, 0.94, 0.99):
		cylinder("Aro de empuñadura", (0.46, -0.205, z), 0.034, 0.012, bronze, sword_parts, 10)
	sphere("Pomo", (0.46, -0.205, 0.765), (0.055, 0.045, 0.055), bronze, sword_parts, 12, 8)

	# Escudo heráldico izquierdo con ribete, remaches y emblema.
	cube("Escudo", (-0.53, -0.20, 1.02), (0.34, 0.075, 0.48), cloth, shield_parts, 0.07, (0, 0, -7))
	cube("Ribete escudo vertical", (-0.53, -0.246, 1.02), (0.035, 0.02, 0.42), bronze, shield_parts, 0.012, (0, 0, -7))
	cube("Ribete escudo horizontal", (-0.53, -0.246, 1.03), (0.27, 0.02, 0.035), bronze, shield_parts, 0.012, (0, 0, -7))
	sphere("Boss del escudo", (-0.53, -0.26, 1.02), (0.085, 0.025, 0.10), steel_light, shield_parts)
	for side in (-1, 1):
		for z in (0.84, 1.20):
			sphere("Remache escudo", (-0.53 + side * 0.12, -0.25, z), (0.018, 0.012, 0.018), bronze, shield_parts, 10, 6)

	# Raspones y óxido sobre el metal.
	for i in range(9):
		x = -0.20 + (i % 5) * 0.10
		z = 1.30 + (i // 5) * 0.13
		cube("Raspon", (x, -0.252, z), (0.012, 0.006, 0.055 + (i % 3) * 0.018), rust if i % 3 == 0 else steel_dark, body_parts, 0.002, (0, 0, -12 + i * 3))

	body_mesh = join_parts(body_parts, "Cuerpo_Armadura")
	head_mesh = join_parts(head_parts, "Yelmo")
	shield_mesh = join_parts(shield_parts, "Escudo_Heraldico")
	sword_mesh = join_parts(sword_parts, "Espada")
	# Inclinamos toda la espada alrededor de la mano para que se proyecte hacia el costado.
	if sword_mesh:
		pivot = Vector((0.46, -0.205, 0.91))
		grip_target = Vector((0.60, -0.205, 1.03))
		turn = Matrix.Rotation(math.radians(55), 4, "Y")
		world_transform = Matrix.Translation(grip_target) @ turn @ Matrix.Translation(-pivot) @ sword_mesh.matrix_world
		sword_mesh.data.transform(world_transform)
		sword_mesh.matrix_world = Matrix.Identity(4)
		sword_mesh.data.update()
	for obj in (body_mesh, head_mesh, shield_mesh, sword_mesh):
		if obj:
			world = obj.matrix_world.copy()
			obj.parent = head_pivot if obj == head_mesh else root
			obj.matrix_world = world

	# Keep head pivot world position and place the hierarchy at the origin.
	root.location = (0, 0, 0)
	for obj in (root, head_pivot, body_mesh, head_mesh, shield_mesh, sword_mesh):
		if obj:
			obj.select_set(False)
	bpy.ops.object.select_all(action="DESELECT")
	root.select_set(True)
	bpy.context.view_layer.objects.active = root

	# Add a simple studio setup for Blender preview only. It is excluded from GLB export.
	bpy.ops.object.camera_add(location=(3.2, -5.8, 2.65), rotation=(math.radians(73), 0, math.radians(28)))
	camera = bpy.context.object
	camera.name = "PreviewCamera"
	scene.camera = camera
	bpy.ops.object.light_add(type="AREA", location=(1.4, -3.0, 3.4))
	key = bpy.context.object
	key.name = "PreviewKey"
	key.data.energy = 420
	key.data.shape = "DISK"
	key.data.size = 4.0
	bpy.ops.object.light_add(type="AREA", location=(-3.0, -1.0, 2.2))
	fill = bpy.context.object
	fill.name = "PreviewFill"
	fill.data.energy = 230
	fill.data.color = (0.32, 0.52, 1.0)
	fill.data.size = 3.5

	# Helpful viewport framing.
	for area in bpy.context.screen.areas:
		if area.type == "VIEW_3D":
			area.spaces.active.region_3d.view_location = (0, 0, 1.0)
			area.spaces.active.region_3d.view_distance = 4.2
			area.spaces.active.region_3d.view_rotation = (0.79, 0.61, 0.0, 0.0)

	bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))

	# Export only the visual hierarchy: no camera/lights, and keep the head pivot.
	bpy.ops.object.select_all(action="DESELECT")
	for obj in (root, head_pivot, body_mesh, head_mesh, shield_mesh, sword_mesh):
		if obj:
			obj.select_set(True)
	bpy.context.view_layer.objects.active = root
	bpy.ops.export_scene.gltf(
		filepath=str(GLB_PATH),
		export_format="GLB",
		export_apply=True,
		export_cameras=False,
		export_lights=False,
	)


if __name__ == "__main__":
	main()
