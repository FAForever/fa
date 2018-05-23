local UIUtil = import('/lua/ui/uiutil.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Popup = import('/lua/ui/controls/popups/popup.lua').Popup
local MultiLineText = import('/lua/maui/multilinetext.lua').MultiLineText
local RadioButton = import('/lua/ui/controls/radiobutton.lua').RadioButton
local Prefs = import('/lua/user/prefs.lua')

-- this version of Checkbox allows scaling of checkboxes
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local ToggleButton = import('/lua/ui/controls/togglebutton.lua').ToggleButton 
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local SkinsManager = import('/lua/ui/lobby/SkinsManager.lua')

local Factions = import('/lua/ui/lobby/SkinsManager.lua').Factions
 
local GUI = { isOpen = false } 

local controlList = {}
local controlMap = {}

local dialogWidth = 750
local dialogHeight = 790
local skinIconSize = 50
local skinInfoPosition = skinIconSize + 15
local skinInfoHeight = skinIconSize + 20
local skinsPerPage = math.floor((dialogWidth - 100) / skinInfoHeight)

local callback
 
local skins = {
    selectable = {},
    activated = {}, 
    colors = {
        desciption = 'FFA2A5A2', -- #FFA2A5A2
        normal = 'FFE9ECE9', -- #FFE9ECE9
        selected = import('/lua/ui/uiutil.lua').factionTextColor
    }
}

local skinTags = {
    { faction = 'CYBRAN', name = 'CYBRAN', filtered = false,   },
    { faction = 'UEF', name = 'UEF', filtered = false,   },
    { faction = 'AEON', name = 'AEON', filtered = false,  },
    { faction = 'SERAPHIM', name = 'SERAPHIM', filtered = false,   },
    { faction = 'NOMADS', name = 'NOMADS', filtered = false,   },
}

function CloseDialog()
    if GUI.isOpen then
       GUI.isOpen = false
       GUI.popup:Close()
    end
end

function CreateDialog(inParent, saveBehaviour) 
    callback = saveBehaviour

    GUI.dialog = Group(inParent)
    GUI.dialog.Width:Set(dialogWidth)
    GUI.dialog.Height:Set(dialogHeight)

    GUI.popup = Popup(inParent, GUI.dialog)
    GUI.popup.OnClose = function()
        GUI.isOpen = false
    end

    local title = UIUtil.CreateText(GUI.dialog, 'Unit Skin Manager', 22, UIUtil.titleFont)
    title:SetColor('B9BFB9') --#B9BFB9
    title:SetDropShadow(true)
    LayoutHelpers.AtHorizontalCenterIn(title, GUI.dialog, 0)
    LayoutHelpers.AtTopIn(title, GUI.dialog, 10)

    GUI.subtitle = UIUtil.CreateText(GUI.dialog, 'Select one skin for each faction and unit type from the list of available skins below', 
        13, UIUtil.bodyFont)
    GUI.subtitle:SetColor('B9BFB9') --#B9BFB9
    GUI.subtitle:SetDropShadow(true)
    LayoutHelpers.Below(GUI.subtitle, title, 5)
    LayoutHelpers.AtHorizontalCenterIn(GUI.subtitle, GUI.dialog, 0)
     
    GUI.status = UIUtil.CreateText(GUI.dialog, 'Activated Skin: ', 15, UIUtil.bodyFont )
    GUI.status:SetColor('B9BFB9') --#B9BFB9
    GUI.status:SetDropShadow(true)
    LayoutHelpers.AtRightIn(GUI.status, GUI.dialog, 15)
    LayoutHelpers.AtTopIn(GUI.status, GUI.dialog, 10)
    
    GUI.saveButton = UIUtil.CreateButtonWithDropshadow(GUI.dialog, '/BUTTON/medium/', "Save", -1)
    GUI.saveButton:UseAlphaHitTest(true)
    LayoutHelpers.AtRightIn(GUI.saveButton, GUI.dialog, 10)
    LayoutHelpers.AtBottomIn(GUI.saveButton, GUI.dialog, 15)
    Tooltip.AddControlTooltip(GUI.saveButton, {
       text = 'Save Unit Skins',
       body = 'Save currently selects unit skins.' })

    controlList = {}

    GUI.scroll = Group(GUI.dialog)

    LayoutHelpers.AtLeftIn(GUI.scroll, GUI.dialog, 5)
    GUI.scroll.Width:Set(function() return GUI.dialog.Width() - 25 end)
    GUI.scroll.Top:Set(function() return GUI.subtitle.Bottom() + 15 end)
    GUI.scroll.Bottom:Set(function() return GUI.saveButton.Top() - 10 end)

    skinsPerPage = math.floor((GUI.scroll.Height() - 10) / skinInfoHeight)

    UIUtil.CreateLobbyVertScrollbar(GUI.scroll, 1, 0, -10, 10)
    GUI.scroll.top = 1

    GUI.scroll.GetScrollValues = function(self, axis)
       return 1, table.getn(controlList), self.top, math.min(self.top + skinsPerPage - 1, table.getn(controlList))
    end

    GUI.scroll.ScrollLines = function(self, axis, delta)
       self:ScrollSetTop(axis, self.top + math.floor(delta))
    end

    GUI.scroll.ScrollPages = function(self, axis, delta)
       self:ScrollSetTop(axis, self.top + math.floor(delta) * skinsPerPage)
    end

    GUI.scroll.ScrollSetTop = function(self, axis, top)
       top = math.floor(top)
       if top == self.top then return end
       self.top = math.max( math.min(table.getn(controlList) - skinsPerPage + 1 , top), 1)
       self:CalcVisible()
    end

    GUI.scroll.CalcVisible = function(self)
       local top = self.top
       local bottom = self.top + skinsPerPage
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

    GUI.saveButton.OnClick = function(self)
        GUI.popup:Close()

        if callback then
           LOG('GUI.saveButton callback' .. table.getsize(skins.activated))
           callback(skins.activated)
        else
           LOG('GUI.saveButton SetSelectedSkins' .. table.getsize(skins.activated))
           SkinsManager.SaveSkins(skins.activated)
        end
        return skins.activated
    end

    RefreshSkinsList()

    GUI.scroll.HandleEvent = function(self, event)
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

    local position = 0
 
    GUI.filters = {}
    for key, tag in skinTags do
        GUI.filters[key] = CreateSkinsFilter(GUI.dialog, tag)
        Tooltip.AddControlTooltip(GUI.filters[key], {
           text = 'Filter '.. tag.faction ..' Skins',
           body = 'Toggle visibility of all skins for '.. tag.faction ..' units.' })
        LayoutHelpers.AtLeftIn(GUI.filters[key], GUI.dialog, position)
        LayoutHelpers.AtBottomIn(GUI.filters[key], GUI.dialog, 10)
        position = position + 110
    end
 

    GUI.isOpen = true

    return GUI.popup
end
 
function FilterSkins()
    local filterIN = {}
    local filterOT = {}
    for i, control in ipairs(controlList) do
        local filtered = true
        for name, tag in skinTags do
            if control.skin.tags[tag.faction] then
                filtered =  tag.filtered
            else 

            end
        end
        control.filtered = filtered

        if control.filtered then 
            table.insert(filterIN, control.skin.name)
        else 
            table.insert(filterOT, control.skin.name)
        end
    end

    GUI.scroll:ScrollSetTop(nil,2)
    GUI.scroll:ScrollSetTop(nil,1)
end

function CreateSkinsFilter(parent, tag)
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
    filterToggle.faction = tag.faction
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

            for key, skinTag in skinTags do
                if skinTag.faction == self.faction then
                   skinTag.filtered = not self.checked
                    LOG('skinTag ' .. tostring(self.faction) )
                end
            end
            
            FilterSkins()
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

function UpdateSkinCounters() 
    local skinsCount = table.getsize(skins.activated)
    GUI.status:SetText(LOCF("Activated Skins:  %d", skinsCount))
end

local posCounter = 1
function AppendSkins(skinlist, active, enabled, labelParam, labelSet)
    for uid, skin in skinlist do
        local label = labelParam or LOC(labelSet[uid])
        local entry = CreateSkinElement(GUI.scroll, skin, posCounter)
        if not enabled then
            entry.bg:Disable()
        end
        if active then
            SkinActivate(uid)
        end

        if label then
            entry.target:SetText(label)
        end
        posCounter = posCounter + 1
    end
end

function RefreshSkinsList()
    if controlList then
        for k, v in controlList do
            v:Destroy()
        end
    end

    controlList = {}
    controlMap = {}

    skins.selectable = import('/lua/ui/lobby/SkinsManager.lua').GetSelectableSkins()
    skins.activated = import('/lua/ui/lobby/SkinsManager.lua').GetSelectedSkins()

    --table.print(skins.activated,'skins.activated')

    -- reset state of skins 
    skins.active = {}
    skins.inactive = {}
    
    for uid, skin in skins.selectable do
        skin.tags = {} 
        skin.tags[skin.faction] = true 

        if skins.activated[uid] then
           skins.active[uid] = skin
           --WARN("skins.active "..uid.. " : "..skin.name)
        else
           skins.inactive[uid] = skin
           --WARN("skins.inactive "..uid.. " : "..skin.name)
        end
         
    end 
    -- append active skins 
    AppendSkins(skins.active, true, true)

    -- append inactive skins 
    AppendSkins(skins.inactive, false, true)
      
    UpdateSkinCounters()

    SkinSort()

    GUI.scroll.top = 1
    GUI.scroll:CalcVisible()
end

function SkinActivate(uid)
    
    controlMap[uid].bg:SetCheck(true, true) 
    controlMap[uid].name:SetColor(skins.colors.selected)
    controlMap[uid].target:SetColor(skins.colors.selected)

    if skins.activated[uid] then return end
    
    LOG('SkinsManager activated: ' .. skins.selectable[uid].title)

    local newSkin = skins.selectable[uid]
    local faction = newSkin.faction

    -- deactivate skins for the same faction and target unit such that
    -- there is only one skin selected for each faction and target unit
    for skinId, _ in skins.activated do
        local oldSkin = skins.selectable[skinId]
        if oldSkin.uid ~= newSkin.uid and
           oldSkin.faction == newSkin.faction and
           oldSkin.target == newSkin.target then
           SkinDeactivate(oldSkin.uid)
        end
    end 

    skins.activated[uid] = true

    UpdateSkinCounters()
end

function SkinDeactivate(uid)
 
    controlMap[uid].bg:SetCheck(false, true)
    controlMap[uid].name:SetColor(skins.colors.normal) 
    controlMap[uid].target:SetColor(skins.colors.normal)

    if not skins.activated[uid] then return end

    LOG('SkinsManager deactivate: ' .. skins.selectable[uid].title)

    skins.activated[uid] = nil

    UpdateSkinCounters()
end

function SkinSort()
    table.sort(controlList, function(a,b)
        -- sort skins by faction
        if a.skin.faction ~= b.skin.faction then
            return Factions[a.skin.faction].order < Factions[b.skin.faction].order
        else -- sort skins by title
           if a.skin.title ~= b.skin.title then
               return a.skin.title < b.skin.title
           else -- sort skins by uid
               return a.skin.uid < b.skin.uid
           end
        end
        return 0
    end)
end
 
function CreateSkinElement(parent, skin, Pos)
    local group = Bitmap(parent)

    group.filtered = false
    group.pos = Pos
    group.skin = skin 
    group.bg = Checkbox(group,
        UIUtil.SkinnableFile('/MODS/blank.dds'),
        UIUtil.SkinnableFile('/MODS/single.dds'),
        UIUtil.SkinnableFile('/MODS/single.dds'),
        UIUtil.SkinnableFile('/MODS/double.dds'),
        UIUtil.SkinnableFile('/MODS/disabled.dds'),
        UIUtil.SkinnableFile('/MODS/disabled.dds'),
            'UI_Tab_Click_01', 'UI_Tab_Rollover_01') 
    group.bg.Height:Set(skinIconSize + 10)
    group.bg.Width:Set(dialogWidth - 15)

    group.Height:Set(skinIconSize + 20)
    group.Width:Set(GUI.scroll.Width() - 5)
    LayoutHelpers.AtLeftTopIn(group, parent, 2, group.Height()*(Pos-1))
    LayoutHelpers.FillParent(group.bg, group)
    
    group.icon = Bitmap(group, skin.icon)
    group.icon.Height:Set(skinIconSize)
    group.icon.Width:Set(skinIconSize)
    group.icon:DisableHitTest()
    LayoutHelpers.AtLeftTopIn(group.icon, group, 10, 7)
    LayoutHelpers.AtVerticalCenterIn(group.icon, group)

    group.name = UIUtil.CreateText(group, skin.title, 14, UIUtil.bodyFont)
    group.name:SetColor(skins.colors.normal) 
    --group.name:SetFont('Arial Black', 12)
    group.name:DisableHitTest()
    LayoutHelpers.AtLeftTopIn(group.name, group, skinInfoPosition, 8)
    group.name:SetDropShadow(true)

    group.desc = MultiLineText(group, UIUtil.bodyFont, 12, skins.colors.desciption)
    group.desc:DisableHitTest()
    LayoutHelpers.AtLeftTopIn(group.desc, group, skinInfoPosition, 25)
    group.desc.Width:Set(group.Width() - group.icon.Width()-50)
    group.desc:SetText(skin.description)
      
    group.target = UIUtil.CreateText(group, '', 12, 'Arial Narrow Bold')
    group.target:DisableHitTest()
    group.target:SetColor(skins.colors.normal)
    group.target:SetFont('Arial Black', 12)
    group.faction = skin.faction

    if not skin.target then
        group.target:SetText(' skin_info.lua is missing unit target')
    else
        group.target:SetText(skin.faction .. ' ' .. skin.target .. ' Skin')
    end

    LayoutHelpers.AtRightTopIn(group.target, group, 12, 8)
     
    --group.faction = Bitmap(group, skin.factionIcon)
    --group.faction.Height:Set(20)
    --group.faction.Width:Set(20)
    --group.faction:DisableHitTest()
    ----LayoutHelpers.AtLeftTopIn(group.faction, group, skinInfoPosition, 8)
    --LayoutHelpers.LeftOf(group.faction, group.target, 4)
    --LayoutHelpers.AtTopIn(group.faction, group, 4)
    
    table.insert(controlList, group)
    controlMap[skin.uid] = group

     local uid = skin.uid
     group.bg.OnCheck = function(self, checked)
         if checked then
             SkinActivate(uid)
         else
             SkinDeactivate(uid)
         end
     end

    return group
end