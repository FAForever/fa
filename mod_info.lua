--******************************************************************************************************
--** Copyright (c) 2024 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

-- You can learn more about how the server parses this type of file here:
-- - https://github.com/FAForever/faf-java-commons/blob/develop/faf-commons-data%2Fsrc%2Fmain%2Fjava%2Fcom%2Ffaforever%2Fcommons%2Fmod%2FModReader.java
-- 
-- You can learn more about how the game parses this type of file here:
-- - https://github.com/FAForever/fa/blob/deploy/fafdevelop/lua/MODS.LUA

name = "Forged Alliance Forever"
version = 3824          -- needs to be an integer as it is parsed as a short (16 bit integer)
_faf_modname='faf'
copyright = "Forged Alliance Forever Community"
description = "Forged Alliance Forever extends Forged Alliance, bringing new patches, game modes, units, ladder, and much more!"
author = "Forged Alliance Forever Community"
url = "https://www.faforever.com"
uid = "dcd9a5e5-5444-4266-a016-edfaff528268"
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
    units = '/units',
    props = '/props'
}
hooks = {
    '/schook'
}
