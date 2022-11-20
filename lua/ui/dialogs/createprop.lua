local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Combo = import("/lua/ui/controls/combo.lua").Combo
local UIUtil = import("/lua/ui/uiutil.lua")
local Edit = import("/lua/maui/edit.lua").Edit
local options = import("/lua/user/prefs.lua").GetFromCurrentProfile('options')

local dialog, nameDialog, defaultEditField
local activeFilters, activeFilterTypes, specialFilterControls, filterSet = {}, {}, {}, {}
local UnitList, CreationList = {}, {}
local __blueprints

local TableGetN = table.getn

local ChoiceColumns = options.spawn_menu_filter_columns or 5

local FolterListTabs = function()
    local ssub, gsub = string.sub, string.gsub
    local listicle, folders = {}, {}

    for id, bp in __blueprints do
        if 'prop.bp' == ssub(id, -7) then
            local folder = ssub(id,string.find(id,'%/[^%/]+%/[^%/]+%/'))
            if not folders[folder] then
                folders[folder] = true
            end
        end
    end

    for folder in folders do
        specialFilterControls[folder] = folder
        table.insert(listicle, {
            title = ssub(gsub(folder, '%b//', ''),1,-2),
            key = folder,
            sortFunc = function(ID, folder) return folder == ssub(ID, 1, string.len(folder)) end
        })
    end

    return listicle
end

local nameFilters = {
    {
        title = 'Search',
        key = 'custominput',
        sortFunc = function(unitID, text)
            local bp = __blueprints[unitID]
            local desc = string.lower(LOC(bp.Description or ''))
            local name = string.lower(LOC(bp.General.UnitName or ''))
            text = string.lower(text)
            return string.find(unitID, text) or string.find(desc, text) or string.find(name, text)
        end,
    },
    {
        title = 'Folder',
        key = 'sourcefolder',
        choices = FolterListTabs(),
    },
}

local function getItems()
    local props = {}
    for id, bp in __blueprints do
        if string.find(id, 'prop.bp') then
            table.insert(props, id)
        end
    end
    return props
end

local function CreateNameFilter(data)
    local group = Group(dialog)
    group.Width:Set(dialog.Width)
    if data.choices and data.choices[1] and TableGetN(data.choices) > ChoiceColumns then
        group.Height:Set(30 + math.floor((TableGetN(data.choices)-1)/ChoiceColumns) * 25)
    else
        group.Height:Set(30)
    end

    group.check = UIUtil.CreateCheckboxStd(group, '/dialogs/check-box_btn/radio')
    LayoutHelpers.AtLeftIn(group.check, group)
    if data.choices and data.choices[1] and TableGetN(data.choices) > ChoiceColumns then
        LayoutHelpers.AtTopIn(group.check, group, 2)
    else
        LayoutHelpers.AtVerticalCenterIn(group.check, group)
    end

    group.check.key = data.key
    if filterSet[data.key] == nil then
        filterSet[data.key] = {value = data.key == 'spawnable', choices = {}}
    end
    if activeFilters[data.key] == nil then
        activeFilters[data.key] = {}
    end

    group.label = UIUtil.CreateText(group, data.title, 14, UIUtil.bodyFont)
    LayoutHelpers.RightOf(group.label, group.check)
    if data.choices and data.choices[1] and TableGetN(data.choices) > ChoiceColumns then
        LayoutHelpers.AtTopIn(group.label, group, 7)
    else
        LayoutHelpers.AtVerticalCenterIn(group.label, group)
    end

    if data.choices then
        group.items = {}
        for i, v in data.choices do
            local index = i
            group.items[index] = UIUtil.CreateCheckboxStd(group, data.key == 'spawnable' and '/dialogs/check-box_btn/radio' or '/dialogs/toggle_btn/toggle')
            if index == 1 then
                LayoutHelpers.AtLeftTopIn(group.items[index], group, 95)
            elseif index < ChoiceColumns+1 then
                LayoutHelpers.RightOf(group.items[index], group.items[index-1])
            else
                LayoutHelpers.Below(group.items[index], group.items[index-ChoiceColumns])
            end
            if index < ChoiceColumns+1 then
                LayoutHelpers.AtTopIn(group.items[index], group)
            end

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
                    local otherChecked
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
                filterSet[data.key].choices[v.key] = data.key == 'spawnable' and v.key == 'spawnable'
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
        group.edit.Width:Set((ChoiceColumns-2)*82+15)
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
        dialog = nil
        return
    end

    CreationList = {}

    dialog = Bitmap(GetFrame(0))
    dialog:SetSolidColor('CC000000')
    dialog.Height:Set(800)
    dialog.Width:Set(90 + 83 * ChoiceColumns)
    dialog.Left:Set(function() return math.max(math.min(x - dialog.Width() / 2, GetFrame(0).Right() - dialog.Width()), 0) end)
    dialog.Top:Set(function() return math.max(math.min(y - 160, GetFrame(0).Bottom() - dialog.Height()), 0) end)
    dialog.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)

    local cancelBtn = UIUtil.CreateButtonStd(dialog, '/widgets/small', "Cancel", 12)
    LayoutHelpers.AtBottomIn(cancelBtn, dialog)
    LayoutHelpers.AtRightIn(cancelBtn, dialog)
    cancelBtn.OnClick = function(button)
        dialog:Destroy()
        dialog = nil
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

    local function spreadSpawn(id, count)
        if tonumber(count) == 1 then return ConExecuteSave('CreateProp ' .. id .. ' ' .. ' ' .. x .. ' ' .. y) end

        local unitbp = __blueprints[id]
        local offsetX = (unitbp.Physics.SkirtSizeX or unitbp.SizeX or 1) * 75
        local offsetZ = (unitbp.Physics.SkirtSizeZ or unitbp.SizeZ or 1) * 75
        local square = math.ceil(math.sqrt(count))
        local startOffsetX = square * 0.5 * offsetX
        local startOffsetZ = square * 0.5 * offsetZ

        for i = 1, count do
            local X = x - startOffsetX + math.mod(i,square) * offsetX
            local Z = y - startOffsetZ + math.mod(math.floor(i/square), square) * offsetZ
            ConExecuteSave('CreateProp ' .. id .. ' ' .. ' ' .. X .. ' ' .. Z)
        end
    end

    local createBtn = UIUtil.CreateButtonStd(dialog, '/widgets/small', "Create", 12)
    LayoutHelpers.AtBottomIn(createBtn, dialog)
    LayoutHelpers.AtHorizontalCenterIn(createBtn, dialog)
    createBtn.OnClick = function(button)
        for unitID, _ in CreationList do
            local numUnits = 1
            if type(tonumber(count:GetText())) == 'number' then
                numUnits = count:GetText()
            end
            spreadSpawn(unitID, numUnits)
        end
        dialog:Destroy()
        dialog = nil
    end

    local function SetFilters(filterTable)
        for filterGroup, groupControls in filterGroups do
            local key = groupControls.check.key
            if filterTable[key] ~= nil then
                _ALERT('setting key: ', key, ' to: ', filterTable[key].value)
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

    local filterSetCombo = Combo(dialog, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
    filterSetCombo.Width:Set(250)
    LayoutHelpers.AtLeftTopIn(filterSetCombo, dialog)
    filterSetCombo.OnClick = function(self, index, text, skipUpdate)
        SetFilters(self.keyMap[index])
    end

    local function RefreshFilterList(defName)
        filterSetCombo:ClearItems()
        filterSetCombo.itemArray = {}
        filterSetCombo.keyMap = {}
        local CurrentFilterSets = GetPreference('CreatePropFilters')
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
            if GetPreference('CreatePropFilters') then
                newFilterListing = table.deepcopy(GetPreference('CreatePropFilters'))
                newFilterListing[name] = filterSet
            else
                newFilterListing[name] = filterSet
            end
            SetPreference('CreatePropFilters',newFilterListing)
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
            local oldFilterSets = GetPreference('CreatePropFilters')
            if oldFilterSets[delName] then
                oldFilterSets[delName] = nil
            end
            SetPreference('CreatePropFilters',oldFilterSets)
            RefreshFilterList()
       end
    end

    local propSwapBtn = UIUtil.CreateButton(dialog,
        '/dialogs/toggle_btn/toggle-d_btn_up.dds',
        '/dialogs/toggle_btn/toggle-d_btn_down.dds',
        '/dialogs/toggle_btn/toggle-d_btn_over.dds',
        '/dialogs/toggle_btn/toggle-d_btn_dis.dds',
        'Unit mode', 10
    )
    LayoutHelpers.Below(propSwapBtn, dialog, 5)
    LayoutHelpers.RightOf(propSwapBtn, delFilterSet, 9)
    propSwapBtn.OnClick = function(button)
        ConExecuteSave('ui_lua import("/lua/ui/dialogs/createunit.lua").CreateDialog('..x..','..y..')')
        dialog:Destroy()
        dialog = nil
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
    dialog.unitList.Height:Set(function() return createBtn.Top() - filterGroups[TableGetN(filterGroups)].Bottom() - 5 end)
    dialog.unitList.Width:Set(function() return dialog.Width() - 40 end)
    LayoutHelpers.Below(dialog.unitList, filterGroups[TableGetN(filterGroups)])
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
        if DiskGetFileInfo(UIUtil.UIFile(__blueprints[unitData].Display.Mesh.LODs[1].AlbedoName, true)) then
            mouseover.img:SetTexture(UIUtil.UIFile(__blueprints[unitData].Display.Mesh.LODs[1].AlbedoName, true))
        else
            mouseover.img:SetTexture(UIUtil.UIFile('/icons/units/default_icon.dds'))
        end

        mouseover.name = UIUtil.CreateText(mouseover, __blueprints[unitData].Interface and __blueprints[unitData].Interface.HelpText or __blueprints[unitData].Description, 14, UIUtil.bodyFont)
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
                    spreadSpawn(self.unitID, numUnits)
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
        return TableGetN(UnitList)
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
                        if type(specialFilterControls[filterIndex]) == "string" then
                            specialText = specialFilterControls[filterIndex]
                        else
                            specialText = specialFilterControls[filterIndex]:GetText()
                        end
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
        nameDialog = nil
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
        nameDialog = nil
    end

    nameEdit.OnEnterPressed = function(self, text)
        okButton.OnClick()
    end
end

-- kept for mod backwards compatibility
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local Text = import("/lua/maui/text.lua").Text
local Border = import("/lua/maui/border.lua").Border
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local RadioGroup = import("/lua/maui/mauiutil.lua").RadioGroup
local unselectedCheckboxFile = UIUtil.UIFile('/widgets/rad_un.dds')
local selectedCheckboxFile = UIUtil.UIFile('/widgets/rad_sel.dds')