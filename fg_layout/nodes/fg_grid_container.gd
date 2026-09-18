@tool
class_name FgGridContainer
extends Container

class GridItem:
	var child: Control
	var minimum: Vector2
	var row: int
	var column: int

	func _init(item_child: Control, item_minimum: Vector2, item_row: int, item_column: int) -> void:
		child = item_child
		minimum = item_minimum
		row = item_row
		column = item_column

class GridLayout:
	var items: Array[GridItem]
	var column_count: int
	var row_count: int
	var column_widths: Array[float] = []
	var row_heights: Array[float] = []

	func _init(layout_items: Array[GridItem], layout_column_count: int, layout_row_count: int) -> void:
		items = layout_items
		column_count = layout_column_count
		row_count = layout_row_count


# Values

@export_range(1, 1000, 1) var columns: int = 1:
	set(value):
		columns = maxi(value, 1)
		_request_layout()


@export_range(0.0, 10000.0, 0.1, "or_greater") var column_gap: float = 0.0:
	set(value):
		column_gap = maxf(value, 0.0)
		_request_layout()


@export_range(0.0, 10000.0, 0.1, "or_greater") var row_gap: float = 0.0:
	set(value):
		row_gap = maxf(value, 0.0)
		_request_layout()


@export var column_tracks: Array[FgGridTrack] = []:
	set(value):
		_disconnect_tracks(column_tracks)
		column_tracks = value
		_connect_tracks(column_tracks)
		_request_layout()


# Lifecycle

func _ready() -> void:
	_connect_tracks(column_tracks)


func _exit_tree() -> void:
	_disconnect_tracks(column_tracks)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_layout_children()


func _get_minimum_size() -> Vector2:
	var children := _participating_children()
	if children.is_empty():
		return Vector2.ZERO

	var layout := _build_layout(children)
	var column_minimums := _column_minimums(layout)
	var row_minimums := _row_minimums(layout)

	return Vector2(
      _sum(column_minimums) + column_gap * float(layout.column_count - 1),
      _sum(row_minimums) + row_gap * float(layout.row_count - 1)
    )


# Helpers

func _connect_tracks(tracks: Array[FgGridTrack]) -> void:
	for track in tracks:
		if track != null and not track.changed.is_connected(_request_layout):
			track.changed.connect(_request_layout)


func _disconnect_tracks(tracks: Array[FgGridTrack]) -> void:
	for track in tracks:
		if track != null and track.changed.is_connected(_request_layout):
			track.changed.disconnect(_request_layout)


func _request_layout() -> void:
	update_minimum_size()
	queue_sort()


func _sum(values: Array[float]) -> float:
	var total := 0.0

	for value in values:
		total += value

	return total


func _participating_children() -> Array[Control]:
	var result: Array[Control] = []

	for child in get_children():
		if child is Control and child.visible:
			result.append(child)

	return result


func _build_layout(children: Array[Control]) -> GridLayout:
	var column_count := _column_count()
	var row_count := int(ceili(float(children.size()) / float(column_count)))
	var items: Array[GridItem] = []

	for child_index in children.size():
		var child := children[child_index]
		items.append(GridItem.new(
			child,
			child.get_combined_minimum_size(),
			child_index / column_count,
			child_index % column_count,
		))

	return GridLayout.new(items, column_count, row_count)


func _size_columns(layout: GridLayout) -> void:
	var widths := _column_minimums(layout)
	var available := maxf(size.x - column_gap * float(layout.column_count - 1), 0.0)

	if column_tracks.is_empty():
		var equal_width := available / float(layout.column_count)
		for column in layout.column_count:
			widths[column] = maxf(widths[column], equal_width)

		layout.column_widths = widths
		return

	var used_width := 0.0
	var fraction_total := 0.0

	for column in layout.column_count:
		var track := column_tracks[column]
		if track != null and track.type == FgGridTrack.Type.FIXED:
			widths[column] = track.value
			used_width += widths[column]
		elif track == null or track.type == FgGridTrack.Type.AUTO:
			used_width += widths[column]
		else:
			widths[column] = 0.0
			fraction_total += track.value

	var remaining := maxf(available - used_width, 0.0)
	if fraction_total > 0.0:
		for column in layout.column_count:
			var track := column_tracks[column]
			if track != null and track.type == FgGridTrack.Type.FRACTION:
				widths[column] = remaining * track.value / fraction_total

	layout.column_widths = widths


func _column_minimums(layout: GridLayout) -> Array[float]:
	var minimums: Array[float] = []
	minimums.resize(layout.column_count)

	for item in layout.items:
		var column := item.column
		if column_tracks.is_empty() or column_tracks[column] == null or column_tracks[column].type == FgGridTrack.Type.AUTO:
			minimums[column] = maxf(minimums[column], item.minimum.x)

	if not column_tracks.is_empty():
		for column in layout.column_count:
			var track := column_tracks[column]
			if track != null and track.type == FgGridTrack.Type.FIXED:
				minimums[column] = track.value

	return minimums


func _row_minimums(layout: GridLayout) -> Array[float]:
	var minimums: Array[float] = []
	minimums.resize(layout.row_count)

	for item in layout.items:
		minimums[item.row] = maxf(minimums[item.row], item.minimum.y)

	return minimums


func _column_count() -> int:
	return column_tracks.size() if not column_tracks.is_empty() else columns


func _track_positions(sizes: Array[float], track_gap: float) -> Array[float]:
	var positions: Array[float] = []
	positions.resize(sizes.size())
	var position := 0.0

	for index in sizes.size():
		positions[index] = position
		position += sizes[index] + track_gap

	return positions


func _layout_children() -> void:
	var children := _participating_children()
	if children.is_empty():
		return

	var layout := _build_layout(children)
	_size_columns(layout)
	layout.row_heights = _row_minimums(layout)
	var column_positions := _track_positions(layout.column_widths, column_gap)
	var row_positions := _track_positions(layout.row_heights, row_gap)

	for item in layout.items:
		fit_child_in_rect(item.child, Rect2(
			column_positions[item.column],
			row_positions[item.row],
			layout.column_widths[item.column],
			layout.row_heights[item.row],
		))
