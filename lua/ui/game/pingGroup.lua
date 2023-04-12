
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Text = import("/lua/maui/text.lua").Text
local Button = import("/lua/maui/button.lua").Button
local Prefs = import("/lua/user/prefs.lua")
local Tooltips = import("/lua/ui/game/tooltip.lua")
local GameCommon = import("/lua/ui/game/gamecommon.lua")

local cmdMode = import("/lua/ui/game/commandmode.lua")
local ObjectivesGroup = import('/lua/ui/game/objectives2.lua').controls.bg
local UIPing = import("/lua/ui/game/ping.lua")

local ActiveGroups = {}

local firstPingGroup = true

local queuedGroups = {}
local waitThreadHandle = false

function WaitThread()
    local time = 0
    while not import('/lua/ui/game/objectives2.lua').WidgetGroup do
        WaitSeconds(.5)
        time = time + 1
        if time > 100 then
            WARN('Waiting to create ping groups exceeded 20 seconds!  Something has gone horribly wrong!!')
            return
        end
    end
    ObjectivesGroup = import('/lua/ui/game/objectives2.lua').controls.bg
    for i, v in queuedGroups do
        AddPingGroups(v)
    end
end

function AddPingGroups(groupData)
    if not ObjectivesGroup then
        table.insert(queuedGroups, groupData)
            if not waitThreadHandle then
                waitThreadHandle = ForkThread(WaitThread)
            end
        return
    end
    if firstPingGroup then
        function EndBehavior(mode, data)
            if mode == 'order' and data.groupID then
                UIPing.DoPing(data.pingtype)
                local position = GetMouseWorldPos()
                for _, v in position do
                    local var = v
                    if var != v then
                        return
                    end
                end
                local data = {ID = data.groupID, Location = position}
                SimCallback({Func = 'PingGroupClick', Args = data})
            end
        end
        cmdMode.AddEndBehavior(EndBehavior)
        firstPingGroup = false
    end
    
    for groupIndex, pingGroup in groupData do
        local icon = UIUtil.UIFile('/game/orders/guard_btn_up.dds')
        if pingGroup.BlueprintID then
            icon = GameCommon.GetCachedUnitIconFileNames(__blueprints[pingGroup.BlueprintID])
        elseif pingGroup.Type == 'attack' then
            icon = UIUtil.UIFile('/game/orders/attack_btn_up.dds')
        elseif pingGroup.Type == 'move' then
            icon = UIUtil.UIFile('/game/orders/move_btn_up.dds')
        end
        ActiveGroups[pingGroup.ID] = Bitmap(GetFrame(0), UIUtil.UIFile('/game/pinggroup/border-group.dds'))
        ActiveGroups[pingGroup.ID].Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
        ActiveGroups[pingGroup.ID].btn = Button(ActiveGroups[pingGroup.ID], icon, icon, icon, icon)
        LayoutHelpers.AtCenterIn(ActiveGroups[pingGroup.ID].btn, ActiveGroups[pingGroup.ID])
        ActiveGroups[pingGroup.ID].btn.Data = pingGroup
        ActiveGroups[pingGroup.ID].btn.OnClick = function(self, modifiers)
            local cursor = "RULEUCC_Guard"
            if self.Data.Type == 'attack' then
                cursor = "RULEUCC_Attack"
            elseif self.Data.Type == 'move' then
                cursor = "RULEUCC_Move"
            end
            local modeData = {
                name="RULEUCC_Script",
                Cursor=cursor,
                pingtype=self.Data.Type,
                groupID=self.Data.ID,
            }
            cmdMode.StartCommandMode("order", modeData)
        end
        Tooltips.AddButtonTooltip(ActiveGroups[pingGroup.ID].btn, pingGroup.Name)
    end
    LayoutPingGroups()
end

function RemovePingGroups(removeData)
    for _, groupID in removeData do
        if ActiveGroups[groupID] then
            ActiveGroups[groupID]:Destroy()
            ActiveGroups[groupID] = nil
        end
    end
    LayoutPingGroups()
end

function LayoutPingGroups()
    local lastControl = false
    if table.getn(ActiveGroups) > 0 then
        for i, v in ActiveGroups do
            if lastControl then
                LayoutHelpers.Below(v, lastControl)
            else
                LayoutHelpers.Below(v, ObjectivesGroup, 10)
            end
            lastControl = v
        end
    end
end