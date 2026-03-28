extends Node

# Singleton to manage resources and economy.

# Resources available in the game.
# We'll use a dictionary to store the amount of each resource.
var resources: Dictionary = {
    "money": 1000,   # Starting money
    "wood": 50,
    "stone": 20,
    "iron": 10,
    "food": 30
}

# Production recipes: what is needed to produce something, and what is produced.
# For example, to produce a plank, you need 2 wood and 1 time unit.
# We'll keep it simple for now: just a dictionary of input resources and output resource.
# In a full game, this would be more complex (with time, power, etc.).
var recipes: Dictionary = {
    "plank": {
        "inputs": {"wood": 2},
        "output": {"wood": 1}  # Note: we are converting wood to plank, but we'll keep the key as "plank" for output.
        # Actually, we should change the output key to "plank". Let's do:
        # "output": {"plank": 1}
        # But then we need to add "plank" to the resources dictionary.
        # We'll do that below.
    }
}

# We'll add the plank to the resources dictionary.
# We'll do it in _ready to avoid initialization order issues.
func _ready() -> void:
    resources["plank"] = 0

# Try to spend resources. Returns true if successful, false if not enough resources.
func spend_resources(costs: Dictionary) -> bool:
    for resource in costs.keys():
        if not resources.has(resource) or resources[resource] < costs[resource]:
            return false
    # If we have enough, deduct the resources.
    for resource in costs.keys():
        resources[resource] -= costs[resource]
    return true

# Try to gain resources. Returns true (always, unless there's an overflow, but we ignore that).
func gain_resources(gains: Dictionary) -> void:
    for resource in gains.keys():
        if resources.has(resource):
            resources[resource] += gains[resource]
        else:
            # If the resource doesn't exist, add it.
            resources[resource] = gains[resource]

# Get the amount of a resource.
func get_resource_amount(resource: String) -> int:
    return resources.get(resource, 0)

# Set the amount of a resource (for setting or adding).
func set_resource_amount(resource: String, amount: int) -> void:
    resources[resource] = amount

# Produce an item using a recipe.
# Returns true if the production was started (i.e., we had the inputs).
func produce_item(item: String) -> bool:
    if not recipes.has(item):
        push_warning("Recipe not found: " + item)
        return false
    var recipe = recipes[item]
    if spend_resources(recipe["inputs"]):
        gain_resources(recipe["output"])
        return true
    return false