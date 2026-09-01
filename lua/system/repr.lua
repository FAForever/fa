---@declare-global

--******************************************************************************************************
-- MIT LICENSE
--
-- Copyright (c) 2022 Enrique García Cota
--
-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be included
-- in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
-- OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--******************************************************************************************************

-- upvalue scope for performance
local DebugAllocatedSize = debug.allocatedsize
local DebugGetInfo = debug.getinfo
local MathFloor = math.floor
local StringFormat = string.format
local StringGsub = string.gsub
local StringMatch = string.match
local StringRep = string.rep
local StringSub = string.sub
local TableEmpty = table.empty
local TableSort = table.sort

local getmetatable = getmetatable
local next = next
local rawget = rawget
local tostring = tostring
local type = type

local DiskToLocal = DiskToLocal

---@class DebugInspector
---@field buf table
---@field depth integer
---@field level integer
---@field ids table<type, integer> | table<any, integer|string>
---@field newline string
---@field meta boolean
---@field indent string
local Inspector = {}
local Inspector_mt = { __index = Inspector }

---@class DebugInspectOptions
---@field depth? number
---@field newline? string
---@field indent? string
---@field meta? boolean

---@param t table
---@return function
---@return table
---@return nil
local function rawpairs(t)
    return next, t, nil
end

---@param str string
---@return string
local function smartQuote(str)
    if StringMatch(str, '"') and not StringMatch(str, "'") then
        return "'" .. str .. "'"
    end
    return '"' .. StringGsub(str, '"', '\\"') .. '"'
end

---@type table<string, boolean>
local luaKeywords = {
    ['and'] = true,
    ['break'] = true,
    ['do'] = true,
    ['else'] = true,
    ['elseif'] = true,
    ['end'] = true,
    ['false'] = true,
    ['for'] = true,
    ['function'] = true,
    ['goto'] = true,
    ['if'] = true,
    ['in'] = true,
    ['local'] = true,
    ['nil'] = true,
    ['not'] = true,
    ['or'] = true,
    ['repeat'] = true,
    ['return'] = true,
    ['then'] = true,
    ['true'] = true,
    ['until'] = true,
    ['while'] = true,
}

---@param str any
---@return boolean
local function isIdentifier(str)
    return type(str) == "string" and
---@diagnostic disable-next-line: undefined-field
        not not str:match("^[_%a][_%a%d]*$") and
        not luaKeywords[str]
end

---@param k any
---@param sequenceLength integer
---@return boolean
local function isSequenceKey(k, sequenceLength)
    return type(k) == "number" and
        MathFloor(k) == k and
        1 <= (k) and
        k <= sequenceLength
end

---@type table<string, number>
local defaultTypeOrders = {
    ['number'] = 1, ['boolean'] = 2, ['string'] = 3, ['table'] = 4,
    ['function'] = 5, ['userdata'] = 6, ['thread'] = 7,
}

---@param a any
---@param b any
---@return boolean
local function sortKeys(a, b)
    local ta, tb = type(a), type(b)


    if ta == tb and (ta == 'string' or ta == 'number') then
        return (a) < (b)
    end

    local dta = defaultTypeOrders[ta] or 100
    local dtb = defaultTypeOrders[tb] or 100


    return dta == dtb and ta < tb or dta < dtb
end

---@param t table
---@return table
---@return integer
---@return integer
local function getKeys(t)

    local seqLen = 1
    while rawget(t, seqLen) ~= nil do
        seqLen = seqLen + 1
    end
    seqLen = seqLen - 1

    local keys, keysLen = {}, 0
    for k in rawpairs(t) do
        if not isSequenceKey(k, seqLen) then
            keysLen = keysLen + 1
            keys[keysLen] = k
        end
    end
    TableSort(keys, sortKeys)
    return keys, keysLen, seqLen
end

---@param buf table
---@param str string
local function puts(buf, str)
    buf.n = buf.n + 1
    buf[buf.n] = str
end

---@param inspector DebugInspector
local function tabify(inspector)
    puts(inspector.buf, inspector.newline .. StringRep(inspector.indent, inspector.level))
end

---@param v any
---@return string
function Inspector:getId(v)
    local id = self.ids[v]
    local ids = self.ids
    if not id then
        local tv = type(v)
        id = (ids[tv] or 0) + 1
        ids[tv] = id
        if tv == "function" then
            local info = DebugGetInfo(v, "S")
            id = StringFormat("%s %s(%d)", id, DiskToLocal(StringSub(info.source, 2)--[[@as FileName]]), info.linedefined)
        end
        ids[v] = id
    end
    return tostring(id)
end

local VectorMeta = getmetatable(Vector2(0, 0))
local LazyVarMeta = import('/lua/lazyvar.lua').LazyVarMetaTable

-- Converts the `__name` field added to engine classes in `classes.lua` to a friendlier name
local CClassNameToString = {
    -- moho classes that share the same name across user and sim

    CPrefetchSet = "CPrefetchSet",
    EntityCategory = "Entity Category",
    -- sound_methods = "Sound", -- In moho but has no fields, including `__name`

    --Sim moho classes

    aibrain_methods = "AIBrain",
    aipersonality_methods = "AIPersonality",
    platoon_methods = "Platoon",

    ScriptTask_Methods = "Script Task",

    IEffect = "IEffect",
    CDecalHandle = "Decal",

    entity_methods = "Entity",

    unit_methods = "Unit",
    navigator_methods = "Navigator",
    blip_methods = "Blip",
    shield_methods = "Shield",
    weapon_methods = "Weapon",
    projectile_methods = "Projectile",
    CollisionBeamEntity = "Collision Beam",
    -- EconomyEvent = "EconomyEvent", -- In moho but has no fields, including `__name`

    prop_methods = "Prop",
    MotorFallDown = "MotorFallDown",

    manipulator_methods = "Manipulator",
    AimManipulator = "AimManipulator",
    RotateManipulator = "RotateManipulator",
    StorageManipulator = "StorageManipulator",
    CollisionManipulator = "CollisionManipulator",
    SlaveManipulator = "SlaveManipulator",
    ThrustManipulator = "ThrustManipulator",
    BoneEntityManipulator = "BoneEntityManipulator",
    SlideManipulator = "SlideManipulator",
    BuilderArmManipulator = "BuilderArmManipulator",
    AnimationManipulator = "AnimationManipulator",
    FootPlantManipulator = "FootPlantManipulator",

    CDamage = "CDamage",
    CAiAttackerImpl_methods = "CAiAttackerImpl",

    --User moho classes

    cursor_methods = "Cursor",

    control_methods = "Control",
    scrollbar_methods = "Scrollbar",
    bitmap_methods = "Bitmap",
    dragger_methods = "Dragger",
    item_list_methods = "ItemList",
    movie_methods = "Movie",
    border_methods = "Border",
    text_methods = "Text",
    edit_methods = "Edit",
    group_methods = "Group",
    frame_methods = "Frame",

    lobby_methods = "Lobby Communications",
    discovery_service_methods = "Discovery Service",
    ui_map_preview_methods = "Map Preview",
    WldUIProvider_methods = "WldUIProvider",

    UIWorldView = "WorldView",
    userDecal_methods = "UserDecal",
    world_mesh_methods = "WorldMesh",

    mesh_methods = "mesh_methods",
    histogram_methods = "Histogram",
    PathDebugger_methods = "PathDebugger",

    -- Shared class implemented in Lua
    Trashbag = "Trashbag",
}

---@param v table | fa-class | fa-class-state
local function objectToString(v)
    local mt = getmetatable(v)
    if rawget(v, "__State") then
        return StringFormat("%s (State %s)", tostring(v), tostring(v.__StateIdentifier))
    elseif mt == VectorMeta then
        return StringFormat("%s (%s)", tostring(v), "Vector")
    elseif mt == LazyVarMeta then
        return StringFormat("%s (%s)", tostring(v), "LazyVar")
    else
        local friendlyName = CClassNameToString[mt.__name]
        if friendlyName then
            return StringFormat("%s (%s)", tostring(v), friendlyName)
        else
            return tostring(v)
        end
    end
end

---@param v any
function Inspector:putValue(v)
    local buf = self.buf
    local tv = type(v)
    if tv == 'string' then
        puts(buf, smartQuote(v))
    elseif tv == 'number' or tv == 'boolean' or tv == 'nil' or
        tv == 'cdata' or tv == 'ctype' then
        puts(buf, tostring(v))
    elseif tv == 'table' and not self.ids[v] then
        local t = v

        if self.level >= self.depth then
            puts(buf, StringFormat("{...} -- %s (%g bytes)", objectToString(t), DebugAllocatedSize(t)))
        else
            local keys, keysLen, seqLen = getKeys(t)

            puts(buf, StringFormat("{ -- %s (%d bytes)", objectToString(t), DebugAllocatedSize(t)))
            self.level = self.level + 1

            for i = 1, seqLen + keysLen do
                if i > 1 then puts(buf, ',') end
                if i <= seqLen then
                    tabify(self)
                    self:putValue(t[i])
                else
                    local k = keys[i - seqLen]
                    tabify(self)
                    if isIdentifier(k) then
                        puts(buf, k)
                    else
                        puts(buf, "[")
                        self:putValue(k)
                        puts(buf, "]")
                    end
                    puts(buf, ' = ')
                    if k == "__index" and tostring(t[k]) == tostring(t) then
                        puts(buf, StringFormat("{...} -- %s (%g bytes)", 'table (self): ' .. string.sub(tostring(v), 8), DebugAllocatedSize(t)))
                    else
                        self:putValue(t[k])
                    end
                end
            end

            local mt
            local checkMeta
            if self.meta then
                mt = getmetatable(t)
                checkMeta = type(mt) == 'table' and not TableEmpty(mt)
            end

            if checkMeta then
                if seqLen + keysLen > 0 then puts(buf, ',') end
                tabify(self)
                puts(buf, '<metatable> = ')
                self:putValue(mt)
            end

            self.level = self.level - 1

            if keysLen > 0 or checkMeta then
                tabify(self)
            elseif seqLen > 0 then
                puts(buf, ' ')
            end

            puts(buf, '}')
        end

    else
        puts(buf, StringFormat('<%s %s>', tv, self:getId(v)))
    end
end

--- Debugging code to inspect a table. This can be an extensive operation, at no point should this code run outside of a debugging session!
---@param root any
---@param options? DebugInspectOptions
---@return string
local function inspect(root, options)
    options = options or {}

    local depth = options.depth or 3
    local newline = options.newline or '\n'
    local indent = options.indent or '  '
    local meta = options.meta or false

    ---@type DebugInspector
    local inspector = setmetatable({
        buf = { n = 0 },
        ids = {},
        depth = depth,
        meta = meta,
        level = 0,
        newline = newline,
        indent = indent,
    }, Inspector_mt)

    inspector:putValue(root)

    return table.concat(inspector.buf)
end

-- backwards compatibility for mods

repr = inspect
repru = inspect
reprs = inspect

---@param root any
---@param options? DebugInspectOptions
---@return string
reprsl = function(root, options)
    local str = inspect(root, options)
    LOG(str)
    return str
end
