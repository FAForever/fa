---
layout: post
title: Example of Manual Crash Analysis
permalink: development/manual-crash-analysis
parent: Development
---

We will analyze this: [#2045 (comment)](https://github.com/FAForever/fa/issues/2045#issuecomment-924210717)
The analysis of this simple example should help those who want to start picking FAF.
Explaining the debugger interface is not part of this guide.

Run replay 15362291 under debugger. Wait for ACCESS_VIOLATION(code C0000005).
This should happen at 48:38 game time. All values is HEX.
An exception occurred at 0050DFD8(EIP).
This is usually the only thing useful in Bugsplat reports.
Here is this instruction: MOV EDX,DWORD PTR DS:[ECX+5C]
ECX at this moment is 0. ECX+5C = 0000005C. This corresponds to the report.
Since the game takes up memory starting from 400000, all smaller addresses are obviously not valid.

How now to understand what the reason is?

The inscription \_\_blueprints is visible nearby... this is a hint)
If this inscription is not visible, then you need to configure the debugger or it is bad.
Go to the caller address. If you scroll the disassembler up, you will see the desc of the LUA function.
This is Entity:GetBlueprint. The function body starts at 0068AFB0.
And its prologue at 0068AF30. This is the standard prologue of LUA functions in FA.
(The block at 0068AF50 fills structure that is used to register GetBlueprint in the LUA VM.
Explaining this process is not part of this guide.)

Where was this called from in LUA?

To get some information about the state of VM LUA, first you need to find a pointer to [lua_State](https://github.com/FAForever/FA-Binary-Patches/blob/360ed5705940bc80fde52aedf3b3afdb2586e57c/sections/include/moho.h#L167)
lua_State is an analog of a thread in the OS.
This pointer is passed through a single argument and ESI to the function's prologue.
The exception occurred far from the prologue and the ESI contains something other.
We will take it from the stack. Find the return address from the function body in the stack. This is 0068AF45.
The value below is the address of lua_State. You can check it like this: `[[lua_State+44]] = lua_State`
([] means that you need to take the contents of the address)
Get the size of the LUA call stack:
`[lua_State+14] = end`
`[lua_State+28] = begin`
(end - begin) / 28 = 4
Now, following this instruction, you can get the LUA the call points:
(lvl starts from 1. For non-LUA call points will show garbage)
[Get debugging info about a Lua call](https://github.com/FAForever/FA-Binary-Patches/blob/360ed5705940bc80fde52aedf3b3afdb2586e57c/sections/include/global.h#L9)
The very first call:
`@c:\programdata\faforever\gamedata\lua.nx2\lua\defaultcollisionbeams.lua 196`

```
DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)
```

How can this be verified? If you continue to go through the C call stack, the DamageArea function will be found.

But it's easier to use [FADeepProbe](https://github.com/FAForever/FADeepProbe), which will do it yourself.

So what's the reason of crash?

Let's look at the GetBlueprint input parameters.
[lua_State+C] indicates the current LUA stack frame. This is a list of [lua_var](https://github.com/FAForever/FA-Binary-Patches/blob/360ed5705940bc80fde52aedf3b3afdb2586e57c/sections/include/moho.h#L147).
At begin are the input parameters. GetBlueprint accepts Entity. This is the [table](https://lua.org/source/5.0/lobject.h.html#Table).
In it, you need to find the \_c_object parameter. In this case, is the very first.
I will not explain in detail the structure of LUA tables.
You can get the value of this parameter as follows: [[[[lua_State+C]+0\*8+4]+14]+0\*14+C]
This is a UserData type value. Add [value+10] to get a pointer to the C object.
What is the class of this object? You can find out like [this](https://github.com/FAForever/FA-Binary-Patches/blob/360ed5705940bc80fde52aedf3b3afdb2586e57c/sections/include/global.h#L3).
That's how it's called: .?AVCollisionBeamEntity@Moho@@ (FADeepProbe does it)
Intuitively it is clear that this is a [CollisionBeamEntity](https://github.com/FAForever/fa/blob/7542596ea1c16be28615fdc40cc9bf9c8bb5481a/engine/Sim/CollisionBeamEntity.lua) and it is a descendant of an [Entity](https://github.com/FAForever/fa/blob/7542596ea1c16be28615fdc40cc9bf9c8bb5481a/engine/Sim/Entity.lua).
To be sure, you can look at the [ancestors](https://github.com/FAForever/FA-Binary-Patches/blob/360ed5705940bc80fde52aedf3b3afdb2586e57c/sections/include/global.h#L4).
Let's go back to the crash address.
Restart the game, put a breakpoint at this address, do something to trigger the GetBlueprint function.
Now there is a C object in ECX whose class name has the letters Blueprint. What does [ECX+5C] read?
After tracing the hierarchy of classes and reaching [RBlueprint](https://github.com/FAForever/FA-Binary-Patches/blob/360ed5705940bc80fde52aedf3b3afdb2586e57c/sections/include/moho.h#L308), we find out that 5C is a [BlueprintOrdinal](https://github.com/FAForever/FA-Binary-Patches/blob/360ed5705940bc80fde52aedf3b3afdb2586e57c/sections/include/moho.h#L316).
Who owns this Blueprint?
By deduction and code exploring, you can find out that it belongs to an object from the GetBlueprint input parameter.
You can check it like this: [CObject+6C] = ECX
After checking the LUA stack frames([[lua_State+28]+lvl\*5\*8]), we find that this object was passed to DamageArea.
Now all the puzzle pieces are assembled:
ECX=0, **blueprints, DamageArea, CollisionBeamEntity, BlueprintOrdinal.
FA could not read **blueprints[CollisionBeamEntity.Blueprint.BlueprintOrdinal] due to the missing of Blueprint.
CollisionBeamEntity has been passed to DamageArea.
(FADeepProbe is trying to gather additional information. If there is no Blueprint or it is corrupted, this will be checked)

Finding out where the Blueprint disappeared is not included in this guide.
