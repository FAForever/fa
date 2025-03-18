local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Window = import("/lua/maui/window.lua").Window
local Group = import("/lua/maui/group.lua").Group

local Root = false

---@class AIBaseInfoUI : Window
---@field Data AIBaseDebugInfo
---@field Structures { Tech1: Button, Tech2: Button, Tech3: Button, Experimental: Button }
AIBaseInfoUI = ClassUI(Window) {

    ---@param self AIBaseInfoUI
    ---@param parent Control
    __init = function(self, parent)
        Window.__init(self, parent, "AIBrain Economy Data", false, false, false, true, false, "AIBrainEconomyData1", {
            Left = 10,
            Top = 300,
            Right = 310,
            Bottom = 525
        })

        do
            ---@param ids EntityId[]
            local function ConvertToSelection(ids)
                local units = { }
                for k, id in ids do
                    local unit = GetUnitById(id)
                    if unit then
                        table.insert(units, unit)
                    end
                end

                SelectUnits(units)
            end

            local tech1 = UIUtil.CreateButtonStd(self, '/BUTTON/medium/', 'Tech 1: ...', 12, 0, 0)
            tech1.OnClick = function()
                if self.Data then
                    ConvertToSelection(self.Data.Managers.StructureManagerDebugInfo.Structures.TECH1)
                end
            end

            local tech2 = UIUtil.CreateButtonStd(self, '/BUTTON/medium/', 'Tech 2: ...', 12, 0, 0)
            tech2.OnClick = function()
                if self.Data then
                    ConvertToSelection(self.Data.Managers.StructureManagerDebugInfo.Structures.TECH2)
                end
            end

            local tech3 = UIUtil.CreateButtonStd(self, '/BUTTON/medium/', 'Tech 3: ...', 12, 0, 0)
            tech3.OnClick = function()
                if self.Data then
                    ConvertToSelection(self.Data.Managers.StructureManagerDebugInfo.Structures.TECH3)
                end
            end

            local experimental = UIUtil.CreateButtonStd(self, '/BUTTON/medium/', 'Exp: ...', 12, 0, 0)
            experimental.OnClick = function()
                if self.Data then
                    ConvertToSelection(self.Data.Managers.StructureManagerDebugInfo.Structures.EXPERIMENTAL)
                end
            end

            self.Structures = {
                Tech1 = tech1,
                Tech2 = tech2,
                Tech3 = tech3,
                Experimental = experimental,
            }
        end

        AddOnSyncHashedCallback(
            ---@param data AIBaseDebugInfo
            function(data)
                self.Data = data

                self.Structures.Tech1.label:SetText(string.format('Tech 1: %d', table.getsize(data.Managers.StructureManagerDebugInfo.Structures.TECH1)))
                self.Structures.Tech2.label:SetText(string.format('Tech 2: %d', table.getsize(data.Managers.StructureManagerDebugInfo.Structures.TECH2)))
                self.Structures.Tech3.label:SetText(string.format('Tech 3: %d', table.getsize(data.Managers.StructureManagerDebugInfo.Structures.TECH3)))
                self.Structures.Experimental.label:SetText(string.format('Exp: %d', table.getsize(data.Managers.StructureManagerDebugInfo.Structures.EXPERIMENTAL)))

            end, 'AIBaseInfo', 'AIBaseInfo.lua'
        )

        AddOnSyncHashedCallback(
            function(data)
                if Root then
                    self.Data = nil

                    self.Structures.Tech1.label:SetText(string.format('Tech 1: ...'))
                    self.Structures.Tech2.label:SetText(string.format('Tech 2: ...'))
                    self.Structures.Tech3.label:SetText(string.format('Tech 3: ...'))
                    self.Structures.Experimental.label:SetText(string.format('Exp: ...'))
                end
            end, 'FocusArmyChanged', 'AIBaseInfo.lua'
        )
    end,

    ---@param self AIBaseInfoUI
    __post_init = function(self, parent)

        LayoutHelpers.LayoutFor(self.Structures.Tech1)
            :Over(self, 5)
            :AtLeftTopIn(self, 14, 34)
            :End()

        LayoutHelpers.LayoutFor(self.Structures.Tech2)
            :Over(self, 5)
            :RightOf(self.Structures.Tech1, 10)
            :End()

        LayoutHelpers.LayoutFor(self.Structures.Tech3)
            :Over(self, 5)
            :Below(self.Structures.Tech1, 10)
            :End()

        LayoutHelpers.LayoutFor(self.Structures.Experimental)
            :Over(self, 5)
            :RightOf(self.Structures.Tech3, 10)
            :End()
    end,

    ---@param self AIBaseInfoUI
    Update = function(self)
    end,

    OnClose = function(self)
    end,
}

function OpenWindow()
    if Root then
        Root:Show()
    else
        Root = AIBaseInfoUI(GetFrame(0))
        Root:Show()
    end
end

function CloseWindow()
    if Root then
        Root:Hide()
    end
end

--- Called by the module manager when this module is dirty due to a disk change
function __moduleinfo.OnDirty()
    if Root then
        Root:Destroy()
        Root = false
    end
end
