Instructions to set up your development environment
---------------------------------------------------

A collection of useful information to help you set up your development environment.

Read this in other languages: [English](setup-english.md), [Russian](setup-russian.md)

Running the game with your changes
----------------------------------

_There is a section about Git in the FAQ if you're unfamilar with it._

Fork the repository. Clone your fork to your system using your favorite Git tool. We refer to the `repository` directory as the location of your repository on your system. We refer to the `bin` directory as the `bin` folder in the data location, as defined in the client settings. By default this is:
 - `C:/ProgramData/FAForever/bin`

Copy the contents of `repository/setup/bin` into the `bin` folder. Open `init_dev.lua` now found in the `bin` folder. At the top it states:

```lua
-- change this to the location of the repository on your disk. Note that `\` is used
-- for escaping characters and you can just use `/` in your path instead.
local locationOfRepository = 'your-fa-repository-location'
```

Change that to match the path to the `repository` on your system. You can start the game by calling `dev_windows.bat` or `dev_linux.sh`. You can inspect them to find out what they do. When you use the scripts the game will start with your `repository` as a source.

Base game files
---------------

The repository doesn't contain all the base game blueprint and / or script files. This is due to licensing issues. You'll need the remaining files when you work with the repository. This is useful to search for a file that is being imported or to search for examples. You can see this pattern in the initialisation file you copied in the previous step:

```lua
-- mount in development branch
MountDirectory(locationOfRepository, '/')

-- load in any .nxt that matches the whitelist / blacklist in FAF gamedata
MountAllowedContent(InitFileDir .. '/../gamedata/', '*.nx5', allowedAssetsNxy)
MountAllowedContent(InitFileDir .. '/../gamedata/', '*.nxt', allowedAssetsNxt)

-- load in any .scd that matches the whitelist / blacklist in FA gamedata
MountAllowedContent(fa_path .. '/gamedata/', '*.scd', allowedAssetsScd)
```

We load the fork of the repository, files set by FAF and then the base game files. The first file it finds is the file that the game will read from. As an example, the file `/lua/sim/unit.lua` is in the repository on your system, in `lua.nx5` and in `lua.scd`. The first file found is used - and in this case that is the file in your repository.

You can extract the remaining files by unpacking the relevant files in the gamedata folder of your installation:
 - `projectiles.scd`
 - `props.scd`
 - `units.scd`
 - `lua.scd`
 - `mohodata.scd`
 - `moholua.scd`
 - `schook.scd`

You can copy the file, change the extension to `zip` and unpack it using your favorite compression software. We recommend you to create a separate folder that stores the unpacked folders. You can launch a separate instance of Visual Studio Code to search through the base game code. You can also add an additional folder to a workspace in Visual Studio Code if you do not want multiple instances.

Branching
---------

We have two type of patches: a balance patch and a development patch. The former is done by the balance team and they branch from `deploy/fafbeta`. The latter is done by the game team and they branch from `deploy/fafdevelop`. The `fafbeta` branch is used for balance changes, a typical example is the tweaking of statistics of units such as hitpoints, movement speed and damage. The `fafdevelop` branch is used for game changes in general, such as performance improvements, fixing of bugs and the introduction of (new) mechanics.

Development environment
----------------

When you're new to programming then you may not have a work environment. This is often referred to as an Integrated Development Environment (IDE). We recommend you to use [Visual Studio Code](https://code.visualstudio.com/) (VSC).

If you're unfamiliar with Visual Studio Code then it will save you time to familiarize yourself with it. There is an excellent [introductionary series](https://code.visualstudio.com/docs/getstarted/introvideos) provided by Visual Studio Code themselves. Note that you do **not** need to do what the videos tell you to do. As an example, you do **not** need to install Python. We don't use Python for the game repository. The videos show you what is possible - it shows you how the tool works.

Other useful information:
 - [Shortcuts](https://code.visualstudio.com/shortcuts/keyboard-shortcuts-windows.pdf) for Visual Studio Code

Shortcuts can significantly improve your workflow. You do not need to familiarize yourself with each and every shortcut. We recommend you to look at this sheet every month and see if there is a common action that you've been doing that can be done by a shortcut instead. 

Useful extensions in general:
 - [Git graph](https://marketplace.visualstudio.com/items?itemName=mhutchie.git-graph): useful for graph visualizations
 - [Gitlens](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens): useful for seeing who made what change
 - [Peacock](https://marketplace.visualstudio.com/items?itemName=johnpapa.vscode-peacock): useful for coloring your workspaces when you have multiple

Useful extensions if you intent to work with shaders:
 - [Shader languages support for VS Code](https://marketplace.visualstudio.com/items?itemName=slevesque.shader)
 - [HLSL Tools](https://marketplace.visualstudio.com/items?itemName=TimGJones.hlsltools)
 - [Hex editor](https://marketplace.visualstudio.com/items?itemName=ms-vscode.hexeditor)

Setup the FA Lua Extension
----------------
Releases can be found [here](https://github.com/FAForever/fa-lua-vscode-extension/releases). 

To setup you will want to download the `.vsix` file and install it in VS Code. Follow the steps in the image and you will be able to select the extension file downloaded.  
![Extension install](/images/setup/extension-install.png)
> Note: Whenever there is a new version of the extension you will have to download it and install it again

Once you have it installed you're good to go for the FAF repo. For mod/map folders will be a different setup process (TODO, write guide for maps/mods).

Using the in game debugger
----------------------
[Thanks to Ejsstiil](https://github.com/FAForever/fa/pull/3938) the in-game debugger is working again.

### To invoke the Lua debugger, you can use:

* <kbd>Alt</kbd> + <kbd>F9</kbd> - the default keybind (this sometimes works only after you invoked binds menu (<kbd>F1</kbd>) first)
* in game console `SC_LuaDebugger`
* on cmdline `/debug` (most convenient for dev)

### Controls
* <kbd>double</kbd> <kbd>click</kbd> on the line sets the breakpoint
* <kbd>F5</kbd> resume execution
* <kbd>F10</kbd> step-in (can't find any way how to do step-over)
* <kbd>Ctrl</kbd> + <kbd>G</kbd> goto line
* <kbd>Ctrl</kbd> + <kbd>R</kbd> reloads the file

Tips:

* If you have a breakpoint set in the frequently used includes, it can significantly slow the game in general, even when your breakpoint is not being hit, better you disable or delete all breakpoints, then set it just before you need it
* due to the above, sometimes game seems froze-up, but you can just wait (or kill game) and clear all breakpoints right after

![preview](https://github.com/assets/36369441/8ab2b65c-d208-48d7-87d0-2676093e8ebd)




Attaching the debugger
----------------------

_This step is optional and only required when you intend to investigate an exception / crash to desktop._

With thanks to KionX we have a [debugger](https://github.com/FAForever/FADeepProbe). When an exception occurs it can trace the exception to a line of Lua code. A compiled executable is available in each [release](https://github.com/FAForever/FADeepProbe/releases). Store the executable in your `bin` folder. This is the same `bin` folder as defined earlier. We need to adapt the bat / bash files to use the debugger. As an example we change the bat file from:

```bat
ForgedAlliance.exe /init "init_dev.lua" /EnableDiskWatch /showlog /log "dev.log"
```
To:
```bat
FADeepProbe.exe /init "init_dev.lua" /EnableDiskWatch /showlog /log "dev.log"
```

The arguments are passed along by the debugger. The change to the bash script is similar. When the game crashes the debugger will try and inform you in the log what happened.

Running a replay
----------------

A hard crash may only show up in a replay. You'll need to use the debugger to investigate. You want to run the replay using the debugger. This requires two steps: match the game version of the replay and acquire the replay itself.

The game version depends on the game type. Checkout the repository to the correct branch:  
 - `FAF`: `deploy/faf`
 - `FAF Beta`: `deploy/fafbeta`
 - `FAF Develop`: `deploy/fafdevelop`

Unlike the `.fafreplay` files you can get from and view with the faf client, the base game which you will run to test and debug only recognizes the `.scfareplay` extension for replays. To convert a `.fafreplay` to the `.scfareplay` extension you can start the replay with the faf client and immediately close it. The client will have created a temporary  version of your replay with the `.scfareplay` format in the cache folder of the client:
 - `C:/ProgramData/FAForever/cache/temp.scfareplay`

Copy that replay to the replays folder of the game:
 - `C:/Users/%USER_NAME%/Documents/My Games/Gas Powered Games/Supreme Commander Forged Alliance/replays/%PROFILE_NAME%`

Note that the last path is incomplete: you need replace `%USER_NAME%` with your systems profile name and `%PROFILE_NAME%` with the profile name you use in the game. You can launch the game using the bat files as described earlier.

Multiple instances
------------------

You can start several processes at once when the debug facilities are enabled. You can do this by adding the following line to your preference file:
 - `debug = { enable_debug_facilities = true }`

The preference file can be found here:
 - `%userprofile%\AppData\Local\Gas Powered Games\Supreme Commander Forged Alliance\Game.prefs`

Hooking
-------

All files in the `schook` directory hook files in the `lua` folder. A mod applies a similar hooking strategy. Hooking means concatenating files: one file is appended to the next. This allows you to add code to a file. As an example, say we have this base game file:
 - `lua/sim/unit.lua`

And say we are trying to hook it with both:
 - `schook/lua/unit.lua`
 - `mods/my-mod/hook/lua/unit.lua`

Then what happens is:
 - `lua/sim/unit.lua` = `lua/sim/unit.lua` + `schook/lua/unit.lua` + `mods/my-mod/hook/lua/unit.lua`

Where the addition operator should be interpreted as appending one text (source) file to the other text (source) file. this extents the unit file. This hooking is done when a file is imported for the first time. The directory that is used for hooks can be configured in the initialization files.

Tips
----

Helpful hotkeys and resource you can use in game

* <kbd>Alt</kbd> + <kbd>F2</kbd> to invoke the unit spawning page, great for making units for free or taking control of an AI.
* <kbd>F9</kbd> to open the log window if you close it or it's not open for whatever reason.
* <kbd>~</kbd> to Open the Console
* In the Console run `ren_ShowNetworkStats` for the sim rate / package drops, on the top right
* In the Console run `ShowStats` for engine stats, on the left

Frequently asked Questions (FAQ)
--------------------------------

There is more specific information on the [wiki](https://github.com/FAForever/fa/wiki) about the structure of the repository or how a release works.

<dl>
<dt> What is Git? </dt>
<dd> Git is software for tracking changes in a set of files. This is particular useful for source files. It is an industry standard. It is a good time investment to familiarize yourself with it. There are various sources to learn git. You can learn using Git via the <a href="https://www.w3schools.com/git/git_intro.asp?remote=github">command line</a>, via <a href="https://desktop.github.com/">Github Desktop</a> or via <a href="https://code.visualstudio.com/docs/introvideos/versioncontrol">Visual Studio Code</a>. At first it is important to understand what a fork is, how to stage, commit or push your files and how you can make a pull request. More advanced topics like merging stratgies or rebasing get relevant as you become more involved with the project. </dd>

<dt> Can I play the game with other people that include my changes? </dt>
<dd> You can not - this will cause a desync. As an example: if one changes the amount of damage that is applied then that happens only on your version of the simulation.</dd>

<dt> I have no .nx5 files. </dt>
<dd> Launch a game with the client using FAF Develop as your game type. An .nx5 file is part of the FAF Develop game type. The client will download them accordingly. This may take a while. </dd>

<dt> My moholog settings keep resetting </dt>
<dd> This is done on purpose - you will need to enable debug facilities to prevent this. See the section on running multiple instances. </dd>
</dl>
