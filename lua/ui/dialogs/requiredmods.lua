-- ==========================================================================================
-- * File       : lua/modules/ui/dialogs/requiredmods.lua 
-- * Authors    : FAF Community, KeyBlue
-- * Summary    : Contains UI for displaying the map required mods
-- ==========================================================================================
local Popup = import('/lua/ui/controls/popups/popup.lua').Popup
local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Mods = import('/lua/mods.lua')    
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Tooltip  = import('/lua/ui/game/tooltip.lua')


local dialogContent = nil
local popup = nil

MaxNameLength = 40
MaxDescriptionLength = 16
MaxHowtogetLength = 16

function CreateDialog(parent, scenario)
    dialogContent = Group(parent)
    dialogContent.Width:Set(750)
    dialogContent.Height:Set(350)

    popup = Popup(parent, dialogContent)

    local title = UIUtil.CreateText(dialogContent, "Required Mods", 24)
    LayoutHelpers.AtTopIn(title, dialogContent, 10)
    LayoutHelpers.AtHorizontalCenterIn(title, dialogContent)
    dialogContent.title = title
    
    local closeBtn = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _Close>")
    LayoutHelpers.AtBottomIn(closeBtn, dialogContent, 5)
    LayoutHelpers.AtHorizontalCenterIn(closeBtn, dialogContent)
    
    closeBtn.OnClick = function()
        popup:Close()
    end

    local availableMods, missingMods = filterMods(scenario)
    
    local availableTitle = UIUtil.CreateText(dialogContent, "Available Mods", 20)
    availableTitle:SetColor("55ff55")
    LayoutHelpers.Below(availableTitle, title)
    LayoutHelpers.AtLeftIn(availableTitle, dialogContent, 25)
    dialogContent.availableTitle = availableTitle
    
    local availableContainer = Group(dialogContent)
    availableContainer.Height:Set(function() return ((dialogContent.Height() - title.Height() - closeBtn.Height()) / 2) - availableTitle.Height()  end)
    availableContainer.Width:Set(function() return dialogContent.Width() - 18 end)
    availableContainer.top = 0
    LayoutHelpers.Below(availableContainer, availableTitle, 2)
    
    availableContainer.Display = {}
    CreateModElements(availableContainer, availableTitle, availableMods)

    local missingTitle = UIUtil.CreateText(dialogContent, "Missing Mods", 20)
    missingTitle:SetColor("ff5555")
    LayoutHelpers.Below(missingTitle, availableContainer)
    LayoutHelpers.AtLeftIn(missingTitle, dialogContent, 25)
    dialogContent.missingTitle = missingTitle
    
    local missingContainer = Group(dialogContent)
    missingContainer.Height:Set(function() return ((dialogContent.Height() - title.Height() - closeBtn.Height()) / 2)  - missingTitle.Height()  end)
    missingContainer.Width:Set(function() return dialogContent.Width() - 18 end)
    missingContainer.top = 0
    LayoutHelpers.Below(missingContainer, missingTitle, 2)
    
    
    local addInfoLocation = function(nextTo, offset1, offset2) 
        local availableInfo = UIUtil.CreateText(dialogContent, "Info", 17)
        availableInfo:SetColor("ffffff")
        LayoutHelpers.RightOf(availableInfo, nextTo, offset1)
        dialogContent.availableInfo = availableInfo
        local availableLocation = UIUtil.CreateText(dialogContent, "Location", 17)
        availableInfo:SetColor("ffffff")
        LayoutHelpers.RightOf(availableLocation, availableInfo, offset2)
        dialogContent.availableLocation = availableLocation
    end
    
    addInfoLocation(availableTitle, 195, 125)
    addInfoLocation(missingTitle, 213, 125)
    
    missingContainer.Display = {}
    CreateModElements(missingContainer, missingTitle, missingMods)
    
    return popup
end

function filterMods(scenario)
    local available = {}
    local missing = {}
    local allMods = Mods.AllMods()
    for _,mod in scenario.RequiredMods do
        local present = false
        for _,aMod in allMods do
            if mod.uid == aMod.uid then
                present = true
                break
            end
        end
        if present then
            table.insert(available, mod)
        else
            table.insert(missing, mod)
        end
    end
    
    return available, missing
end

function CreateModElements(parent, title, data)
    local display = parent.Display
    local function CreateElement(index)
        local function CreateExtra(parent, text, rightOf)
            bitMap = Bitmap(parent)
            bitMap.Height:Set(25)
            bitMap.Width:Set(150)
            LayoutHelpers.RightOf(bitMap, rightOf, 10)
            
            bitMap.text = UIUtil.CreateText(parent, text, 14, UIUtil.bodyFont)
            bitMap.text:DisableHitTest()
            LayoutHelpers.AtLeftTopIn(bitMap.text, bitMap, 10)
            
            return bitMap
        end
    
        local modGroup = Group(parent)
        modGroup.Height:Set(25)
        modGroup.Width:Set(function() return parent.Width() + 4 end)

        modGroup.bg = Bitmap(modGroup)
        modGroup.bg.Depth:Set(modGroup.Depth)
        LayoutHelpers.FillParent(modGroup.bg, modGroup)
        modGroup.bg.Right:Set(function() return modGroup.Right() - 400 end)

        modGroup.text = UIUtil.CreateText(parent, 'debug', 14, UIUtil.bodyFont)
        modGroup.text:DisableHitTest()
        LayoutHelpers.AtLeftTopIn(modGroup.text, modGroup, 10)
        
        modGroup.description = CreateExtra(modGroup, 'description', modGroup.bg)
        -- modGroup.description = Bitmap(modGroup)
        -- modGroup.description.Height:Set(25)
        -- modGroup.description.Width:Set(150)
        -- LayoutHelpers.RightOf(modGroup.description, modGroup.bg, 10)
        
        -- modGroup.description.text = UIUtil.CreateText(parent, 'description', 14, UIUtil.bodyFont)
        -- modGroup.description.text:DisableHitTest()
        -- LayoutHelpers.AtLeftTopIn(modGroup.description.text, modGroup.description, 10)
        
        
        modGroup.howtoget = CreateExtra(modGroup, 'howtoget', modGroup.description)
        -- modGroup.howtoget = Bitmap(modGroup)
        -- modGroup.howtoget.Height:Set(25)
        -- modGroup.howtoget.Width:Set(150)
        -- LayoutHelpers.RightOf(modGroup.howtoget, modGroup.description, 10)

        -- modGroup.howtoget.text = UIUtil.CreateText(parent, 'howtoget', 14, UIUtil.bodyFont)
        -- modGroup.howtoget.text:DisableHitTest()
        -- LayoutHelpers.AtLeftTopIn(modGroup.howtoget.text, modGroup.howtoget, 10)

        display[index] = modGroup
    end

    CreateElement(1)
    LayoutHelpers.Below(display[1], title, -3)
    LayoutHelpers.AtLeftIn(display[1], title, -5)

    local index = 2
    while display[table.getsize(display)].Bottom() + display[1].Height() < parent.Bottom() do
        CreateElement(index)
        LayoutHelpers.Below(display[index], display[index-1])
        index = index + 1
    end
    
    local numLines = function() return table.getsize(display) end
    local function DataSize()
        return table.getn(data)
    end
    
    -- called when the scrollbar for the control requires data to size itself
    -- GetScrollValues must return 4 values in this order:
    -- rangeMin, rangeMax, visibleMin, visibleMax
    -- aixs can be "Vert" or "Horz"
    parent.GetScrollValues = function(self, axis)
        local size = DataSize()
        return 0, size, self.top, math.min(self.top + numLines(), size)
    end

    -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    parent.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta))
    end

    -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    parent.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta) * numLines())
    end

    -- called when the scrollbar wants to set a new visible top line
    parent.ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.top then return end
        local size = DataSize()
        self.top = math.max(math.min(size - numLines() , top), 0)
        self:CalcVisible()
    end

    -- called to determine if the control is scrollable on a particular access. Must return true or false.
    parent.IsScrollable = function(self, axis)
        return true
    end

    -- determines what controls should be visible or not
    parent.CalcVisible = function(self)
        
        local function cutOff( line, cutOffPoint)
            if string.len(line) > cutOffPoint then
                line = string.sub(line,0, cutOffPoint) .. '...'
            end
            return line
        end
        
        for i, v in display do
            local iData = data[i + self.top]
            if iData then
                v.text:SetText(cutOff(iData.name, MaxNameLength))
                if iData.description and iData.description.key then 
                    v.description.text:SetText(cutOff(iData.description.key, MaxDescriptionLength))
                    if iData.description.tooltip then
                        Tooltip.AddControlTooltip(v.description, {text="Info",body=iData.description.tooltip})
                    else
                        Tooltip.RemoveControlTooltip(v.description)
                    end
                    v.description:Show()
                else
                    v.description.text:SetText('')
                    Tooltip.RemoveControlTooltip(v.description)
                end
                if iData.howtoget and iData.howtoget.key  then
                    v.howtoget.text:SetText(cutOff(iData.howtoget.key, MaxHowtogetLength))
                    if iData.howtoget.tooltip then
                        Tooltip.AddControlTooltip(v.howtoget, {text="Location",body=iData.howtoget.tooltip})
                    else
                        Tooltip.RemoveControlTooltip(v.howtoget)
                    end
                else
                    v.howtoget.text:SetText('')
                    Tooltip.RemoveControlTooltip(v.howtoget)
                end
            else
                v.text:SetText('')
                v.bg:SetSolidColor('00000000')
                v.description.text:SetText('')
                Tooltip.RemoveControlTooltip(display[i].description)
                v.howtoget.text:SetText('')
                Tooltip.RemoveControlTooltip(display[i].howtoget)
            end
        end
    end

    parent:CalcVisible()

    parent.HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            local lines = 1
            if event.WheelRotation > 0 then
                lines = -1
            end
            self:ScrollLines(nil, lines)
        end
    end
    
    UIUtil.CreateLobbyVertScrollbar(parent, -30, -25, -5)
end

function IsPlayable(scenario)
    if scenario.RequiredMods then
        local allMods = Mods.AllMods()
        for _,mod in scenario.RequiredMods do
            local present = false
            for _,aMod in allMods do
                if mod.uid == aMod.uid then
                    present = true
                    break
                end
            end
            if not present then
                return false
            end
        end
    end
    return true
end

function CountAvailableMods(scenario)
        
    local availableCount = 0
    local modMissing = false
    local availableMods = Mods.AllMods()
    for _,mod in scenario.RequiredMods do
        
        for _,aMod in availableMods do
            if mod.uid == aMod.uid then
                availableCount = availableCount + 1
                break
            end
        end
    end
    return availableCount, (table.getn(scenario.RequiredMods) - availableCount)
end

function CreateInitialDialog(parent, scenario)
    UIUtil.QuickDialog(parent, "You're missing mods required for this map",
                            "More Info", function() import("/lua/ui/dialogs/requiredmods.lua").CreateDialog(parent, scenario)  end,
                            "<LOC _OK>", nil,
                            nil, nil,
                            true,
                            {escapeButton = 2, enterButton = 2})
end