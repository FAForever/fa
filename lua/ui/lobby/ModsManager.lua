-- ==========================================================================================
-- * File       : lua/modules/ui/lobby/ModsManager.lua
-- * Authors    : Gas Powered Games, FAF Community, HUSSAR
-- * Summary    : Contains UI for managing mods in FA lobby
-- ==========================================================================================
local Mods = import('/lua/mods.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local MultiLineText = import('/lua/maui/multilinetext.lua').MultiLineText
local Popup = import('/lua/ui/controls/popups/popup.lua').Popup
local RadioButton = import('/lua/ui/controls/radiobutton.lua').RadioButton
local Prefs = import('/lua/user/prefs.lua')
-- this version of Checkbox allows scaling of checkboxes
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local ToggleButton = import('/lua/ui/controls/togglebutton.lua').ToggleButton
local RestrictedData = import('/lua/ui/lobby/UnitsRestrictions.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

local ModsBlacklist = import('/etc/faf/blacklist.lua').Blacklist
local SetUtils = import('/lua/system/setutils.lua')
local GUIOpen = false
local IsHost = false

local controlList = {}
local controlMap = {}

local dialogWidth = 700 -- 557
local dialogHeight = 700 -- 602
local modIconSize = 50 --56
local modInfoPosition = modIconSize + 15 --80
local modInfoHeight = modIconSize + 20  --40
-- calculates how many number of mods to show per page based on dialog height
local modsPerPage = math.floor((dialogHeight - 100) / modInfoHeight) -- - 1

-- Counters for the benefit of the UI.
local numEnabledUIMods = 0
local numEnabledSimMods = 0

local scrollGroup
local dialogContent
local subtitle
local modsDialog

local callback

local mods = {
    -- lookup table with uid of mods that are selectable
    selectable = {},
    -- lookup table with uid of mods that are activated
    activated = {},
    -- mods that are disabled by the mod_info flag
    disabled = {},
    -- mods that are disabled by the FAF blacklist
    blacklisted = {},
    -- mods that are disabled because not everyone has them
    missingByOthers = {},
    -- mods that are disabled because dependencies are not installed
    missingDependencies = {},
    -- mods that change sim/game
    sim = {
        active = {},
        inactive = {}
    },
    -- mods that change UI
    ui = {
        active = {},
        inactive = {}
    },
    -- mods that are available to all players (passed from lobby.lua)
    availableToAll = {},
}
-- Maps uids to the output of Mods.GetDependencies(uid)
local modDependencyMap = {}

-- Maps uids to sets of uids of mods that depend on the first uid
local modBackwardDependencyMap = {}

function UpdateClientModStatus(mod_selec)
    if GUIOpen then
        modsDialog:Close()
        GUIOpen = false
    end
end

-- Returns true iff every peer in the game reports having a mod with the given id installed.
local function EveryoneHasMod(modID)
    if not IsHost then
        return true
    end
    for _, peerMods in mods.availableToAll do
        if not peerMods[modID] then
            return false
        end
    end
    return true
end

local modsTags = {
 UI       =  { key = 'UI', name = LOC('<LOC uiunitmanager_10>UI MODS'),   filtered = false,  color = 'FF21AEDE', }, -- #FF21AEDE UI mod
 GAME     =  { key = 'GAME', name = LOC('<LOC uiunitmanager_11>GAME MODS'), filtered = false, color = 'FFDE4521', }, -- #FFDE4521 game mod
 UNITS    =  { key = 'UNITS', name = LOC('<LOC uiunitmanager_12>UNITS'),    filtered = false, color = 'FFDED621', }, -- #FFDED621 units mod
 DISABLED =  { key = 'DISABLED', name = LOC('<LOC uiunitmanager_13>BLACKLISTED'), filtered = false, color = 'FF696A6A', }, -- #FF696A6A T2 changes
 LOCAL    =  { key = 'LOCAL', name = LOC('<LOC uiunitmanager_14>LOCAL'), filtered = false, color = 'FF696A6A', }, -- #FF696A6A T2 changes
}

-- Create the dialog for Mod Manager
-- @param parent UI control to create the dialog within.
-- @param IsHost Is the user opening the control the host (and hence able to edit?)
-- @param availableMods Present only if user is host. The availableMods map from lobby.lua.
function CreateDialog(parent, isHost, availableMods, saveBehaviour)
    IsHost = isHost
    callback = saveBehaviour

    mods.availableToAll = availableMods

    dialogContent = Group(parent)
    dialogContent.Width:Set(dialogWidth)
    dialogContent.Height:Set(dialogHeight)

    modsDialog = Popup(parent, dialogContent)
    modsDialog.OnClose = function()
        GUIOpen = false
    end

    -- Title
    local title = UIUtil.CreateText(dialogContent, '<LOC _Mod_Manager>Mods Manager', 20, UIUtil.titleFont)
    title:SetColor('B9BFB9')
    title:SetDropShadow(true)
    LayoutHelpers.AtHorizontalCenterIn(title, dialogContent, 0)
    LayoutHelpers.AtTopIn(title, dialogContent, 5)

    -- SubTitle: display counts of how many mods are enabled.
    subtitle = UIUtil.CreateText(dialogContent, '', 12, 'Arial')
    subtitle:SetColor('B9BFB9')
    subtitle:SetDropShadow(true)
    LayoutHelpers.AtHorizontalCenterIn(subtitle, dialogContent, 0)
    LayoutHelpers.AtTopIn(subtitle, dialogContent, 26)

    -- Save button
    local SaveButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "Ok", -1)
    SaveButton:UseAlphaHitTest(true)
    LayoutHelpers.AtRightIn(SaveButton, dialogContent, 10)
    LayoutHelpers.AtBottomIn(SaveButton, dialogContent, 15)

    controlList = {}

    modsPerPage = math.floor((dialogHeight - 100) / modInfoHeight)

    -- TODO separate mods into two 2 mods lists: UI and Game
    -- so that it is faster to find and activate mods
    scrollGroup = Group(dialogContent)

    LayoutHelpers.AtLeftIn(scrollGroup, dialogContent, 2)
    scrollGroup.Top:Set(function() return subtitle.Bottom() + 5 end)
    scrollGroup.Bottom:Set(function() return SaveButton.Top() - 10 end)
    scrollGroup.Width:Set(function() return dialogContent.Width() - 20 end)

    UIUtil.CreateLobbyVertScrollbar(scrollGroup, 1, 0, -10, 10)
    scrollGroup.top = 1

    scrollGroup.GetScrollValues = function(self, axis)
        return 1, table.getn(controlList), self.top, math.min(self.top + modsPerPage - 1, table.getn(controlList))
    end

    scrollGroup.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta))
    end

    scrollGroup.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta) * modsPerPage)
    end

    scrollGroup.ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.top then return end
        self.top = math.max(math.min(table.getn(controlList) - modsPerPage + 1 , top), 1)
        self:CalcVisible()
    end

    scrollGroup.CalcVisible = function(self)
        local top = self.top
        local bottom = self.top + modsPerPage
        local visibleIndex = 1
        for index, control in ipairs(controlList) do
            if control.filtered then
                control:Hide()
            elseif visibleIndex < top or visibleIndex >= bottom then
                control:Hide()
                visibleIndex = visibleIndex + 1
            else
                control:Show()
                control.Left:Set(self.Left)
                local i = visibleIndex
                local c = control
                control.Top:Set(function() return self.Top() + ((i - top) * c.Height()) end)
                visibleIndex = visibleIndex + 1
            end
        end
    end

    SaveButton.OnClick = function(self)
        modsDialog:Close()
        GUIOpen = false
        if callback then
            mods.ui.active = SetUtils.PredicateFilter(mods.activated,
                function(uid)
                    return mods.selectable[uid].ui_only
                end
            )
            mods.sim.active = SetUtils.Subtract(mods.activated, mods.ui.active)
            table.print(mods.sim.active, 'mods.sim.active')
            table.print(mods.ui.active, 'mods.ui.active')

            callback(mods.sim.active, mods.ui.active)
        else
            import('/lua/mods.lua').SetSelectedMods(mods.activated)
        end

        return mods.activated
    end

    RefreshModsList()

    scrollGroup.HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            local lines = 1
            if event.WheelRotation > 0 then
                lines = -1
            end
            self:ScrollLines(nil, lines)
            return true
        end

        return false
    end

    local position = 5
    local filterGameMods = CreateModsFilter(dialogContent, modsTags.GAME)
    Tooltip.AddControlTooltip(filterGameMods, {
        text = LOC('<LOC uiunitmanager_01>Filter Game Mods'),
        body = LOC('<LOC uiunitmanager_02>Toggle visibility of all game mods in above list of mods.') })
    LayoutHelpers.AtLeftIn(filterGameMods, dialogContent, position)
    LayoutHelpers.AtBottomIn(filterGameMods, dialogContent, 15)

    position = position + 110
    local filterUIMods = CreateModsFilter(dialogContent, modsTags.UI)
    Tooltip.AddControlTooltip(filterUIMods, {
        text = LOC('<LOC uiunitmanager_03>Filter UI Mods'),
        body = LOC('<LOC uiunitmanager_04>Toggle visibility of all UI mods in above list of mods.') })
    LayoutHelpers.AtLeftIn(filterUIMods, dialogContent, position)
    LayoutHelpers.AtBottomIn(filterUIMods, dialogContent, 15)

    position = position + 110
    local filterDisabledMods = CreateModsFilter(dialogContent, modsTags.DISABLED)
    Tooltip.AddControlTooltip(filterDisabledMods, {
        text = LOC('<LOC uiunitmanager_05>Filter Blacklisted Mods'),
        body = LOC('<LOC uiunitmanager_06>Toggle visibility of blacklisted mods in above list of mods.') })
    LayoutHelpers.AtLeftIn(filterDisabledMods, dialogContent, position)
    LayoutHelpers.AtBottomIn(filterDisabledMods, dialogContent, 15)

    GUIOpen = true

    return modsDialog
end

function FilterMods()
    for i, control in ipairs(controlList) do
        local filtered = true
        for name, tag in modsTags do
            if control.modInfo.tags[name] then
                filtered =  tag.filtered
            end
        end
        control.filtered = filtered
    end
    scrollGroup:ScrollSetTop(nil,2)
    scrollGroup:ScrollSetTop(nil,1)
end

function CreateModsFilter(parent, tag)

    local states = {
        normal   = UIUtil.SkinnableFile('/BUTTON/medium/_btn_up.dds'),
        active   = UIUtil.SkinnableFile('/BUTTON/medium/_btn_down.dds'),
        over     = UIUtil.SkinnableFile('/BUTTON/medium/_btn_over.dds'),
        disabled = UIUtil.SkinnableFile('/BUTTON/medium/_btn_dis.dds'),
    }
    local filterToggle = UIUtil.CreateButton(parent,
            states.active,
            states.active,
            states.highlight,
            states.disabled,
            tag.name,
            11)

    local height = filterToggle.label.Height() + 30
    local width = 130
    filterToggle.tag = tag.key
    filterToggle.checked = true
    filterToggle.Height:Set(height)
    filterToggle.Width:Set(width)
    filterToggle.HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' then
            if not self.checked then
                self.checked = true
                self:SetTexture(states.active)
            else
                self.checked = false
                self:SetTexture(states.normal)
            end
            local modTag = modsTags[self.tag]
            if modTag then
               modTag.filtered = not self.checked
            end
            FilterMods()
            return true
        elseif event.Type == 'MouseEnter' then
            self:OnRolloverEvent('enter')
            return true
        elseif event.Type == 'MouseExit' then
            self:OnRolloverEvent('exit')
            return true
        end
    end
    filterToggle:UseAlphaHitTest(true)
    return filterToggle
end

local function UpdateModsCounters()
    subtitle:SetText(LOCF("<LOC uimod_0027>%d game mods and %d UI mods activated", numEnabledSimMods, numEnabledUIMods))
end

local UnitsAnalyzer = import('/lua/ui/lobby/UnitsAnalyzer.lua')

function GetModUnits(mod)
    local searchMods =  {}
    searchMods[mod.uid] = mod
    return GetModsUnits(searchMods)
end

function GetModsUnits(searchMods)
    UnitsAnalyzer.FetchBlueprints(searchMods, true)
    local bps = UnitsAnalyzer.GetBlueprintsList(searchMods, true)
    bps = table.merged(bps.Units, bps.Enhancements)
    return bps
end

function GetModsFiles(mod, pattern)
    local units = '*_unit.bp'
    for k,file in DiskFindFiles(mod.location, pattern) do
        BlueprintLoaderUpdateProgress()
        safecall("loading mod blueprint "..file, doscript, file)
    end
end
-- Gets a name and actual version for specified mod
function GetModNameVersion(mod)
    local name = mod.name
    -- remove old mod version from mod name
    name = name:gsub(" %[", " ")
    name = name:gsub("%]", "")
    name = name:gsub(" V", " ")
    name = name:gsub(" v", " ")
    name = name:gsub(" %(V", " ")
    name = name:gsub(" %(v", " ")
    name = name:gsub("%d%)", "")
    name = name:gsub(" %d%_%d%_%d", "")
    name = name:gsub(" %d%.%d%d%d", "")
    name = name:gsub(" %d%.%d%d", "")
    name = name:gsub(" %d%.%d", "")
    name = name:gsub(" %d%.", "")
    name = name:gsub(" %d", "")
    -- cleanup name
    name = name:gsub(" %(%)", "")
    name = name:gsub("%)", "")
    name = name:gsub(" %-", " ")
    name = name:gsub("%- ", "")
    name = name:gsub("%-", " ", 1)
    name = name:gsub("%_", " ")
    name = name:gsub(" %(", " - ")
    name = StringCapitalize(name)

    if not mod.version then
        name = name .. ' ---- (v1.0)'
    elseif type(mod.version) == 'number' then
        local ver = string.format("v%01.2f", mod.version)
        ver = ver:gsub("%.*0$", "")
        -- append actual mod version to mod name
        name = name .. ' ---- (' .. ver .. ')'
    elseif type(mod.version) == 'string' then
        local ver = mod.version
        -- correct mod version (e.g. 1.1.1 --> 1.11)
        if string.find(ver, "%d%.%d%.%d") then
            ver = StringReverse(ver)
            ver = ver:gsub("%.", "", 1)
            ver = StringReverse(ver)
        elseif not string.find(ver, "%.") then
            ver = ver .. '.0'
        end
        name = name .. ' ---- (v' .. ver .. ')'
    end
    return name
end
-- Gets a name and type for specified mod
function GetModNameType(uid)
    local mod = mods.selectable[uid]
    return mod.type  .. ' mod - '.. mod.title
end
local posCounter = 1
-- Append the given list of mods to the UI, applying the given label and activeness state to each.
function AppendMods(modlist, active, enabled, labelParam, labelSet)
    for k, mod in modlist do

        local label = labelParam or LOC(labelSet[k])
        local entry = CreateListElement(scrollGroup, mod, posCounter)
        --LOG('MOD  AppendMod '  .. tostring(label) .. '  ' .. mod.name)
        if not enabled then
            entry.bg:Disable()
        end
        if active then
            LOG('ModsManager activated: ' .. GetModNameType(mod.uid))
        end
        entry.bg:SetCheck(active, true)

        if label then
            entry.type:SetText(label)
        end
        posCounter = posCounter + 1
    end
end
-- Update mods in specified table with info about units that mods adds to the game
function UpdateMods(modsList)
    local units = GetModsUnits(modsList)
    for uid, mod in modsList do
        --mod.units = GetModsUnits(mod)
        for id, bp in units do
            if bp.Mod.uid == uid then
                mod.units[id] = bp
            end
        end
        if table.getsize(mod.units) > 0 then
            mod.tags['UNITS'] = true
        end
    end
end

-- Refreshes the mod list UI.
function RefreshModsList()
    if controlList then
        for k, v in controlList do
            v:Destroy()
        end
    end

    controlList = {}
    controlMap = {}

    mods.selectable = Mods.AllSelectableMods()
    mods.activated = Mods.GetSelectedMods()

    -- reset state of mods
    mods.sim.active = {}
    mods.sim.inactive = {}
    mods.ui.active = {}
    mods.ui.inactive = {}
    -- mods that are disabled by the mod_info flag
    mods.disabled = {}
    -- mods that are disabled because not everyone has them
    mods.missingByOthers = {}
    -- mods that are disabled because dependencies are not installed
    mods.missingDependencies = {}
    -- mods that are disabled by the FAF blacklist
    mods.blacklisted = {}

    -- Construct various filtered lists of mods. We then concatenate these to form the list.
    for uid, mod in mods.selectable do
        mod.tags = {}
        mod.units = {}

        --for id, bp in Blueprints.All do
        --    if bp.Mod.uid == uid then
        --        mod.tags['UNITS'] = true
        --        mod.units[id] = bp
        --    end
        --end
        mod.title = GetModNameVersion(mod)
        if mod.ui_only then
            mod.type = 'UI'
        else
            mod.type = 'GAME'
        end

        if ModsBlacklist[uid] then
            -- value is a message explaining why it's blacklisted
            mod.sort = 'X'
            mod.tags['DISABLED'] = true
            mods.blacklisted[uid] = mod
        elseif mod.enabled == false then
            mod.sort = 'X'
            mod.tags['DISABLED'] = true
            mods.disabled[uid] = mod
        else
            -- check for the dependencies of mods are installed
            local dependencies = Mods.GetDependencies(uid)
            modDependencyMap[uid] = dependencies
            if dependencies.missing then
                mod.tags['DISABLED'] = true
                mods.missingDependencies[uid] = mod
            elseif dependencies.requires then
                -- Construct backward-dependency map for this mod (so we can disable this one if
                -- someone turns off something we depend on)
                for k, v in dependencies.requires do
                    -- Dependency on a blacklisted mod?
                    if ModsBlacklist[k] then
                        mod.tags['DISABLED'] = true
                        mods.missingDependencies[uid] = mod
                    end

                    if not modBackwardDependencyMap[k] then
                        modBackwardDependencyMap[k] = {}
                    end

                    modBackwardDependencyMap[k][uid] = true
                end
            end

            if mod.ui_only then
                -- Is this a UI mod that depends on a sim mod that is turned off?
                if not IsHost and dependencies.requires then
                    for innerUid, innerMod in dependencies.requires do
                        if not innerMod.ui_only and not mods.sim.active[innerUid] then
                            mod.tags['DISABLED'] = true
                            mods.missingDependencies[uid] = mod
                            break
                        end
                    end
                end

                if mods.missingDependencies[uid] then
                    mod.sort = 'X'
                    mod.tags['DISABLED'] = true
                else
                    mod.sort = 'UI'
                    mod.tags['UI'] = true

                    if mods.activated[uid] then
                        mods.ui.active[uid] = mod
                    else
                        mods.ui.inactive[uid] = mod
                    end
                end
            else
                -- check if everyone has sim mod otherwise disable it.
                if not EveryoneHasMod(uid) then
                    mod.sort = 'X'
                    mod.tags['DISABLED'] = true
                    mods.missingByOthers[uid] = mod
                -- excluding sim mods that are missing dependency
                elseif mods.missingDependencies[uid] then
                    mod.sort = 'X'
                    mod.tags['DISABLED'] = true
                else
                    mod.sort = 'GAME'
                    mod.tags['GAME'] = true
                    if mods.activated[uid] then
                        mods.sim.active[uid] = mod
                    else
                        mods.sim.inactive[uid] = mod
                    end
                end
            end
        end
    end

    -- Make the conflict relation commutative.
    for uid, deps in modDependencyMap do
        if deps.conflicts then
            for conflicter, _ in deps.conflicts do
                -- If the conflicting mod is installed, add a backwards conflict relation.
                if modDependencyMap[conflicter] then
                    if not modDependencyMap[conflicter].conflicts then
                        modDependencyMap[conflicter].conflicts = {}
                    end
                    if not modDependencyMap[conflicter].conflicts[uid] then
                        WARN("A mod defines a non-commutative conflict set!")
                        WARN("Adding conflict from "..conflicter.." to " .. uid)
                        modDependencyMap[conflicter].conflicts[uid] = true
                    end
                end
            end
        end
    end
    --UpdateMods(mods.sim.active)

    -- Create entries for the list of interesting mods
    AppendMods(mods.sim.active, true, true)
    AppendMods(mods.ui.active, true, true)
    if IsHost then
        --UpdateMods(mods.sim.inactive)
        AppendMods(mods.sim.inactive, false, true)
    end
    AppendMods(mods.ui.inactive, false, true)
    AppendMods(mods.disabled, false, false)
    for uid, mod in mods.missingByOthers do
        LOG('ModsManager others players are missing ' .. GetModNameType(uid))
    end
    AppendMods(mods.missingByOthers, false, false, LOC('<LOC uimod_0019>Players missing mod'))
    for uid, mod in mods.missingDependencies do
        LOG('ModsManager is missing dependency for ' .. GetModNameType(uid))
    end
    AppendMods(mods.missingDependencies, false, false, LOC('<LOC uimod_0020>Missing dependency'))
    AppendMods(mods.blacklisted, false, false, nil, ModsBlacklist)

    numEnabledUIMods = table.getsize(mods.ui.active)
    numEnabledSimMods = table.getsize(mods.sim.active)

    UpdateModsCounters()

    SortMods()

    scrollGroup.top = 1
    scrollGroup:CalcVisible()
end
-- Activates the mod with the given uid
-- @param isRecursing Indicates this is a recursive call (usually pulling in dependencies), so should
--                    not prompt the user for input.
-- @param visited The set of mods visited during this recursive set of calls (used to break cycles)
function ActivateMod(uid, isRecursing, visited)
    if mods.activated[uid] then
        return
    end

    visited = visited or {}
    if visited[uid] then
        return
    end
    visited[uid] = true

    -- Dependency checking time!
    local deps = modDependencyMap[uid]

    if deps then
        -- Any conflicting mods activated? We discard exclusive mods to a universal conflict set, so
        -- those are handled here, too.
        if deps.conflicts then
            -- List of uids that need to be disabled for this mod to work.
            local activatedConflictingMods = {}
            for uid, _ in deps.conflicts do
                if mods.activated[uid] then
                    LOG("ModsManager found conflicting: ".. GetModNameType(uid))
                    table.insert(activatedConflictingMods, uid)
                end
            end
            -- Closure copy
            local thisUID = uid
            local doEnable = function()
                for k, uid in activatedConflictingMods do
                    DeactivateMod(uid)
                    ActivateMod(thisUID, true, visited)
                    LOG("ModsManager activated: ".. GetModNameType(thisUID))
                end
            end
            -- Prompt the user, and if they approve, turn off all conflicting mods.
            if table.getn(activatedConflictingMods) > 0 then
                if isRecursing then
                    -- Just quietly get on and do it if it's a recursive call.
                    doEnable()
                else
                    local target = controlMap[uid].bg
                    UIUtil.QuickDialog(dialogContent,
                        "<LOC uimod_0010>This mod conflicts with some of the other mods you have active. Shall we turn those mods off and this one on?",
                        "<LOC _Yes>", doEnable,
                        "<LOC _No>", function() target:SetCheck(false, true) end)
                end
                return
            end
        end
        -- Activate any dependencies. We guaranteed that these all exist earlier on.
        if deps.requires then
            for uid, _ in deps.requires do
                ActivateMod(uid, true, visited)
                LOG("ModsManager activated dependency: ".. GetModNameType(uid))
            end
        end
    end
    mods.activated[uid] = true
    controlMap[uid].bg:SetCheck(true, true)

    if mods.selectable[uid].ui_only then
        numEnabledUIMods = numEnabledUIMods + 1
    else
        numEnabledSimMods = numEnabledSimMods + 1
    end

    UpdateModsCounters()
end

function DeactivateMod(uid, visited)
    if not mods.activated[uid] then
        return
    end

    visited = visited or {}
    if visited[uid] then
        return
    end
    visited[uid] = true

    -- Check for backward dependencies: do other mods require this one? If so, we should disable
    -- those mods, as well.
    local victims = modBackwardDependencyMap[uid]
    if victims then
        for k, v in victims do
            DeactivateMod(k, true, visited)
        end
    end

    mods.activated[uid] = nil
    controlMap[uid].bg:SetCheck(false, true)

    if mods.selectable[uid].ui_only then
        numEnabledUIMods = numEnabledUIMods - 1
    else
        numEnabledSimMods = numEnabledSimMods - 1
    end
    UpdateModsCounters()
end

function SortMods()
    table.sort(controlList, function(a,b)
        -- sort mods by active state, then by type and finally by name
        if mods.activated[a.modInfo.uid] and
           not mods.activated[b.modInfo.uid] then
           return true
        elseif not mods.activated[a.modInfo.uid] and
                   mods.activated[b.modInfo.uid] then
           return false
        elseif a.modInfo.sort == 'UI' and
               b.modInfo.sort == 'GAME' then
           return true
        elseif a.modInfo.sort == 'GAME' and
               b.modInfo.sort == 'UI' then
           return false
        else
            if a.modInfo.sort == b.modInfo.sort then
                if a.modInfo.name == b.modInfo.name then
                    return tostring(a.modInfo.version) < tostring(b.modInfo.version)
                else
                    return string.upper(a.modInfo.title) < string.upper(b.modInfo.title)
                end
            else
                return a.modInfo.sort < b.modInfo.sort
            end
        end
        return 0
    end)
end
function CreateListElement(parent, modInfo, Pos)
    local group = Group(parent)
    -- changed fixed-size checkboxes to scalable checkboxes
    group.filtered = false
    group.pos = Pos
    group.modInfo = modInfo
    group.bg = Checkbox(group,
        UIUtil.SkinnableFile('/MODS/blank.dds'),
        UIUtil.SkinnableFile('/MODS/single.dds'),
        UIUtil.SkinnableFile('/MODS/single.dds'),
        UIUtil.SkinnableFile('/MODS/double.dds'),
        UIUtil.SkinnableFile('/MODS/disabled.dds'),
        UIUtil.SkinnableFile('/MODS/disabled.dds'),
            'UI_Tab_Click_01', 'UI_Tab_Rollover_01')
    group.bg.Height:Set(modIconSize + 10)
    group.bg.Width:Set(dialogWidth - 15)

    group.Height:Set(modIconSize + 20)
    group.Width:Set(dialogWidth - 20)
    LayoutHelpers.AtLeftTopIn(group, parent, 2, group.Height()*(Pos-1))
    LayoutHelpers.FillParent(group.bg, group)

    if not modInfo.icon or modInfo.icon == '' then
        WARN('ModsManager cannot load an icon for mod: ' .. GetModNameType(modInfo.uid))
    end

    group.icon = Bitmap(group, modInfo.icon)
    group.icon.Height:Set(modIconSize)
    group.icon.Width:Set(modIconSize)
    group.icon:DisableHitTest()
    LayoutHelpers.AtLeftTopIn(group.icon, group, 10, 7)
    LayoutHelpers.AtVerticalCenterIn(group.icon, group)

    group.name = UIUtil.CreateText(group, modInfo.title, 14, UIUtil.bodyFont)
    group.name:SetColor('FFE9ECE9')
    group.name:DisableHitTest()
    LayoutHelpers.AtLeftTopIn(group.name, group, modInfoPosition, 5)
    group.name:SetDropShadow(true)

    group.desc = MultiLineText(group, UIUtil.bodyFont, 12, 'FFA2A5A2')
    group.desc:DisableHitTest()
    LayoutHelpers.AtLeftTopIn(group.desc, group, modInfoPosition, 25)
    group.desc.Width:Set(group.Width() - group.icon.Width()-50)
    group.desc:SetText(modInfo.description)

    group.type = UIUtil.CreateText(group, '', 12, 'Arial Narrow Bold')
    group.type:DisableHitTest()
    group.type:SetColor('B9BFB9')
    group.type:SetFont('Arial Black', 11)
    group.ui = modInfo.ui_only
    if modInfo.ui_only then
        group.type:SetText(LOC('<LOC uimod_0028>UI Mod'))
    else
        group.type:SetText(LOC('<LOC uimod_0029>Game Mod'))
    end
    LayoutHelpers.AtRightTopIn(group.type, group, 12, 4)

    table.insert(controlList, group)
    controlMap[modInfo.uid] = group

    if IsHost or modInfo.ui_only then
        local uid = modInfo.uid
        group.bg.OnCheck = function(self, checked)
            if checked then
                LOG('ModsManager selected: ' .. GetModNameType(uid))
                ActivateMod(uid)
            else
                LOG('ModsManager deselected: ' .. GetModNameType(uid))
                DeactivateMod(uid)
            end
        end
    else
        -- Disable all mouse interactivity with the control, but don't _disable_ it, as that alters
        -- what it looks like.
        group.bg.HandleEvent = function() return true end
    end

    return group
end
