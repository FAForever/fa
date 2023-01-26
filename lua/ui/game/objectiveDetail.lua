local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Button = import("/lua/maui/button.lua").Button
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local GameCommon = import("/lua/ui/game/gamecommon.lua")
local Grid = import("/lua/maui/grid.lua").Grid
local WinMgr = import("/lua/ui/game/windowmanager.lua")

local WIN_ID = 'Objectives_Log'
local lobbyoptions = import("/lua/ui/lobby/lobbyoptions.lua")

local isCampaign = import("/lua/ui/campaign/campaignmanager.lua").campaignMode
local savedParent = false
local DetailWindow = false

local ObjectiveLogData = {}
local ObjectiveDetails = {}
local GUI = {
    bg = false,
    closeBtn = false,
    logEntries = {},
    detailEntries = {},
    --wc = false,
}

function Create()
    local frame = GetFrame(0)

    local function GetBGTextures(bgtype)
        if bgtype == 'title' then
             return UIUtil.UIFile('/dialogs/objective-log-btn-bar/tab_bmp.dds'),
             UIUtil.UIFile('/dialogs/objective-log-btn-bar/tab_bmp.dds'),
             UIUtil.UIFile('/dialogs/objective-log-btn-bar/tab_bmp.dds'),
             UIUtil.UIFile('/dialogs/objective-log-btn-bar/tab_bmp.dds'),
             UIUtil.UIFile('/dialogs/objective-log-btn-bar/tab_bmp.dds'),
             UIUtil.UIFile('/dialogs/objective-log-btn-bar/tab_bmp.dds')
        elseif bgtype == 'bottom' then
             return UIUtil.UIFile('/dialogs/objective-log-btn-bar/bar-bottom_btn_up.dds'),
             UIUtil.UIFile('/dialogs/objective-log-btn-bar/bar-bottom_btn_select.dds'),
             UIUtil.UIFile('/dialogs/objective-log-btn-bar/bar-bottom_btn_over.dds'),
             UIUtil.UIFile('/dialogs/objective-log-btn-bar/bar-bottom_btn_select.dds'),
             UIUtil.UIFile('/dialogs/objective-log-btn-bar/bar-bottom_btn_up.dds'),
             UIUtil.UIFile('/dialogs/objective-log-btn-bar/bar-bottom_btn_up.dds')
        else
             return UIUtil.UIFile('/dialogs/objective-log-btn-bar/bar_btn_up.dds'),
             UIUtil.UIFile('/dialogs/objective-log-btn-bar/bar_btn_select.dds'),
             UIUtil.UIFile('/dialogs/objective-log-btn-bar/bar_btn_over.dds'),
             UIUtil.UIFile('/dialogs/objective-log-btn-bar/bar_btn_select.dds'),
             UIUtil.UIFile('/dialogs/objective-log-btn-bar/bar_btn_up.dds'),
             UIUtil.UIFile('/dialogs/objective-log-btn-bar/bar_btn_up.dds')
        end
    end
    GUI.bg = Bitmap(savedParent, UIUtil.UIFile('/dialogs/objective-log-02/panel_bmp_t.dds'))
    LayoutHelpers.AtHorizontalCenterIn(GUI.bg, frame)
    LayoutHelpers.AtTopIn(GUI.bg, frame, 30)
    GUI.bg.Depth:Set(frame:GetTopmostDepth() + 1)

    --GUI.wc = UIUtil.CreateWorldCover(GUI.bg)

    GUI.bg.bottom = Bitmap(GUI.bg, UIUtil.UIFile('/dialogs/objective-log-02/panel_bmp_b.dds'))
    GUI.bg.bottom.Left:Set(GUI.bg.Left)
    LayoutHelpers.AtBottomIn(GUI.bg.bottom, frame, 30)
    GUI.bg.bottom.Depth:Set(GUI.bg.Depth)


    GUI.bg.middle = Bitmap(GUI.bg, UIUtil.UIFile('/dialogs/objective-log-02/panel_bmp_m.dds'))
    GUI.bg.middle.Left:Set(GUI.bg.Left)
    GUI.bg.middle.Top:Set(GUI.bg.Bottom)
    GUI.bg.middle.Depth:Set(GUI.bg.Depth)
    GUI.bg.middle.Bottom:Set(GUI.bg.bottom.Top)
    GUI.bg.middle.Height:Set(function() return GUI.bg.bottom.Top() - GUI.bg.Bottom() end)

    GUI.closeBtn = UIUtil.CreateButtonStd(GUI.bg, "/widgets02/small", "<LOC _Close>", 16)
    LayoutHelpers.AtRightIn(GUI.closeBtn, GUI.bg.bottom, 70)
    LayoutHelpers.AtBottomIn(GUI.closeBtn, GUI.bg.bottom, 28)
    GUI.closeBtn.OnClick = function(self, modifiers)
        ToggleDisplay()
    end

    GUI.bg.HandleEvent = function(self, event)
        if event.Type == 'KeyDown' then
            if event.KeyCode == UIUtil.VK_ESCAPE or event.KeyCode == UIUtil.VK_ENTER or event.KeyCode == 342 then
                GUI.closeBtn:OnClick()
            end
        end
    end

    GUI.logContainer = Group(GUI.bg)
    GUI.logContainer.Height:Set(function() return GUI.bg.middle.Height() + LayoutHelpers.ScaleNumber(20) end)
    LayoutHelpers.SetWidth(GUI.logContainer, 571)
    GUI.logContainer.top = 0

    local titleText = ''
    if isCampaign then
        titleText = '<LOC tooltipui0058>'
    else
        titleText = '<LOC sel_map_0000>'
    end

    GUI.title = UIUtil.CreateText(GUI.bg, LOC(titleText), 20)
    LayoutHelpers.AtLeftTopIn(GUI.title, GUI.bg, 30, 25)

    LayoutHelpers.AtLeftTopIn(GUI.logContainer, GUI.bg, 48, 89)
    UIUtil.CreateVertScrollbarFor(GUI.logContainer)

    local function CreateObjectiveElements()
        if GUI.logEntries then
            for i, v in GUI.logEntries do
                if v.bg then v.bg:Destroy() end
            end
            GUI.logEntries = {}
        end
        local function eventHandler(self, checked)
            if self.id then
                SetDetailTable(self.id)
            end
            for i, v in GUI.logEntries do
                if v.bg.id and v.bg.id == self.id then
                    v.bg:SetCheck(true, true)
                    ObjectiveLogData[v.bg.id].isChecked = true
                elseif v.bg.id and v.bg.id != self.id then
                    v.bg:SetCheck(false, true)
                end
            end
            for i, v in ObjectiveLogData do
                if i != self.id then
                    v.isChecked = false
                end
            end
        end

        local function CreateElement(index)
            GUI.logEntries[index] = {}
            GUI.logEntries[index].bg = Checkbox(GUI.logContainer,GetBGTextures('title'))
            GUI.logEntries[index].bg.OnCheck = eventHandler
            GUI.logEntries[index].bg.Left:Set(GUI.logContainer.Left)
            GUI.logEntries[index].bg.Right:Set(GUI.logContainer.Right)
            LayoutHelpers.SetHeight(GUI.logEntries[index].bg, 64)

            GUI.logEntries[index].icon = Button(GUI.logEntries[1].bg)
            GUI.logEntries[index].icon:SetSolidColor('00000000')
            GUI.logEntries[index].icon:DisableHitTest()
            LayoutHelpers.SetDimensions(GUI.logEntries[index].icon, 48, 48)

            GUI.logEntries[index].title = UIUtil.CreateText(GUI.logEntries[1].bg, '', 14, "Arial")
            GUI.logEntries[index].title:DisableHitTest()

            GUI.logEntries[index].time = UIUtil.CreateText(GUI.logEntries[1].bg, '', 12, "Arial")
            GUI.logEntries[index].time:DisableHitTest()

            GUI.logEntries[index].status = UIUtil.CreateText(GUI.logEntries[1].bg, '', 12, "Arial")
            GUI.logEntries[index].status:DisableHitTest()

            LayoutHelpers.AtLeftIn(GUI.logEntries[index].icon, GUI.logEntries[index].bg, 25)
            LayoutHelpers.AtVerticalCenterIn(GUI.logEntries[index].icon, GUI.logEntries[index].bg)
            LayoutHelpers.AtTopIn(GUI.logEntries[index].title, GUI.logEntries[index].icon)
            LayoutHelpers.AnchorToRight(GUI.logEntries[index].title, GUI.logEntries[index].icon, 5)
            LayoutHelpers.Below(GUI.logEntries[index].time, GUI.logEntries[index].title)
            LayoutHelpers.Below(GUI.logEntries[index].status, GUI.logEntries[index].time)
        end

        CreateElement(1)
        LayoutHelpers.AtTopIn(GUI.logEntries[1].bg, GUI.logContainer)

        local index = 2
        while GUI.logEntries[table.getsize(GUI.logEntries)].bg.Top() + (2 * GUI.logEntries[1].bg.Height()) < GUI.logContainer.Bottom() do
            CreateElement(index)
            LayoutHelpers.Below(GUI.logEntries[index].bg, GUI.logEntries[index-1].bg, -4)
            index = index + 1
        end
    end
    CreateObjectiveElements()

    local numLines = function() return table.getsize(GUI.logEntries) end

    local function DataSize()
        return table.getn(ObjectiveLogData)
    end

    -- called when the scrollbar for the control requires data to size itself
    -- GetScrollValues must return 4 values in this order:
    -- rangeMin, rangeMax, visibleMin, visibleMax
    -- aixs can be "Vert" or "Horz"
    GUI.logContainer.GetScrollValues = function(self, axis)
        local size = DataSize()
        --LOG(size, ":", self.top, ":", math.min(self.top + numLines, size))
        return 0, size, self.top, math.min(self.top + numLines(), size)
    end

    -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    GUI.logContainer.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta))
    end

    -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    GUI.logContainer.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta) * numLines())
    end

    -- called when the scrollbar wants to set a new visible top line
    GUI.logContainer.ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.top then return end
        local size = DataSize()
        self.top = math.max(math.min(size - numLines() , top), 0)
        self:CalcVisible()
    end

    -- called to determine if the control is scrollable on a particular access. Must return true or false.
    GUI.logContainer.IsScrollable = function(self, axis)
        return true
    end
    -- determines what controls should be visible or not
    GUI.logContainer.CalcVisible = function(self)
        local function SetTextLine(line, data, lineID)
            line.bg:Show()
            if data.isChecked then
                line.bg:SetCheck(true, true)
            else
                line.bg:SetCheck(false, true)
            end
            if data.type == 'title' then
                line.bg:Disable()
                line.bg:SetNewTextures(GetBGTextures(data.type))
                line.icon:Hide()
                line.title:SetText(LOC(data.title))
                line.title:SetColor(data.color)
                line.title:SetFont("Arial Bold", 18)
                line.time:SetText('')
                line.status:SetText('')
                LayoutHelpers.AtVerticalCenterIn(line.title, line.icon, 8)
                LayoutHelpers.AtLeftIn(line.title, line.bg, 12)
            else
                local bgtype = 'middle'
                if (ObjectiveLogData[lineID+1] and ObjectiveLogData[lineID+1].type == 'title') or not ObjectiveLogData[lineID+1] then
                    bgtype = 'bottom'
                end
                line.bg:SetNewTextures(GetBGTextures(bgtype))
                line.bg:Enable()
                if data.HideIcon then
                    line.icon:Hide()
                    LayoutHelpers.AtLeftIn(line.title, line.bg, 25)
                else
                    LayoutHelpers.AnchorToRight(line.title, line.icon, 5)
                    line.icon:Show()
                    line.icon:SetNewTextures(GetTargetImages(data))
                    line.icon:SetTexture(line.icon.mNormal)
                end
                line.bg.id = lineID
                local prefixStr = "<LOC objlog_string_0000>Assigned at"
                if data.EndTime then
                    prefixStr = "<LOC objlog_string_0001>Completed at"
                end
                local status = ''
                if data.type == 'setting' then
                    status = data.progress
                    line.time:SetText(LOC(status))
                else
                    local timeSeconds = data.EndTime or data.StartTime
                    local timeMinutes = math.floor(timeSeconds / 60)
                    local time = LOCF("%s %02d:%02d:%02d", prefixStr,
                        math.floor(timeMinutes / 60), math.mod(timeMinutes, 60), math.mod(timeSeconds, 60))
                    line.time:SetText(time)
                    if data.complete == 'complete' then
                        status = "<LOC objui_0003>Complete"
                    elseif data.complete == 'incomplete' then
                        if data.hidden then
                            status = '<LOC objui_0005>Incomplete'
                        else
                            status = data.progress or '<LOC objui_0005>Incomplete'
                        end
                    else
                        status = "<LOC objui_0004>Failed"
                    end
                    line.status:SetText(LOC(status))
                end
                line.title:SetColor('ffffffff')
                line.title:SetText(LOC(data.title))
                line.title:SetFont("Arial", 14)
                LayoutHelpers.AtTopIn(line.title, line.icon)
            end
        end
        for i, v in GUI.logEntries do
            if ObjectiveLogData[i + self.top] then
                SetTextLine(v, ObjectiveLogData[i + self.top], i + self.top)
            else
                v.bg:Hide()
                v.title:SetText('')
                v.time:SetText('')
                v.status:SetText('')
                v.icon:Hide()
                v.bg:Disable()
            end
        end
    end
    GUI.logContainer.Height.OnDirty = function(self)
        CreateObjectiveElements()
        if not GUI.logContainer:IsHidden() then
            GUI.logContainer:CalcVisible()
        end
    end

    GUI.detailsContainer = Group(GUI.bg)
    LayoutHelpers.SetDimensions(GUI.detailsContainer, 571, 103)
    GUI.detailsContainer.top = 0

    LayoutHelpers.AtLeftTopIn(GUI.detailsContainer, GUI.bg.bottom, 48, 21)
    UIUtil.CreateVertScrollbarFor(GUI.detailsContainer)

    GUI.detailEntries[1] = {}
    GUI.detailEntries[1].bg = Bitmap(GUI.detailsContainer)


    GUI.detailEntries[1].Text = UIUtil.CreateText(GUI.detailEntries[1].bg, '', 14, "Arial")
    LayoutHelpers.AtLeftTopIn(GUI.detailEntries[1].Text, GUI.detailsContainer)
    LayoutHelpers.SetWidth(GUI.detailEntries[1].Text, 60)
    GUI.detailEntries[1].Text:DisableHitTest()

    LayoutHelpers.FillParent(GUI.detailEntries[1].bg, GUI.detailEntries[1].Text)
    GUI.detailEntries[1].bg.Right:Set(GUI.detailsContainer.Right)

    local index = 2
    while GUI.detailEntries[table.getsize(GUI.detailEntries)].Text.Bottom() + GUI.detailEntries[1].Text.Height() < GUI.detailsContainer.Bottom() do
        GUI.detailEntries[index] = {}
        GUI.detailEntries[index].bg = Bitmap(GUI.detailsContainer)

        GUI.detailEntries[index].Text = UIUtil.CreateText(GUI.detailEntries[index].bg, '', 14, "Arial")
        LayoutHelpers.Below(GUI.detailEntries[index].Text, GUI.detailEntries[index-1].Text)
        GUI.detailEntries[index].Text:DisableHitTest()

        LayoutHelpers.FillParent(GUI.detailEntries[index].bg, GUI.detailEntries[index].Text)
        GUI.detailEntries[index].bg.Right:Set(GUI.detailsContainer.Right)
        index = index + 1
    end

    local numDescLines = table.getsize(GUI.detailEntries)

    local function DetailSize()
        return table.getn(ObjectiveDetails)
    end

    -- called when the scrollbar for the control requires data to size itself
    -- GetScrollValues must return 4 values in this order:
    -- rangeMin, rangeMax, visibleMin, visibleMax
    -- aixs can be "Vert" or "Horz"
    GUI.detailsContainer.GetScrollValues = function(self, axis)
        local size = DetailSize()
        --LOG(size, ":", self.top, ":", math.min(self.top + numLines, size))
        return 0, size, self.top, math.min(self.top + numDescLines, size)
    end

    -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    GUI.detailsContainer.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta))
    end

    -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    GUI.detailsContainer.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta) * numDescLines)
    end

    -- called when the scrollbar wants to set a new visible top line
    GUI.detailsContainer.ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.top then return end
        local size = DetailSize()
        self.top = math.max(math.min(size - numDescLines , top), 0)
        self:CalcVisible()
    end

    -- called to determine if the control is scrollable on a particular access. Must return true or false.
    GUI.detailsContainer.IsScrollable = function(self, axis)
        return true
    end

    -- determines what controls should be visible or not
    GUI.detailsContainer.CalcVisible = function(self)
        local function SetTextLine(control, data)
            if data.type == 'title' then
                control.Text:SetColor(data.color)
                control.Text:SetFont("Arial Bold", 14)
            elseif data.type == 'desc' then
                control.Text:SetColor(data.color)
                control.Text:SetFont("Arial", 14)
            end
            control.Text:SetText(data.text)
        end
        for i, v in GUI.detailEntries do
            if ObjectiveDetails[i + self.top] then
                SetTextLine(v, ObjectiveDetails[i + self.top])
            else
                v.Text:SetText('')
                v.bg:Disable()
            end
        end
    end

    GUI.logContainer:CalcVisible()
    WinMgr.AddWindow({id = WIN_ID, closeFunc = ToggleDisplay})
end

function WrapText(intext)
    local textBoxWidth = GUI.detailsContainer.Right() - GUI.detailsContainer.Left()
    local retText = import("/lua/maui/text.lua").WrapText(intext, textBoxWidth,
    function(text)
        return GUI.detailEntries[1].Text:GetStringAdvance(text)
    end)
    return retText
end

function SetDetailTable(id)
    ObjectiveDetails = {}
    local titleData = WrapText(LOC(ObjectiveLogData[id].title))
    local descData = WrapText(LOC(ObjectiveLogData[id].description))
    for i, v in titleData do
        table.insert(ObjectiveDetails, {text = v, type = 'title', color = 'ffe4e95f'})
    end
    local progtext = ObjectiveLogData[id].progress or ''
    if ObjectiveLogData[id].complete == 'complete' then
        progtext = '<LOC objui_0003>'
    elseif ObjectiveLogData[id].complete == 'failed' then
        progtext = '<LOC objui_0004>'
    end
    table.insert(ObjectiveDetails, {text = LOC(progtext), type = 'desc', color = 'ffe4e95f'})
    for i, v in descData do
        table.insert(ObjectiveDetails, {text = v, type = 'desc', color = 'ffd0d0d0'})
    end
    GUI.detailsContainer:CalcVisible()
end

function OpenToElement(id)
    ToggleDisplay()
    local entryNum = 0
    for i, v in ObjectiveLogData do
        if v.tag and v.tag == id then
            entryNum = i
            break
        end
    end
    if entryNum == 0 then
        WARN('ObjectiveLog: Unable to find entry '..id)
    else
        GUI.logContainer:ScrollSetTop(nil, entryNum-1)
        GUI.logContainer:CalcVisible()
        for i, v in GUI.logEntries do
            if v.bg.id == entryNum then
                v.bg:SetCheck(true)
                break
            end
        end
    end
end

function SetupObjectiveDetail(parent)
    savedParent = parent
end

function ToggleDisplay()
    if GUI.bg then
        GUI.bg:SetHidden(not GUI.bg:IsHidden())
        if not GUI.bg:IsHidden() then
            Refresh()
            GUI.logContainer:CalcVisible()
            WinMgr.OpenWindow(WIN_ID)
            AddInputCapture(GUI.bg)
        else
            WinMgr.CloseWindow(WIN_ID)
            RemoveInputCapture(GUI.bg)
        end
    else
        SetupObjectiveDetail(GetFrame(0))
        Refresh()
        Create()
        AddInputCapture(GUI.bg)
        WinMgr.OpenWindow(WIN_ID)
    end
end

function GetTargetImages(data)
    -- look for an image to display
    local overrideImage = UIUtil.UIFile(data.actionImage)

    if (overrideImage) then
        return overrideImage, overrideImage, overrideImage, overrideImage
    else
        local blueprint
        local iconName
        for k,v in data.targets do
            if v.BlueprintId then
                blueprint = __blueprints[v.BlueprintId]
                --return GameCommon.GetCachedUnitIconFileNames(blueprint)
            elseif v.Type == 'Area' then
                iconName = UIUtil.UIFile('/game/target-area/target-area_bmp.dds')
                --return iconName, iconName, iconName, iconName
            end
        end
        if blueprint then
            return GameCommon.GetCachedUnitIconFileNames(blueprint)
        elseif iconName then
            return iconName, iconName, iconName, iconName
        end
    end

    local questionMark = UIUtil.UIFile('/dialogs/objective-unit/help-lg-graphics_bmp.dds')
    return questionMark, questionMark, questionMark, questionMark
end

function Refresh()
    local primtitle = '<LOC SCORE_0037>'
    local sectitle = '<LOC SCORE_0040>'
    local bontitle = '<LOC SCORE_0041>Bonus Objectives'
    local hidtitle = '<LOC SCORE_0042>'
    local hiddesc = '<LOC SCORE_0048>'
    local comtitle = '<LOC objui_0003>'
    local failtitle = '<LOC objui_0004>'
    local mapinfo = '<LOC sel_map_0000>'
    if isCampaign then
        local Objectives = table.deepcopy(import('/lua/ui/game/objectives2.lua').GetCurrentObjectiveTable())
        local sortedPrim = {}
        local sortedSec = {}
        local sortedBon = {}
        local sortedCom = {}
        local sortedFail = {}
        for k, ObjData in Objectives do
            -- Hide information about incompleted or failed bonus objectives
            if ObjData.type == 'bonus' and ObjData.complete ~= 'complete' then
                ObjData.title = hidtitle
                ObjData.description = hiddesc
                ObjData.progress = ''
                ObjData.actionImage = '/dialogs/objective-unit/help-lg-graphics_bmp.dds'
            end
            if ObjData.complete ~= 'incomplete' then
                if ObjData.complete == 'complete' then
                    table.insert(sortedCom, ObjData)
                else
                    table.insert(sortedFail, ObjData)
                end
            else
                if ObjData.type == 'primary' then
                    table.insert(sortedPrim, ObjData)
                elseif ObjData.type == 'secondary' then
                    table.insert(sortedSec, ObjData)
                elseif ObjData.type == 'bonus' then
                    table.insert(sortedBon, ObjData)
                end
            end
        end
        local index = 1
        local function SortFunc(t1, t2)
            return (t1.EndTime or t1.StartTime) > (t2.EndTime or t2.StartTime)
        end
        if not table.empty(sortedPrim) then
            ObjectiveLogData[index] = {type = 'title', title = primtitle, color = 'ffff0000'}
            index = index + 1
            table.sort(sortedPrim, SortFunc)
            for i, v in sortedPrim do
                ObjectiveLogData[index] = table.deepcopy(v)
                index = index + 1
            end
        end
        if not table.empty(sortedSec) then
            ObjectiveLogData[index] = {type = 'title', title = sectitle, color = 'fffff700'}
            index = index + 1
            table.sort(sortedSec, SortFunc)
            for i, v in sortedSec do
                ObjectiveLogData[index] = table.deepcopy(v)
                index = index + 1
            end
        end
        if not table.empty(sortedBon) then
            ObjectiveLogData[index] = {type = 'title', title = bontitle, color = 'ffba00ff'}
            index = index + 1
            table.sort(sortedBon, SortFunc)
            for i, v in sortedBon do
                ObjectiveLogData[index] = table.deepcopy(v)
                index = index + 1
            end
        end
        if not table.empty(sortedCom) then
            ObjectiveLogData[index] = {type = 'title', title = comtitle, color = 'ff5fbde9'}
            index = index + 1
            table.sort(sortedCom, SortFunc)
            for i, v in sortedCom do
                ObjectiveLogData[index] = table.deepcopy(v)
                index = index + 1
            end
        end
        if not table.empty(sortedFail) then
            ObjectiveLogData[index] = {type = 'title', title = failtitle, color = 'ffe95f5f'}
            index = index + 1
            table.sort(sortedFail, SortFunc)
            for i, v in sortedFail do
                ObjectiveLogData[index] = table.deepcopy(v)
                index = index + 1
            end
        end
    else
        ObjectiveLogData[1] = {type = 'title', title = mapinfo, color = 'ff5fbde9'}
        local mapinfo = SessionGetScenarioInfo()
        local mapsizes = import("/lua/ui/dialogs/mapselect.lua").mapFilters[2].Options
        local retText = ''
        for i, v in mapsizes do
            if v.key == mapinfo.size[1] then
                retText = v.text
            end
        end
        local invalidOptions = {
            ScenarioFile=true,
        }
        ObjectiveLogData[2] = {title = mapinfo.name, HideIcon = true, type = 'setting',
            description = mapinfo.description, progress = retText}
        local index = 3
        for i, v in mapinfo.Options do
            if not invalidOptions[i] then
                local tablestr = 'globalOpts'
                if i == 'TeamLock' or i == 'TeamSpawn' then
                    tablestr = 'teamOptions'
                end
                if ExtractStrings(i, v, tablestr) then
                    ObjectiveLogData[index] = ExtractStrings(i, v, tablestr)
                    index = index + 1
                end
            end
        end
    end
end

function ExtractStrings(key, setting, tablestr)
    for i, v in lobbyoptions[tablestr] do
        if v.key == key then
            local retHelp = ''
            local retText = ''
            for index, val in v.values do
                if val.key == setting then
                    retText = val.text
                    retHelp = val.help
                end
            end
            return {title = v.label, HideIcon = true, type = 'setting', description = retHelp, progress = retText}
        end
    end
end

function RefreshData()
    Refresh()
    GUI.logContainer.CalcVisible()
end

--[[  Example Data
  actionImage="/game/orders/production_btn_up.dds",
  complete="incomplete",
  description="<LOC E01_M01_OBJ_010_122>Select your CDR and click the Mass Extractor icon. You can only build Mass Extractors on Mass Deposits; your CDR has highlighted the correct locations.",
  progress="(0/3)",
  tag="Objective0",
  StartTime = '150',
  targets={ { BlueprintId="ueb1103", Type="Blueprint" } },
  title="<LOC E01_M01_OBJ_010_121>Build Three Mass Extractors",
  type="primary"

  CheatsEnabled="true",
  FogOfWar="explored",
  GameSpeed="adjustable",
  ScenarioFile="/maps/scmp_011/scmp_011_scenario.lua",
  TeamLock="locked",
  TeamSpawn="fixed",
  Timeouts="3",
  UnitCap="750",
  Victory="sandbox"
--]]