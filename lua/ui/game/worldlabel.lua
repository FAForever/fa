local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local CommandMode = import('/lua/ui/game/commandmode.lua')

local fadeStart = 150
local fadeRange = 650
local fadeLimit = 0.5

local worldLabelManagers

local function TrackCommandMode()
    CommandMode.AddStartBehavior(
        function(commandMode,modeData)
            LOG('Start behavior')
            for labelManager, _ in worldLabelManagers do
                labelManager:OnCommandMode(true, commandMode, modeData)
            end
        end,
        'WorldLabelCommandModeUpdate'
    )

    CommandMode.AddEndBehavior(
        function(commandMode,modeData)
            LOG('End behavior')
            for labelManager, _ in worldLabelManagers do
                labelManager:OnCommandMode(false, commandMode, modeData)
            end
        end,
        'WorldLabelCommandModeUpdate'
    )
end

---@class WorldLabelManager : Group
---@field camera Camera
---@field labelTable table<string, Group>
---@field view WorldView
---@field changed boolean
local WorldLabelManager = ClassUI(Group) {

    __init = function(self, view)
        LOG('Initializing world label manager')
        self.view = view
        self.camera = GetCamera("WorldCamera")
        self.mapGroup = view:GetParent()
        self.mapGroup.WorldLabelManager = self

        Group.__init(self, self.mapGroup)
        LayoutHelpers.FillParent(self, self.mapGroup)

        if not worldLabelManagers then
            worldLabelManagers = {}
            TrackCommandMode()
        end
        worldLabelManagers[self] = true

        self:DisableHitTest()
        self:Show()

        self:SetNeedsFrameUpdate(true)

        self._prevZoom = self.camera:GetZoom()
        self._prevPos = self.camera:GetFocusPosition()

        self._labelGroups = {}

        self.changed = true

    end,

    GetLabelGroup = function(self, type)
        return self._labelGroups[type]
    end,

    RegisterLabelGroup = function(self, type, group)
        self._labelGroups[type] = group
        if not self:ShowLabels() then
            self:ShowLabels(true)
        end
    end,

    DeregisterLabelGroup = function(self, type)
        self._labelGroups[type] = nil
        if table.empty(self._labelGroups) then
            self:ShowLabels(false)
        end
    end,

    -- Start processing our positional changes (or not)
    ShowLabels = function(self, show)
        if show == nil then
            return self._showingLabels
        elseif show or self._showingLabels then
            self:SetNeedsFrameUpdate(show)
            self._showingLabels = show
        end
    end,

    OnFrame = function(self, delta)

        local zoom = self.camera:GetZoom()
        local pos = self.camera:GetFocusPosition()

        self.changed =
            zoom ~= self._prevZoom or
            pos[1] ~= self._prevPos[1] or
            pos[2] ~= self._prevPos[2] or
            pos[3] ~= self._prevPos[3]

        if self.changed then
            self._prevZoom = zoom
            self._prevPos = pos
        end

    end,

    OnCommandMode = function(self, inMode, commandMode, modeData)
        LOG(repr(self._labelGroups))
        for type, group in self._labelGroups do
            group:OnCommandMode(inMode, commandMode, modeData)
        end
    end,
}

function GetWorldLabelManager(view)
    view = view or import("/lua/ui/game/worldview.lua").viewLeft
    if not view.worldLabelManager then
        LOG('Creating world label manager')
        view.worldLabelManager = WorldLabelManager(view)
    end
    return view.worldLabelManager
end

---@class WorldLabelGroup : Group
---@field type string
WorldLabelGroup = ClassUI(Group) {

    ---@param self WorldLabelGroup
    ---@param type string
    ---@param view WorldView
    __init = function(self, type, view)
        self.manager = GetWorldLabelManager(view)
        Group.__init(self, self.manager)
        LayoutHelpers.FillParent(self, self.manager)
        self:DisableHitTest()
        self.type = type
        self.manager:RegisterLabelGroup(type, self)
    end,

    OnCommandMode = function(self, inMode, commandMode, modeData)
        -- override me!
    end,

}

---@class WorldLabel : Group
---@field position Vector
---@field manager WorldLabelManager
---@field view WorldView
WorldLabel = ClassUI(Group) {

    ---@param self WorldLabel
    __init = function(self, position, type, view)

        local type = type or 'none_type'
        self.manager = GetWorldLabelManager(view)
        Group.__init(self, self.manager:GetLabelGroup(type) or self:CreateLabelGroup(type, view))

        self.position = position
        self:SetLayout(position)
        self:ProjectToScreen()
        self:SetNeedsFrameUpdate(true)
    end,

    ---@param self WorldLabel
    SetLayout = function(self, position)
        -- override me!
    end,

    ---@param self WorldLabel
    CreateLabelGroup = function(self, type, view)
        return WorldLabelGroup(type, view)
    end,

    ---@param self WorldLabel
    ProjectToScreen = function(self)
        local proj = self.manager.view:Project(self.position)
        self.Left:SetValue(proj.x - 0.5 * self.Width())
        self.Top:SetValue(proj.y - 0.5 * self.Height() + 1)
    end,

    --- Called each frame by the engine
    ---@param self WorldLabel
    ---@param delta number
    OnFrame = function(self, delta)
        if self.manager.changed then
            self:ProjectToScreen()
        end
    end,

    --- Called when the control is hidden or shown, used to start updating
    ---@param self WorldLabel
    ---@param hidden boolean
    OnHide = function(self, hidden)
        self:SetNeedsFrameUpdate(not hidden)
    end,
}