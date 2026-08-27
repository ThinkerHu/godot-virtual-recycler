extends SceneTree

const VirtualRecyclerScript = preload("res://addons/virtual_recycler/virtual_recycler.gd")

var failures: Array[String] = []

func _init() -> void:
	await _run_tests()
	if failures.is_empty():
		print("VirtualRecycler tests: PASS (8 cases)")
	else:
		for failure in failures:
			push_error(failure)
		print("VirtualRecycler tests: FAIL (%d cases)" % failures.size())
	quit(1 if not failures.is_empty() else 0)

func _run_tests() -> void:
	var list = VirtualRecyclerScript.new()
	root.add_child(list)
	await process_frame
	list.size = Vector2(720, 640)
	list.set_adapter(_make_cell, _bind_cell, _make_items(100))
	await process_frame
	await process_frame

	_check(list.get_item_count() == 100, "initial item count")
	_check(list.get_active_count() > 0, "visible cells created")
	_check(list.get_active_count() < 30, "cell count is virtualized")
	_check(list.total_content_height > 9600.0, "variable heights contribute to content size")

	var first_range: Vector2i = list.get_visible_range()
	_check(first_range.x == 0, "initial visible range starts at zero")

	list.notify_item_inserted(0, {"id": 999, "height": 160.0})
	await process_frame
	_check(list.get_item_count() == 101, "insert operation")
	_check(int(list.items[0].get("id")) == 999, "inserted item is first")

	var updated: Dictionary = list.items[0].duplicate()
	updated["title"] = "updated"
	list.notify_item_changed(0, updated)
	_check(str(list.items[0].get("title")) == "updated", "local update operation")

	_check(list.notify_item_removed(0), "remove operation returns true")
	_check(list.get_item_count() == 100, "remove operation count")
	list.append_items(_make_items(20, 100))
	await process_frame
	_check(list.get_item_count() == 120, "pagination append operation")

	list.scroll_to_index(60)
	await process_frame
	await process_frame
	_check(list.scroll_container.scroll_vertical > 0, "scroll to index changes scroll position")
	_check(list.get_active_count() < 30, "cell count remains bounded after scroll")

func _make_cell() -> Control:
	var cell := Control.new()
	cell.custom_minimum_size = Vector2(0, 80)
	return cell

func _bind_cell(_cell: Control, _index: int, _data: Dictionary) -> void:
	pass

func _make_items(count: int, offset: int = 0) -> Array:
	var result: Array = []
	for i in range(count):
		result.append({"id": offset + i, "height": 96.0 + (32.0 if i % 4 == 0 else 0.0)})
	return result

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
