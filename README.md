# Godot VirtualRecycler

RecyclerView-style virtualized list component for Godot 4.x. It keeps a bounded pool of `Control` cells, binds only the visible range, supports variable row heights, and exposes adapter-shaped update APIs.

This repository contains both the reusable component and a runnable demo. The component is written in GDScript and has no third-party dependencies.

## Features

- Visible-range virtualization with overscan and Cell reuse.
- Fixed or variable row heights with cached prefix offsets and binary lookup.
- Adapter facade: factory, binder, submit list, insert/remove/change notifications.
- Smooth scrolling to an index and visible-range inspection.
- Pagination-friendly append API.
- Touch-friendly event propagation; interactive controls inside a Cell remain clickable.
- Headless tests for core behavior.
- Demo with 10,000 logical records and multiple Cell data types.

## Requirements

- Godot 4.3 or newer (tested with Godot 4.7.2).
- Android export templates only if building the demo for Android.

## Install As A Component

Copy `addons/virtual_recycler` into your Godot project. The component can be used directly from script; no editor plugin activation is required.

```gdscript
const VirtualRecyclerScript = preload("res://addons/virtual_recycler/virtual_recycler.gd")

var recycler: VirtualRecycler

func _ready() -> void:
    recycler = VirtualRecyclerScript.new()
    add_child(recycler)
    recycler.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    recycler.set_adapter(_create_cell, _bind_cell, records)

func _create_cell() -> Control:
    return preload("res://ui/list_cell.tscn").instantiate()

func _bind_cell(cell: Control, index: int, data: Dictionary) -> void:
    cell.bind_data(index, data)
```

Each item can optionally provide a `height` field. Set `variable_height = false` when all rows have the same height for the simplest and fastest path.

## API

```gdscript
recycler.set_adapter(factory, binder, data)
recycler.submit_list(data)
recycler.append_items(page)
recycler.notify_item_inserted(index, item)
recycler.notify_item_removed(index)
recycler.notify_item_changed(index, item)
recycler.notify_item_range_changed(start_index, end_index)
recycler.scroll_to_index(index)
var visible: Vector2i = recycler.get_visible_range()
```

Signals:

```gdscript
recycler.item_activated.connect(_on_item_activated)
recycler.metrics_changed.connect(_on_metrics_changed)
```

`metrics_changed(active_count, pool_count, first_index, last_index)` is useful for triggering pagination when `last_index` approaches the end of the loaded data.

## Demo

Open this repository as a Godot project and run `main.tscn`. The demo shows 10,000 logical records loaded in pages of 120, dynamic 96px/128px rows, insert/remove/local update, pagination, smooth index jump, and active Cell/reuse-pool counters.

## Tests

```sh
godot --headless --path . --script res://tests/test_virtual_recycler.gd
```

Expected output:

```text
VirtualRecycler tests: PASS (8 cases)
```

The tests cover virtualization bounds, variable-height content metrics, insertion, removal, local updates, pagination append and scroll positioning.

## Repository Layout

```text
addons/virtual_recycler/   Reusable component
tests/                     Headless component tests
main.tscn                  Demo entry scene
main.gd                   Demo data source and controls
demo_cell.gd               Demo Cell implementation
```

## Scope And Compatibility

This is a Godot-native virtual list, not a wrapper around Android's `RecyclerView`. It provides the same core adapter/recycling behavior, but Android View accessibility semantics, `DiffUtil`, native nested scrolling and platform View lifecycle are outside the component's scope.

Grid, waterfall, sticky-header and drag-sort layouts should be implemented as separate layout strategies on top of the same Cell factory/binder contract.

## License

MIT. See [LICENSE](LICENSE).
