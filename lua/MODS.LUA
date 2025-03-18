--[[
----------------------------------------------------------------------------------------------------
FAF Mods
----------------------------------------------------------------------------------------------------

FAF mods are special kinds of Supreme Commander mods in the FAF vault designed to work within the
FAF framework. They differ from regular Supreme Commander mods, i.e. those that directly replace
and hook original .scd files on startup. In a sense, FAF itself is a Supreme Commander mod that
coordinates the participation of other mods intended to be used inside of it once the game launches.
In this light, there are certain technical limitations and restrictions that are necessary to be
able to flexibly support the modding scene, but beyond these basic managerial requirements, they are
pretty much free to do whatever they like with the game and the FAF framework.

Several (but not all) of the restrictions include:
 * If you upload the mod to the vault, you MUST follow the rules:
   https://faforever.com/rules
   https://wiki.faforever.com/en/Development/Vault/Rules
    * In particular, make sure you have the right to distribute the content of the mod you are
      uploading. Require other mods when reasonable to avoid copying others' work.
 * Mods are not able to modify the lobby (since mods are only fully loaded after the game launches).
    * However, you can provide AI lobby options (see below).
 * All of a mod's files (except sounds) are mounted behind the mod directory to avoid naming
   conflicts or accidental file replacement. Outside of lua scripting (which can always hook
   original and FAF files), this means that only sound files can ever be replaced.
    * In practice, since the location a resource such as a texture points to can be changed by a lua
      file, this only really affects shaders, which are accessed by the game engine directly and
      cannot be modded under the FAF framework, and movies, which will not be in the correct
      directory to be read.
    * Sounds are still mounted directly to `/sounds` and can override files or cause conflicts.
    * Note that mods can still have all kinds of logical conflicts, such overriding the same
      function or blueprint.
 * Maps cannot be included in mods.


----------
Mod info file
----------

Each mod has a `mod_info.lua` file which contains various bits of info:

    -- Required name to use for this mod. This is what is displayed in the Lobby, after undergoing
    -- title-casing. Do NOT add version information here - keep this the exactly same when you
    -- update what you consider to be the same mod as the FAF client will uses this to auto-update
    -- mods.
    name = "Happy mod"

    -- Required integer version to use for this mod (please only increment) to indicate the most
    -- current version. Decimals are not supported. If updating the mod, make sure to change the
    -- `uid` (as the FAF client requires that) and leave the name exactly the same.
    version = 4

    -- Optional copyright info. Invisible in-game but shown in the FAF client.
    copyright = "Copyright © 2023, Someone"

    -- Optional text displayed in the mods manager and FAF client
    description = "A long description of happy mod and why it will make you happy"

    -- Required name(s) of author(s). Shows up as `"UNKNOWN"` if left blank. Will begin to be
    -- truncated in-game if over 20 characters. Make sure this reflects all contributors whose work
    -- is present.
    author = "Joe"

    -- Optional URL to anywhere author likes. Will show up in the mods manager if valid.
    url = "https://www.faforever.com"

    -- Optional URL to anywhere author likes. Will show up in the mods manager if valid.
    github = "https://github.com/FAForever"

    -- Uniquely identifies this mod. This defaults to the mod's name, but that's not a very safe way
    -- to keep mods differentiated. It's recommended to use a GUID, or Guaranteed Unique ID.
    -- Every new version of a mod should get a new GUID so that mods which rely on the old version
    -- can select it appropriately, and so that the FAF client can keep track.
    -- The following webpages allow you to generate a GUID online (as of June 2023)
    --   http://www.somacon.com/p113.php
    --   http://www.famkruithof.net/uuid/uuidgen
    uid = "B019FBEE-E411-11DB-AFAE-13D355D89593"

    -- Flag for whether to list this mod in the mods manager window, where the player can select it.
    -- An example where you would set it to false is library mod supplying functions, textures, and
    -- props for use by other mods. Those mods indicate that they require this one, and it is
    -- automatically loaded when they are. Note that unselectable mods can still be loaded.
    selectable = true

    -- Setting enabled to false causes a mod to never be loaded. Provides an easy way to disable a
    -- mod during development or for dummy mod packs that nest other mods inside for distribution.
    -- The default is true.
    enabled = true

    -- A simple form of preventing conflicting mods. If a mod has `exclusive`, then no other mod can
    -- be active. The default is false (please leave it like that). Note that this precludes the use
    -- of `conflicts`.
    exclusive = false

    -- Setting to true means this mod will only affect the user interface's Lua state. If this flag
    -- is false (the default), all players in a multiplayer game must have it in order for anyone to
    -- use it. If true, one player can have it active independently of the other players.
    ui_only = false

    -- Path of the icon to use for this mod in the mods manager window. The game defaults to
    -- `"/textures/ui/common/dialogs/mod-manager/generic-icon_bmp.dds"`. The FAF client cannot
    -- read `.dds` so please use `.png` or `.jpg` as both the game and client understand those.
    -- Note that this is unrelated to the `mod_icons.lua` file explained below.
    icon = "mod_icon.dds"

    -- Optionally indicates that this mod only works if another mod is also present. Does not affect
    -- mod loading order.
    -- It might be nice if you add a comment after each UID to denote the name of the mod so mere
    -- mortals can maintain your list :)
    requires = {
        "fec58b30-0036-4b9e-9995-fe2d6fe4c6e9",     -- Chris' Whacky Mod
        "18e391bc-67aa-49fb-8a5f-34efec2d1c2c",     -- Jeff's Cool Mod
        "61d2cb50-08ac-46ba-b261-3c3e3372aef0",     -- Ted's Dumb Mod
    }

    -- Optional table which will map the required UID's to friendly names so the user of the mod can
    -- determine what they are missing.
    requiresNames = {
        ["fec58b30-0036-4b9e-9995-fe2d6fe4c6e9"] = "Chris' Whacky Mod", -- v123
        ["18e391bc-67aa-49fb-8a5f-34efec2d1c2c"] = "Jeff's Cool Mod",
        ["61d2cb50-08ac-46ba-b261-3c3e3372aef0"] = "Ted's Dumb Mod",
    }
    
    -- Optionally indicates any other mods that this mod is known to conflict with; the game will
    -- refuse to enable both of them at the same time. You do not need to add old versions of your
    -- mod here (unless you'd like to be extra careful); the client determines mods with the same
    -- name to be the same mod and auto-updates them. Same format as `requires`.
    conflicts = {
    }

    -- Optional list of other mod UID's. If this mod happens to be active at the same time as any of
    -- the named other mods, it will be applied before them. Same format as `requires`.
    before = {
    }

    -- Optional list of other mod UID's. If this mod happens to be active at the same time as any of
    -- the named other mods, it will be applied after them. If you do not supply an `after` list,
    -- the `requires` list will be used in its place (if present). Same format as `requires`.
    after = {
    }


`location` also gets filled in before initialization (in case you want to use it for relative paths)
to the full path of the mod_info file and the directory containing it. It is also set afterwards as
well, so changing this has no affect.

There are a couple other fields that a mod can specify - it's best to leave them alone.


----------
Script Hooking
----------

A mod can also contain a `/hook` folder, which can contain script files matching the structure of
the game's main data folder. After any script file is loaded, each active mod is checked to see if
it defines a hook of the same name; if so, the file is concatenated to the end of the script before
it is run. This allows hooks to tweak or replace individual functions, classes, or other data while
still using the rest of the original code in the file.

The pattern for overriding a function called `Fn` is

    -- introduce new scope to gaurentee our local variables don't overwrite anything in another mod
    do
        local oldFn = Fn
        function Fn(arguments)
            -- preserve original behavior or another mod's changes
            oldFn(arguments)

            -- now we do our modifications
            -- ...
        end
    end

The pattern for overriding a class method called `Method` in a class called `Cls` is

    -- introduce new scope to gaurentee our local variables don't overwrite anything in another mod
    do
        local oldCls = Cls
        local oldMethod = oldCls.Method

        Cls = Class(oldCls) {
            Method = function(self, arguments)
                -- preserve original behavior or another mod's changes
                oldMethod(self, arguments)
                
                -- now we do our modifications
                -- ...
            end,
        }
    end


----------
Blueprints
----------

If an active sim mod has any .bp files, they will be automatically ran during blueprint loading to
register all blueprint definitions inside. The ID of the blueprint can be specified by the
`BlueprintId` field, but if absent, it will default to the file source (lowercased). For unit
blueprints, the source is shortened to the filename without the suffix (e.g. `"_unit.bp"`) in that
case. If you have multiple blueprints in a file, be sure to specify each `BlueprintId`.

If the blueprint ID ends up matching the ID of an existing blueprint, then the mod's blueprint will
replace the one currently there unless the `Merge = true` flag is set in the blueprint. This will
make the blueprint only add or override the fields it defines (including nested tables - the entire
subtable isn't replaced in this mode), leaving the rest intact (which could possibly also have been
changed by other mods).


----------
Balance changes
----------

There are two main ways to make balance changes.

First, a mod can merge or override blueprints as described above.

Second, a mod can hook the `/lua/system/Blueprints.lua` file and override the `ModBlueprints`
function to modify existing blueprints in an organized manner. Be sure to call the old function like
this, so that other mods' changes aren't overridden:

    -- introduce new scope to gaurentee our local variables don't overwrite anything in another mod
    do
        local oldModBlueprints = ModBlueprints
        function ModBlueprints(all_bps)
            -- preserve original behavior or another mod's changes
            oldModBlueprints(all_bps)

            -- now we do our modifications
            for id, unitBp in all_bps.Unit do
                -- some systematic change to each `unitBp`
            end
        end
    end


----------
Custom skins
----------

UI skins are pulled from the `/lua/skins/skins.lua#skins` table.
Until a proper system is in place, call this when your mods loads:

    import("/lua/skins/skins.lua").skins.<new skin name> = <skin table>

Take a look at the skins defined there for an idea of the fields you can set. When a field is not
found, it will simply use whatever field is in the `default` table.

You can proceed to cycle between faction skins in-game as usual with `Alt+Left` and `Alt+Right` (by
default). Note that new layouts are not supported, and even the existing ones do not work properly.


----------
AI Lobby Options
----------

The lobby will pull lobby options from any mod in the player's mod folder, regardless of if the mod
is active. It does this by importing all `/lua/AI/LobbyOptions/lobbyoptions.lua` files it finds in
every mod. After that, it pulls the `AIOpts` global table and merges all of the options it finds
under the AI Options header. The table should be a list of `ScenarioOption`s, each having the
following format:

    {
        -- required default index into the values table the option starts at
        default = 6,
        -- title of the option
        label = "<LOC aisettings_0119>AI Land Expansion Limit",
        -- optional tooltip body
        help = "<LOC aisettings_0120>Set the limit for the number of land expansions that each AI can have (will still be modified by the number of AIs).",
        -- required unique identifier for the option 
        key = 'LandExpansionsAllowed',
        -- optional flag for multiplayer options; if true, will not show up in singleplayer
        mponly = false,
        -- String formatter used if any values don't have a `.text` key; the value is passed as a
        -- formatting option to this format specifier. Required when non-`ScenarioOptionValue`s
        -- are used.
        value_text = "%s",
        -- optional string formatter used for the tooltip body in the same manner as above
        value_help = "<LOC aisettings_0123>%s Land Expansions Allowed",
        -- list of values or `ScenarioOptionValue`s
        values = {
            -- a `ScenarioOptionValue` has the following format:
            {
                -- required display name for the value
                text = "<LOC aisettings_0121>None",
                -- optional tooltip body
                help = "<LOC aisettings_0122>No Land Expansions Allowed",
                -- the actual value that will be used if this is selected
                key = '0',
            },
            '1', '2', '3', '4', '5', '6', '7', '8',
            {
                text = "<LOC aisettings_0131>Unlimited",
                help = "<LOC aisettings_0132>Unlimited Land Expansions Allowed",
                key = '99999',
            },
        },
    },


----------
Strategic Icon Replacement
----------

A UI mod can contain a `mod_icons.lua` file to specify strategic icons to replace for particular
units. This is one of the few times a UI mod will be able to have an effect on things in the
simulation (blueprints, in this case), and as such it is done in a controlled manner (for example,
the environment of the file is heavily restricted, and only available inside the called function).

Either a function `ScriptedIconAssignments` or a table `UnitIconAssignments` can be define (or both;
the script is applied before the manual unit icon assignment table is). The table is a list of
units-icons pairs to replace in the form `{BlueprintID = "id", IconSet = "filename"}` (see below).
If defined, the function returns a table with the same format.

    ---@param units UnitBlueprint[] reference copy of the unit blueprints (modifying has no affect)
    ---@param projectiles ProjectileBlueprint[] for reference only; projectile strategic icons cannot be replaced
    ---@param icons FileName[] list of icons found in your mod's `/custom-strategic-icons` folder
    ---@return BlueprintIconAssignment[] list of 
    function ScriptedIconAssignments(units, projectiles, icons)
    --  ...
    --  return UnitIconAssignment
    end

    ---@type BlueprintIconAssignment[]
    UnitIconAssignments = {
    --  {
    --      BlueprintId = "", -- blueprint id to target
    --      IconSet = "",     -- filename to set `StrategicIconName` to
    --      TypeId = "",      -- unused
    --  },
    --  ...
    }


----------
Mod ordering
----------

It often matters in what order mods take effect. For example, perhaps two mods both adjust the
tuning of some units, and they have a few in common. The mod that is applied last will have the last
say in what happens to that unit.

Mods are applied in an arbitrary order. However, you can get more control by listing other mods in
the `before` and `after` sections of your mod info file. Requiring other mods does not affect order,
only presence.

If any mods specify an inconsistent ordering (e.g. they both ask to be before the other or form a
cycle), the mod loader will abort the dependency system entirely (including the dependencies of
other well-specified mods that don't have any problems) and all active mods will be loaded in an
arbitrary ordering with a warning logged. No mods are disabled when this happens.


----------
Mod initialization
----------

There are three general sorts of mods:

    Front end mods   [`mountpoints` set] - used internally by FAF, applied before the game launches
    Game mods        [`ui_only` not set] - all players in the game will have the same ones
    UI mods          [`ui_only` flag set] - each user can have a different set applied to their UI

The mod manager (whether run from the front end or from the lobby) loads this module to get a list
of all mods in the system, so the user can select and deselect mods. This selection is stored in the
player's preferences.

When launching a game, the lobby scripts call this module to get the list of active Game mods to
pass into the simulation (in `gameinfo.Options.Mods`). The simulation just uses whatever list it was
given.

The ingame UI calls this module to get a list of ingame UI mods to apply directly from preferences.

----------------------------------------------------------------------------------------------------
]]


---@alias ModType
---| "BLACKLISTED"
---| "GAME"
---| "LOCAL"
---| "NO_DEPENDENCY"
---| "UI"

---@alias ModSort ModType | 'X'


-- we should really stick in an option for the `/custom-strategic-icons` folder here

---@class ModInfo
---@field location FileName  defaults to `Dirname(filename)`
---@field name UnlocalizedString        defaults to `filename`
---@field description UnlocalizedString defaults to `"<LOC uimod_0006>(No description)"`
---@field author UnlocalizedString      defaults to `''`; if left this way, appears as `"UNKNOWN"`
---@field copyright string              unused, defaults to `''`
---@field exclusive boolean  defaults to `false`
---@field icon FileName      defaults to `'/textures/ui/common/dialogs/mod-manager/generic-icon_bmp.dds'`
---@field selectable boolean defaults to `true`
---@field hookdir FileName   defaults to `'/hook'`
---@field shadowdir FileName legacy field, defaults to `'/shadow'`
---@field uid string         defaults to `filename`
---@field url? string        must be a valid link if present
---@field github? string     must be a valid link if present
---@field version? number    must be an integer
---@field ui_only? boolean
---@field enabled? boolean
---@field requires? string[]   UID list of mods that this mod requires to be also present
---@field conflicts? string[]  UID list of mods that the game will refuse to launch with
---@field before? string[]     UID list of mods that this mod will be applied before
---@field after? string[]      UID list of mods this this mod will be applied after; defaults to `requires` if absent
---@field requiresNames? table<string, string> Optional UID-to-name map of required mods
---
---@field title? UnlocalizedString   used by the mods manager (title-cased name and version)
---@field type? ModType              used by the mods manager
---@field sort? ModSort              used by the mods manager (nearly the same as `type`)
---@field status? LocalizedString    used by the mods manager (localized version of `type`)
---@field tags? table                used by the mods manager
---
---@field _faf_modname? "faf"    frontend mod field, if present in a FAF vault mod, must be `"faf"`
---@field mountpoints? table     frontend mod field, must be absent for a FAF vault mod

---@alias uidSet table<string, true>


local SetUtils = import("/lua/system/setutils.lua")

-- Table of all mods found on disk, indexed by id
---@type table<string, ModInfo>?
local _mod_cache = nil


--- Sets the list of active mods requested by the user from the mod manager.
--- `nil` means do nothing (happens when `cancel` is selected from mod manager)
---@param selectedMods? uidSet set of mod UID's
function SetSelectedMods(selectedMods)
    if selectedMods then
        LOG("MOD LIST SET TO:")
        for uid in selectedMods do
            LOG("\t" .. tostring(_mod_cache[uid].name) .. "\t(" .. uid .. ")")
        end

        SetPreference('active_mods', selectedMods)
        UpdateUIMods()
    end
end

--- Returns the set of all sim mod UID's a player has installed
---@return uidSet #set of mod UID's
function GetLocallyAvailableMods()
    local result = {}
    for _, mod in AllMods() do
        if not mod.ui_only then
            result[mod.uid] = true
        end
    end
    return result
end

--- Gets the list of selected mods (both sim and UI) from the preferences and checks if they still
--- exist on disk
---@return uidSet #set of mod UID's
function GetSelectedMods()
    local modsFromGamePrefs = GetPreference('active_mods') or {}
    local modsFromDisk = {}
    for _, moddata in AllMods() do
        modsFromDisk[moddata.uid] = true
    end
    for modid in modsFromGamePrefs do
        if not modsFromDisk[modid] then
            SPEW('Mod ID='..modid..' is selected as active mod, but missing on Disk!')
            modsFromGamePrefs[modid] = nil
            SetPreference('active_mods', modsFromGamePrefs)
        end
    end
    return modsFromGamePrefs
end

--- Returns currently selected sim mods (active mods without `ui_only` set to true)
---@return uidSet #set of mod UID's
---@see GetSimMods(mods) # for a version that tries to sort by dependency
function GetSelectedSimMods()
    local allMods = AllMods()
    return SetUtils.PredicateFilter(GetSelectedMods(), function(uid)
        return not allMods[uid].ui_only
    end)
end

--- Returns currently selected UI mods (active mods with `ui_only` set to true)
---@return uidSet #set of mod UID's
---@see GetUiMods(mods) # for a version that tries to sort by dependency
function GetSelectedUIMods()
    local allMods = AllMods()
    return SetUtils.PredicateFilter(GetSelectedMods(), function(uid)
        return allMods[uid].ui_only
    end)
end

--- Loads a mod from `filename` and returns its `ModInfo` table with default values set if no
--- problems occur
---@param filename FileName
---@return ModInfo | nil
local function LoadModInfo(filename)
    local location = Dirname(filename)
    -- fill in some defaults to start with...
    local env = {
        location = location,
        name = filename,
        description = "<LOC uimod_0006>(No description)",
        author = '',
        copyright = '',
        exclusive = false,
        icon = '/textures/ui/common/dialogs/mod-manager/generic-icon_bmp.dds',
        selectable = true,
        hookdir = '/hook',      -- specify the name of the hook sub-directory
        shadowdir = '/shadow',  -- legacy
        uid = filename, -- default uid to name, should be a unique id
    }

    local ok, result = pcall(doscript, filename, env)
    if not ok then
        WARN("Problem loading " .. filename .. ":\n" .. result)
        return nil
    end

    env.location = location -- make sure the mod didn't change this
    return env
end


--- Clears `_mod_cache` to pick up any changes on disk
function ClearCache()
    _mod_cache = nil
end


--- Returns a map of all mods found on disk
---@return table<string, ModInfo> #keys are UID's
function AllMods()
    if not _mod_cache then
        local cache = {}
        for _, file in DiskFindFiles('/mods', '*mod_info.lua') do
            local mod = LoadModInfo(file)
            -- why can't a mod be named `Hotstats`?
            if mod and mod.enabled ~= false and mod.name ~= "Hotstats" then
                cache[mod.uid] = mod
            end
        end
        _mod_cache = cache
    end
    return _mod_cache
end

--- Returns a map of all mods found on disk with the `selectable` flag set
---@return table<string, ModInfo> #keys are UID's
function AllSelectableMods()
    local selectableMods = {}
    for uid, mod in AllMods() do
        if mod.selectable then
            selectableMods[uid] = mod
        end
    end
    return selectableMods
end

--- Topological sort the mods using before/after lists  
--- log a warning and return `nil` in case of a cycle
---@param mods_to_sort table<string, ModInfo> keys are UID's
---@return ModInfo[] | nil
local function ModTopSort(mods_to_sort)
    ---@type table<string, string[]>
    local required_for = {}
    for uid in mods_to_sort do
        required_for[uid] = {}
    end

    for uid in mods_to_sort do
        local mod = _mod_cache[uid]
        local before_mods = mod.before
        local after_mods = mod.after

        if before_mods then
            for _, before_uid in before_mods do
                if mods_to_sort[before_uid] ~= nil then
                    table.insert(required_for[uid], before_uid)
                end
            end
        end

        if after_mods then
            for _, after_uid in after_mods do
                if mods_to_sort[after_uid] ~= nil then
                    table.insert(required_for[after_uid], uid)
                end
            end
        end
    end

    local result = {}
    local has_cycle = {}
    --- Returns if an cycle is detected in the graph node
    ---@param uid string
    ---@return boolean 
    local function HasCycle(uid)
        if has_cycle[uid] ~= nil then
            return has_cycle[uid]
        end

        has_cycle[uid] = true -- only tentatively
        for _, child_uid in required_for[uid] do
            if HasCycle(child_uid) then return true end
        end
        has_cycle[uid] = false

        table.insert(result, mods_to_sort[uid])
        return false
    end

    -- traverse the directed graph and look for cycles
    for uid in mods_to_sort do
        if HasCycle(uid) then
            WARN('Inconsistent mod order lists, load order will be arbitrary')
            return
        end
    end

    return table.reverse(result)
end

--- Gets a list of mods based on a filter (optionally over a selection) and sorts them topologically
--- based on dependencies, if possible.
---@param filter fun(mod: ModInfo): boolean
---@param selected? uidSet set of mod UID's to filter from; defaults to `GetSelectedMods()`
---@return ModInfo[]
local function GetActiveModsFiltered(filter, selected)
    if not selected then
        selected = GetSelectedMods()
    end

    local all_mods = AllMods()
    local filtered = {}

    for uid, mod in all_mods do
        if selected[uid] and filter(mod) then
            filtered[uid] = mod
        end
    end

    local active_mods = ModTopSort(filtered)
    if active_mods == nil then
        active_mods = {}
        for _, mod in filtered do
            table.insert(active_mods, mod)
        end
    end

    return active_mods
end

--- Returns a list of UI mods (mods with `ui_only` set to true) that is sorted topologically by mod
--- dependency, if possible.
---@param mods? uidSet set of mod UID's to filter from; defaults to `GetSelectedMods()`
---@return ModInfo[]
---@see GetSelectedUIMods() # for a version that doesn't try to sort by dependency
function GetUiMods(mods)
    return GetActiveModsFiltered(function(m) return m.ui_only end, mods)
end

--- Returns a list of sim mods (mods without `ui_only` set to true) that is sorted topologically by
--- mod dependency, if possible.
---@param mods? uidSet set of mod UID's to filter from; defaults to `GetSelectedMods()`
---@return ModInfo[]
---@see GetSelectedSimMods() # for a version that doesn't try to sort by dependency
function GetGameMods(mods)
    return GetActiveModsFiltered(function(m) return not m.ui_only end, mods)
end

--- If `scenario` is a campaign type, returns only the FAF campaign mod
--- (`6AAFE20A-E851-11DB-B8BE-ECC755D89593`) or an empty list if it is not enabled.
--- Otherwise, returns `GetGameMods()`.
---@param scenario UIScenarioInfo
---@return uidSet #set of mod UID's
function GetCampaignMods(scenario)
    local r
    if scenario.type == 'campaign' then
        r = GetGameMods{ ['6AAFE20A-E851-11DB-B8BE-ECC755D89593'] = true }
    else
        r = GetGameMods()
    end
    return r
end

--- Given a UID of a mod, return a table containing:  
---  `requires`: set of installed UID's that this mod requires  
---  `missing`: set of UID's that this mod requires but aren't installed  
---  `conflicts`: set of installed UID's that this mod conflicts with (or conflict with this mod)
---@param uid string
---@return {requires: uidSet, missing: uidSet, conflicts: uidSet}
function GetDependencies(uid)
    local allMods = AllMods()
    local depRequires = {}
    local depMissing = {}
    local depConflicts = {}

    local function RecurseDependencies(uid)
        local mod = allMods[uid]

        -- check if this mod lists known conflicts with other mods
        if mod.conflicts then
            for _, conflict in mod.conflicts do
                if allMods[conflict] then
                    depConflicts[conflict] = true
                end
            end
        end

        -- exclusive mods conflict with everything
        if mod.exclusive then
            for con in allMods do
                depConflicts[con] = true
            end
        end

        -- check if any other mods list this mod as a conflict
        for id in allMods do
            if id == uid then continue end
            local otherMod = allMods[id]
            if otherMod.conflicts then
                for _, conflict in otherMod.conflicts do
                    if uid == conflict then
                        depConflicts[id] = true
                        break -- don't need to continue as we're just looking for this mod
                    end
                end
            end
        end

        -- check for all mods required by this mod, and then check those required dependencies
        if mod.requires then
            for _, required in mod.requires do
                if allMods[required] then
                    depRequires[required] = true
                    RecurseDependencies(required)
                else
                    depMissing[required] = true
                end
            end
        end
    end

    if allMods[uid] then
        RecurseDependencies(uid)
    end

    if table.empty(depRequires) then depRequires = nil end
    if table.empty(depMissing) then depMissing = nil end
    if table.empty(depConflicts) then depConflicts = nil end
    return {
        requires = depRequires,
        missing = depMissing,
        conflicts = depConflicts,
    }
end

--- Update `__active_mods` from `GetUiMods`
function UpdateUIMods()
    __active_mods = {}
    for _, mod in ipairs(GetUiMods()) do
        table.insert(__active_mods, mod)
    end
end
