Running the game with your changes
----------------------------------

_There is a section about Git in the FAQ if you're unfamilar with it._

Fork the repository. Clone your fork to your system using your favorite Git tool. We define the `repository` directory to be the location of your repository on your system. We define the `bin` directory to be the `bin` folder in the installation folder of the client. By default this is:
 - `C:/ProgramData/FAForever/bin`

Copy the content of `repository/setup/bin` into the `bin` folder. Open up `init_dev.lua` that now resides in the `bin` folder. At the top it states:

```lua
-- change this to the location of the repository on your disk. Note that `\` is used
-- for escaping characters and you can just use `/` in your path instead.
local locationOfRepository = 'your-fa-repository-location'
```

Change that to match the path to the repository on your system. You can start the game by calling `start_dev.bat` or `start_dev.sh`. You can inspect them to find out what they do.When you use the scripts the game will start with your `repository` as a source. 

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

We have two type of patches: a balance patch and a development patch. The former is done by the balance team and they branch from deploy/fafbeta. The latter is done by the game team and they branch from deploy/fafdevelop. 

Work environment
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

Note that I do not recommend the Lua language server. The game uses a slightly adjusted version of Lua. The syntax doesn't match. We also have a different import system. The Lua language server generates dozens of errors. And it is not equipped to work with our import system.

Attaching the debugger
----------------------

_This step is optional and only required if you intent to investigate an exception / crash to desktop._

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
 - FAF: deploy/faf
 - FAF Beta: deploy/fafbeta
 - FAF Develop: deploy/fafdevelop

You can find the replay by starting it with the client once and immediately closing it. The replay is stored in the cache of the client:
 - `C:/ProgramData/FAForever/cache/temp.scfareplay`

Copy that replay to the replays folder of the game:
 - `C:/Users/%USER_NAME%/Documents/My Games/Gas Powered Games/Supreme Commander Forged Alliance/replays/%PROFILE_NAME%`

Note that the last path is incomplete: you need replace `%USER_NAME%` with your systems profile name and `%PROFILE_NAME%` with the profile name you use in the game. You can launch the game using the bat files as described earlier.

Frequently asked Questions (FAQ)
--------------------------------

There is more specific information on the [wiki](https://github.com/FAForever/fa/wiki) about the structure of the repository or how a release works.

 - - What is Git?

Git is software for tracking changes in a set of files. This is particular useful for source files. It is an industry standard. It is a good time investment to familiarize yourself with it. A few sources to learn Git from:
 - Git via the [command line](https://www.w3schools.com/git/git_intro.asp?remote=github)
 - Git via [Github Desktop](https://desktop.github.com/)
 - Git via [Visual Studio Code](https://code.visualstudio.com/docs/introvideos/versioncontrol)

At first it is important to understand what a fork is, how to stage, commit or push your files and how you can make a pull request. More advanced topics like merging stratgies or rebasing get relevant as you become more involved with the project.

 - - Can I play the game with other people that include my changes?

You can not - this will cause a desync.

 - - I have no .nx5 files.

Launch a game with the client using FAF Develop as your game type.
