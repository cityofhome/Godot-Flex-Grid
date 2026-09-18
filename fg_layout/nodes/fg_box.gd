@tool
class_name FgBox
extends Container


# Spacing

@export var margin: FgSpacing = FgSpacing.new():
	set(value):
		_disconnect_spacing(margin)
		margin = value if value != null else FgSpacing.new()
		_connect_spacing(margin)
		_request_layout()


@export var padding: FgSpacing = FgSpacing.new():
	set(value):
		_disconnect_spacing(padding)
		padding = value if value != null else FgSpacing.new()
		_connect_spacing(padding)
		_request_layout()


# Background

@export var background_color: Color = Color.TRANSPARENT:
	set(value):
		background_color = value
		_request_layout()


# Border

@export_group("Border")

@export var border_color: Color = Color.BLACK:
	set(value):
		border_color = value
		_request_layout()


@export_range(0.0, 1000.0, 0.1, "or_greater") var border_width: float = 0.0:
	set(value):
		border_width = maxf(value, 0.0)
		_request_layout()


@export_range(0.0, 10000.0, 0.1, "or_greater") var border_radius: float = 0.0:
	set(value):
		border_radius = maxf(value, 0.0)
		_request_layout()


# Lifecycle

func _ready() -> void:
	_connect_spacing(margin)
	_connect_spacing(padding)
	_request_layout()


func _exit_tree() -> void:
	_disconnect_spacing(margin)
	_disconnect_spacing(padding)


func _draw() -> void:
	_update_style_box()
	var border_rect := _border_rect()
	if border_rect.size.x > 0.0 and border_rect.size.y > 0.0:
		draw_style_box(_style_box, border_rect)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_layout_child()
	elif what == NOTIFICATION_CHILD_ORDER_CHANGED:
		update_configuration_warnings()
		_request_layout()


func _get_minimum_size() -> Vector2:
	var minimum := Vector2(margin.horizontal(), margin.vertical())
	minimum += Vector2(
      border_width * 2.0 + padding.horizontal(), 
      border_width * 2.0 + padding.vertical()
    )

	var child := _content_child()
	if child != null:
		minimum += child.get_combined_minimum_size()

	return minimum


func _get_configuration_warnings() -> PackedStringArray:
	if _participating_children().size() > 1:
		return PackedStringArray(["FgBox expects a single Control child. Only the first Control child will participate in layout."])
    
	return PackedStringArray()


# Style box

var _style_box := StyleBoxFlat.new()

func _update_style_box() -> void:
	_style_box.bg_color = background_color
	_style_box.border_color = border_color
	_style_box.border_width_left = roundi(border_width)
	_style_box.border_width_top = roundi(border_width)
	_style_box.border_width_right = roundi(border_width)
	_style_box.border_width_bottom = roundi(border_width)
	_style_box.corner_radius_top_left = roundi(border_radius)
	_style_box.corner_radius_top_right = roundi(border_radius)
	_style_box.corner_radius_bottom_right = roundi(border_radius)
	_style_box.corner_radius_bottom_left = roundi(border_radius)
	_style_box.anti_aliasing = true


# Helpers

func _connect_spacing(spacing: FgSpacing) -> void:
	if spacing != null and not spacing.changed.is_connected(_request_layout):
		spacing.changed.connect(_request_layout)


func _disconnect_spacing(spacing: FgSpacing) -> void:
	if spacing != null and spacing.changed.is_connected(_request_layout):
		spacing.changed.disconnect(_request_layout)


func _request_layout() -> void:
	update_minimum_size()
	queue_sort()
	queue_redraw()


func _border_rect() -> Rect2:
	var position := Vector2(margin.left, margin.top)
	var border_size := size - Vector2(margin.horizontal(), margin.vertical())
	return Rect2(position, border_size.max(Vector2.ZERO))


func _layout_child() -> void:
	var child := _content_child()
	if child == null:
		return

	var content_rect := _border_rect().grow_individual(
      -border_width - padding.left, 
      -border_width - padding.top, 
      -border_width - padding.right, 
      -border_width - padding.bottom
    )
	content_rect.size.x = maxf(content_rect.size.x, 0.0)
	content_rect.size.y = maxf(content_rect.size.y, 0.0)
	fit_child_in_rect(child, content_rect)


func _content_child() -> Control:
	var children := _participating_children()
	return children.front() if not children.is_empty() else null


func _participating_children() -> Array[Control]:
	var result: Array[Control] = []

	for child in get_children():
		if child is Control and child.visible:
			result.append(child)

	return result
