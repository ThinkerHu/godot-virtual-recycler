extends Control

const VirtualListScript = preload("res://addons/virtual_recycler/virtual_recycler.gd")
const DemoCellScript = preload("res://demo_cell.gd")
const TOTAL_ITEMS := 10000
const PAGE_SIZE := 120

var virtual_list: VirtualList
var count_label: Label
var pool_label: Label
var range_label: Label
var jump_input: LineEdit
var toast_label: Label
var load_more_button: Button
var items: Array = []
var refresh_serial := 0
var loading_more := false
var selected_index := 0

func _ready() -> void:
	_build_ui()
	items = _make_items(PAGE_SIZE)
	virtual_list.configure(_create_cell, _bind_cell)
	virtual_list.set_items(items)
	virtual_list.item_activated.connect(_on_item_activated)
	virtual_list.metrics_changed.connect(_on_metrics_changed)

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#0b1020")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	var header := MarginContainer.new()
	header.add_theme_constant_override("margin_left", 22)
	header.add_theme_constant_override("margin_right", 22)
	header.add_theme_constant_override("margin_top", 22)
	header.add_theme_constant_override("margin_bottom", 16)
	root.add_child(header)
	var header_box := VBoxContainer.new()
	header.add_child(header_box)
	var title := Label.new()
	title.text = "Virtual List Lab"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#f5f7fb"))
	header_box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Godot RecyclerView-style node recycling"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color("#8c9ab5"))
	header_box.add_child(subtitle)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 18)
	header_box.add_child(stats)
	count_label = _make_stat("数据 10,000")
	pool_label = _make_stat("活动 Cell 0")
	range_label = _make_stat("可见范围 -")
	stats.add_child(count_label)
	stats.add_child(pool_label)
	stats.add_child(range_label)

	var toolbar_margin := MarginContainer.new()
	toolbar_margin.add_theme_constant_override("margin_left", 22)
	toolbar_margin.add_theme_constant_override("margin_right", 22)
	toolbar_margin.add_theme_constant_override("margin_bottom", 12)
	root.add_child(toolbar_margin)
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	toolbar_margin.add_child(toolbar)
	var refresh_button := Button.new()
	refresh_button.text = "刷新可见项"
	refresh_button.custom_minimum_size = Vector2(122, 42)
	refresh_button.pressed.connect(_refresh_visible)
	toolbar.add_child(refresh_button)
	jump_input = LineEdit.new()
	jump_input.placeholder_text = "索引"
	jump_input.text = "5000"
	jump_input.custom_minimum_size = Vector2(92, 42)
	jump_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	toolbar.add_child(jump_input)
	var jump_button := Button.new()
	jump_button.text = "跳转"
	jump_button.custom_minimum_size = Vector2(78, 42)
	jump_button.pressed.connect(_jump_to_index)
	toolbar.add_child(jump_button)
	var hint := Label.new()
	hint.text = "拖动列表或点击 Cell 内的查看"
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color("#74819a"))
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(hint)

	var actions_margin := MarginContainer.new()
	actions_margin.add_theme_constant_override("margin_left", 22)
	actions_margin.add_theme_constant_override("margin_right", 22)
	actions_margin.add_theme_constant_override("margin_bottom", 12)
	root.add_child(actions_margin)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	actions_margin.add_child(actions)
	var insert_button := Button.new()
	insert_button.text = "插入首项"
	insert_button.custom_minimum_size = Vector2(108, 38)
	insert_button.pressed.connect(_insert_first)
	actions.add_child(insert_button)
	var remove_button := Button.new()
	remove_button.text = "删除首项"
	remove_button.custom_minimum_size = Vector2(108, 38)
	remove_button.pressed.connect(_remove_first)
	actions.add_child(remove_button)
	var update_button := Button.new()
	update_button.text = "局部更新"
	update_button.custom_minimum_size = Vector2(108, 38)
	update_button.pressed.connect(_update_first)
	actions.add_child(update_button)
	load_more_button = Button.new()
	load_more_button.text = "加载更多"
	load_more_button.custom_minimum_size = Vector2(108, 38)
	load_more_button.pressed.connect(_load_more)
	actions.add_child(load_more_button)

	var list_margin := MarginContainer.new()
	list_margin.add_theme_constant_override("margin_left", 16)
	list_margin.add_theme_constant_override("margin_right", 16)
	list_margin.add_theme_constant_override("margin_bottom", 12)
	list_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(list_margin)
	var list_panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#0f1729")
	panel_style.border_color = Color("#202c44")
	panel_style.set_border_width_all(1)
	panel_style.corner_radius_top_left = 14
	panel_style.corner_radius_top_right = 14
	panel_style.corner_radius_bottom_left = 14
	panel_style.corner_radius_bottom_right = 14
	list_panel.add_theme_stylebox_override("panel", panel_style)
	list_margin.add_child(list_panel)
	virtual_list = VirtualListScript.new()
	virtual_list.name = "VirtualList"
	virtual_list.set("item_height", 96.0)
	virtual_list.set("overscan", 5)
	virtual_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_panel.add_child(virtual_list)

	var footer := MarginContainer.new()
	footer.add_theme_constant_override("margin_left", 22)
	footer.add_theme_constant_override("margin_right", 22)
	footer.add_theme_constant_override("margin_bottom", 16)
	root.add_child(footer)
	toast_label = Label.new()
	toast_label.text = "复用池初始化中..."
	toast_label.add_theme_font_size_override("font_size", 12)
	toast_label.add_theme_color_override("font_color", Color("#5eead4"))
	footer.add_child(toast_label)

func _make_stat(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("#a8b4ca"))
	return label

func _create_cell() -> Control:
	return DemoCellScript.new()

func _bind_cell(cell: Control, index: int, data: Dictionary) -> void:
	if cell is DemoCell:
		cell.bind_data(index, data)

func _make_items(count: int, offset: int = 0) -> Array:
	var result: Array = []
	var statuses := ["处理中", "已完成", "待审核", "已排队"]
	var colors := [Color("#5eead4"), Color("#7dd3fc"), Color("#fbbf24"), Color("#c4b5fd")]
	var kinds := ["标准 Cell", "扩展 Cell", "优先 Cell"]
	for i in range(count):
		var item_index := offset + i
		result.append({
			"title": "虚拟列表条目 %05d" % (item_index + 1),
			"detail": "%s · 第 %d 条数据 · Cell 可复用" % [kinds[item_index % kinds.size()], item_index + 1],
			"time": "%02d:%02d" % [item_index % 24, item_index % 60],
			"status": statuses[item_index % statuses.size()],
			"progress": (item_index * 37) % 101,
			"color": colors[item_index % colors.size()],
			"kind": kinds[item_index % kinds.size()],
			"height": 96.0 + (32.0 if item_index % 4 == 0 else 0.0)
		})
	return result

func _on_metrics_changed(active_count: int, pool_count: int, first_index: int, last_index: int) -> void:
	if count_label:
		count_label.text = "已加载 %d / %d" % [items.size(), TOTAL_ITEMS]
		pool_label.text = "活动 Cell %d · 池 %d" % [active_count, pool_count]
		range_label.text = "可见范围 %d-%d" % [first_index + 1, last_index + 1]
	if last_index >= items.size() - 8 and items.size() < TOTAL_ITEMS and not loading_more:
		_load_more()

func _on_item_activated(index: int) -> void:
	selected_index = index
	toast_label.text = "已激活第 %d 条 · 节点仍由复用池管理" % (index + 1)

func _refresh_visible() -> void:
	refresh_serial += 1
	for item in items:
		item["progress"] = (int(item["progress"]) + 7) % 101
	virtual_list.refresh_range(0, items.size() - 1)
	toast_label.text = "已刷新可见数据 · 批次 %d" % refresh_serial

func _jump_to_index() -> void:
	var parsed := jump_input.text.to_int() - 1
	virtual_list.scroll_to_index(parsed)
	toast_label.text = "已定位到第 %d 条" % (clampi(parsed, 0, items.size() - 1) + 1)

func _insert_first() -> void:
	var inserted: Dictionary = _make_items(1, 0)[0]
	inserted["title"] = "新插入条目 · %s" % Time.get_time_string_from_system()
	virtual_list.insert_item(0, inserted)
	selected_index = 0
	toast_label.text = "已插入 1 条数据 · 当前总量 %d" % items.size()

func _remove_first() -> void:
	if virtual_list.remove_item(0):
		selected_index = clampi(selected_index - 1, 0, maxi(0, items.size() - 1))
		toast_label.text = "已删除首项 · 当前总量 %d" % items.size()

func _update_first() -> void:
	if items.is_empty():
		return
	var updated: Dictionary = items[0].duplicate()
	updated["title"] = "局部更新完成 · %s" % Time.get_time_string_from_system()
	updated["progress"] = (int(updated.get("progress", 0)) + 13) % 101
	virtual_list.update_item(0, updated)
	toast_label.text = "只更新了第 1 条 Cell"

func _load_more() -> void:
	if loading_more or items.size() >= TOTAL_ITEMS:
		return
	loading_more = true
	load_more_button.disabled = true
	load_more_button.text = "加载中..."
	toast_label.text = "正在加载下一页数据..."
	await get_tree().create_timer(0.35).timeout
	var page_count: int = mini(PAGE_SIZE, TOTAL_ITEMS - items.size())
	virtual_list.append_items(_make_items(page_count, items.size()))
	loading_more = false
	load_more_button.disabled = items.size() >= TOTAL_ITEMS
	load_more_button.text = "已全部加载" if items.size() >= TOTAL_ITEMS else "加载更多"
	toast_label.text = "已追加 %d 条 · 当前总量 %d" % [page_count, items.size()]
