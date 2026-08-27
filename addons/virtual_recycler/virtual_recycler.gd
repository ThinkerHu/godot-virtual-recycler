extends "res://addons/virtual_recycler/virtual_list.gd"
class_name VirtualRecycler

## Adapter-shaped facade around the virtualized list implementation.
## The factory creates a reusable Cell and the binder binds one data item.
func set_adapter(factory: Callable, binder: Callable, data: Array) -> void:
	configure(factory, binder)
	submit_list(data)

func notify_data_set_changed(data: Array) -> void:
	submit_list(data)
