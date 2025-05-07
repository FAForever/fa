- (#6726) Introduce the ability to paint on the map

Introduces the ability for players and observers to paint directly on the map. The brush strokes are shared with allied players. Observers can view all brush strokes, and only share with other observers. All brush strokes made by players are part of the replay. 

A brush stroke is limited in length. This is a technical limitation to limit the network traffic to a minimum. There's no limit on the number of brush strokes. Players can create complicated shapes such as an arrow by creating multiple brush strokes.

The scaling factor of the UI influences the width of a brush stroke.

With thanks to Ctrl-K for both the assembly implementation to be able to draw lines and the concurrent Lua implementation. Without his time and effort it would not be possible, and it wouldn't be as refined as it is now.

Limitations:

- You can not make a painting when you hold shift.
- You can not make a painting when you have a unit selection.

Controls:

- You can paint by holding the right mouse button.
- You can remove strokes by holding alt and the right mouse button.
- You can mute players by holding ctrl, alt and the right mouse button.

Game options:

- You can enable or disable the feature as a whole. It is enabled by default.
- You can tweak the duration of a brush stroke. The shorter the duration, the quicker it disappears on its own.
