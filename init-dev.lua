-- Replace this with the path to your local repository.
repository =  'E:\\Games\\FAF Workspace\\fa\\forged-alliance-forever-lua'

-- Imports a path file that is written by Forged Alliance Forever right before it starts the game - do not change.
dofile(InitFileDir .. '\\..\\fa_path.lua')

-- The all-mighty path table that will hold all our mounted directories.
path = {}

-- Adds an entry to the path table - ensuring it is properly formatted.
local function mount_dir(dir, mountpoint)
    table.insert(path, { dir = dir, mountpoint = mountpoint } )
end

-- Mounts all folders in the directory to the mount point.
-- Example: Mount all mods at the mount point '/mods/
-- dir        = SHGetFolderPath('PERSONAL') .. 'My Games\\Gas Powered Games\\Supreme Commander Forged Alliance\\mods'
-- mountpoint = '/mods'
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

-- The classic Supreme Commander directories in your 'My Documents' folder.
-- They don't work with accents or other foreign characters in usernames.
mount_contents(SHGetFolderPath('PERSONAL') .. 'My Games\\Gas Powered Games\\Supreme Commander Forged Alliance\\mods', '/mods')
mount_contents(SHGetFolderPath('PERSONAL') .. 'My Games\\Gas Powered Games\\Supreme Commander Forged Alliance\\maps', '/maps')

-- The fall-back vault location. 
-- They don't work with accents or other foreign characters in usernames.
mount_contents(InitFileDir .. '\\..\\user\\My Games\\Gas Powered Games\\Supreme Commander Forged Alliance\\mods', '/mods')
mount_contents(InitFileDir .. '\\..\\user\\My Games\\Gas Powered Games\\Supreme Commander Forged Alliance\\maps', '/maps')
mount_dir(repository, '/')

-- The game data as provided by Steam / GPG.
mount_dir(fa_path .. '\\gamedata\\*.scd', '/')
mount_dir(fa_path, '/')

hook = {
    '/schook'
}

-- Various protocols for communication - unsure what these do.
protocols = {
    'http',
    'https',
    'mailto',
    'ventrilo',
    'teamspeak',
    'daap',
    'im',
}