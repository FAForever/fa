---
title: Deployment
layout: page
nav_order: 4
permalink: /development
---

# Development

This document contains a wide range of tips and tricks surrounding the development of the Lua code of the FAForever project. It can help you setup the development environment. It can help you with understand what is, and is not available to you in the Lua environment of Supreme Commander. It is however not a guide on how to write Lua code. And it is not a guide on programming in general. And it is also not a guide on how Git and/or GitHub works.

## Tooling

Everything works and breaks with your tooling. In this section we explain what has worked best so far.

### Lua development

We recommend the following tooling for development of Supreme Commander:

- [Visual Studio Code](https://code.visualstudio.com/) as your interactive development environment (IDE).
- [Github Desktop](https://github.com/apps/desktop) or [Github CLI](https://git-scm.com/) as your tool to interact with Git.

For Visual Studio Code we recommend the following extensions:

- [FA Lua extension](https://github.com/FAForever/fa-lua-vscode-extension/releases): introduces intellisense - absolutely vital to development.
- [Gitlens](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens): useful for seeing who made what change.
- [Prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode): useful for formatting.
- [Code Spell Checker](https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker): useful to prevent common spelling mistakes.

### Batch processing of blueprints

We recommend the following tooling in addition of the tooling used for development of Supreme Commander:

- [Brew WikiGen](https://github.com/The-Balthazar/BrewWikiGen) that allows for batch processing of blueprints.
- [Lua 5.4](https://www.lua.org/download.html) required for the Brew WikiGen to work.

There is a `Run.lua` file inside the Brew WikiGen source files. It represents the configuration of the tool. Copy the file and update the following fields:

- `WikiGeneratorDirectory` needs to reference the folder where the Brew WikiGen is located. Requires a trailing `/`.
- `EnvironmentData.location` needs to reference the checked out fa repository. Requires a trailing `/`.
- `EnvironmentData.RebuildBlueprints` should be `true`.
- `EnvironmentData.lua` needs to reference the checked out fa repository. Requires a trailing `/`.
- `EnvironmentData.LOC` needs to reference the checked out fa repository. Requires a trailing `/`.
- `EnvironmentData.PostModBlueprints` needs to reference the name of a function that is in the scope of [blueprints.lua](https://github.com/FAForever/fa/blob/c36404675c7a95cda20fe867d78bd1c01c7df103/lua/system/Blueprints.lua). This function is provided all the blueprint values that are loaded in a similar fashion to how the game provides the blueprint files.

And the following fields should be empty:

- `EnvironmentData.ExtraData`
- `ModDirectories`

Depending on what blueprints you'd like to rebuild you'll need to update `RebuildBlueprintOptions.RebuildBpFiles` and `EnvironmentData.LoadExtraBlueprints`. You should now be able to batch process all the blueprint files using the functions provided in `EnvironmentData.PostModBlueprints` by calling your run file with the Lua compiler that you installed. You can use [#6279](https://github.com/FAForever/fa/pull/6279) and [#6274](https://github.com/FAForever/fa/pull/6274) as an example on how to prepare the functionality in [blueprints.lua](https://github.com/FAForever/fa/blob/c36404675c7a95cda20fe867d78bd1c01c7df103/lua/system/Blueprints.lua).

### Automation via GitHub Actions

We recommend the following tooling in addition of the tooling used for development of Supreme Commander:

- [Act](https://github.com/nektos/act): allows you to run the average GitHub action on your local machine.
- [Docker](https://www.docker.com/products/docker-desktop/): required for Act to work.
- [Github CLI](https://github.com/cli/cli): required to authenticate yourself for Act to work.

You can verify the tooling is installed and available by running `gh --version`, `act --version` and `docker --version` in the command line.

#### Specifics for Act

The tool `act` only works on workflows that have the `push` event. Temporarily add the `push` event to the workflow that you want to test if it is missing.

```bash
         # Container to use                                        # Workflow to debug              # Token to authorize (optional)    # Do not pull the docker image each time
    act -P 'ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest' -W '.github/workflows/test.yaml' -s GITHUB_TOKEN="$(gh auth token)" -p=false
```

You can find all the Docker images that work with Act [on Github](https://github.com/catthehacker/docker_images).

## Specifics to the Lua environment

There are various specifics but you're usually actively discouraged to use them. The reason for this is simple: using them breaks all the tooling surrounding the game.

- The operator `^` is the bit-wise XOR operator and **not** the typical power operator, which is `math.pow`.
- The operator `|` is the bit-wise OR operator.
- The operator `&` is the bit-wise AND operator.
- The operators `>>` and `<<` are the bit-wise shift operators.
- The operator `!=` is an alternative to `~=` to check for inequality.
- The syntax `#` is an alternative to `--` for creating comments.
- The statement `continue` exists, which works like you'd expect in other languages with the `continue` keyword.

The one exception that can be used to [improve the performance of the game](https://github.com/FAForever/fa/issues/4539) is this:

- The `{h&a&}` is new syntax to create a table with a pre-allocated hash and array sections. The value `h` pre-allocates `math.pow(2, h)` entries in the hash section of a table. The value `a` pre-allocates `a` entries in the array section of a table.

Due to safety concerns various modules and/or functions that are part of the default Lua library are not available. This primarily applies to the entire `io` and `os` modules, which is only available during the initialisation phase of the game. [Interfacing with a C package](https://www.lua.org/pil/8.2.html) is also not available. In general anything that would provide access outside of the sandbox of the game is not available. There are some alternatives such as `DiskFindFiles` and `DiskGetFileInfo` that provide basic access to files that are made accessible during the initialisation phase of the game.

### Lua contexts

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

<!--
## Writing high performing Lua code for Supreme Commander

It goes without saying that premature optimisation is the root of all evil in the world. But Supreme Commander is not like the world. There is some common hygiene that you can apply to make your code a magnitude faster and more readable at the same time.

In Supreme Commander all Lua code is read, parsed and transpiled into bytecode that represent instructions. This happens when a module is [imported](../lua/system/import.lua) for the first time. The instructions are then executed by an interpreter. Unlike the [average compiler](https://en.wikipedia.org/wiki/Optimizing_compiler), an interpreter (and specifically a Lua interpreter) takes your code extremely literal. The instructions directly map to the syntax of the Lua script. You can learn more about what instructions exist by reading chapter 7 of [The implementation of Lua 5.0](https://www.lua.org/doc/jucs05.pdf). You can evaluate the instructions that make up a function using `debug.listcode`.

<todo> -->
