@tool
class_name FgGridTrack
extends Resource

enum Type {
	FIXED,
	FRACTION,
	AUTO,
}

# Values

@export var type: Type = Type.AUTO:
	set(value):
		type = value
		emit_changed()

@export_range(0.0, 10000.0, 0.1, "or_greater") var value: float = 1.0:
	set(new_value):
		value = maxf(new_value, 0.0)
		emit_changed()
