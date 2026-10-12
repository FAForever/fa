- Fix a rare crash that could happen while drawings or other shapes are shown in the world. An engine patch that runs while they are drawn wrote outside its memory and corrupted Lua tables (#7336, [FA-Binary-Patches#176](https://github.com/FAForever/FA-Binary-Patches/pull/176)).

