extends PanelContainer
class_name DemoCell

signal activated

var accent: ColorRect
var index_label: Label
var title_label: Label
var detail_label: Label
var status_label: Label
var progress: ProgressBar
var action_button: Button

func _ready() -> void:
	custom_minimum_size = Vector2(0, 84)
	# Let ScrollContainer receive drag gestures that start on the card.
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()

func _build_ui() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#151d2d")
	style.border_color = Color("#26334c")
	style.set_border_width_all(1)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	accent = ColorRect.new()
	accent.custom_minimum_size = Vector2(4, 0)
	accent.color = Color("#5eead4")
	row.add_child(accent)

	var number_panel := PanelContainer.new()
	number_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number_panel.custom_minimum_size = Vector2(52, 52)
	var number_style := StyleBoxFlat.new()
	number_style.bg_color = Color("#202d47")
	number_style.corner_radius_top_left = 10
	number_style.corner_radius_top_right = 10
	number_style.corner_radius_bottom_left = 10
	number_style.corner_radius_bottom_right = 10
	number_panel.add_theme_stylebox_override("panel", number_style)
	row.add_child(number_panel)
	index_label = Label.new()
	index_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	index_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	index_label.add_theme_font_size_override("font_size", 16)
	number_panel.add_child(index_label)

	var info := VBoxContainer.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color("#f3f7ff"))
	info.add_child(title_label)
	detail_label = Label.new()
	detail_label.add_theme_font_size_override("font_size", 12)
	detail_label.add_theme_color_override("font_color", Color("#8492ac"))
	info.add_child(detail_label)
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 6
	progress.show_percentage = false
	progress.add_theme_stylebox_override("background", _bar_style(Color("#25324b")))
	progress.add_theme_stylebox_override("fill", _bar_style(Color("#5eead4")))
	info.add_child(progress)

	var trailing := VBoxContainer.new()
	trailing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trailing.custom_minimum_size.x = 78
	trailing.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(trailing)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 11)
	trailing.add_child(status_label)
	action_button = Button.new()
	action_button.text = "查看"
	action_button.custom_minimum_size = Vector2(74, 32)
	action_button.add_theme_font_size_override("font_size", 12)
	action_button.pressed.connect(func(): activated.emit())
	trailing.add_child(action_button)

func _bar_style(color: Color) -> StyleBoxFlat:
	var bar := StyleBoxFlat.new()
	bar.bg_color = color
	bar.corner_radius_top_left = 4
	bar.corner_radius_top_right = 4
	bar.corner_radius_bottom_left = 4
	bar.corner_radius_bottom_right = 4
	return bar

func bind_data(index: int, data: Dictionary) -> void:
	index_label.text = str(index + 1)
	title_label.text = str(data.get("title", "列表项"))
	detail_label.text = "%s  ·  %s" % [data.get("detail", "演示数据"), data.get("time", "刚刚")]
	var value := int(data.get("progress", 0))
	progress.value = value
	status_label.text = str(data.get("status", "处理中"))
	status_label.add_theme_color_override("font_color", data.get("color", Color.WHITE))
	accent.color = data.get("color", Color("#5eead4"))
