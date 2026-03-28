extends Node3D

# The size of the grid in meters (should match the asset size)
const GRID_SIZE = 4.0

# We'll try to load the wall scene from the exported assets.
# If it fails, we'll fall back to a BoxMesh.
var wall_scene : PackedScene = null

# The preview material (a semi-transparent version of the wall material)
var preview_material : Material

# Reference to the HUD labels
@onready var player_label : Label = $"UI/MarginContainer/VBoxContainer/PlayerLabel"
@onready var money_label : Label = $"UI/MarginContainer/VBoxContainer/MoneyLabel"

# Reference to the game state and resource manager
var game_state : Node
var resource_manager : Node

func _ready() -> void:
    game_state = get_node("/root/game_state")
    resource_manager = get_node("/root/resource_manager")
    
    # Update the HUD with the player name and money
    _update_hud()
    
    # Try to load the wall scene
    wall_scene = load("res://assets/exported/models/modular/wall.glb")
    if wall_scene == null:
        push_warning("Could not load wall.glb, using BoxMesh placeholder.")
    
    # Create a preview material (we'll use a simple shader for now)
    var preview_shader = Shader.new()
    preview_shader.code = """
        shader_type spatial;
        render_mode unshaded, cull_back;
        void fragment() {
            ALBEDO = vec3(0.8, 0.8, 0.8);
            ALPHA = 0.5;
        }
    """
    preview_material = ShaderMaterial.new()
    preview_material.shader = preview_shader
    preview_material.transparent = true
    # We'll set the depth draw mode to make it visible when transparent.
    # For alpha, we want to draw after the opaque objects, but we'll leave it as default for now.
    # We'll set the cull mode to back and unshaded.

    # We'll update the preview in the _process function.
    set_process(true)

func _update_hud() -> void:
    player_label.text = "Player: %s" % game_state.player_name
    money_label.text = "Money: $%d" % resource_manager.call("get_resource_amount", "money")

func _make_wall_instance() -> Node3D:
    if wall_scene != null:
        return wall_scene.instantiate()
    else:
        # Fallback to a box mesh
        var wall_instance = MeshInstance3D.new()
        wall_instance.mesh = BoxMesh.new()
        wall_instance.mesh.size = Vector3(4, 0.2, 3)  # Match the wall dimensions: 4m wide, 0.2m thick, 3m high
        # Create a simple material that matches the vertex color we used in Blender (light gray)
        var wall_mat = ShaderMaterial.new()
        var wall_shader = Shader.new()
        wall_shader.code = """
            shader_type spatial;
            void fragment() {
                ALBEDO = vec3(0.8, 0.8, 0.8);
            }
        """
        wall_mat.shader = wall_shader
        wall_instance.material = wall_mat
        return wall_instance

func _unhandled_input(event) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MouseButton.LEFT:
        # Place a wall at the current mouse position on the grid.
        var mouse_pos = get_viewport().get_mouse_position()
        var cam = get_viewport().get_camera_3d()
        if cam == null:
            return
        
        # Get the ray from the camera through the mouse position.
        var from = cam.project_ray_origin(mouse_pos)
        var to = from + cam.project_ray_normal(mouse_pos) * 1000.0
        
        # We'll intersect with the ground plane (y=0).
        var plane = Plane(Vector3.UP, 0.0)  # Plane at y=0, normal up.
        var intersect = plane.intersects_ray(from, to - from)
        if intersect:
            var point = intersect.position
            # Snap to grid.
            var grid_x = int(point.x / GRID_SIZE) * GRID_SIZE
            var grid_z = int(point.z / GRID_SIZE) * GRID_SIZE
            var grid_point = Vector3(grid_x, 0, grid_z)
            
            # Check if we can afford the wall (let's say a wall costs 100 money)
            var cost = 100
            if resource_manager.call("get_resource_amount", "money") >= cost:
                resource_manager.call("spend_resources", {"money": cost})
                # Instance the wall and place it at the grid point.
                var wall_instance = _make_wall_instance()
                wall_instance.global_transform.origin = grid_point
                add_child(wall_instance)
                
                # Update the HUD
                _update_hud()
            else:
                print("Not enough money to place a wall.")
    
    # Optional: right click to remove a wall? We'll leave that for later.

func _process(delta) -> void:
    # Update the preview position based on the mouse.
    var mouse_pos = get_viewport().get_mouse_position()
    var cam = get_viewport().get_camera_3d()
    if cam == null:
        return
    
    var from = cam.project_ray_origin(mouse_pos)
    var to = from + cam.project_ray_normal(mouse_pos) * 1000.0
    
    var plane = Plane(Vector3.UP, 0.0)
    var intersect = plane.intersects_ray(from, to - from)
    if intersect:
        var point = intersect.position
        var grid_x = int(point.x / GRID_SIZE) * GRID_SIZE
        var grid_z = int(point.z / GRID_SIZE) * GRID_SIZE
        var grid_point = Vector3(grid_x, 0, grid_z)
        
        # If we don't have a preview instance, create one.
        if not has_node("Preview"):
            var preview_instance = _make_wall_instance()
            preview_instance.name = "Preview"
            preview_instance.material_override = preview_material
            add_child(preview_instance)
        
        $Preview.global_transform.origin = grid_point
    else:
        # If we have a preview instance and the mouse is not over the ground, hide it.
        if has_node("Preview"):
            $Preview.queue_free()
    
    # Update the HUD every frame (we can change to a timer later for performance)
    _update_hud()