local ItemList = import('/lua/maui/itemlist.lua').ItemList
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Text = import('/lua/maui/text.lua').Text
local Border = import('/lua/maui/border.lua').Border
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local RadioGroup = import('/lua/maui/mauiutil.lua').RadioGroup
local Combo = import('/lua/ui/controls/combo.lua').Combo
local UIUtil = import('/lua/ui/uiutil.lua')
local Edit = import('/lua/maui/edit.lua').Edit

local dialog = false
local nameDialog = false
local activeFilters = {}
local activeFilterTypes = {}
local specialFilterControls = {}
local filterSet = {}
local currentArmy = GetFocusArmy()
local UnitList = {}
local CreationList = {}

local defaultEditField = false

local unselectedCheckboxFile = UIUtil.UIFile('/widgets/rad_un.dds')
local selectedCheckboxFile = UIUtil.UIFile('/widgets/rad_sel.dds')

local nameFilters = import('/lua/ui/dialogs/createunitfilters.lua').Filters

local function getItems()
    local idlist = EntityCategoryGetUnitList(categories.ALLUNITS)
    table.sort(idlist)

    return idlist
end

local function CreateNameFilter(data)
    local group = Group(dialog)
    group.Width:Set(dialog.Width)
    group.Height:Set(30)

    group.check = UIUtil.CreateCheckboxStd(group, '/dialogs/check-box_btn/radio')
    LayoutHelpers.AtLeftIn(group.check, group)
    LayoutHelpers.AtVerticalCenterIn(group.check, group)
    group.check.key = data.key
    if filterSet[data.key] == nil then
        filterSet[data.key] = {value = false, choices = {}}
    end
    if activeFilters[data.key] == nil then
        activeFilters[data.key] = {}
    end

    group.label = UIUtil.CreateText(group, data.title, 14, UIUtil.bodyFont)
    LayoutHelpers.RightOf(group.label, group.check)
    LayoutHelpers.AtVerticalCenterIn(group.label, group)

    if data.choices then
        group.items = {}
        for i, v in data.choices do
            local index = i
            group.items[index] = UIUtil.CreateCheckboxStd(group, '/dialogs/toggle_btn/toggle')
            if index == 1 then
                LayoutHelpers.AtLeftTopIn(group.items[index], group, 95)
            else
                LayoutHelpers.RightOf(group.items[index], group.items[index-1])
            end
            LayoutHelpers.AtVerticalCenterIn(group.items[index], group)

            group.items[index].label = UIUtil.CreateText(group.items[index], v.title, 10, UIUtil.bodyFont)
            LayoutHelpers.AtCenterIn(group.items[index].label, group.items[index])
            group.items[index].label:DisableHitTest()

            group.items[index].sortFunc = v.sortFunc
            group.items[index].filterKey = v.key
            group.items[index].key = data.key
            group.items[index].OnCheck = function(self, checked)
                filterSet[self.key].choices[self.filterKey] = checked
                self.label:SetColor(UIUtil.fontColor)
                if checked then
                    if not group.check:IsChecked() then
                        group.check:SetCheck(true)
                    end
                    activeFilters[self.key][self.filterKey] = self.sortFunc
                elseif activeFilters[self.key][self.filterKey] then
                    local otherChecked = false
                    for _, control in group.items do
                        if control ~= self then
                            if control:IsChecked() then
                                otherChecked = true
                                break
                            end
                        end
                    end
                    if not otherChecked then
                        group.check:SetCheck(false)
                    end
                    activeFilters[self.key][self.filterKey] = nil
                end
                RefreshList()
            end
            if filterSet[data.key].choices[v.key] == nil then
                filterSet[data.key].choices[v.key] = false
            end
            group.items[index]:SetCheck(filterSet[data.key].choices[v.key])
            if activeFilters[data.key] == nil then activeFilters[data.key] = {} end
        end
    else
        group.edit = Edit(group)
        group.edit:SetForegroundColor(UIUtil.fontColor)
        group.edit:SetBackgroundColor('ff333333')
        group.edit:SetHighlightForegroundColor(UIUtil.highlightColor)
        group.edit:SetHighlightBackgroundColor("880085EF")
        group.edit.Height:Set(15)
        group.edit.Width:Set(400)
        group.edit:SetText(filterSet[data.key].editText or '')
        group.edit:SetFont(UIUtil.bodyFont, 12)
        group.edit:SetMaxChars(20)
        LayoutHelpers.AtLeftIn(group.edit, group, 95)
        LayoutHelpers.AtVerticalCenterIn(group.edit, group)
        group.edit.filterKey = data.key
        group.edit.key = data.key
        group.edit.sortFunc = data.sortFunc

        group.edit.OnTextChanged = function(self, new, old)
            if new == '' then
                activeFilters[self.key][self.filterKey] = nil
                if group.check:IsChecked() then
                    group.check:SetCheck(false)
                end
            else
                filterSet[self.key].editText = new
                activeFilters[self.key][self.filterKey] = self.sortFunc
                if not group.check:IsChecked() then
                    group.check:SetCheck(true)
                end
            end
            RefreshList()
        end

        defaultEditField = group.edit

        specialFilterControls[data.key] = group.edit
    end

    group.check.OnCheck = function(self, checked)
        activeFilterTypes[self.key] = checked
        filterSet[data.key].value = checked
        local labelColor = 'ff555555'
        if checked then
            labelColor = UIUtil.fontColor
        end
        if group.items then
            for i, v in group.items do
                if not checked then
                    v:SetCheck(false, true)
                end
                v.label:SetColor(labelColor)
            end
        else

        end
        group.label:SetColor(labelColor)
        RefreshList()
    end
    group.check:SetCheck(filterSet[data.key].value)

    return group
end

function CreateDialog(x, y)
    if dialog then
        dialog:Destroy()
        dialog = false
        return
    end

    CreationList = {}

    dialog = Bitmap(GetFrame(0))
    dialog:SetSolidColor('CC000000')
    local NoArmies = math.ceil( ( table.getn(GetArmiesTable().armiesTable) / 2 ) + 1 )
    -- set window high. 400 pixel for the window + 30 pixel for every army line
    dialog.Height:Set(450 + 30 * NoArmies)
    dialog.Width:Set(550)
    dialog.Left:Set(function() return math.max(math.min(x, GetFrame(0).Right() - dialog.Width()), 0) end)
    dialog.Top:Set(function() return math.max(math.min(y, GetFrame(0).Bottom() - dialog.Height()), 0) end)
    dialog.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)

    local cancelBtn = UIUtil.CreateButtonStd(dialog, '/widgets/small', "Cancel", 12)
    LayoutHelpers.AtBottomIn(cancelBtn, dialog)
    LayoutHelpers.AtRightIn(cancelBtn, dialog)
    cancelBtn.OnClick = function(button)
        dialog:Destroy()
        dialog = false
    end

    local countLabel = UIUtil.CreateText(dialog, 'Count:', 12, UIUtil.bodyFont)
    LayoutHelpers.AtBottomIn(countLabel, dialog,10)
    LayoutHelpers.AtLeftIn(countLabel, dialog, 5)

    local count = Edit(dialog)
    count:SetForegroundColor(UIUtil.fontColor)
    count:SetBackgroundColor('ff333333')
    count:SetHighlightForegroundColor(UIUtil.highlightColor)
    count:SetHighlightBackgroundColor("880085EF")
    count.Height:Set(15)
    count.Width:Set(50)
    count:SetFont(UIUtil.bodyFont, 12)
    count:SetMaxChars(4)
    count:SetText('1')
    LayoutHelpers.RightOf(count, countLabel, 5)

    local createBtn = UIUtil.CreateButtonStd(dialog, '/widgets/small', "Create", 12)
    LayoutHelpers.AtBottomIn(createBtn, dialog)
    LayoutHelpers.AtHorizontalCenterIn(createBtn, dialog)
    createBtn.OnClick = function(button)
        for unitID, _ in CreationList do
            local numUnits = 1
            if type(tonumber(count:GetText())) == 'number' then
                numUnits = count:GetText()
            end
            for i = 1, numUnits do
                local cmd = 'CreateUnit ' .. unitID .. ' ' .. (currentArmy-1) .. ' ' .. x .. ' ' .. y
                ConExecuteSave(cmd)
            end
        end
        dialog:Destroy()
        dialog = false
    end

    local function SetFilters(filterTable)
        for filterGroup, groupControls in filterGroups do
            local key = groupControls.check.key
            if filterTable[key] ~= nil then
                LOG('setting key: ', key, ' to: ', filterTable[key].value)
                if groupControls.check:IsChecked() ~= filterTable[key].value then
                    groupControls.check:SetCheck(filterTable[key].value)
                end
                if groupControls.items then
                    for choiceIndex, choiceControl in groupControls.items do
                        if filterTable[key].choices[choiceControl.filterKey] ~= nil and choiceControl:IsChecked() ~= filterTable[key].choices[choiceControl.filterKey] then
                            choiceControl:SetCheck(filterTable[key].choices[choiceControl.filterKey])
                        end
                    end
                else
                    groupControls.edit:SetText(filterTable[key].editText)
                end
            end
        end
        RefreshList()
    end

    local function CreateArmySelectionSlot(parent, index, armyData)
        local group = Bitmap(parent)
        group.Height:Set(30)
        group.Width:Set(function() return parent.Width() / 2 end)

        local iconBG = Bitmap(group)
        iconBG.Height:Set(30)
        iconBG.Width:Set(30)
        iconBG:SetSolidColor(armyData.color)
        LayoutHelpers.AtLeftTopIn(iconBG, group)
        iconBG:DisableHitTest()

        local icon = Bitmap(iconBG)
        if armyData.civilian then
            icon:SetSolidColor('aaaaaaaa')
        else
            icon:SetTexture(UIUtil.UIFile(UIUtil.GetFactionIcon(armyData.faction)))
        end
        LayoutHelpers.FillParent(icon, iconBG)
        icon:DisableHitTest()

        -- Player / Ai name
        local name = UIUtil.CreateText(group, armyData.nickname, 12, UIUtil.bodyFont)
        LayoutHelpers.RightOf(name, icon, 2)
        LayoutHelpers.AtTopIn(name, group)
        name:SetColor('ffffffff')
        name:DisableHitTest()

        local army = UIUtil.CreateText(group, armyData.name, 12, UIUtil.bodyFont)
        LayoutHelpers.Below(army, name)
        army:DisableHitTest()

        group.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                if currentArmy == index then
                    self:SetSolidColor('cc00cc00')
                else
                    self:SetSolidColor('77007700')
                end
            elseif event.Type == 'MouseExit' then
                if currentArmy == index then
                    self:SetSolidColor('aa00aa00')
                else
                    self:SetSolidColor('00000000')
                end
            elseif event.Type == 'ButtonPress' then
                currentArmy = index
                for i, v in parent.armySlots do
                    if i == index then
                        v:SetSolidColor('aa00aa00')
                    else
                        v:SetSolidColor('00000000')
                    end
                end
            elseif event.Type == 'ButtonDClick' then
                ConExecute('SetFocusArmy '..tostring(currentArmy-1))
            end
        end
        if index == currentArmy then
            group:SetSolidColor('aa00aa00')
        end
        return group
    end

    local armiesGroup = Group(dialog)
    armiesGroup.Width:Set(dialog.Width)
    LayoutHelpers.AtLeftTopIn(armiesGroup, dialog)

    armiesGroup.armySlots = {}
    local lowestControl = false
    local NoArmies = math.ceil( ( table.getn(GetArmiesTable().armiesTable) / 2 ) + 1 )
    for i, val in GetArmiesTable().armiesTable do
                       
        armiesGroup.armySlots[i] = CreateArmySelectionSlot(armiesGroup, i, val)
        -- set the layout to left at the first army
        if i == 1 then
            LayoutHelpers.AtLeftTopIn(armiesGroup.armySlots[i],armiesGroup)
            lowestControl = armiesGroup.armySlots[i]
        -- Change layout to right after half army count
        elseif i == NoArmies then
            LayoutHelpers.RightOf(armiesGroup.armySlots[i],armiesGroup.armySlots[1])
            LayoutHelpers.AtTopIn(armiesGroup.armySlots[i],armiesGroup)
        else
            LayoutHelpers.Below(armiesGroup.armySlots[i],armiesGroup.armySlots[i-1])
        end
        if armiesGroup.armySlots[i].Bottom() > lowestControl.Bottom() then
            lowestControl = armiesGroup.armySlots[i]
        end
    end

    armiesGroup.Height:Set(function() return lowestControl.Bottom() - armiesGroup.armySlots[1].Top() end)

    local filterSetCombo = Combo(dialog, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
    filterSetCombo.Width:Set(340)
    LayoutHelpers.Below(filterSetCombo, armiesGroup, 5)
    filterSetCombo.OnClick = function(self, index, text, skipUpdate)
        SetFilters(self.keyMap[index])
    end

    local function RefreshFilterList(defName)
        filterSetCombo:ClearItems()
        filterSetCombo.itemArray = {}
        filterSetCombo.keyMap = {}
        local CurrentFilterSets = GetPreference('CreateUnitFilters')
        if CurrentFilterSets and table.getsize(CurrentFilterSets) > 0 then
            local index = 1
            local default = 1
            for filterName, filter in sortedpairs(CurrentFilterSets) do
                if filterName == defName then
                    default = index
                end
                filterSetCombo.itemArray[index] = string.format('%s', filterName)
                filterSetCombo.keyMap[index] = filter
                index = index + 1
            end
            filterSetCombo:AddItems(filterSetCombo.itemArray, default)
        end
    end

    local saveFilterSet = UIUtil.CreateButton(dialog,
        '/dialogs/toggle_btn/toggle-d_btn_up.dds',
        '/dialogs/toggle_btn/toggle-d_btn_down.dds',
        '/dialogs/toggle_btn/toggle-d_btn_over.dds',
        '/dialogs/toggle_btn/toggle-d_btn_dis.dds',
        'Save Filter', 10)
    saveFilterSet.label:SetFont(UIUtil.bodyFont, 10)
    LayoutHelpers.RightOf(saveFilterSet, filterSetCombo)
    LayoutHelpers.AtVerticalCenterIn(saveFilterSet, filterSetCombo)
    saveFilterSet.OnClick = function(self, modifiers)
        NameSet(function(name)
            local newFilterListing = {}
            if GetPreference('CreateUnitFilters') then
                newFilterListing = table.deepcopy(GetPreference('CreateUnitFilters'))
                newFilterListing[name] = filterSet
            else
                newFilterListing[name] = filterSet
            end
            SetPreference('CreateUnitFilters',newFilterListing)
            RefreshFilterList(name)
        end)
    end

    local delFilterSet = UIUtil.CreateButton(dialog,
        '/dialogs/toggle_btn/toggle-d_btn_up.dds',
        '/dialogs/toggle_btn/toggle-d_btn_down.dds',
        '/dialogs/toggle_btn/toggle-d_btn_over.dds',
        '/dialogs/toggle_btn/toggle-d_btn_dis.dds',
        'Delete Filter', 10)
    delFilterSet.label:SetFont(UIUtil.bodyFont, 10)
    LayoutHelpers.RightOf(delFilterSet, saveFilterSet)
    LayoutHelpers.AtVerticalCenterIn(delFilterSet, filterSetCombo)
    delFilterSet.OnClick = function(self, modifiers)
        local index = filterSetCombo:GetItem()
        if index >= 1 then
            local delName = filterSetCombo.itemArray[index]
            LOG(delName)
            local oldFilterSets = GetPreference('CreateUnitFilters')
            if oldFilterSets[delName] then
                oldFilterSets[delName] = nil
            end
            SetPreference('CreateUnitFilters',oldFilterSets)
            RefreshFilterList()
       end
    end

    RefreshFilterList()

    filterGroups = {}
    for filtIndex, filter in nameFilters do
        local index = filtIndex
        filterGroups[index] = CreateNameFilter(filter)
        if filtIndex == 1 then
            LayoutHelpers.Below(filterGroups[index], filterSetCombo)
            LayoutHelpers.AtLeftIn(filterGroups[index], dialog)
        else
            LayoutHelpers.Below(filterGroups[index], filterGroups[index-1])
        end
    end

    dialog.unitList = Group(dialog)
    dialog.unitList.Height:Set(function() return createBtn.Top() - filterGroups[table.getn(filterGroups)].Bottom() - 5 end)
    dialog.unitList.Width:Set(function() return dialog.Width() - 40 end)
    LayoutHelpers.Below(dialog.unitList, filterGroups[table.getn(filterGroups)])
    dialog.unitList.top = 0

    dialog.unitEntries = {}

    UIUtil.CreateVertScrollbarFor(dialog.unitList)

    local LineColors = {
        Up = '00000000', Sel_Up = 'ff447744',
        Over = 'ff444444', Sel_Over = 'ff669966',
    }

    local mouseover = false
    local function CreateElementMouseover(unitData,x,y)
        if mouseover then mouseover:Destroy() end
        mouseover = Bitmap(dialog)
        mouseover:SetSolidColor('dd115511')

        mouseover.img = Bitmap(mouseover)
        mouseover.img.Height:Set(40)
        mouseover.img.Width:Set(40)
        LayoutHelpers.AtLeftTopIn(mouseover.img, mouseover, 2,2)
        if DiskGetFileInfo(UIUtil.UIFile('/icons/units/'..unitData..'_icon.dds', true)) then
            mouseover.img:SetTexture(UIUtil.UIFile('/icons/units/'..unitData..'_icon.dds', true))
        else
            mouseover.img:SetTexture(UIUtil.UIFile('/icons/units/default_icon.dds'))
        end

        mouseover.name = UIUtil.CreateText(mouseover, __blueprints[unitData].Description, 14, UIUtil.bodyFont)
        LayoutHelpers.RightOf(mouseover.name, mouseover.img, 2)

        mouseover.desc = UIUtil.CreateText(mouseover, __blueprints[unitData].General.UnitName or unitData, 14, UIUtil.bodyFont)
        LayoutHelpers.AtLeftIn(mouseover.desc, mouseover, 44)
        LayoutHelpers.AtBottomIn(mouseover.desc, mouseover, 5)

        mouseover.Left:Set(x+20)
        mouseover.Top:Set(y+20)
        mouseover.Height:Set(function() return mouseover.img.Height() + 4 end)
        mouseover.Width:Set(function() return mouseover.img.Width() + math.max(mouseover.name.Width(), mouseover.desc.Width()) + 8 end)
        mouseover.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    end
    local function MoveMouseover(x,y)
        if mouseover then
            mouseover.Left:Set(x+20)
            mouseover.Top:Set(y+20)
        end
    end
    local function DestroyMouseover()
        if mouseover then
            mouseover:Destroy()
            mouseover = false
        end
    end

    local function CreateUnitElements()
        if dialog.unitEntries then
            for i, v in dialog.unitEntries do
                if v.bg then v.bg:Destroy() end
            end
            dialog.unitEntries = {}
        end

        local function CreateElement(index)
            dialog.unitEntries[index] = Bitmap(dialog.unitList)
            dialog.unitEntries[index].Left:Set(dialog.unitList.Left)
            dialog.unitEntries[index].Right:Set(dialog.unitList.Right)
            dialog.unitEntries[index].Height:Set(16)
            dialog.unitEntries[index].Checked = false
            dialog.unitEntries[index].HandleEvent = function(self, event)
                if event.Type == 'MouseEnter' then
                    CreateElementMouseover(self.unitID,event.MouseX,event.MouseY)
                    if self.Checked then
                        self:SetSolidColor(LineColors.Sel_Over)
                    else
                        self:SetSolidColor(LineColors.Over)
                    end
                elseif event.Type == 'MouseExit' then
                    DestroyMouseover()
                    if self.Checked then
                        self:SetSolidColor(LineColors.Sel_Up)
                    else
                        self:SetSolidColor(LineColors.Up)
                    end
                elseif event.Type == 'ButtonPress' and event.Modifiers.Left then
                    self.Checked = not self.Checked
                    if CreationList[self.unitID] then
                        CreationList[self.unitID] = nil
                    else
                        CreationList[self.unitID] = true
                        self:SetSolidColor(LineColors.Sel_Up)
                    end
                elseif event.Type == 'ButtonDClick' and event.Modifiers.Left then
                    local numUnits = 1
                    if type(tonumber(count:GetText())) == 'number' then
                        numUnits = count:GetText()
                    end
                    for i = 1, numUnits do
                        local cmd = 'CreateUnit ' .. self.unitID .. ' ' .. (currentArmy-1) .. ' ' .. x .. ' ' .. y
                        ConExecuteSave(cmd)
                    end
                    cancelBtn:OnClick()
                elseif event.Type == 'MouseMotion' then
                    MoveMouseover(event.MouseX,event.MouseY)
                end
            end

            dialog.unitEntries[index].id = UIUtil.CreateText(dialog.unitEntries[index], '', 12, UIUtil.bodyFont)
            LayoutHelpers.AtLeftTopIn(dialog.unitEntries[index].id, dialog.unitEntries[index])
        end

        CreateElement(1)
        LayoutHelpers.AtTopIn(dialog.unitEntries[1], dialog.unitList)

        local index = 2
        while dialog.unitEntries[table.getsize(dialog.unitEntries)].Top() + (2 * dialog.unitEntries[1].Height()) < dialog.unitList.Bottom() do
            CreateElement(index)
            LayoutHelpers.Below(dialog.unitEntries[index], dialog.unitEntries[index-1])
            index = index + 1
        end
    end
    CreateUnitElements()

    local numLines = function() return table.getsize(dialog.unitEntries) end

    local function DataSize()
        return table.getn(UnitList)
    end

    -- called when the scrollbar for the control requires data to size itself
    -- GetScrollValues must return 4 values in this order:
    -- rangeMin, rangeMax, visibleMin, visibleMax
    -- aixs can be "Vert" or "Horz"
    dialog.unitList.GetScrollValues = function(self, axis)
        local size = DataSize()
        --LOG(size, ":", self.top, ":", math.min(self.top + numLines, size))
        return 0, size, self.top, math.min(self.top + numLines(), size)
    end

    -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    dialog.unitList.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta))
    end

    -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    dialog.unitList.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta) * numLines())
    end

    -- called when the scrollbar wants to set a new visible top line
    dialog.unitList.ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.top then return end
        local size = DataSize()
        self.top = math.max(math.min(size - numLines() , top), 0)
        self:CalcVisible()
    end

    -- called to determine if the control is scrollable on a particular access. Must return true or false.
    dialog.unitList.IsScrollable = function(self, axis)
        return true
    end
    -- determines what controls should be visible or not
    dialog.unitList.CalcVisible = function(self)
        local function SetTextLine(line, data, lineID)
            line:Show()
            if CreationList[data.id] then
                line.Checked = true
                line:SetSolidColor(LineColors.Sel_Up)
            else
                line.Checked = false
                line:SetSolidColor(LineColors.Up)
            end
            line.unitID = data.id
            line.id:SetText(string.format('%s %5s %s', data.id, ' ', data.desc))
        end
        for i, v in dialog.unitEntries do
            if UnitList[i + self.top] then
                SetTextLine(v, UnitList[i + self.top], i + self.top)
            else
                v:Hide()
            end
        end
        --LOG(repr(ObjectiveLogData))
    end

    dialog.unitList.HandleEvent = function(control, event)
        if event.Type == 'WheelRotation' then
            local lines = 3
            if event.WheelRotation > 0 then
                lines = -3
            end
            control:ScrollLines(nil, lines)
        end
    end
    defaultEditField:AcquireFocus()
    RefreshList()
end

function RefreshList()
    if not dialog.unitList then return end
    UnitList = {}
    local totalList = getItems()
    for i, v in totalList do
        local allValid = true
        for filterType, filters in activeFilters do
            if activeFilterTypes[filterType] then
                local valid = false
                for filterIndex, filter in filters do
                    local specialText = ''
                    if specialFilterControls[filterIndex] then
                        specialText = specialFilterControls[filterIndex]:GetText()
                    end
                    if filter(v, specialText) then
                        valid = true
                        break
                    end
                end
                allValid = valid and allValid
            end
        end
        if allValid then

            table.insert(UnitList, {id = v, name = LOC(__blueprints[v].General.UnitName) or '', desc = LOC(__blueprints[v].Description) or ''})
        end
    end
    dialog.unitList.top = 0
    dialog.unitList:CalcVisible()
end

function NameSet(callback)
    -- Dialog already showing? Don't show another one
    if nameDialog then return end

    nameDialog = Bitmap(dialog, UIUtil.SkinnableFile('/dialogs/dialog_02/panel_bmp.dds'), "Marker Name Dialog")
    LayoutHelpers.AtCenterIn(nameDialog, GetFrame(0))
    nameDialog.Depth:Set(GetFrame(0):GetTopmostDepth() + 10)

    local label = UIUtil.CreateText(nameDialog, "Name your filter set:", 16, UIUtil.buttonFont)
    label.Top:Set(function() return nameDialog.Top() + 30 end)
    label.Left:Set(function() return nameDialog.Left() + 35 end)

    local cancelButton = UIUtil.CreateButtonStd(nameDialog, '/widgets02/small', "<LOC _CANCEL>", 12)
    cancelButton.Top:Set(function() return nameDialog.Top() + 112 end)
    cancelButton.Left:Set(function() return nameDialog.Left() + (((nameDialog.Width() / 4) * 1) - (cancelButton.Width() / 2)) end)
    cancelButton.OnClick = function(self, modifiers)
        nameDialog:Destroy()
        nameDialog = false
    end

    --TODO this should be in layout
    local nameEdit = Edit(nameDialog)
    LayoutHelpers.AtLeftTopIn(nameEdit, nameDialog, 35, 60)
    nameEdit.Width:Set(283)
    nameEdit.Height:Set(nameEdit:GetFontHeight())
    nameEdit:ShowBackground(false)
    nameEdit:AcquireFocus()
    UIUtil.SetupEditStd(nameEdit, UIUtil.fontColor, nil, nil, nil, UIUtil.bodyFont, 16, 30)

    local okButton = UIUtil.CreateButtonStd(nameDialog, '/widgets02/small', "<LOC _OK>", 12)
    okButton.Top:Set(function() return nameDialog.Top() + 112 end)
    okButton.Left:Set(function() return nameDialog.Left() + (((nameDialog.Width() / 4) * 3) - (okButton.Width() / 2)) end)
    okButton.OnClick = function(self, modifiers)
        local newName = nameEdit:GetText()
        callback(newName)
        nameDialog:Destroy()
        nameDialog = false
    end

    nameEdit.OnEnterPressed = function(self, text)
        okButton.OnClick()
    end
end