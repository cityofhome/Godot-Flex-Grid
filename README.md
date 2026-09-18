# Godot Flex & Grid

CSS inspired layout primitives for normal Godot `Control`-type nodes. This plugin provides something like flex, grid, and a box-model container (like `div`) without attempting to introduce anything else browser related. 

## Requirements

This plugin is built for and using `Godot 4.7`. You can attempt to get it working with any other version, but (currently) I have no need to, so that's up to you. 

## Installing

To install the addon in your Godot project:

1. Create an `addons/` directory under `res://` if you don't have one already.
2. Copy `fg_layout` from this repository into your `res://addons/` directory.
3. Open your project in Godot.
4. Enable **FG Layout** in **Project > Project Settings > Plugins**

## New Nodes

### FgFlexContainer

The flexbox like container. It lays out visible direct `Control`-type child nodes in either a row or a column. Invisible children and non-`Control`-type children are ignored.

Inspector settings: 

- `Direction`: Either row or column
- `Gap`: The minimum space between participating children
- `Justify Content`: Along the direction axis. One of start, center, end, space-between, space-around, or space-evenly
- `Align Items`: Along the opposite of the direction axis. One of start, center, end, or stretch

A `flex-grow` like behavior is possible by using the `Control` node's own **Container Sizing** config. For example, to set up a child with `flex-grow: 2` along the x-axis:

- Open that node in the inspector
- Scroll to **Control** then **Layout > Container Sizing**
- Set `Horizontal` to **Fill** and check **Expand**
- Set **Stretch Ratio** to `2.0`

An example scene tree using FgFlexContainer might look like:

```text
Control
  - FgFlexContainer
    - Button
    - Label
    - TextureRect
```

### FgBox

A div like box model around one visible direct `Control`-type child node. 

Inspector settings:

- `Margin`: An amount of spacing in px that sits **outside** of this node's border
- `Padding`: An amount of spacing in px that sits **inside** of this node's border
- `Background`: A background color for this node
- `Border`: Controls for border width (in px), border radius (corner radius, in px), and color

Margin is included in the node's minimum size, but stays transparent regardless of background setting. The border is rendered inside the margin.

This node can either go inside a control node (including FgFlexContainer), or outside, but may only have one direct visible `Control`-type child. If you attempt to include more than one, the editor reports a configuration warning and only the first will participate in the layout. Make use of nested flex containers when the box needs multiple contents. 

An example scene tree using an FgBox might look like:

```text
Control
  - FgBox
    - FgFlexContainer
      - Button
      - Label
      - TextureRect
```

### Shared resources

`FgSpacing` stores independently editable `Top`, `Right`, `Bottom`, and `Left` values. Negative values are currently clamped to zero. 