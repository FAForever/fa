local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group

---@class WorldLabelManager : Group
---@field camera Camera
---@field labelTable table<string, Group>
---@field view WorldView
---@field changed boolean
local WorldLabelManager = ClassUI(Group) {

    __init = function(self, labelView)
        LOG('Initializing world label manager')
        Group.__init(self, labelView)
        labelView.WorldLabelManager = self

        self.view = labelView
        self.camera = GetCamera("WorldCamera")
        LayoutHelpers.FillParent(self, labelView)
        self:DisableHitTest()
        self:Show()

        self:SetNeedsFrameUpdate(true)

        self._prevZoom = self.camera:GetZoom()
        self._prevPos = self.camera:GetFocusPosition()

        self.labelTable = {}

        self.changed = true

    end,

    -- Register a label with the manager, and start showing labels if we weren't already
    RegisterLabel = function(self, label)
        LOG('Registering label')
        if not self.labelTable[label.type] then
            LOG('First label of type '..label.type)
            self.labelTable[label.type] = {}
            self:ShowLabels(true)
        end
        self.labelTable[label.type][label] = true
    end,

    -- Dregister a label with the manager, stop showing labels if we have none
    DeregisterLabel = function(self, label)
        LOG('Deregistering label')
        self.labelTable[label.type][label] = nil
        if table.empty(self.labelTable[label.type]) then
            LOG('No more labels of type '..label.type)
            self.labelTable[label.type] = nil
            if table.empty(self.labelTable) then
                LOG('No more labels of any kind')
                self:ShowLabels(false)
            end
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

        self._prevZoom = zoom
        self._prevPos = pos

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

---@class WorldLabel : Group
---@field position Vector
---@field type string
---@field manager WorldLabelManager
---@field view WorldView
WorldLabel = ClassUI(Group) {

    ---@param self WorldLabel
    __init = function(self, position, type)
        self.type = type or 'none_type'
        self.manager = GetWorldLabelManager()
        Group.__init(self, self.manager)
        self.manager:RegisterLabel(self)
        
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

    OnDestroy = function(self)
        self.manager:DeregisterLabel(self)
    end,
}