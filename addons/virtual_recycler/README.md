# VirtualRecycler Addon

Copy this directory into the `addons/` directory of a Godot 4.x project.

The runtime component is available through:

```gdscript
const VirtualRecyclerScript = preload("res://addons/virtual_recycler/virtual_recycler.gd")
```

`virtual_recycler.gd` provides the adapter-shaped facade. `virtual_list.gd` contains the virtualization engine and can also be used directly when the facade is not needed.
