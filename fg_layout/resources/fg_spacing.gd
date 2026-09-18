@tool
class_name FgSpacing
extends Resource

# Values

@export var top: float = 0.0:
	set(value):
		top = maxf(value, 0.0)
		emit_changed()

@export var right: float = 0.0:
	set(value):
		right = maxf(value, 0.0)
		emit_changed()

@export var bottom: float = 0.0:
	set(value):
		bottom = maxf(value, 0.0)
		emit_changed()

@export var left: float = 0.0:
	set(value):
		left = maxf(value, 0.0)
		emit_changed()

# Helpers

func horizontal() -> float:
	return left + right

func vertical() -> float:
	return top + bottom
