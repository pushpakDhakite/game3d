extends Node

# Singleton to hold the current game state.
# This will be saved and loaded.

# Player data
var player_name: String = ""
var player_money: int = 0

# Game progress
var day: int = 1
var time_of_day: float = 0.0 # 0.0 to 1.0 representing the time in a day

# Resources (example)
var resources: Dictionary = {
    "wood": 0,
    "stone": 0,
    "iron": 0,
    "food": 0
}

# Buildings placed in the world
# Each building is a dictionary with at least: type, position (Vector3), and any other relevant data.
var buildings: Array = []

# Active productions (if we have a factory system)
var active_productions: Array = []

# Research unlocked
var research_unlocked: Array = []

# Reset the game state to default values (for a new game)
func reset() -> void:
    player_name = ""
    player_money = 1000 # Starting money
    day = 1
    time_of_day = 0.0
    resources = {
        "wood": 50,
        "stone": 20,
        "iron": 10,
        "food": 30
    }
    buildings = []
    active_productions = []
    research_unlocked = []

# Convert the game state to a dictionary for saving
func to_dict() -> Dictionary:
    return {
        "player_name": player_name,
        "player_money": player_money,
        "day": day,
        "time_of_day": time_of_day,
        "resources": resources.deep_duplicate(),
        "buildings": buildings.duplicate(),
        "active_productions": active_productions.duplicate(),
        "research_unlocked": research_unlocked.duplicate()
    }

# Load the game state from a dictionary
func from_dict(state: Dictionary) -> void:
    player_name = state.get("player_name", "")
    player_money = state.get("player_money", 0)
    day = state.get("day", 1)
    time_of_day = state.get("time_of_day", 0.0)
    resources = state.get("resources", {}).duplicate()
    buildings = state.get("buildings", []).duplicate()
    active_productions = state.get("active_productions", []).duplicate()
    research_unlocked = state.get("research_unlocked", []).duplicate()