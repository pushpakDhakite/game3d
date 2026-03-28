import bpy
import bmesh
from mathutils import Vector

# Clear existing objects
def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    # Clear collections
    for collection in bpy.data.collections:
        bpy.data.collections.remove(collection)

# Set scene to metric units
def setup_scene():
    bpy.context.scene.unit_settings.system = 'METRIC'
    bpy.context.scene.unit_settings.scale_length = 1.0

# Create material with vertex color
def create_vertex_color_material(name, color):
    mat = bpy.data.materials.new(name=name)
    mat.use_vertex_color_paint = True
    mat.diffuse_color = (*color, 1.0)  # RGBA
    return mat

# Assign vertex color to entire mesh
def assign_vertex_color(mesh_obj, color):
    mesh = mesh_obj.data
    if not mesh.vertex_colors:
        mesh.vertex_colors.new()
    color_layer = mesh.vertex_colors.active
    for poly in mesh.polygons:
        for loop_index in poly.loop_indices:
            color_layer.data[loop_index].color = (*color, 1.0)

# Create a simple wall segment (4m x 3m x 0.2m)
def create_wall_segment():
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
    wall = bpy.context.active_object
    wall.name = "Wall_Segment_4m"
    wall.dimensions = (4, 3, 0.2)  # X, Y, Z
    wall.location = (0, 0, 1.5)    # Base at Z=0
    
    # Assign light gray color (concrete)
    mat = create_vertex_color_material("Wall_Mat", (0.8, 0.8, 0.8))
    if wall.data.materials:
        wall.data.materials[0] = mat
    else:
        wall.data.materials.append(mat)
    
    # Apply transform and set origin to base
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUND')
    wall.location.z = 0  # Reset base to Z=0
    
    return wall

# Create a simple floor tile (4m x 4m x 0.1m)
def create_floor_tile():
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
    floor = bpy.context.active_object
    floor.name = "Floor_Tile_4m"
    floor.dimensions = (4, 4, 0.1)
    floor.location = (0, 0, 0.05)  # Base at Z=0
    
    # Assign medium gray color
    mat = create_vertex_color_material("Floor_Mat", (0.6, 0.6, 0.6))
    if floor.data.materials:
        floor.data.materials[0] = mat
    else:
        floor.data.materials.append(mat)
    
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUND')
    floor.location.z = 0
    
    return floor

# Create a simple road segment (4m x 4m x 0.1m)
def create_road_segment():
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
    road = bpy.context.active_object
    road.name = "Road_Segment_4m"
    road.dimensions = (4, 4, 0.1)
    road.location = (0, 0, 0.05)
    
    # Assign dark gray color (asphalt)
    mat = create_vertex_color_material("Road_Mat", (0.2, 0.2, 0.2))
    if road.data.materials:
        road.data.materials[0] = mat
    else:
        road.data.materials.append(mat)
    
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUND')
    road.location.z = 0
    
    return road

# Create a simple tree (trunk + foliage)
def create_tree():
    # Trunk (cylinder)
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.25, depth=2, location=(0, 0, 1))
    trunk = bpy.context.active_object
    trunk.name = "Tree_Trunk"
    
    # Foliage (sphere)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=4, radius=1, location=(0, 0, 2.5))
    foliage = bpy.context.active_object
    foliage.name = "Tree_Foliage"
    
    # Join objects
    bpy.ops.object.select_all(action='DESELECT')
    trunk.select_set(True)
    foliage.select_set(True)
    bpy.context.view_layer.objects.active = trunk
    bpy.ops.object.join()
    tree = bpy.context.active_object
    tree.name = "Tree_LowPoly"
    
    # Assign colors: trunk brown, foliage green
    # We'll use vertex groups or separate materials - for simplicity, assign average color
    # Better approach: split by material index, but keeping it simple with vertex colors per object before join
    # Since we joined, we need to assign colors per vertex - let's do it by selecting vertices by height
    
    # Instead, let's create materials and assign by face (simpler for low poly)
    trunk_mat = create_vertex_color_material("Trunk_Mat", (0.5, 0.25, 0.0))  # Brown
    foliage_mat = create_vertex_color_material("Foliage_Mat", (0.0, 0.5, 0.0))  # Green
    
    # Clear and assign new materials
    tree.data.materials.clear()
    tree.data.materials.append(trunk_mat)
    tree.data.materials.append(foliage_mat)
    
    # Assign material indices: bottom half trunk, top half foliage
    mesh = tree.data
    for poly in mesh.polygons:
        # Calculate average Z of polygon
        avg_z = sum(tree.data.vertices[v].co.z for v in poly.vertices) / len(poly.vertices)
        if avg_z < 1.5:  # Roughly trunk
            poly.material_index = 0
        else:  # Foliage
            poly.material_index = 1
    
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUND')
    tree.location.z = 0
    
    return tree

# Export selected object to glTF
def export_gltf(obj, filepath):
    # Deselect all
    bpy.ops.object.select_all(action='FALSE')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    
    # Export as glTF 2.0
    bpy.ops.export_scene.gltf(
        filepath=filepath,
        export_selected=True,
        export_apply=True,
        export_yup=True,  # Y-up for Godot
        export_materials='EXPORT',
        export_vertex_color='BLEND'  # Important for vertex colors
    )

# Main execution
def main():
    clear_scene()
    setup_scene()
    
    # Create assets
    wall = create_wall_segment()
    floor = create_floor_tile()
    road = create_road_segment()
    tree = create_tree()
    
    # Export to appropriate folders
    base_path = "//../../../exported/models/"  # Relative to blend file location
    
    export_gltf(wall, base_path + "modular/wall_straight_4m.glb")
    export_gltf(floor, base_path + "floor_tile_concrete.glb")
    export_gltf(road, base_path + "terrain/road_straight.glb")
    export_gltf(tree, base_path + "props/tree_oak.glb")
    
    print("Asset generation complete!")

if __name__ == "__main__":
    main()