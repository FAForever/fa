-- Forged Alliance Forever mod_info.lua file
--
-- Documentation for the extended FAF mod_info.lua format can be found here:
-- https://github.com/FAForever/fa/wiki/mod_info.lua-documentation
name = "Forged Alliance Forever"
version = 3667
_faf_modname='balancetesting'
copyright = "Forged Alliance Forever Community"
description = "Forged Alliance Forever extends Forged Alliance, bringing new patches, game modes, units, ladder, and much more!"
author = "Forged Alliance Forever Community"
url = "http://www.faforever.com"
uid = "dcd9a5e5-5444-4266-a016-ccbbff528268"
selectable = false
exclusive = false
ui_only = false
conflicts = {}
mountpoints = {
    etc = "/etc",
    env = "/env",
    loc = '/loc',
    schook = '/schook',
    effects = '/effects',
    lua = '/lua',
    meshes = '/meshes',
    modules = '/modules',
    projectiles = '/projectiles',
    textures = '/textures',
    units = '/units'
}
hooks = {
    '/schook',
}
