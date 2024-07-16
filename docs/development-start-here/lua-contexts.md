---
layout: page
nav_order: 4
title: 04. Lua contexts
parent: Development - Start here
permalink: development/start-here/lua-context
---

# Lua context



## Lua syntax

There are various Lua contexts in Supreme Commander. Each context is isolated from all the other contexts. This is intentional, especially for the session related contexts as changes to the simulation that are not synchronized to all users in a session will cause a desync. All contexts have [access to a shared package of globals](https://github.com/FAForever/fa/blob/c36404675c7a95cda20fe867d78bd1c01c7df103/engine/Core.lua).

- (1) Initialisation context

This is run at the start of the game. It is responsible for running the init files, such as [init_faf.lua](https://github.com/FAForever/fa/blob/c36404675c7a95cda20fe867d78bd1c01c7df103/init_faf.lua). Unlike other contexts the `io` and `os` modules are available.

- (2) Blueprint loading context

This is run when preparing a game session. It is responsible for loading and processing all the blueprint files. The [globalInit.lua](https://github.com/FAForever/fa/blob/c36404675c7a95cda20fe867d78bd1c01c7df103/lua/globalInit.lua) is run to initialize the context and then proceeds to call functions in [blueprints.lua](https://github.com/FAForever/fa/blob/c36404675c7a95cda20fe867d78bd1c01c7df103/lua/system/Blueprints.lua) to process the blueprints.

- (3) Main menu UI context

This is run (as a separate instance) during the splash screen, during the main menu (including the lobby). It is responsible for a lot of the UI functionality. The [userInit.lua](https://github.com/FAForever/fa/blob/c36404675c7a95cda20fe867d78bd1c01c7df103/lua/userInit.lua) is run to initialize the context and all [user globals](https://github.com/FAForever/fa/blob/c36404675c7a95cda20fe867d78bd1c01c7df103/engine/User.lua) are available.

- (4) Session UI context

This is run when a game session has started. It is responsible for a lot of the UI functionality. The [sessionInit.lua](https://github.com/FAForever/fa/blob/c36404675c7a95cda20fe867d78bd1c01c7df103/lua/SessionInit.lua) is run to initialize the context and all [user globals](https://github.com/FAForever/fa/blob/c36404675c7a95cda20fe867d78bd1c01c7df103/engine/User.lua) are available. You can use [Sim Callbacks](https://github.com/FAForever/fa/blob/c36404675c7a95cda20fe867d78bd1c01c7df103/lua/SimCallbacks.lua) to pass and synchronize information to the session sim context. In general, all user globals that (indirectly) interact with the simulation is input and synchronized between users.

- (5) Session sim context

This is run when a game session has started. It is responsible for all the Lua interactions in the simulation and all [sim globals](https://github.com/FAForever/fa/blob/c36404675c7a95cda20fe867d78bd1c01c7df103/engine/Sim.lua) are available. The [simInit.lua](https://github.com/FAForever/fa/blob/c36404675c7a95cda20fe867d78bd1c01c7df103/lua/simInit.lua) is run to initialize the context. You can use [UserSync.lua](https://github.com/FAForever/fa/blob/c36404675c7a95cda20fe867d78bd1c01c7df103/lua/UserSync.lua) to pass information to the Session UI context.