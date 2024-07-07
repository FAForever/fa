---
layout: post
nav_order: 1
title: 01. Setup
parent: Development
permalink: development/setup
---

# Setup of a development environment

Development can be difficult when your development environment is not flexible enough. In this section we explain what we think works best. We do not provide details on how to use the tooling outside of specifics that are related to Supreme Commander.

In general we assume that you made a [fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo) of the [fa repository](https://github.com/FAForever/fa) and that you have [cloned](https://docs.github.com/en/desktop/adding-and-cloning-repositories/cloning-a-repository-from-github-to-github-desktop) your fork to the device that you intend to use to develop on.

## Tooling

Everything works and breaks with your tooling. We recommend the following tooling:

- [Visual Studio Code](https://code.visualstudio.com/) as your interactive development environment (IDE).
- [Github Desktop](https://github.com/apps/desktop) or [Github CLI](https://git-scm.com/) as your tool to interact with Git.

For Visual Studio Code we recommend the following extensions:

- [FA Lua extension](https://github.com/FAForever/fa-lua-vscode-extension/releases): introduces intellisense - absolutely vital to development.
- [Gitlens](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens): useful for seeing who made what change.
- [Prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode): useful for formatting.
- [Code Spell Checker](https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker): useful to prevent common spelling mistakes.

## Running the game with your changes

Open up two explorers. Navigate to where you cloned the repository in one. Navigate to the bin folder of the FAForever client in another. Usually the bin folder of the client is located in:

- `C:\ProgramData\FAForever\bin`

Copy the `init_local_development.lua` file your fork to the the bin folder. The game uses an initialisation file to understand where it should (not) search for game files. The initialisation file you just copied is an adjusted initialisation file that tells the game to also look at your local repository. We still need to tell it where that is. Open up the file that you copied. At the top you'll find:

```lua
-- change this to the location of the repository on your disk. Note that `\` is used
-- for escaping characters and you can just use `/` in your path instead.
local locationOfRepository = 'your-fa-repository-location'
```

Update the path to where your local repository is. Make sure that it is still valid Lua. And make sure that you use `/` instead of `\`.

Now we need to tell the game to launch with the adjusted initialisation file. We can do this through program arguments. We recommend you to create a small batch script file in the bin folder called `dev_windows`. The content should be roughly similar to:

```batch
ForgedAlliance.exe /init "init_local_development.lua" /EnableDiskWatch /showlog /log "local-development.log" /nomovie

REM /init               Defines what initialisation file to use
REM /EnableDiskWatch    Allows the game to reload files when it sees they're changed on disk
REM /showlog            Opens the moho log by default
REM /log                Defines where to store the log file
REM /nomovie            Removes potentially lagging starting/launching movies (will require you to hit escape on startup)
REM
REM Other interesting program arguments:
REM /debug              Start the game with the Lua debugger enabled
```

For Linux users you can use the following bash script file instead:

```bash
#! /bin/sh

# Change this to the location of your run proton run script (you will have copied this into your client folder https://wiki.faforever.com/en/FAQ/Client-Setup)
RunProton="$HOME/Applications/FAF/downlords-faf-client-1.6.0/run"
$RunProton $HOME/.faforever/bin/ForgedAlliance.exe /init init_dev.lua /showlog /log "dev.log" /EnableDiskWatch /nomovie

# /init               Define what initialisation file to use
# /EnableDiskWatch    Allows the game to reload files when it sees they're changed on disk
# /showlog            Opens the moho log by default
# /log                Informs the game where to store the log
# /nomovie            Removes potentially lagging starting/launching movies (will require you to hit escape on startup)
#
# Other interesting program arguments:
# /debug              Start the game with the Lua debugger enabled
```

Now you can start the game by executing the batch/bash script file. If all is good then the game starts as usual and you'll be in the main menu. If something is off then the game usually does not start. In that case you likely made a typo.
