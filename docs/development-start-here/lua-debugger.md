---
layout: page
nav_order: 2
title: 02. Lua debugger
parent: Development - Start here
permalink: development/start-here/lua-debugger
---

# Lua debugger

A debugger allows you to set breakpoints and review the program state when the breakpoint is hit. The game ships with a debugger for Lua. And with thanks to [#3938](https://github.com/FAForever/fa/pull/3938) that debugger is now functional for everyone who has a local development environment. The debugger is not functional in any of the game types of the FAF Client.

There are various approaches to enabling the debugger:

- Keybinding: <kbd>Alt</kbd> + <kbd>F9</kbd>, this keybinding can be overwritten in the keybindings menu. If unassigned, search for 'debugging window' in the keybindings menu.
- Console command: `SC_LuaDebugger`
- Program argument: `/debug`

## Overview

![Screenshot of the debugger where it hit a breakpoint]({{ 'assets/images/development/lua/debugger-01.png' | relative_url }} )

In general there are three distinct panels:

- File explorer: allows you to search for a source file to set a breakpoint. Double click a source file to add it to the source panel.
- Source panel: allows you to navigate between source files the source code of the selected source file.
- Details panel: represents the program state at a given moment when a breakpoint is hit.

There are various additional buttons to interact with the debugger:

- `1`: Resume execution (hotkey: F5)
- `2`: Step into (hotkey: F10)
- `3`: Enable all breakpoints
- `4`: Disable all breakpoints
- `5`: Clear all breakpoints
- `6`: Find (in a source file)
- `7`: Find next (in a source file)
- `8`: Find previous (in a source file)

### Stack tab

Represents the [stacktrace](https://en.wikipedia.org/wiki/Stack_trace). You can click on each element. The source panel will jump to the relevant file and line. The locals and globals tab are updated with the locals and globals that are available at that moment in time.

### Locals tab

Represents all variables that are available at the local and upvalue scope. You can double-click table variables to show of its all key value pairs.

### Globals tab

Similar to the locals tab, except that it represents the values that are accessible in the global scope.

## Controls

- <kbd>double</kbd> <kbd>click</kbd> on a line of source code to set a breakpoint
- <kbd>F5</kbd> resume execution
- <kbd>F10</kbd> step-in (can't find any way how to do step-over)
- <kbd>Ctrl</kbd> + <kbd>G</kbd> goto line
- <kbd>Ctrl</kbd> + <kbd>R</kbd> reloads the file

## Tips and tricks

- The moment you set a breakpoint the game becomes effectively unplayable, regardless of whether your breakpoint is hit. It is best to remove all breakpoints until you're certain that you're ready to reproduce the situation that you are investigating.
- The debugger can be 'hidden' behind the game. To fix this you can run the game in windowed mode.
- The debugger can be 'offscreen', if that is the case then you can reset its coordinates in the preference file. Backup your preference file before editing it manually. Removing the `Windows` entry is sufficient.

We highly suggest reading [The implementation of Lua 5.0](https://www.lua.org/doc/jucs05.pdf) for a deeper understanding. In particular chapter 5 is useful to read to better understand the debugger window.

