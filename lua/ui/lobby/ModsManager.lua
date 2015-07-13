local Mods = import('/lua/mods.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local MultiLineText = import('/lua/maui/multilinetext.lua').MultiLineText
local Popup = import('/lua/ui/controls/popups/popup.lua').Popup
local RadioButton = import('/lua/ui/controls/radiobutton.lua').RadioButton
local Prefs = import('/lua/user/prefs.lua')
local Checkbox = import('/lua/ui/controls/Checkbox.lua').Checkbox
local ModBlacklist = import('/etc/faf/blacklist.lua').Blacklist
local SetUtils = import('/lua/system/setutils.lua')
local GUIOpen = false
local IsHost = false

local controlList = {}
local controlMap = {}

local ELEMENTS_PER_PAGE = 7

-- Counters for the benefit of the UI.
local numEnabledUIMods = 0
local numEnabledSimMods = 0

local scrollGroup
local dialogContent
local subtitle
local modsDialog

local callback

-- The availableMods map from lobby.lua.
local modsAvailable

-- The set of active mods (maps uids to true)
local activeMods
local allMods

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

--- Returns true iff every peer in the game reports having a mod with the given id installed.
local function EveryoneHasMod(modId)
    if not IsHost then
        return true
    end

    for peerId, peerMods in modsAvailable do
        if not peerMods[modId] then
            return false
        end
    end

    return true
end

--- Show the dialog
-- @param parent UI control to create the dialog within.
-- @param IsHost Is the user opening the control the host (and hence able to edit?)
-- @param availableMods Present only if user is host. The availableMods map from lobby.lua.
function CreateDialog(parent, availableMods, saveBehaviour)
    IsHost = availableMods ~= nil
    callback = saveBehaviour

    modsAvailable = availableMods

    dialogContent = Group(parent)
    dialogContent.Width:Set(557)
    dialogContent.Height:Set(602)

    modsDialog = Popup(parent, dialogContent)
    modsDialog.OnClose = function()
        GUIOpen = false
    end

    -- Title
    local title = UIUtil.CreateText(dialogContent, 'Mod Manager', 17, 'Arial')
    title:SetColor('B9BFB9')
    title:SetDropShadow(true)
    LayoutHelpers.AtHorizontalCenterIn(title, dialogContent, 0)
    LayoutHelpers.AtTopIn(title, dialogContent, 10)
        
    -- SubTitle: display counts of how many mods are enabled.
    subtitle = UIUtil.CreateText(dialogContent, '', 12, 'Arial')
    subtitle:SetColor('B9BFB9')
    subtitle:SetDropShadow(true)
    LayoutHelpers.AtHorizontalCenterIn(subtitle, dialogContent, 0)
    LayoutHelpers.AtTopIn(subtitle, dialogContent, 26)
        
    -- Save button
    local SaveButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "Ok", -1)
    LayoutHelpers.AtLeftIn(SaveButton, dialogContent, -2)
    LayoutHelpers.AtBottomIn(SaveButton, dialogContent, 10)

    -- Mod list
    scrollGroup = Group(dialogContent)
    scrollGroup.Width:Set(539)
    scrollGroup.Height:Set(504)
    LayoutHelpers.AtLeftTopIn(scrollGroup, dialogContent, 0, 47)
    UIUtil.CreateLobbyVertScrollbar(scrollGroup, 1, 0, -10, 10)
    controlList = {}
    scrollGroup.top = 1
    
    scrollGroup.GetScrollValues = function(self, axis)
        return 1, table.getn(controlList), self.top, math.min(self.top + ELEMENTS_PER_PAGE - 1, table.getn(controlList))
    end
    
    scrollGroup.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta))
    end
    
    scrollGroup.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta) * ELEMENTS_PER_PAGE)
    end
    
    scrollGroup.ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.top then return end
        self.top = math.max(math.min(table.getn(controlList) - ELEMENTS_PER_PAGE + 1 , top), 1)
        self:CalcVisible()
    end
    
    scrollGroup.CalcVisible = function(self)
        local top = self.top
        local bottom = self.top + ELEMENTS_PER_PAGE
        for index, control in ipairs(controlList) do
            if index < top or index >= bottom then
                control:Hide()
            else
                control:Show()
                control.Left:Set(self.Left)
                local lIndex = index
                local lControl = control
                control.Top:Set(function() return self.Top() + ((lIndex - top) * lControl.Height()) end)
            end
        end
    end
    
    SaveButton.OnClick = function(self)
        modsDialog:Close()
        GUIOpen = false
        if callback then
            local activeUIMods = SetUtils.PredicateFilter(activeMods,
                function(uid)
                    return allMods[uid].ui_only
                end
            )
            local activeSimMods = SetUtils.Subtract(activeMods, activeUIMods)


            table.print(activeSimMods)
            table.print(activeUIMods)

            WARN("WHAAAT")

            callback(activeSimMods, activeUIMods)
        else
            import('/lua/mods.lua').SetSelectedMods(activeMods)
        end

        return activeMods
    end

    Refresh_Mod_List()

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

    GUIOpen = true

    return modsDialog
end

function UpdateEnabledModCounterDisplay()
    subtitle:SetText(LOCF("%d game mods and %d UI mods activated", numEnabledSimMods, numEnabledUIMods))
end

--- Initialise the mod list UI.
function Refresh_Mod_List()
    if controlList then
        for k, v in controlList do
            v:Destroy()
        end
    end

    controlList = {}
    controlMap = {}

    allMods = Mods.AllSelectableMods()
    activeMods = Mods.GetSelectedMods()

    local activeSimMods = {}
    local activeUIMods = {}
    local inactiveSimMods = {}
    local inactiveUIMods = {}

    -- Mods that are disabled by the mod_info flag
    local disabledMods = {}

    -- Mods that are disabled because not everyone has them
    local notInstalledMods = {}

    -- Mods that are disabled because dependencies are not installed
    local missingDepsMods = {}

    -- Mods that are disabled by the FAF blacklist
    local blacklistedMods = {}

    -- Construct various filtered lists of mods. We then concatenate these to form the list.
    for uid, mod in allMods do
        if ModBlacklist[uid] then
            -- Value is a message explaining why it's blacklisted
            blacklistedMods[uid] = mod
        elseif mod.enabled == false then
            disabledMods[uid] = mod
        else
            -- Are all the dependencies of this mod installed?
            local dependencies = Mods.GetDependencies(uid)
            modDependencyMap[uid] = dependencies
            if dependencies.missing then
                missingDepsMods[uid] = mod
            elseif dependencies.requires then
                -- Construct backward-dependency map for this mod (so we can disable this one if
                -- someone turns off something we depend on)
                for k, v in dependencies.requires do
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
                        if not innerMod.ui_only and not activeSimMods[innerUid] then
                            missingDepsMods[uid] = mod
                            break
                        end
                    end
                end

                if not missingDepsMods[uid] then
                    if activeMods[uid] then
                        activeUIMods[uid] = mod
                    else
                        inactiveUIMods[uid] = mod
                    end
                end
            else
                -- We only care about everyone having it if it's a sim mod, and in this case we
                -- disable it.
                if not EveryoneHasMod(uid) then
                    notInstalledMods[uid] = mod
                elseif activeMods[uid] then
                    activeSimMods[uid] = mod
                else
                    inactiveSimMods[uid] = mod
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

    local posCounter = 1
    --- Append the given list of mods to the UI, applying the given label and activeness state to
    -- each.
    local function appendMods(modlist, active, enabled, labelParam, labelSet)
        for k, v in modlist do
            local label = labelParam or LOC(labelSet[k])

            local entry = CreateListElement(scrollGroup, v, posCounter)
            if not enabled then
                entry.bg:Disable()
            end

            entry.bg:SetCheck(active, true)

            if label then
                entry.type:SetText(label)
            end
            posCounter = posCounter + 1
        end
    end

    -- Create entries for the list of interesting mods.
    appendMods(activeSimMods, true, true)
    appendMods(activeUIMods, true, true)
    if IsHost then
        appendMods(inactiveSimMods, false, true)
    end
    appendMods(inactiveUIMods, false, true)
    appendMods(disabledMods, false, false)
    appendMods(notInstalledMods, false, false, LOC('<LOC uimod_0019>Players missing mod'))
    appendMods(missingDepsMods, false, false, LOC('<LOC uimod_0020>Missing dependency'))
    appendMods(blacklistedMods, false, false, nil, ModBlacklist)

    numEnabledUIMods = table.getsize(activeUIMods)
    numEnabledSimMods = table.getsize(activeSimMods)

    UpdateEnabledModCounterDisplay()

    scrollGroup.top = 1
    scrollGroup:CalcVisible()
end

--- Activate the mod with the given uid
-- @param isRecursing Indicates this is a recursve call (usually pulling in dependencies), so should
--                    not prompt the user for input.
-- @param visited The set of mods visited during this recursive set of calls (used to break cycles)
function ActivateMod(uid, isRecursing, visited)
    if activeMods[uid] then
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
        -- Any conflicting mods activated? We desugared exclusive mods to a universal conflict set, so
        -- those are handled here, too.
        if deps.conflicts then
            -- List of uuids that need to be disabled for this mod to work.

            WARN("Activating "..uid)
            local activatedConflictingMods = {}
            for uid, _ in deps.conflicts do
                if activeMods[uid] then
                    WARN(uid .. " EEK!")
                    table.insert(activatedConflictingMods, uid)
                end
            end

            -- Closure copy
            local thisUID = uid
            local doEnable = function()
                for k, uid in activatedConflictingMods do
                    DeactivateMod(uid)
                    ActivateMod(thisUID, true, visited)
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
            end
        end
    end

    activeMods[uid] = true
    controlMap[uid].bg:SetCheck(true, true)

    if allMods[uid].ui_only then
        numEnabledUIMods = numEnabledUIMods + 1
    else
        numEnabledSimMods = numEnabledSimMods + 1
    end
    UpdateEnabledModCounterDisplay()
end

function DeactivateMod(uid, visited)
    if not activeMods[uid] then
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

    activeMods[uid] = nil
    controlMap[uid].bg:SetCheck(false, true)

    if allMods[uid].ui_only then
        numEnabledUIMods = numEnabledUIMods - 1
    else
        numEnabledSimMods = numEnabledSimMods - 1
    end
    UpdateEnabledModCounterDisplay()
end

function CreateListElement(parent, modInfo, Pos)
    local group = Group(parent)
    group.bg = Checkbox(group,
        UIUtil.SkinnableFile('/MODS/blank.dds'),
        UIUtil.SkinnableFile('/MODS/single.dds'),
        UIUtil.SkinnableFile('/MODS/single.dds'),
        UIUtil.SkinnableFile('/MODS/double.dds'),
        UIUtil.SkinnableFile('/MODS/disabled.dds'),
        UIUtil.SkinnableFile('/MODS/disabled.dds'),
        ''
    )
    group.Height:Set(group.bg.Height())
    group.Width:Set(group.bg.Width())
    LayoutHelpers.AtLeftTopIn(group, parent, 0, group.Height()*(Pos-1))
    
    group.pos = Pos
    group.modInfo = modInfo

    LayoutHelpers.FillParent(group.bg, group)

    group.icon = Bitmap(group, modInfo.icon)
    group.icon.Height:Set(56)
    group.icon.Width:Set(56)
    group.icon:DisableHitTest()
    LayoutHelpers.AtLeftTopIn(group.icon, group, 7, 7)

    group.name = UIUtil.CreateText(group, modInfo.name, 14, UIUtil.bodyFont)
    group.name:SetColor('B9BFB9')
    group.name:DisableHitTest()
    LayoutHelpers.AtLeftTopIn(group.name, group, 80, 10)
    group.name:SetDropShadow(true)
    
    group.desc = MultiLineText(group, UIUtil.bodyFont, 12, 'B9BFB9')
    group.desc:DisableHitTest()
    LayoutHelpers.AtLeftTopIn(group.desc, group, 80, 30)
    group.desc.Height:Set(40)
    group.desc.Width:Set(group.Width()-86)
    group.desc:SetText(modInfo.description)
    
    group.type = UIUtil.CreateText(group, '', 10, 'Arial Narrow Bold')
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
                ActivateMod(uid)
            else
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
