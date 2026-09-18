@tool
class_name FgFlexContainer
extends Container

enum FlexDirection {
	ROW,
	COLUMN,
}

enum JustifyContent {
	START,
	CENTER,
	END,
	SPACE_BETWEEN,
	SPACE_AROUND,
	SPACE_EVENLY,
}

enum AlignItems {
	START,
	CENTER,
	END,
	STRETCH,
}

class FlexItem:
	var child: Control
	var main_minimum: float
	var cross_minimum: float
	var grow_factor: float
	var main_size: float

	func _init(
		item_child: Control,
		item_main_minimum: float,
		item_cross_minimum: float,
		item_grow_factor: float,
	) -> void:
		child = item_child
		main_minimum = item_main_minimum
		cross_minimum = item_cross_minimum
		grow_factor = item_grow_factor
		main_size = item_main_minimum


# Flexbox values

@export var direction: FlexDirection = FlexDirection.ROW:
	set(value):
		direction = value
		_request_layout()


@export_range(0.0, 10000.0, 0.1, "or_greater") var gap: float = 0.0:
	set(value):
		gap = maxf(value, 0.0)
		_request_layout()


@export var justify_content: JustifyContent = JustifyContent.START:
	set(value):
		justify_content = value
		_request_layout()


@export var align_items: AlignItems = AlignItems.START:
	set(value):
		align_items = value
		_request_layout()


# Lifecycle

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_layout_children()


func _get_minimum_size() -> Vector2:
	var children := _participating_children()
	if children.is_empty():
		return Vector2.ZERO

	var main_size := 0.0
	var cross_size := 0.0

	for child in children:
		var minimum := child.get_combined_minimum_size()
		if _is_row():
			main_size += minimum.x
			cross_size = maxf(cross_size, minimum.y)
		else:
			main_size += minimum.y
			cross_size = maxf(cross_size, minimum.x)
      
	main_size += gap * float(children.size() - 1)
	return Vector2(main_size, cross_size) if _is_row() else Vector2(cross_size, main_size)


# Helpers

func _request_layout() -> void:
	update_minimum_size()
	queue_sort()


func _participating_children() -> Array[Control]:
	var result: Array[Control] = []

	for child in get_children():
		if child is Control and child.visible:
			result.append(child)

	return result


func _is_row() -> bool:
	return direction == FlexDirection.ROW


func _grow_factor(child: Control, is_row: bool) -> float:
	var flags := child.size_flags_horizontal if is_row else child.size_flags_vertical
	if flags & Control.SIZE_EXPAND == 0:
		return 0.0

	return maxf(child.size_flags_stretch_ratio, 0.0)


func _justify_start(extra_space: float, child_count: int) -> float:
	match justify_content:
		JustifyContent.CENTER:
			return extra_space * 0.5
		JustifyContent.END:
			return extra_space
		JustifyContent.SPACE_AROUND:
			return extra_space / float(child_count) * 0.5
		JustifyContent.SPACE_EVENLY:
			return extra_space / float(child_count + 1)

	return 0.0


func _justify_gap(extra_space: float, child_count: int) -> float:
	if child_count < 2:
		return 0.0
	match justify_content:
		JustifyContent.SPACE_BETWEEN:
			return extra_space / float(child_count - 1)
		JustifyContent.SPACE_AROUND:
			return extra_space / float(child_count)
		JustifyContent.SPACE_EVENLY:
			return extra_space / float(child_count + 1)

	return 0.0


func _build_layout_items(children: Array[Control], is_row: bool) -> Array[FlexItem]:
	var items: Array[FlexItem] = []

	for child in children:
		var minimum := child.get_combined_minimum_size()
		var main_minimum := minimum.x if is_row else minimum.y
		var cross_minimum := minimum.y if is_row else minimum.x
		items.append(FlexItem.new(child, main_minimum, cross_minimum, _grow_factor(child, is_row)))

	return items


func _total_main_minimum(items: Array[FlexItem]) -> float:
	var total := gap * float(items.size() - 1)
	for item in items:
		total += item.main_minimum

	return total


func _allocate_main_sizes(items: Array[FlexItem], available_space: float) -> float:
	var total_grow := 0.0
	for item in items:
		total_grow += item.grow_factor

	if total_grow == 0.0:
		return available_space

	for item in items:
		item.main_size += available_space * item.grow_factor / total_grow

	return 0.0


func _child_rect(item: FlexItem, main_position: float, cross_available: float, is_row: bool) -> Rect2:
	var cross_size := item.cross_minimum
	var cross_position := 0.0
	match align_items:
		AlignItems.CENTER:
			cross_position = (cross_available - cross_size) * 0.5
		AlignItems.END:
			cross_position = cross_available - cross_size
		AlignItems.STRETCH:
			cross_size = maxf(cross_available, item.cross_minimum)

	return Rect2(main_position, cross_position, item.main_size, cross_size) if is_row else Rect2(cross_position, main_position, cross_size, item.main_size)


func _layout_children() -> void:
	var children := _participating_children()
	if children.is_empty():
		return

	var is_row := _is_row()
	var items := _build_layout_items(children, is_row)

	var cross_available := size.y if is_row else size.x
	var main_available := size.x if is_row else size.y
	var available_space := maxf(main_available - _total_main_minimum(items), 0.0)
	var remaining_space := _allocate_main_sizes(items, available_space)

	var main_position := _justify_start(remaining_space, children.size())
	var distributed_gap := gap + _justify_gap(remaining_space, children.size())

	for item in items:
		fit_child_in_rect(item.child, _child_rect(item, main_position, cross_available, is_row))
		main_position += item.main_size + distributed_gap
