--[[ ------------------------------------------------------------------------------------------------------------------
Mods

All mods must be in subdirectories somewhere under /mods. Each mod has a
mod_info.lua file which contains various bits of info:

    name = "Happy mod"                          # Name to use for this mod
    version = 123                               # Version number to use for this mod
    copyright = "Copyright © 2006, Someone"     # Optional copyright info
    description = "A long description of happy mod and why it will make you happy"
    author = "Joe"                              # Optional author info
    url = "http://www.gaspoweredgames.com"      # Optional URL to anywhere author likes

    uid = B019FBEE-E411-11DB-AFAE-13D355D89593
        Uniquely identify this mod. This defaults to the mods name, but that's
        not a very safe way to keep mods differentiated. I'd recommend using a GUID
        or Guaranteed Unique ID. Also, every new version of a mod should get a new
        GUID so that mods which rely on the old version can select it appropriately.
        This following webpages allow you to generate a guaranteed unique ID on line (as of 4/6/07)
        http://www.somacon.com/p113.php
        http://www.famkruithof.net/uuid/uuidgen

    selectable = true
        Flag for whether to list this mod in the mod manager window, where the
        player can select it. Examples where you would set it to false are:

        1.  A mod containing just custom maps, along with textures and props used
            on those maps. The mod will be automatically enabled when one of its
            maps is used.

        2.  A mod supplying textures and props for use by other mods. Those mods
            indicate that they require this one, and it is automatically enabled
            when they are.

    enabled = true
        Setting enabled to false causes a mod to never be loaded. Provides
        an easy way to disable a mod during development. The default is true.

    exclusive = false
        A simple form of preventing conflicting mods. Only one 'exclusive' mod
        can be active at a time. The default is false. Note that this precludes
        the use of requires/conflicts

    ui_only = false
        Set true to indicate that this mod only affects the user interface. If
        this flag is false (the default), all players in a multiplayer game must
        have it in order for anyone to use it. If true, one player can have it
        active independently of the other players. (Games on GPGNet may restrict
        this further.)

        TODO: If ui_only is set true, the mod's files should not even be accessible
        from within the sim, but we need the VFS stuff implemented properly first.

    icon = "mod_icon.dds"
        Name of icon to use for this mod in the mod selection window. The default is
        mod_icon.dds in the same directory as the mod_info.lua file.

    requires = {
        # Optionally indicates that this mod only works if another mod is also present.
        # It might be nice if you add a comment after each uid to denote the name of the mod
        # so mere mortals can maintain your list :)
        "fec58b30-0036-4b9e-9995-fe2d6fe4c6e9",     -- Chris' Whacky Mod
        "18e391bc-67aa-49fb-8a5f-34efec2d1c2c",     -- Jeffs Cool Mod
        "61d2cb50-08ac-46ba-b261-3c3e3372aef0",     -- Teds Dumb Mod
    }

    conflicts = {
        Indicate any other mods that this mod is known to conflict with; the game
        will refuse to enable both of them at the same time.
        Same format as 'requires'.
    }

    before = {
        List of other mod names. If this mod happens to be active at the same time
        as any of the named other mods, it will be applied before them.
        Same format as 'requires'.
    }

    after = {
        List of other mod names. If this mod happens to be active at the same time
        as any of the named other mods, it will be applied after them. If you do
        not supply an 'after' list, the 'requires' list will be used in its place.
        Same format as 'requires'.
    }

    requiresNames = {
        # an optional table which will map the required uids to friendly names so the user of the mod can determine what they are missing
        ["fec58b30-0036-4b9e-9995-fe2d6fe4c6e9"] = "Chris' Whacky Mod v123",
        ["18e391bc-67aa-49fb-8a5f-34efec2d1c2c"] = "Jeff's Cool Mod",
        ["61d2cb50-08ac-46ba-b261-3c3e3372aef0"] = "Ted's Dumb Mod",
    }

Fields 'id' and 'location' also get filled in during initialization, to the full
path to the mod_info file and the directory containing it.



Adding extra maps

   Any extra maps in a mod will automatically show up on the available maps list on
   the single- and multi-player skirmish screen, as long as they have an appropriate
   Configuration set up.

   If you select a map from a mod for play, that mod (and any other mods it depends on)
   will automatically be active for that session. This allows you to define custom
   units or props just for a particular set of maps.


 Adding custom units

   If an active mod has any .bp files defining units, they will be automatically
   included during blueprint loading.

   If a mod contains a blueprint matching the ID of an existing unit (e.g. uel0001)
   then the mod's blueprint will replace the original. If the "Merge=true" flag is
   set in the mod blueprint, it will be merged with the original can can override
   some fields while leaving others intact.


 Balance changes

   There are two ways to make large-scale balance changes.

   First, you can define one or more .bp files with "Merge=true", that override
   particular fields for many units. This is how the campaign balance mod works.

   Second, you can define a function <TODO>, which is called on each blueprint
   as it is loaded. This function can then manipulate the blueprint in arbitrary
   ways.

   First, a mod can simply add a new blueprint file that defines a new blueprint.

   Second, a mod can contain a blueprint with the same ID as an existing blueprint.
   In this case it will completely override the original blueprint. Note that in
   order to replace an original non-unit blueprint, the mod must set the "BlueprintId"
   field to name the blueprint to be replaced. Otherwise the BlueprintId is defaulted
   off the source file name. (Units don't have this problem because the BlueprintId is
   shortened and doesn't include the original path).

   Finally, a mod can define a ModBlueprints() function which manipulates the
   original_blueprints table in arbitrary ways. [How/when exactly is this done?]


 Custom skins

   A mod can add a ??? file to indicate that it contains a custom skin. The skin
   will automatically be made available on the list of available skins.
   TODO: need help from CBlackwell to work out and document custom skin system.


 Other changes

   A mod can contain a 'shadow' folder, which contains files matching the names
   and directory structure of the game's top-level folder. These files will REPLACE
   the game's files on all lookups. You can use this mechanism to replace entire
   textures, audio files, scripts, blueprints, or any other game data. Note that
   when a game file is shadowed, the original file becomes completely inaccessible.
   This is ok for textures and such but usually not what you want for scripts.

   A mod can also contain a 'hook' folder, which contains files named the same way,
   matching the structure of the game's main data folder. After any script file is
   loaded, we check in the active mods to see if they define a hook of the same
   name; if so, we run the hook in the same environment as the original script. This
   allows hooks to tweak or replace individual functions, classes, or other data
   while still using the original code.


 Mod ordering

   It often matters in what order mods take effect. For example, perhaps two mods
   both adjust the tuning of some units, and they have a few in common. The mod
   that is applied last will take precedence.

   By default, mods are applied in simple alphabetical order. However, you can
   get more control by listing other mods in the 'before' and 'after' sections.

   If two mods specify an inconsistent ordering (e.g. they both ask to be before
   the other), SC will choose an arbitrary ordering and log a warning, but both
   mods will still be active.


Mod initialization issues

    There are three general sorts of mods:
        Front end mods [do not work at the moment]
        Ingame UI mods    [ui_only flag set]
        Game mods         [all others]

    The mod manager (whether run from the front end or from the lobby) loads this module
    to get a list of all mods in the system, so the user can select and deselect mods.
    Those changes are stored in the player's preferences.

    When launching a game, the lobby scripts call this module to get the list of active
    Game mods to pass into the simulation (in gameinfo.Options.Mods). The simulation just
    uses whatever list it was given.

    The ingame UI calls this module to get a list of ingame UI mods to apply directly from
    preferences.
'
-------------------------------------------------------------------------------------------------------------------- ]]

local SetUtils = import('/lua/system/setutils.lua')

-- Table of all mods found on disk, indexed by id
local _mod_cache = nil


-- Set the list of active mods requested by the user from the mod manager.
-- nil means do nothing (happens when cancel selected from mod manager)
function SetSelectedMods(s)
    if s then
        LOG("MOD LIST SET TO:")
        for uid,v in s do
            LOG("\t" .. tostring(_mod_cache[uid].name) .. "\t(" .. uid .. ")")
        end

        SetPreference('active_mods', s)
        UpdateUIMods()
    end
end

function GetLocallyAvailableMods()
    local result = {}
    for k,mod in AllMods() do
        if not mod.ui_only then
            result[mod.uid] = true
        end
    end
    return result
end

-- Get List of selected mods and check if they still exist.
function GetSelectedMods()
    local ModsFromGamePrefs = GetPreference('active_mods') or {}
    local ModsFromDisk= {}
    for modid,moddata in AllMods() do
        ModsFromDisk[moddata.uid] = true
    end
    for modid in ModsFromGamePrefs do
        if not ModsFromDisk[modid] then
            SPEW('Mod ID='..modid..' is selected as active mod, but missing on Disk!')
            ModsFromGamePrefs[modid] = nil
            SetPreference('active_mods', ModsFromGamePrefs)
        end
    end
    return ModsFromGamePrefs
end

function GetSelectedSimMods()
    return SetUtils.PredicateFilter(GetSelectedMods(),
        function(uid)
            return not AllMods()[uid].ui_only
        end
)
end

function GetSelectedUIMods()
    return SetUtils.PredicateFilter(GetSelectedMods(),
        function(uid)
            return AllMods()[uid].ui_only
        end
)
end

local function LoadModInfo(filename)
    -- Fill in some defaults to start with...
    local env = {
        location = Dirname(filename),
        name = filename,
        description = "<LOC uimod_0006>(No description)",
        author = '',
        copyright = '',
        exclusive = false,
        icon = '/textures/ui/common/dialogs/mod-manager/generic-icon_bmp.dds',
        selectable = true,
        hookdir = '/hook',      -- specify the name of the hook sub-directory
        shadowdir = '/shadow',  -- specify the name of shadow sub-directory
        uid = filename, -- default uid to name, should be a unique id
    }
    local ok, result = pcall(doscript, filename, env)
    if ok then
        env.location = Dirname(filename)
        return env
    else
        WARN("Problem loading " .. filename .. ":\n" .. result)
        return nil
    end
end


--Clear _mod_cache to pick up any changes on disk
function ClearCache()
    _mod_cache = nil
end


-- Return a table of all mods found on disk (mapping id->mod_info)
function AllMods()
    if not _mod_cache then
        local r = {}
        for i,file in DiskFindFiles('/mods', '*mod_info.lua') do
            local mod = LoadModInfo(file)
            if mod and (mod.enabled != false) and (mod.name != "Hotstats") then
                r[mod.uid] = mod
            end
        end
        _mod_cache = r
    end
    return _mod_cache
end


-- Return a table of all mods found on disk with the 'selectable' flag set
function AllSelectableMods()
    local r = {}
    for uid,mod in AllMods() do
        if mod.selectable then
            r[uid] = mod
        end
    end
    return r
end

-- sorts mods according to their before/after lists, otherwise alphabetically
-- returns true when first less than second
local function ModComp(first, second)

    if _mod_cache[first].before then
        for i,uid in _mod_cache[first].before do
            if _mod_cache[second].uid == uid then
                return true
            end
        end
    end

    if _mod_cache[first].after then
        for i,uid in _mod_cache[first].after do
            if _mod_cache[second].uid == uid then
                return false
            end
        end
    end

    return first < second
end

-- Get a list of ingame UI mods that should be active, based on preferences.
-- Only "ui_only" mods are included in the list; mods that affect the sim
-- from from GetActiveGameMods().
local function GetActiveModsFiltered(filter, selected)
    if not selected then
        selected = GetSelectedMods()
    end

    local all_mods = AllMods()
    local r = {}
    for uid,m in sortedpairs(all_mods, ModComp) do
        if selected[uid] and filter(m) then
            table.insert(r,m)
        end
    end
    return r
end

function GetUiMods(selected)
    return GetActiveModsFiltered(function(m) return m.ui_only end, selected)
end

function GetGameMods(selected)
    return GetActiveModsFiltered(function(m) return not m.ui_only end, selected)
end

function GetCampaignMods(scenario)
    local r
    if scenario.type == 'campaign' then
        r = GetGameMods { ['6AAFE20A-E851-11DB-B8BE-ECC755D89593']=true }
    else
        r = GetGameMods()
    end
    return r
end

-- given a uid of a mod, returns a tabe containing:
--  requires: list of installed uids that this mod requires
--  missing: list of uids that this mod requires but aren't installed
--  conflicts: list of installed uids that this mod conflicts with (or conflict with this mod)
function GetDependencies(uid)
    local ret = {requires = {}, missing = {}, conflicts = {}}
    local allMods = AllMods()

    local function RecurseDependencies(uid, ret)
        -- check if this mod lists known conflicts with other mods
        if allMods[uid].conflicts then
            for i, conflict in allMods[uid].conflicts do
                if allMods[conflict] then
                    ret.conflicts[conflict] = true
                end
            end
        end

        -- Exclusive mods conflict with everything.
        if allMods[uid].exclusive then
            ret.conflicts = table.map(function() return true end, allMods)
        end

        -- check if any other mods list this mod as a conflict
        for id, info in allMods do
            if id != uid then
                if allMods[id].conflicts then
                    for i, conflict in allMods[id].conflicts do
                        if uid == conflict then
                            ret.conflicts[id] = true
                            break;  -- don't need to continue as we're just looking for this mod
                        end
                    end
                end
            end
        end

        -- check for all mods required by this mod, and then check those required dependencies
        if allMods[uid].requires then
            -- this variable gets installed requirements so we can check them
            local locReq = {}
            for i, required in allMods[uid].requires do
                if allMods[required] then
                    ret.requires[required] = true
                    table.insert(locReq, required)
                else
                    ret.missing[required] = true
                end
            end
            for i, required in locReq do
                RecurseDependencies(required, ret)
            end
        end
    end

    if allMods[uid] then
        RecurseDependencies(uid, ret)
    end

    if table.empty(ret.requires) then ret.requires = nil end
    if table.empty(ret.missing) then ret.missing = nil end
    if table.empty(ret.conflicts) then ret.conflicts = nil end
    return ret
end

function UpdateUIMods()
    __active_mods = {}
    for i,m in ipairs(GetUiMods()) do
        table.insert(__active_mods, m)
    end
end
