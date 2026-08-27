# Godot Virtual List Lab

这是一个 Godot 4.x 的 RecyclerView 风格虚拟列表演示工程。

## 功能

- 10,000 条数据，但只创建可见区加 overscan 的 Cell
- 分页数据源：首次加载 120 条，触底自动追加下一页
- 固定高度 Cell（96 px）
- Cell 节点复用池
- 快速滚动、点击 Cell、刷新可见数据
- 首项插入、首项删除、首项局部更新
- 加载中状态和“已全部加载”状态
- 动态行高与高度缓存（前缀偏移 + 二分定位）
- 平滑滚动到指定索引
- 多类型 Cell 数据绑定（标准、扩展、优先）
- 跳转到任意索引
- 顶部实时显示活动 Cell、池中 Cell 和可见范围

## 运行

使用 Godot 4.x 导入本目录并运行 `main.tscn`。

命令行运行：

```sh
godot --path /absolute/path/to/godot-virtual-recycler --editor
godot --path /absolute/path/to/godot-virtual-recycler --editor --quit
```

## Android 导出

在 Godot 编辑器中安装 Android export templates，配置 Android SDK/JDK 后：

```sh
godot --headless --path /absolute/path/to/godot-virtual-recycler \
  --export-debug "Android" build/godot_virtual_list.apk
adb install -r build/godot_virtual_list.apk
```

安装后可在设备启动器打开应用，也可以直接在 Godot 编辑器中选择 `Project -> Install Android Build`。

## 结构

- `main.gd`：演示界面、数据源和 Cell 绑定
- `virtual_list.gd`：可复用的虚拟列表组件
- `virtual_recycler.gd`：RecyclerView 风格 Adapter 外观
- `demo_cell.gd`：示例 Cell
- `main.tscn`：入口场景
- `tests/test_virtual_recycler.gd`：headless 单元测试

## 第二阶段 API

`VirtualList` 已提供以下数据变更接口，数据变更后只刷新必要的 Cell 或复用池：

```gdscript
virtual_list.append_items(page)
virtual_list.insert_item(index, item)
virtual_list.remove_item(index)
virtual_list.update_item(index, item)
virtual_list.refresh_range(start_index, end_index)
```

演示中的分页请求使用本地定时器模拟网络延迟。接入真实接口时，将 `_load_more()` 中的 `_make_items()` 替换为异步 HTTP 请求，并在回调中继续调用 `append_items()` 即可。

## 第三阶段实现

列表默认开启 `variable_height`。每个数据项可提供 `height` 字段，组件会维护行高缓存和前缀偏移数组，并通过二分查找计算滚动位置对应的可见索引。`scroll_to_index()` 使用 Tween 平滑滚动到目标项。

当前演示通过 `kind` 字段展示三种 Cell 数据类型。后续如果需要真正不同的节点结构，可在 `_create_cell()` 中按类型返回不同场景，并在 `_bind_cell()` 中分派绑定逻辑，虚拟化核心无需修改。

## 测试

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless \
  --path /absolute/path/to/godot-virtual-recycler \
  --script res://tests/test_virtual_recycler.gd
```

测试覆盖 8 个核心行为：初始数据量、可见 Cell 限制、动态行高、插入、局部更新、删除、分页追加和滚动定位。
