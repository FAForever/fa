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

local dialogWidth = 800
local dialogHeight = 750
local modIconSize = 50
local modInfoPosition = modIconSize + 15
local modInfoHeight = modIconSize + 20
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

function UpdateClientModStatus()
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
 UI = {
    label = LOC('<LOC uiunitmanager_10>UI MODS'),
    text  = LOC('<LOC uiunitmanager_03>Filter UI Mods'),
    body  = LOC('<LOC uiunitmanager_04>Toggle visibility of all UI mods in above list of mods.') },
 GAME = {
    label = LOC('<LOC uiunitmanager_11>GAME MODS'),
    text  = LOC('<LOC uiunitmanager_01>Filter Game Mods'),
    body  = LOC('<LOC uiunitmanager_02>Toggle visibility of all game mods in above list of mods.') },
 BLACKLISTED = {
    label = LOC('<LOC uiunitmanager_13>BLACKLISTED'),
    text  = LOC('<LOC uiunitmanager_05>Filter Blacklisted Mods'),
    body  = LOC('<LOC uiunitmanager_06>Toggle visibility of blacklisted mods in above list of mods.')},
 LOCAL = {
    label = LOC('<LOC uiunitmanager_14>LOCAL MODS'),
    text  = LOC('<LOC uiunitmanager_18>Filter Local Mods'),
    body  = LOC('<LOC uiunitmanager_19>Toggle visibility of game mods that are missing by other players') },
 NO_DEPENDENCY = {
    label = LOC('<LOC uiunitmanager_15>NO DEPENDENCY'),
    text  = LOC('<LOC uiunitmanager_16>Filter Missing Dependency Mods'),
    body  = LOC('<LOC uiunitmanager_17>Toggle visibility of mods that are missing dependency in above list of mods.') },
}

-- Create the dialog for Mod Manager
-- @param parent UI control to create the dialog within.
-- @param IsHost Is the user opening the control the host (and hence able to edit?)
-- @param availableMods Present only if user is host. The availableMods map from lobby.lua.
function CreateDialog(parent, isHost, availableMods, saveBehaviour)
    IsHost = isHost
    callback = saveBehaviour

    mods.availableToAll = availableMods

    dialogHeight = GetFrame(0).Height() - LayoutHelpers.ScaleNumber(80)

    dialogContent = Group(parent)
    LayoutHelpers.SetWidth(dialogContent, dialogWidth)
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
    local SaveButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _OK>OK", -1)
    --SaveButton:UseAlphaHitTest(true)
    LayoutHelpers.AtHorizontalCenterIn(SaveButton, dialogContent)
    LayoutHelpers.AtBottomIn(SaveButton, dialogContent, 15)

    controlList = {}

    -- TODO separate mods into two 2 mods lists: UI and Game
    -- so that it is faster to find and activate mods
    scrollGroup = Group(dialogContent)

    LayoutHelpers.AtLeftIn(scrollGroup, dialogContent, -2)
    LayoutHelpers.AnchorToBottom(scrollGroup, subtitle, 10)
    LayoutHelpers.AnchorToTop(scrollGroup, SaveButton, 70)
    scrollGroup.Width:Set(function() return dialogContent.Width() - 20 end)
    scrollGroup.Height:Set(function() return scrollGroup.Bottom() - scrollGroup.Top() end)

    modsPerPage = math.floor((scrollGroup.Height() - 10) / LayoutHelpers.ScaleNumber(modInfoHeight))

    UIUtil.CreateLobbyVertScrollbar(scrollGroup, 1, 0, 0, 10)
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
                --control.Left:Set(self.Left() +5)
                local i = visibleIndex
                local c = control
                control.Top:Set(function() return self.Top() + ((i - top) * (c.Height() +2)) end)
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
    UIUtil.MakeInputModal(dialogContent, function() SaveButton.OnClick(SaveButton) end, function() SaveButton.OnClick(SaveButton) end)

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

    local position = 10
    local offset = 150
    local filterGameMods = CreateModsFilter(dialogContent, 'GAME')
    LayoutHelpers.AtLeftIn(filterGameMods, dialogContent, position)
    LayoutHelpers.AtBottomIn(filterGameMods, dialogContent, 65)

    position = position + offset
    local filterUIMods = CreateModsFilter(dialogContent, 'UI')
    LayoutHelpers.AtLeftIn(filterUIMods, dialogContent, position)
    LayoutHelpers.AtBottomIn(filterUIMods, dialogContent, 65)

    position = position + offset
    local filterDisabledMods = CreateModsFilter(dialogContent, 'BLACKLISTED')
    LayoutHelpers.AtLeftIn(filterDisabledMods, dialogContent, position)
    LayoutHelpers.AtBottomIn(filterDisabledMods, dialogContent, 65)

    position = position + offset
    local filterNoDependencyMods = CreateModsFilter(dialogContent, 'NO_DEPENDENCY')
    LayoutHelpers.AtLeftIn(filterNoDependencyMods, dialogContent, position)
    LayoutHelpers.AtBottomIn(filterNoDependencyMods, dialogContent, 65)

    position = position + offset
    local filterLocalMods = CreateModsFilter(dialogContent, 'LOCAL')
    LayoutHelpers.AtLeftIn(filterLocalMods, dialogContent, position)
    LayoutHelpers.AtBottomIn(filterLocalMods, dialogContent, 65)

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
    local count = 0
    if tag == 'UI' then
        count = table.getsize(mods.ui.active) + table.getsize(mods.ui.inactive)
    elseif tag == 'GAME' then
        count = table.getsize(mods.sim.active) + table.getsize(mods.sim.inactive)
    elseif tag == 'BLACKLISTED' then
        count = table.getsize(mods.blacklisted) + table.getsize(mods.disabled)
    elseif tag == 'LOCAL' then
        count = table.getsize(mods.missingByOthers)
    elseif tag == 'NO_DEPENDENCY' then
        count = table.getsize(mods.missingDependencies)
    end

    local filterToggle = UIUtil.CreateButton(parent,
            states.active,
            states.active,
            states.highlight,
            states.disabled,
            --' - '.. count,
            modsTags[tag].label .. ' - '.. count,
            11)

    local height = filterToggle.label.Height() + 30
    local width = 180
    filterToggle.tag = tag
    filterToggle.checked = true
    filterToggle.Height:Set(height)
    LayoutHelpers.SetWidth(filterToggle, width)
    filterToggle.HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' then
            if not self.checked then
                self.checked = true
                self:SetTexture(states.active)
            else
                self.checked = false
                self:SetTexture(states.normal)
            end
            if modsTags[self.tag] then
               modsTags[self.tag].filtered = not self.checked
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
    --filterToggle:UseAlphaHitTest(true)
    Tooltip.AddControlTooltip(filterToggle, { text = modsTags[tag].text, body = modsTags[tag].body })

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
    return mod.type  .. ' mod - '.. mod.title .. ' - ' .. mod.location
end
function GetModAuthor(uid)
    local mod = mods.selectable[uid]
    if mod and mod.author and mod.author ~= '' then
        if string.len(mod.author) < 20 then
            return mod.author
        elseif string.find(mod.author, ",") then
            return StringSplit(mod.author, ',')[1]
        elseif string.find(mod.author, " ") then
            return StringSplit(mod.author, ' ')[1]
        end
    end
    return 'UNKNOWN'
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
        if not table.empty(mod.units) then
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
        mod.units = {}
        mod.title = GetModNameVersion(mod)
        if mod.ui_only then
            mod.type = 'UI'
        else
            mod.type = 'GAME'
        end

        if ModsBlacklist[uid] then
            -- value is a message explaining why it's blacklisted
            mod.sort = 'X'
            mod.type = 'BLACKLISTED'
            mods.blacklisted[uid] = mod
        elseif mod.enabled == false then
            mod.sort = 'X'
            mod.type = 'BLACKLISTED'
            mods.disabled[uid] = mod
        else
            -- check for the dependencies of mods are installed
            local dependencies = Mods.GetDependencies(uid)
            modDependencyMap[uid] = dependencies
            if dependencies.missing then
                mod.sort = 'X'
                mod.type = 'NO_DEPENDENCY'
                mods.missingDependencies[uid] = mod

            elseif dependencies.requires then
                -- Construct backward-dependency map for this mod (so we can disable this one if
                -- someone turns off something we depend on)
                for k, v in dependencies.requires do
                    -- Dependency on a blacklisted mod?
                    if ModsBlacklist[k] then
                        mod.sort = 'X'
                        mod.type = 'NO_DEPENDENCY'
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
                    for innerUid in dependencies.requires do
                        if not mods.selectable[innerUid].ui_only and not mods.sim.active[innerUid] then
                            mod.sort = 'X'
                            mod.type = 'NO_DEPENDENCY'
                            mods.missingDependencies[uid] = mod
                            break
                        end
                    end
                end

                if mods.missingDependencies[uid] then
                    mod.sort = 'X'
                    mod.type = 'NO_DEPENDENCY'
                else
                    mod.type = 'UI'
                    mod.sort = 'UI'
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
                    mod.type = 'LOCAL'
                    mods.missingByOthers[uid] = mod
                -- excluding sim mods that are missing dependency
                elseif mods.missingDependencies[uid] then
                    mod.sort = 'X'
                    mod.type = 'NO_DEPENDENCY'
                else
                    mod.sort = 'GAME'
                    mod.type = 'GAME'
                    if mods.activated[uid] then
                        mods.sim.active[uid] = mod
                    else
                        mods.sim.inactive[uid] = mod
                    end
                end
            end
        end
    end

    -- set status and filter tags for all mods
    for uid, mod in mods.selectable do
        mod.tags = {}
        if not mod.type then
            mod.type = 'GAME'
        end

        mod.tags[mod.type] = true

        if mod.type == 'GAME' then
           mod.status = LOC('<LOC uimod_0029>Game Mod')
        elseif mod.type == 'UI' then
           mod.status = LOC('<LOC uimod_0028>UI Mod')
        elseif mod.type == 'NO_DEPENDENCY' then
           mod.status = LOC('<LOC uimod_0020>Missing dependency')
        elseif mod.type == 'LOCAL' then
           mod.status = LOC('<LOC uimod_0019>Players missing mod')
        elseif mod.type == 'BLACKLISTED' then
           mod.status = ModsBlacklist[uid] or 'Disabled'
        else
           mod.status = 'Unknown Mod'
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
        LOG('ModsManager others players are missing mod: ' .. mod.title .. ' - ' .. mod.location)
    end
    AppendMods(mods.missingByOthers, false, false, LOC('<LOC uimod_0019>Players missing mod'))
    for uid, mod in mods.missingDependencies do
        LOG('ModsManager is missing dependency for mod: ' .. mod.title .. ' - ' .. mod.location)
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
function ActivateMod(uid, isRecursing)
    if mods.activated[uid] then
        return
    end

    mods.activated[uid] = true

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
                    ActivateMod(thisUID, true)
                    LOG("ModsManager activated: ".. GetModNameType(thisUID))
                end
            end
            -- Prompt the user, and if they approve, turn off all conflicting mods.
            if not table.empty(activatedConflictingMods) then
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
                ActivateMod(uid, true)
                LOG("ModsManager activated dependency: ".. GetModNameType(uid))
            end
        end
    end
    controlMap[uid].bg:SetCheck(true, true)

    if mods.selectable[uid].ui_only then
        numEnabledUIMods = numEnabledUIMods + 1
    else
        numEnabledSimMods = numEnabledSimMods + 1
    end

    UpdateModsCounters()
end

function DeactivateMod(uid)
    if not mods.activated[uid] then
        return
    end

    mods.activated[uid] = nil

    -- Check for backward dependencies: do other mods require this one? If so, we should disable
    -- those mods, as well.
    local victims = modBackwardDependencyMap[uid]
    if victims then
        for k, v in victims do
            DeactivateMod(k, true)
        end
    end

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
                if a.modInfo.status ~= b.modInfo.status then
                    return tostring(a.modInfo.status) < tostring(b.modInfo.status)
                elseif a.modInfo.name == b.modInfo.name then
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
function CreateListElement(parent, mod, Pos)
    local group = Group(parent)

    -- changed fixed-size checkboxes to scalable checkboxes
    group.filtered = false
    group.pos = Pos
    group.modInfo = mod
    group.bg = Checkbox(group,
        UIUtil.SkinnableFile('/MODS/blank.dds'),
        UIUtil.SkinnableFile('/MODS/single.dds'),
        UIUtil.SkinnableFile('/MODS/single.dds'),
        UIUtil.SkinnableFile('/MODS/double.dds'),
        UIUtil.SkinnableFile('/MODS/disabled.dds'),
        UIUtil.SkinnableFile('/MODS/disabled.dds'),
            'UI_Tab_Click_01', 'UI_Tab_Rollover_01')
    LayoutHelpers.SetHeight(group.bg, modIconSize + 10)
    LayoutHelpers.SetWidth(group.bg, dialogWidth - 15)

    LayoutHelpers.SetHeight(group, modInfoHeight)
    LayoutHelpers.SetWidth(group, dialogWidth - 25)
    LayoutHelpers.AtLeftTopIn(group, parent, 4, group.Height()*(Pos-1))
    LayoutHelpers.FillParent(group.bg, group)

    if not mod.icon or mod.icon == '' then
        WARN('ModsManager cannot load an icon for mod: ' .. mod.title .. ' - ' .. mod.location)
    end

    group.icon = Bitmap(group, mod.icon)
    LayoutHelpers.SetDimensions(group.icon, modIconSize, modIconSize)
    group.icon:DisableHitTest()
    LayoutHelpers.AtLeftTopIn(group.icon, group, 10, 7)
    LayoutHelpers.AtVerticalCenterIn(group.icon, group)

    group.name = UIUtil.CreateText(group, mod.title, 14, UIUtil.bodyFont)
    group.name:SetColor('FFE9ECE9') -- #FFE9ECE9
    group.name:DisableHitTest()
    LayoutHelpers.AtLeftTopIn(group.name, group, modInfoPosition, 7)

    group.createdBy = UIUtil.CreateText(group, ' created by ', 14, UIUtil.bodyFont)
    group.createdBy:DisableHitTest()
    group.createdBy:SetColor('FFA2A5A2') -- #FFA2A5A2
    LayoutHelpers.AtTopIn(group.createdBy, group, 7)
    LayoutHelpers.RightOf(group.createdBy, group.name, 2)

    group.author = UIUtil.CreateText(group, GetModAuthor(mod.uid), 14, UIUtil.bodyFont)
    group.author:DisableHitTest()
    group.author:SetColor('FFE9ECE9') -- #FFE9ECE9
    LayoutHelpers.AtTopIn(group.author, group, 7)
    LayoutHelpers.RightOf(group.author, group.createdBy, 2)

    group.desc = MultiLineText(group, UIUtil.bodyFont, 12, 'FFA2A5A2')
    group.desc:DisableHitTest()
    LayoutHelpers.AtLeftTopIn(group.desc, group, modInfoPosition, 25)
    group.desc.Width:Set(group.Width() - group.icon.Width()-20)
    group.desc:SetText(mod.description)

    group.type = UIUtil.CreateText(group, '', 12, 'Arial Black')
    group.type:DisableHitTest()
    if mod.status then
        group.type:SetText(mod.status)
        group.type:SetColor('FFB9BFB9') --#FFB9BFB9
    else
        group.type:SetText('Unknown Mod')
        group.type:SetColor('FFE94C16') --#FFE94C16
    end

    group.ui = mod.ui_only
    LayoutHelpers.AtRightTopIn(group.type, group, 8, 6)

    table.insert(controlList, group)
    controlMap[mod.uid] = group

    if IsHost or mod.ui_only then
        local uid = mod.uid
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

    if string.len(mod.description) > 240 then
        local description = string.sub(mod.description, 1, 240) .. '...'
        group.desc:SetText(description)
    end

    if mod.type == 'NO_DEPENDENCY' then
        local body = ''
        if not table.empty(mod.requiresNames) then
            for k, v in mod.requiresNames do
                body = v .. ',\n' .. body
            end
        elseif not table.empty(mod.requires) then
            for k, v in mod.requires do
                body = v .. ',\n' .. body
            end
        else
            body = nil
        end

        if body then
            group.type:EnableHitTest()
            Tooltip.AddControlTooltip(group.type, { text = 'Mod Requirements', body = body })
        end
    end

    return group
end
