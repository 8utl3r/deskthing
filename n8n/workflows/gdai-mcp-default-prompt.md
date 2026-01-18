# GDAI MCP Default Prompt

This is the prompt that the GDAI MCP server provides. It contains best practices and guidelines for working with Godot Editor using MCP.

## Prompt Content

# Important information and best practices for working with Godot Editor using MCP

Use the `get_project_info` tool to get a better understanding of the Godot project.

1. **Godot file system guide**
   - Scenes and resources saved to disk are referred to using the `res://` protocol which is the Godot project's root folder.
   - When mentioning any file path or folder path in Godot MCP tools use the `res://` prefix
   - There is also the `user://` protocol which will save files in a special folder which is not in the project folder which is useful for saving saved games, highscores, etc. This is useful because data in the `user://` folder will not be overwritten when the game is updated.
   - Use the `search_files` tool to fuzzy search for different types of files in the project. You MUST try to always pass a `filter` param such to filter by scenes, scripts, images, audio, fonts, models, shaders, resources, etc.
   - You can also use the `get_filesystem_tree` tool to get a recursive tree view of all the files/folders in the project. Here also try to always pass a `filter` param.

2. **Godot node path guide**
   - Nodes in a scene are to be identified using their unique NodePath like `Player/Camera3D` which is relative to the scene root that is in this case `Player`.

3. **Scene Management**
   - Don't edit scene (.tscn) files directly unless absolutely necessary rather use the MCP tools that are designed to do so safely and efficiently.
      - create_scene: Create a new scene with a root node
      - open_scene: Open an existing scene
      - delete_scene: Delete an existing scene
      - add_scene: Instance a scene as a child of a node in the current scene
   - Use the `get_scene_tree` tool to get a description of the scene tree of the opened scene and its nodes.
   - If you still need more information about the scene tree, use the `get_scene_file_contents` tool to get the raw file contents of the scene.
   - ALWAYS open the scene using the `open_scene` before adding any nodes/resources in it.
   - ALWAYS use lower case for folder, scene, script names like `main_menu.tscn`
   - ALWAYS prefer to create new scenes for main or reusable content like player, enemy, walls, levels, etc.

4. **Node Management**
   - Don't edit scene (.tscn) files directly when you want to edit nodes/resources in the scene unless absolutely necessary rather use the MCP tools that are designed to do so safely and efficiently.
      - add_node: Add a new node as a child of a node in the current scene
      - delete_node: Delete an existing node
   - ALWAYS use PascalCase for node names like `MainCamera`
   - When adding nodes, try to add more hierarchy by adding children nodes using the `add_node` tool.
   For example:
     Player (is the scene root of player.tscn)
       - Mesh
       - Collision
       - Camera3D
     To accomplish this you can use the following tools:
      - Use `create_scene` tool to create new scene at path `res://player.tscn` with a CharacterBody3D node as the root named `Player`.
      - Use `add_node` tool to add a `MeshInstance3D` node as a child of the Player node.
      - Use `add_node` tool to add a `CollisionShape3D` node as a child of the Player node.
      - Use `add_node` tool to add a `Camera3D` node as a child of the Player node.
      - Use the `add_resource` tool to add a CapsuleMesh resource to the `mesh` property of the Mesh node in the scene.
      - Use the `add_resource` tool to add a CapsuleShape3D resource to the `shape` property of the Collision node in the scene.

5. **Property Management**
   - Use the `update_property` tool to update a property on a node. The property path can be like `mesh` or even a single value in property like `position:x`. Use the `update_property` for non-resource type properties like `position`, `rotation`, `scale`. For resource based properties like `mesh`, `collision`, `shape` etc use the `add_resource` tool.

   Eg. To set a color

6. **Script Management**
- Use the `create_script`, `edit_file` and `view_script` to create/edit/view GDScript files.
- Use the `attach_script` tool to attach a script to a node in the current scene.
- When writing scripts do not add unnecessary comments unless specifically mentioned.
- If there is no existing scripting convention, then follow the below convention:
   - Use trailing comma for multi-line Array/Dictionary
   - Use 2 new lines between methods
   - Use region groups to group related code like public vars, public methods, private vars and private methods. Eg. `#region Public Methods` followed by `#endregion` for each group.
- Always give a `class_name` for scripts unless the script is an autoload or the script is not going to be referenced by other scripts.
- Always use PascalCase when loading a class into a constant or a variable:
   - Eg. const Weapon = preload("res://weapon.gd")

- Organize new scripts in this order, dont change the existing order in scripts:
   01. @tool, @icon, @static_unload
   02. class_name
   03. extends
   04. ## doc comment

   05. signals
   06. enums
   07. constants
   08. static variables
   09. @export variables
   10. remaining regular variables
   11. @onready variables

   12. _static_init()
   13. remaining static methods
   14. overridden built-in virtual methods:
      1. _init()
      2. _enter_tree()
      3. _ready()
      4. _process()
      5. _physics_process()
      6. remaining virtual methods
   15. overridden custom methods
   16. remaining methods
   17. subclasses

- Similarly for new scripts keep public variables before private ones and keep public methods before private ones.
- Provide type hints when the type is ambiguous, and omit the type hint when it's redundant for variables, signals, methods, etc. Use the type inference operator (:=).
   - Eg. var direction := Vector3(1, 0, 0)

   - Good
   ```
   # The type can be int or float, and thus should be stated explicitly.
   var health: int = 0

   # The type is clearly inferred as Vector3.
   var direction := Vector3(1, 2, 3)
   ```

   - Bad
   ```
   # Typed as int, but it could be that float was intended.
   var health := 0

   # The type hint has redundant information.
   var direction: Vector3 = Vector3(1, 2, 3)

   # What type is this? It's not immediately clear to the reader, so it's bad.
   var value := complex_function()
   ```
- When getting references to nodes using the `get_node` method, use the `as` keyword to provide type inference.
   - Eg. `@onready var health_bar := get_node("UI/LifeBar") as ProgressBar`

7. **Godot Naming Conventions**
[Type: case - example]
- File names: snake_case – yaml_parser.gd
- Class names: PascalCase – class_name YAMLParser
- Node names: PascalCase – Camera3D, Player
- Functions: snake_case – func load_level():
- Variables: snake_case – var particle_effect
- Signals: snake_case – signal door_opened
- Constants: CONSTANT_CASE – const MAX_SPEED = 200
- Enum names: PascalCase – enum Element
- Enum members: CONSTANT_CASE – {EARTH, WATER, AIR, FIRE}

8. **Debugging workflows**
- Check for script errors using the `get_godot_errors` tool

**General Godot practices**
- Use the `get_filesystem_tree`, `open_scene` along with `get_scene_tree` tool to get additional context about the scene before answering any questions or starting new tasks.
- If there is an existing folder structure convention that the project is using continue using that, otherwise keep scenes, scripts and related data in organized folders grouped by functionality/entity like:
   res://
      - player/
         - player.tscn
         - player.gd
         - walk_sound.wav
      - enemies/
         - crawler/
            - crawler.tscn
            - crawler.gd
            - die_sound.wav
      - main/
         - main_menu.tscn
         - main_menu.gd
      - levels/
         - level_1.tscn
      - autoloads/
         - sound_manager.gd
         - signal_bus.gd
      - ui/
         - custom_button.tscn
- You can also use custom colors for a folder by editing the `project.godot` file and specifying the folder path and one of the colors from (red, orange, yellow, green, teal, blue, purple, pink, gray). Eg.
   ```
   [file_customization]

   folder_colors={
   "res://player/": "red",
   "res://world/": "purple"
   }
   ```
- As a last resort use the `execute_editor_script` tool to run arbitrary code in the editor.
  Eg. `execute_editor_script` with code   `func run():\n\treturn Engine.get_version_info()` will return the Godot Engine version Dictionary

**Context7**

- If the context7 tools are available, you can use the `godotengine/godot-docs` docs id to search for documentation related to godot and GDScript.

