FAF LUA Code
------------
master|develop
 ------------ | -------------
[![Build Status](https://travis-ci.org/FAForever/fa.svg?branch=master)](https://travis-ci.org/FAForever/fa) | [![Build Status](https://travis-ci.org/FAForever/fa.svg?branch=develop)](https://travis-ci.org/FAForever/fa)

Current patch is: 3723

Changelog can be found [here](changelog.md).


Contributing
------------

See guidelines for contributing [here](CONTRIBUTING.md).

See git branch model for the repository and how it relates to FAF client game modes [here](branchmodel.png).

Actual exe patches are [here](https://github.com/FAETHER/FA-Binary-Patches)

Running the game with your changes
----------------------------------

When FA starts without any command line arguments, it looks for a file called `SupComDataPath.lua`.

This file is a normal lua-file, that is allowed to use FA's IO operations to load directories and compressed directories (zip files) into the virtual file system.

The normal file looks like this:

    mount_contents(SHGetFolderPath('PERSONAL') .. 'My Games\\Gas Powered Games\\Supreme Commander Forged Alliance\\mods', '/mods')
    mount_contents(SHGetFolderPath('PERSONAL') .. 'My Games\\Gas Powered Games\\Supreme Commander Forged Alliance\\maps', '/maps')
    mount_dir(InitFileDir .. '\\..\\gamedata\\*.scd', '/')
    mount_dir(InitFileDir .. '\\..', '/')

Where `mount_contents` is a helper function defined also in that file.

This loads all maps and mods in your `~\Documents\My Games\...` folder, followed by the core game files that are located in compressed `.scd` files.

What's important to note about the load order is that if two directories contain the same file, the *first loaded* takes precedence. There are ways to get around this using hooks, that I'll explain in the end.

FAF extends the loading mechanism of FA, by using different initialization files: One for each featured mod.

`init_faf.lua` contains a whitelist of files that it allows to be loaded, this whitelist is implemented using the function `mount_dir_with_whitelist`, which is just like the helper function from the normal FA init file, except for the whitelist which only allows the given named files to be loaded.

The actual loading in `init_faf.lua` is done here:

    -- these are the classic supcom directories. They don't work with accents or other foreign characters in usernames
    mount_contents(SHGetFolderPath('PERSONAL') .. 'My Games\\Gas Powered Games\\Supreme Commander Forged Alliance\\mods', '/mods')
    mount_contents(SHGetFolderPath('PERSONAL') .. 'My Games\\Gas Powered Games\\Supreme Commander Forged Alliance\\maps', '/maps')
    -- these are the local FAF directories. The My Games ones are only there for people with usernames that don't work in the upper ones.
    mount_contents(InitFileDir .. '\\..\\user\\My Games\\Gas Powered Games\\Supreme Commander Forged Alliance\\mods', '/mods')
    mount_contents(InitFileDir .. '\\..\\user\\My Games\\Gas Powered Games\\Supreme Commander Forged Alliance\\maps', '/maps')
    mount_dir_with_whitelist(InitFileDir .. '\\..\\gamedata\\', '*.nxt', '/')
    mount_dir_with_whitelist(InitFileDir .. '\\..\\gamedata\\', '*.nx2', '/')
    -- these are using the newly generated path from the dofile() statement at the beginning of this script
    mount_dir_with_whitelist(fa_path .. '\\gamedata\\', '*.scd', '/')
    mount_dir(fa_path, '/')[/code]

After adding all maps and mods to the search path, all `.nxt` compressed directories are loaded (as filtered by the whitelist). This currently includes: murderparty, labwars, advanced strategic icons and texturepack. They are loaded in alphabetical order.

Followed by `.nxt` files, `.nx2` files are loaded. These comprise compressed directories for each subdirectory of the FA virtual file system: effects, env, loc, lua, modules, schook, projectiles, units, textures and meshes.

After all FAF-files have been loaded, the init file loads the base-game .scd files. Since these are loaded _last_, files that are in the FAF-directories take precedence and _shadow_ the base game files.

Hooking
-------

Hooking with the FA virtual file system simply means `concatenating files`.

Given the following directories and load-order:

*cool_mod* directory containing:
- `/hook/lua/file.lua`

*FAF.scd* containing:
- `/lua/file.lua`
- `/schook/lua/file.lua`

*FA.scd* containing:
- `/lua/file.lua`

What ends up in the actual filesystem used by FA is:

`/lua/file.lua` = `FAF.scd/lua/file.lua` + `cool_mod/hook/lua/file.lua` + `FAF.scd/schook/lua/file.lua`

Where "`fileA` + `fileB`" means that `fileB` has been appended to `fileA`.

The directory that is used for hooks can be configured in the init.lua file, and it customizable for each mod in the `mod_info.lua` file.

Setting up a development init file
----------------------------------


[ForgedAlliance.exe takes several useful command-line arguments](http://supcom.wikia.com/wiki/Command_line_switches), and it's even possible to make your own.

We can use a custom init file to ease the development process. The following file init file can be used:

    dev_path = 'C:\\Workspace\\forged-alliance-forever-lua'
    -- this imports a path file that is written by Forged Alliance Forever right before it starts the game.
    dofile(InitFileDir .. '\\..\\fa_path.lua')
    path = {}
    local function mount_dir(dir, mountpoint)
        table.insert(path, { dir = dir, mountpoint = mountpoint } )
    end
    local function mount_contents(dir, mountpoint)
        LOG('checking ' .. dir)
        for _,entry in io.dir(dir .. '\\*') do
            if entry != '.' and entry != '..' then
                local mp = string.lower(entry)
                mp = string.gsub(mp, '[.]scd$', '')
                mp = string.gsub(mp, '[.]zip$', '')
                mount_dir(dir .. '\\' .. entry, mountpoint .. '/' .. mp)
            end
        end
    end
    -- these are the classic supcom directories. They don't work with accents or other foreign characters in usernames
    mount_contents(SHGetFolderPath('PERSONAL') .. 'My Games\\Gas Powered Games\\Supreme Commander Forged Alliance\\mods', '/mods')
    mount_contents(SHGetFolderPath('PERSONAL') .. 'My Games\\Gas Powered Games\\Supreme Commander Forged Alliance\\maps', '/maps')
    -- these are the local FAF directories. The My Games ones are only there for people with usernames that don't work in the upper ones.
    mount_contents(InitFileDir .. '\\..\\user\\My Games\\Gas Powered Games\\Supreme Commander Forged Alliance\\mods', '/mods')
    mount_contents(InitFileDir .. '\\..\\user\\My Games\\Gas Powered Games\\Supreme Commander Forged Alliance\\maps', '/maps')
    mount_dir(dev_path, '/')
    -- these are using the newly generated path from the dofile() statement at the beginning of this script
    mount_dir(fa_path .. '\\gamedata\\*.scd', '/')
    mount_dir(fa_path, '/')
    hook = {
        '/schook'
    }
    protocols = {
        'http',
        'https',
        'mailto',
        'ventrilo',
        'teamspeak',
        'daap',
        'im',
    }

At the very top there is the line: `dev_path`, which should be set to wherever you have cloned this repository.


Starting Forged Alliance from the command line with the following arguments:

`ForgedAlliance.exe /init "init_dev.lua" /EnableDiskWatch /showlog`

Will put it into a mode where it will look for updates to files that it has loaded. So when you modify a unit file or a blueprint, the game will reload the file and put it into the active session.

This way, you don't need to restart the game every time you make a change, you simply need to make a new unit of the type, spawn a new projectile or do whatever it is you're doing.

It's not perfect; some changes will require a full game restart, and certain changes can cause crashes. But it's a lot better than reloading the game for every change, every time.

To start several processes of the game you need to add a line

`debug = { enable_debug_facilities = true }`

to `%userprofile%\AppData\Local\Gas Powered Games\Supreme Commander Forged Alliance\Game.prefs`

Translation guidelines
----------------------------------


The translation of both the game and the faf patch should be written in the way that they follow those guidelines. 
This goes for both future and past work on the SCFA translation and for all languages.

1) *Compliance with the game's UI*
- Text should never overflow from anywhere
- As much as possible, try to keep a few pixels of margin between the text and its parent element boundaries
- Use obvious abbreviations if a shorter translation is impossible, but the abbreviation should be made in a way that it is clear and obvious. Keywords from the game should never be abbreviated.

2) *Gender-neutral writing*
- The translation should never adopt gendered formulations when addressing the player directly, and should respect gender-neutral writing everywhere possible
- Median point and/or parentheses, or gendering a word twice, should be avoided to the maximum.

3) *Consistency of keywords*
- Game specific keywords, like unit names and building names, should always be translated in the same manner consistently across the whole game.
- If a new keyword appears, that is not translated elsewhere, it should be translated in a consistent manner regarding the other translated keywords.
