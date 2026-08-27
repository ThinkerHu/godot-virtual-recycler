extends Control
class_name VirtualList

signal item_activated(index: int)
signal metrics_changed(active_count: int, pool_count: int, first_index: int, last_index: int)

@export var item_height: float = 96.0
@export var overscan: int = 5
@export var variable_height: bool = true

var items: Array = []
var cell_factory: Callable
var cell_binder: Callable
var scroll_container: ScrollContainer
var content: Control
var active_cells: Dictionary = {}
var free_cells: Array[Control] = []
var item_heights: Array = []
var item_offsets: Array = []
var total_content_height: float = 0.0
var refresh_queued := false

func _ready() -> void:
	_build_scroll_view()
	resized.connect(_queue_refresh)

func _build_scroll_view() -> void:
	scroll_container = ScrollContainer.new()
	scroll_container.name = "ScrollContainer"
	scroll_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll_container.add_theme_constant_override("separation", 0)
	add_child(scroll_container)
	content = Control.new()
	content.name = "VirtualContent"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.custom_minimum_size = Vector2(0, 1)
	scroll_container.add_child(content)
	scroll_container.get_v_scroll_bar().value_changed.connect(_on_scroll_changed)

func configure(factory: Callable, binder: Callable) -> void:
	cell_factory = factory
	cell_binder = binder
	_queue_refresh()

func set_items(next_items: Array) -> void:
	_recycle_all()
	items = next_items
	_rebuild_layout_metrics()
	content.size.x = scroll_container.size.x
	_queue_refresh()

func append_items(next_items: Array) -> void:
	if next_items.is_empty():
		return
	items.append_array(next_items)
	_rebuild_layout_metrics()
	_queue_refresh()

func insert_item(index: int, item: Dictionary) -> void:
	var insert_at: int = clampi(index, 0, items.size())
	items.insert(insert_at, item)
	_recycle_all()
	_rebuild_layout_metrics()
	_queue_refresh()

func remove_item(index: int) -> bool:
	if index < 0 or index >= items.size():
		return false
	items.remove_at(index)
	_recycle_all()
	_rebuild_layout_metrics()
	_queue_refresh()
	return true

func update_item(index: int, item: Dictionary) -> bool:
	if index < 0 or index >= items.size():
		return false
	items[index] = item
	_rebuild_layout_metrics()
	if active_cells.has(index) and cell_binder.is_valid():
		cell_binder.call(active_cells[index], index, item)
	return true

func get_item_count() -> int:
	return items.size()

# RecyclerView-style adapter aliases for application code.
func submit_list(next_items: Array) -> void:
	set_items(next_items)

func notify_item_inserted(index: int, item: Dictionary) -> void:
	insert_item(index, item)

func notify_item_removed(index: int) -> bool:
	return remove_item(index)

func notify_item_changed(index: int, item: Dictionary) -> bool:
	return update_item(index, item)

func notify_item_range_changed(start_index: int, end_index: int) -> void:
	refresh_range(start_index, end_index)

func get_visible_range() -> Vector2i:
	if items.is_empty() or scroll_container == null:
		return Vector2i(0, -1)
	var first_index: int = _find_index_at_offset(float(scroll_container.scroll_vertical))
	var last_index: int = _find_index_at_offset(float(scroll_container.scroll_vertical) + scroll_container.size.y)
	return Vector2i(first_index, mini(items.size() - 1, last_index))

func scroll_to_index(index: int) -> void:
	if items.is_empty():
		return
	var clamped := clampi(index, 0, items.size() - 1)
	var target_y: float = item_offsets[clamped]
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(scroll_container, "scroll_vertical", target_y, 0.28)
	_queue_refresh()

func refresh_range(start_index: int, end_index: int) -> void:
	for index in active_cells.keys().duplicate():
		if index >= start_index and index <= end_index and cell_binder.is_valid():
			cell_binder.call(active_cells[index], index, items[index])
	_queue_refresh()

func get_active_count() -> int:
	return active_cells.size()

func get_pool_count() -> int:
	return free_cells.size()

func _on_scroll_changed(_value: float) -> void:
	_queue_refresh()

func _queue_refresh() -> void:
	if refresh_queued:
		return
	refresh_queued = true
	call_deferred("_refresh_visible")

func _refresh_visible() -> void:
	refresh_queued = false
	if not is_node_ready() or scroll_container == null or content == null:
		return
	_rebuild_layout_metrics()
	content.size.x = scroll_container.size.x
	if items.is_empty() or size.y <= 0.0:
		_recycle_all()
		metrics_changed.emit(0, free_cells.size(), 0, -1)
		return

	var viewport_height := scroll_container.size.y
	var scroll_y := float(scroll_container.scroll_vertical)
	var first_index: int = maxi(0, _find_index_at_offset(scroll_y) - overscan)
	var last_index: int = mini(items.size() - 1, _find_index_at_offset(scroll_y + viewport_height) + overscan)
	var wanted: Dictionary = {}
	for index in range(first_index, last_index + 1):
		wanted[index] = true

	for index in active_cells.keys().duplicate():
		if not wanted.has(index):
			_recycle_cell(index)

	for index in range(first_index, last_index + 1):
		if not active_cells.has(index):
			_activate_cell(index)
		var cell: Control = active_cells[index]
		var row_height: float = item_heights[index]
		cell.position = Vector2(12.0, item_offsets[index] + 6.0)
		cell.size = Vector2(max(0.0, content.size.x - 24.0), row_height - 12.0)
		if cell_binder.is_valid():
			cell_binder.call(cell, index, items[index])

	metrics_changed.emit(active_cells.size(), free_cells.size(), first_index, last_index)

func _activate_cell(index: int) -> void:
	var cell: Control
	if free_cells.is_empty():
		if not cell_factory.is_valid():
			return
		cell = cell_factory.call()
		content.add_child(cell)
		if cell.has_signal("activated"):
			cell.activated.connect(_on_cell_activated.bind(cell))
	else:
		cell = free_cells.pop_back()
		cell.show()
	active_cells[index] = cell
	cell.set_meta("virtual_index", index)

func _recycle_cell(index: int) -> void:
	var cell: Control = active_cells[index]
	active_cells.erase(index)
	cell.hide()
	free_cells.append(cell)

func _recycle_all() -> void:
	for index in active_cells.keys().duplicate():
		_recycle_cell(index)

func _on_cell_activated(cell: Control) -> void:
	var index := int(cell.get_meta("virtual_index", -1))
	if index >= 0:
		item_activated.emit(index)

func _rebuild_layout_metrics() -> void:
	item_heights.clear()
	item_offsets.clear()
	total_content_height = 0.0
	for item in items:
		var row_height: float = item_height
		if variable_height and item is Dictionary:
			row_height = maxf(item_height, float(item.get("height", item_height)))
		item_offsets.append(total_content_height)
		item_heights.append(row_height)
		total_content_height += row_height
	if content:
		content.custom_minimum_size.y = maxf(1.0, total_content_height)

func _find_index_at_offset(offset: float) -> int:
	if item_offsets.is_empty():
		return 0
	var low := 0
	var high := item_offsets.size() - 1
	while low < high:
		var mid: int = int((low + high + 1) / 2)
		if item_offsets[mid] <= offset:
			low = mid
		else:
			high = mid - 1
	return low
