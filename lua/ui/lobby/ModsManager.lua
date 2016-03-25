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
local RestrictedData = import('/lua/ui/lobby/UnitsRestrictions.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

local ModBlacklist = import('/etc/faf/blacklist.lua').Blacklist
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

local modsTags = {
 UI       =  { key = 'UI', name = 'UI MODS',   filtered = false,  color = 'FF21AEDE', }, -- #FF21AEDE UI mod
 GAME     =  { key = 'GAME', name = 'GAME MODS', filtered = false, color = 'FFDE4521', }, -- #FFDE4521 game mod
 UNITS    =  { key = 'UNITS', name = 'UNITS',    filtered = false, color = 'FFDED621', }, -- #FFDED621 units mod  
 DISABLED =  { key = 'DISABLED', name = 'DISABLED', filtered = false, color = 'FF696A6A', }, -- #FF696A6A T2 changes
 LOCAL =  { key = 'LOCAL', name = 'LOCAL', filtered = false, color = 'FF696A6A', }, -- #FF696A6A T2 changes
}
 
--- Create the dialog for Mod Manager
-- @param parent UI control to create the dialog within.
-- @param IsHost Is the user opening the control the host (and hence able to edit?)
-- @param availableMods Present only if user is host. The availableMods map from lobby.lua.
function CreateDialog(parent, availableMods, saveBehaviour)
    IsHost = availableMods ~= nil
    callback = saveBehaviour

    modsAvailable = availableMods

    dialogContent = Group(parent)
    dialogContent.Width:Set(dialogWidth)
    dialogContent.Height:Set(dialogHeight)

    modsDialog = Popup(parent, dialogContent)
    modsDialog.OnClose = function()
        GUIOpen = false
    end

    -- Title
    local title = UIUtil.CreateText(dialogContent, 'Mods Manager', 20, UIUtil.titleFont)
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
    LayoutHelpers.AtLeftIn(SaveButton, dialogContent, -2)
    LayoutHelpers.AtBottomIn(SaveButton, dialogContent, 10)
     
    controlList = {}
    
    modsPerPage = math.floor((dialogHeight - 100) / modInfoHeight) -- 1
     
    -- Mod list
    scrollGroup = Group(dialogContent)
    
    LayoutHelpers.AtLeftIn(scrollGroup, dialogContent, 2) 
	scrollGroup.Top:Set(function() return subtitle.Bottom() + 5 end)
    scrollGroup.Bottom:Set(function() return SaveButton.Top() - 20 end)
    scrollGroup.Width:Set(function() return dialogContent.Width() - 20 end)
	  -- top, bottom
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
            --elseif index < top or index >= bottom then
            elseif visibleIndex < top or visibleIndex >= bottom then
                control:Hide()
                visibleIndex = visibleIndex + 1
            else
                control:Show()
                control.Left:Set(self.Left)
                --local vIndex = index
                local i = visibleIndex
                --lIndex = index or 1
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
            local activeUIMods = SetUtils.PredicateFilter(activeMods,
                function(uid)
                    return allMods[uid].ui_only
                end
            )
            local activeSimMods = SetUtils.Subtract(activeMods, activeUIMods)
            table.print(activeSimMods, 'activeSimMods')
            table.print(activeUIMods, 'activeUIMods')

            callback(activeSimMods, activeUIMods)
        else
            import('/lua/mods.lua').SetSelectedMods(activeMods)
        end

        return activeMods
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

    local position = 10 
    local filterGameMods = CreateModsFilter(dialogContent, modsTags.GAME)
    Tooltip.AddControlTooltip(filterGameMods, { 
        text = 'Filter Game Mods', 
        body = 'Toggle visiblity of all game mods in above list of mods.' } )
	   
    LayoutHelpers.AtRightIn(filterGameMods, dialogContent,position)
    LayoutHelpers.AtBottomIn(filterGameMods, dialogContent, 20)
    --filterGameMods.OnCheck = function(self, checked)
    --    local tag = modsTags[self.tag]
    --	local color = checked and self.selectedColor or self.unselectedColor
	--	self.bg:SetSolidColor(color)
    --    tag.filtered = checked
    --    FilterMods()
	--end    
    position = position + 85
    local filterUIMods = CreateModsFilter(dialogContent, modsTags.UI)
    Tooltip.AddControlTooltip(filterUIMods, { 
        text = 'Filter UI Mods', 
        body = 'Toggle visiblity of all UI mods in above list of mods.' } )
    LayoutHelpers.AtRightIn(filterUIMods, dialogContent, position)
    LayoutHelpers.AtBottomIn(filterUIMods, dialogContent, 20)
    
    position = position + 85
    local filterDisabledMods = CreateModsFilter(dialogContent, modsTags.DISABLED)
    Tooltip.AddControlTooltip(filterDisabledMods, { 
        text = 'Filter Disabled Mods', 
        body = 'Toggle visiblity of all disabled mods in above list of mods.' } )
    LayoutHelpers.AtRightIn(filterDisabledMods, dialogContent, position)
    LayoutHelpers.AtBottomIn(filterDisabledMods, dialogContent, 20)
         
    --position = position + 85
    --local filterUNITS = CreateModsFilter(dialogContent, modsTags.UNITS)
    --LayoutHelpers.AtRightIn(filterUNITS, dialogContent, position)
    --LayoutHelpers.AtBottomIn(filterUNITS, dialogContent, 20)
     
    GUIOpen = true

    return modsDialog
end

function FilterMods()
    --LOG('ModsManager filtering mods...')
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
 
    local checkbox = Checkbox(parent,
    UIUtil.SkinnableFile('/MODS/blank.dds'),
    UIUtil.SkinnableFile('/MODS/single.dds'),
    UIUtil.SkinnableFile('/MODS/single.dds'),
    UIUtil.SkinnableFile('/MODS/double.dds'),
    UIUtil.SkinnableFile('/MODS/disabled.dds'),
    UIUtil.SkinnableFile('/MODS/disabled.dds'),
		    'UI_Tab_Click_01', 'UI_Tab_Rollover_01') 

    checkbox.tag = tag.key
    checkbox.selectedColor  = tag.color  --#317E807E,FF363636
	checkbox.unselectedColor = '317E807E' 
    checkbox.border = Bitmap(checkbox)
    LayoutHelpers.AtVerticalCenterIn(checkbox.border, checkbox)
	LayoutHelpers.AtHorizontalCenterIn(checkbox.border, checkbox)
    checkbox.bg = Bitmap(checkbox)
    LayoutHelpers.AtVerticalCenterIn(checkbox.bg, checkbox)
	LayoutHelpers.AtHorizontalCenterIn(checkbox.bg, checkbox)
     
    checkbox.label = UIUtil.CreateText(checkbox, tag.name, 12, 'Arial Bold')
    checkbox.label:SetColor('FFB4B6B4') --#FFB4B6B4
    LayoutHelpers.AtVerticalCenterIn(checkbox.label, checkbox)
	LayoutHelpers.AtHorizontalCenterIn(checkbox.label, checkbox)

    local height = checkbox.label.Height() + 15  -- function() return label.Height() + 5 end
    local width = 80
     
    checkbox.Height:Set(height)
    checkbox.Width:Set(width) 
    checkbox:SetCheck(true, false)
    checkbox.OnCheck = function(self, checked)
        local color = self.unselectedColor
        local modTag = modsTags[self.tag]
        if modTag then
           modTag.filtered = not checked
           color = checked and modTag.color or color 
        end
 		--self.bg:SetSolidColor(color)
        FilterMods()
	end 

    checkbox.border.Width:Set(width) 
    checkbox.border.Height:Set(height)

	checkbox.bg.Width:Set(width - 2) 
    checkbox.bg.Height:Set(height - 2)
	  
    return checkbox 
end
    
local function UpdateModsCounters()
    subtitle:SetText(LOCF("%d game mods and %d UI mods activated", numEnabledSimMods, numEnabledUIMods))
end

local UnitsAnalyzer = import('/lua/ui/lobby/UnitsAnalyzer.lua')

local function GetModUnits(mod)
    local searchMods =  {}
    searchMods[mod.uid] = mod 
    return GetModsUnits(searchMods) 
end

local function GetModsUnits(searchMods) 
    local bps = UnitsAnalyzer.GetBlueprints(searchMods, true)
    bps = table.merged(bps.Units, bps.Enhancements)
    return bps
end

local function GetModsFiles(mod, pattern)
    local units = '*_unit.bp'
     
    for k,file in DiskFindFiles(mod.location, pattern) do
        
    	BlueprintLoaderUpdateProgress()
        safecall("loading mod blueprint "..file, doscript, file)
    end
end

--- Initialise the mod list UI.
function RefreshModsList()
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
        mod.tags = {}
        mod.units = {}

        --for id, bp in Blueprints.All do
        --    if bp.Mod.uid == uid then
        --        mod.tags['UNITS'] = true
        --        mod.units[id] = bp
        --    end
        --end

        if ModBlacklist[uid] then
            -- value is a message explaining why it's blacklisted
            mod.tags['DISABLED'] = true
            blacklistedMods[uid] = mod
        elseif mod.enabled == false then
            mod.tags['DISABLED'] = true
            disabledMods[uid] = mod
        else
            -- check for the dependencies of mods are installed
            local dependencies = Mods.GetDependencies(uid)
            modDependencyMap[uid] = dependencies
            if dependencies.missing then
                mod.tags['DISABLED'] = true
                missingDepsMods[uid] = mod
            elseif dependencies.requires then
                -- Construct backward-dependency map for this mod (so we can disable this one if
                -- someone turns off something we depend on)
                for k, v in dependencies.requires do
                    -- Dependency on a blacklisted mod?
                    if ModBlacklist[k] then
                        mod.tags['DISABLED'] = true
                        missingDepsMods[uid] = mod
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
                        if not innerMod.ui_only and not activeSimMods[innerUid] then
                            mod.tags['DISABLED'] = true
                            missingDepsMods[uid] = mod
                            break
                        end
                    end
                end

                if missingDepsMods[uid] then
                    mod.type = 'X'
                else
                    mod.type = 'UI'
                    mod.tags['UI'] = true

                    if activeMods[uid] then
                        activeUIMods[uid] = mod
                    else
                        inactiveUIMods[uid] = mod
                    end
                end
            else
                mod.tags['GAME'] = true
                -- We only care about everyone having it if it's a sim mod, and in this case we
                -- disable it.
                if not EveryoneHasMod(uid) then
                    mod.type = 'X'
                    mod.tags['DISABLED'] = true
                    notInstalledMods[uid] = mod
                elseif activeMods[uid] then
                    mod.type = 'GAME'
                    --mod.units = GetModsUnits(mod)
                    --if table.getsize(mod.units) > 0 then
                    --    mod.tags['UNITS'] = true
                    --end
                    activeSimMods[uid] = mod
                -- exclude sim mods that are missing dependency   
                elseif not missingDepsMods[uid] then
                    mod.type = 'GAME'
                    --mod.units = GetModsUnits(mod)
                    --if table.getsize(mod.units) > 0 then
                    --    mod.tags['UNITS'] = true
                    --end
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
    local function AppendMods(modlist, active, enabled, labelParam, labelSet)
        for k, mod in modlist do
            
            local label = labelParam or LOC(labelSet[k])
            local entry = CreateListElement(scrollGroup, mod, posCounter)
            --LOG('MOD  AppendMod '  .. tostring(label) .. '  ' .. mod.name)
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

    local function UpdateMods(modsList)
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
    --UpdateMods(activeSimMods)
    
    -- Create entries for the list of interesting mods.
    --LOG('MOD  AppendMods --------------activeSimMods')
    AppendMods(activeSimMods, true, true)
    AppendMods(activeUIMods, true, true)
    if IsHost then
        --UpdateMods(inactiveSimMods)
        AppendMods(inactiveSimMods, false, true)
    end
    --LOG('MOD  AppendMods --------------inactiveUIMods')
    AppendMods(inactiveUIMods, false, true)
    --LOG('MOD  AppendMods --------------disabledMods')
    AppendMods(disabledMods, false, false)
    --LOG('MOD  AppendMods --------------notInstalledMods')
    AppendMods(notInstalledMods, false, false, LOC('<LOC uimod_0019>Players missing mod'))
    --LOG('MOD  AppendMods --------------missingDepsMods')
    AppendMods(missingDepsMods, false, false, LOC('<LOC uimod_0020>Missing dependency'))
    --LOG('MOD  AppendMods --------------blacklistedMods')
    AppendMods(blacklistedMods, false, false, nil, ModBlacklist)

    numEnabledUIMods = table.getsize(activeUIMods)
    numEnabledSimMods = table.getsize(activeSimMods)

    UpdateModsCounters()

    SortMods('name')

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

    UpdateModsCounters()

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
    UpdateModsCounters()
end

function SortMods(sortBy)
	table.sort(controlList, function(a,b)
        -- sort mods first by type and then by name
        local uid = a.modInfo.uid
        if activeMods[a.modInfo.uid] and 
           not activeMods[b.modInfo.uid] then 
           return true  
        elseif not activeMods[a.modInfo.uid] and 
           activeMods[b.modInfo.uid] then 
           return false 
        else
            if a.modInfo.type == b.modInfo.type then 
                if a.modInfo.name == b.modInfo.name then 
                    return tostring(a.modInfo.version) < tostring(b.modInfo.version)  
                else
                    return a.modInfo.name < b.modInfo.name  
                end
            else
                return a.modInfo.type > b.modInfo.type  
            end
        end  
        return 0
	end)	
	 
end
function CreateListElement(parent, modInfo, Pos)
    local group = Group(parent)
    -- changed fixed-size checkboxes to scalable checkboxes

    group.filtered = false

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
   
    group.pos = Pos
    group.modInfo = modInfo

    LayoutHelpers.FillParent(group.bg, group)

    group.icon = Bitmap(group, modInfo.icon)
    group.icon.Height:Set(modIconSize)
    group.icon.Width:Set(modIconSize)
    group.icon:DisableHitTest()
    LayoutHelpers.AtLeftTopIn(group.icon, group, 10, 7)
    LayoutHelpers.AtVerticalCenterIn(group.icon, group)

    group.name = UIUtil.CreateText(group, modInfo.name, 14, UIUtil.bodyFont)
    group.name:SetColor('FFE9ECE9') -- #FFE9ECE9
    group.name:DisableHitTest()
    LayoutHelpers.AtLeftTopIn(group.name, group, modInfoPosition, 5)
    group.name:SetDropShadow(true)
    
    group.desc = MultiLineText(group, UIUtil.bodyFont, 12, 'FFBFC1BF')-- #FFBFC1BF
    group.desc:DisableHitTest()
    LayoutHelpers.AtLeftTopIn(group.desc, group, modInfoPosition, 25)
    --group.desc.Height:Set(modInfoHeight)
    group.desc.Width:Set(group.Width() - group.icon.Width()-50)
    group.desc:SetText(modInfo.description)
    
    group.type = UIUtil.CreateText(group, '', 12, 'Arial Narrow Bold')
    group.type:DisableHitTest()
    group.type:SetColor('B9BFB9') -- #B9BFB9
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
                table.print(allMods[uid], 'actived mod')
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
