


-- get access to shared functionality
dofile(InitFileDir .. "/init_shared.lua")

-- load in development assets
mount_dir('C:\\Users\\Jip\\Documents\\Supreme Commander\\fa', '/')

-- load maps / mods from backup vault location location
load_content(InitFileDir .. '\\..\\user\\My Games\\Gas Powered Games\\Supreme Commander Forged Alliance')

-- load maps / mods from my documents vault location
load_content(SHGetFolderPath('PERSONAL') .. 'My Games\\Gas Powered Games\\Supreme Commander Forged Alliance')

-- load in any .nxt that matches the whitelist / blacklist in FAF gamedata
mount_dir_with_assetsAllowed(InitFileDir .. '\\..\\gamedata\\', '*.nxt', '/')
mount_dir_with_assetsAllowed(InitFileDir .. '\\..\\gamedata\\', '*.nx2', '/')

-- load in any .nxt that matches the whitelist / blacklist in FA gamedata
mount_dir_with_assetsAllowed(fa_path .. '\\gamedata\\', '*.scd', '/')

-- get direct access to preferences file, letting us have much more control over its content. This also includes cache and similar
mount_dir(SHGetFolderPath('LOCAL_APPDATA') .. 'Gas Powered Games\\Supreme Commander Forged Alliance', '/preferences')

-- Load in all the data of the steam installation (movies, maps, sound folders)
mount_dir(fa_path, '/')