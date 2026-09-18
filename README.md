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

### FgBox

A div like box model around one visible direct `Control`-type child node. 

Inspector settings:

- `Margin`: An amount of spacing in px that sits **outside** of this node's border
- `Padding`: An amount of spacing in px that sits **inside** of this node's border
- `Background`: A background color for this node
- `Border`: Controls for border width (in px), border radius (corner radius, in px), and color

Margin is included in the node's minimum size, but stays transparent regardless of background setting. The border is rendered inside the margin.