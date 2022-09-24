local Group = import('/lua/maui/group.lua').Group
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Prefs = import('/lua/user/prefs.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local options = Prefs.GetFromCurrentProfile('options')

local Layouter = LayoutHelpers.ReusedLayoutFor
local Scale = LayoutHelpers.ScaleNumber

local MathFloor = math.floor
local MathMax = math.max
local MathMin = math.min
local TableGetn = table.getn
local TableSort = table.sort

---@class UserReclaimData : BaseReclaimData
---@field count number
---@field max number

---@class ReclaimLabelGroup : Group
---@field view WorldView
---@field isMoving boolean
---@field prevPos Vector


---@type number
local HeightRatio = 0.012

--- Reclaim is no longer combined once this threshold is met, the value (150) is the same camera
--- distance that allows for the reclaim command to work. Guarantees that the  labels represent
--- where you can reclaim.
---@type number
local ZoomThreshold = 150

--- TODO: remove the options
---@type number
local MaxLabels = options.maximum_reclaim_count or 1000
--- TODO: remove the options
---@type number
local MinAmount = options.minimum_reclaim_amount or 10

---@type table<EntityId, PropSyncData>
local Reclaim = {}
---@type table<EntityId, PropSyncData>
local OutsidePlayableAreaReclaim = {}

---@type UserReclaimData[], number, number
local DataPool, DataPoolSize, LastDataSize = {}, 0, 0

---@type WorldLabel[], number, number
local LabelPool, LabelPoolSize, LastLabelCount = {}, 0, 0

---@type UserRect
local PlayableArea

---@type number, number
local MapWidth, MapHeight = 0, 0

local CommandGraphActive = false
local ReclaimChanged = true


--- Retrieves the map size, storing it in `MapHeight` and `MapWidth`
function Init()
    local size = SessionGetScenarioInfo().size
    MapWidth = size[1]
    MapHeight = size[2]
end

--- Called when the playable area is changed
---@param rect UserRect
function SetPlayableArea(rect)
    local InPlayableArea = InPlayableArea
    ReclaimChanged = true
    PlayableArea = rect
    local reclaim = Reclaim
    local offmapReclaim = OutsidePlayableAreaReclaim

    -- add to a separate table so we don't recheck it; this will give us another vector to remove
    -- entries from later, so we don't need to do lagged removal
    local nowOffmap = {}
    for id, r in reclaim do
        if not InPlayableArea(r.position) then
            nowOffmap[id] = r
        end
    end
    -- lag removal so that the table modification doesn't interfere with traversal
    local remove
    for id, r in offmapReclaim do
        if remove then
            offmapReclaim[remove] = nil
            if InPlayableArea(r.position) then
                reclaim[id] = r
                remove = id
            else
                remove = nil
            end
        else
            if InPlayableArea(r.position) then
                reclaim[id] = r
                remove = id
            end
        end
    end
    if remove then
        offmapReclaim[remove] = nil
    end
    -- now swap the offmapping reclaim
    for id, r in nowOffmap do
        reclaim[id] = nil
        offmapReclaim[id] = r
    end
end

--- Adds to and updates the set of reclaim labels
---@param propData table<EntityId, PropSyncData>
function UpdateReclaim(propData)
    local InPlayableArea = InPlayableArea
    local offmapReclaim = OutsidePlayableAreaReclaim
    local reclaim = Reclaim
    ReclaimChanged = true
    for id, prop in propData do
        local mass = prop.mass
        if mass and mass > 0 then
            if InPlayableArea(prop.position) then
                reclaim[id] = prop
                offmapReclaim[id] = nil
            else
                reclaim[id] = nil
                offmapReclaim[id] = prop
            end
        else
            reclaim[id] = nil
            offmapReclaim[id] = nil
        end
    end
end

function ToggleReclaim()
    ShowReclaim(not GetView().ShowingReclaim)
end

---@param show boolean
function OnCommandGraphShow(show)
    do return end
    local view = GetView()
    if view.ShowingReclaim and not CommandGraphActive then return end -- if on by toggle key

    CommandGraphActive = show
    if show then
        ForkThread(function()
            local keydown
            while CommandGraphActive do
                keydown = IsKeyDown("Control")
                if keydown ~= view.ShowingReclaim then -- state has changed
                    ShowReclaim(keydown)
                end
                WaitSeconds(0.1)

            end
            ShowReclaim(false)
            -- check if it's worth freeing the memory
            if TableGetn(Reclaim) * 2 > DataPoolSize then
                -- DataPool = {}
                -- DataPoolSize = 0
            end
            if LabelPoolSize * 2 > MaxLabels then
                -- LabelPool = {}
                -- LabelPoolSize = 0
            end
        end)
    end
end


---@class WorldLabel : Group
---@field icon Bitmap
---@field text Text
---
---@field parent ReclaimLabelGroup
---@field position Vector
---@field reproject boolean
---@field mass number
---@field count number
local WorldLabel = Class(Group) {
    ---@param self WorldLabel
    ---@param parent ReclaimLabelGroup
    ---@param position? Vector
    __init = function(self, parent, position)
        Group.__init(self, parent)
        self.icon = UIUtil.CreateBitmapStd(self, "/game/build-ui/icon-mass")
        self.text = UIUtil.CreateText(self, "", 10, UIUtil.bodyFont, true)

        self.parent = parent
        self.position = position or Vector(0, 0, 0)
        self.reproject = true
        self.mass = 0
        self.count = 0
    end;
    ---@param self WorldLabel
    __post_init = function(self, parent, position)
        self:PositionAt(position)
    end;

    OnLayout = function(self)
        self.Width:Set(function()
            return self.icon.Width() + Scale(2) + self.text.Width()
        end)
        self.Height:Set(function()
            return MathMax(self.icon.Height(), self.text.Height())
        end)
    end;

    Layout = function(self)
        local icon = Layouter(self.icon)
            :Dimensions(14, 14)
            :AtLeftCenterIn(self)
            :Over(self, 3)
            :End()

        Layouter(self.text)
            :AnchorToRight(icon, 2)
            :AtVerticalCenterIn(self)
            :Over(self, 5)
            :End()
    end;

    --- Returns the color of the reclaim label
    ---@param self WorldLabel
    ---@return Color
    GetColor = function(self)
        local value = self.mass
        if value >= 300 then
            if value >= 1000 then
                return "FF6F6F"
            end
            return "FFBA8F"
        end
        if value >= 100 then
            return "FFEE8F"
        end
        return "C7FF8F"
    end;

    --- Returns the text of the reclaim label
    ---@param self WorldLabel
    ---@return number
    GetText = function(self)
        return MathFloor(0.5 + self.mass)
    end;

    ---@param self WorldLabel
    Update = function(self)
        local text = self.text
        text:SetText(self:GetText())
        text:SetColor(self:GetColor())
    end;

    --- Updates the reclaim that this label displays
    ---@param self WorldLabel
    ---@param reclaim UserReclaimData
    DisplayReclaim = function(self, reclaim)
        if self:IsHidden() then
            self:Show()
        end

        self.position = reclaim.position
        local mass, count = reclaim.mass, reclaim.count
        if mass ~= self.mass or count ~= self.count then
            self.mass = mass
            self.count = count
            self:Update()
        end
    end;

    ---@param self WorldLabel
    ---@param position Vector
    MoveTo = function(self, position)
        self.position = position
        self:PositionAt(position)
    end;

    ---@param self WorldLabel
    ---@param position Vector
    PositionAt = function(self, position)
        local proj = self.parent.view:Project(position)
        self.Left:SetValue(proj[1] - 0.5 * self.icon.Width())
        self.Top:SetValue(proj[2] - 0.5 * self.Height())
    end;

    --- Called each frame by the engine
    ---@param self WorldLabel
    ---@param delta number
    OnFrame = function(self, delta)
        if self.reproject then
            self:PositionAt(self.position)
        end
        self.reproject = self.parent.isMoving
    end;

    --- Called when the control is hidden or shown, used to start updating
    ---@param self WorldLabel
    ---@param hidden boolean
    OnHide = function(self, hidden)
        self:SetNeedsFrameUpdate(not hidden)
        if not hidden then
            self.reproject = true
        end
    end;
}

--- Creates an empty reclaim label
---@param labelGroup ReclaimLabelGroup
---@return WorldLabel
function CreateReclaimLabel(labelGroup)
    return Layouter(WorldLabel(labelGroup))
        :End()
end

--- Determines if the point is in the playable area, if available
---@param pos Vector
---@return boolean
function InPlayableArea(pos)
    local x, z = pos[1], pos[3]
    local PlayableArea = PlayableArea
    if PlayableArea then
        return x > PlayableArea[1] and x < PlayableArea[3] and
               z > PlayableArea[2] and z < PlayableArea[4]
    end
    return x > 0 and x < MapWidth and
           z > 0 and z < MapHeight
end

---@param minX number
---@param minZ number
---@param maxX number
---@param maxZ number
---@return boolean
function ContainsWholeMap(minX, minZ, maxX, maxZ)
    local PlayableArea = PlayableArea
    if PlayableArea then
        return minX < PlayableArea[1] and maxX > PlayableArea[3] and
               minZ < PlayableArea[2] and maxZ > PlayableArea[4]
    end
    return minX < 0 and maxX > MapWidth and
           minZ < 0 and maxZ > MapHeight
end

---@return WorldView
function GetView()
    return import("/lua/ui/game/worldview.lua").viewLeft
end

---@param a UserReclaimData
---@param b UserReclaimData
---@return boolean
local function CompareMass(a, b)
    return a.mass > b.mass
end

--- Combines the reclaim by summing them up and positioning it by the weighted average between them
---@param r1 UserReclaimData
---@param r2 UserReclaimData | BaseReclaimData
---@return UserReclaimData
local function SumReclaim(r1, r2)
    local r1Mass, r1Pos = r1.mass, r1.position
    local r2Mass, r2Pos = r2.mass, r2.position
    local massSum = r1Mass + r2Mass
    do
        local r1Weight = r1Mass / massSum
        local r2Weight = r2Mass / massSum
        r1Pos[1] = r1Weight * r1Pos[1] + r2Weight * r2Pos[1]
        r1Pos[2] = r1Weight * r1Pos[2] + r2Weight * r2Pos[2]
        r1Pos[3] = r1Weight * r1Pos[3] + r2Weight * r2Pos[3]
    end
    r1.mass = massSum
    r1.count = r1.count + (r2.count or 1)
    local r2Max = r2.max or r2Mass
    if r2Max > r1.max then
        r1.max = r2Max
    end
    return r1
end

---@param view WorldView
---@param reclaim PropSyncData[]
---@param minAmount number
---@return PropSyncData[] inViewReclaim
---@return number count
local function GetInViewReclaim(view, reclaim, minAmount)
    local inViewCount = 0
    local inViewReclaim = {}

    local tl, tr, br, bl = view:UnProjectCorners()

    local x1, z1 = tl[1], tl[3]
    local x2, z2 = tr[1], tr[3]
    local x3, z3 = br[1], br[3]
    local x4, z4 = bl[1], bl[3]

    local minX = MathMin(x1, x2, x3, x4)
    local maxX = MathMax(x1, x2, x3, x4)
    local minZ = MathMin(z1, z2, z3, z4)
    local maxZ = MathMax(z1, z2, z3, z4)

    if ContainsWholeMap(minX, minZ, maxX, maxZ) then
        -- we can remove checking if in the prop is in view when we know all props are in view
        for _, recl in reclaim do
            if recl.mass >= minAmount then
                inViewCount = inViewCount + 1
                inViewReclaim[inViewCount] = recl
            end
        end
    else
        local x21, z21 = x2 - x1, z2 - z1
        local x32, z32 = x3 - x2, z3 - z2
        local x43, z43 = x4 - x3, z4 - z3
        local x14, z14 = x1 - x4, z1 - z4

        for _, recl in reclaim do
            if recl.mass >= minAmount then
                local pos = recl.position
                local x0, z0 = pos[1], pos[3]
                -- in the view
                if  x0 >= minX and x0 <= maxX and z0 >= minZ and z0 <= maxZ and
                    (x1 - x0) * z21 > x21 * (z1 - z0) and
                    (x2 - x0) * z32 > x32 * (z2 - z0) and
                    (x3 - x0) * z43 > x43 * (z3 - z0) and
                    (x4 - x0) * z14 > x14 * (z4 - z0)
                then
                    inViewCount = inViewCount + 1
                    inViewReclaim[inViewCount] = recl
                end
            end
        end
    end

    return inViewReclaim, inViewCount
end

local function DoCombineLabels()
    return GetCamera("WorldCamera"):SaveSettings().Zoom > ZoomThreshold
end

---@param reclaim PropSyncData[] raw reclaim data
---@param dataPool UserReclaimData[] pool of combined reclaim data
---@param lastDataSize number number of entries used last update
---@return number  # number of combined labels
local function CombineReclaim(reclaim, dataPool, lastDataSize)
    local SumReclaim, Vector = SumReclaim, Vector

    local minDistSq = GetCamera("WorldCamera"):SaveSettings().Zoom * HeightRatio
    minDistSq = minDistSq * minDistSq
    local index = 0

    --- O(n)
    for _, recl in reclaim do
        local notAdded = true
        local reclPos = recl.position
        local reclX, reclZ = reclPos[1], reclPos[3]

        --- TODO: use a basic grid query (quad tree overcomplicates it) -> O(n)
        --- O(n)
        for i = 1, index do
            local cur = dataPool[i]
            local curPos = cur.position
            local dx, dz = reclX - curPos[1], reclZ - curPos[3]
            if dx*dx + dz*dz < minDistSq then
                notAdded = false
                SumReclaim(cur, recl)
                break
            end
        end

        if notAdded then
            index = index + 1
            local data = dataPool[index]
            if not data then
                data = {position = Vector(reclX, reclPos[2], reclZ)}
                dataPool[index] = data
            else
                local pos = data.position
                pos[1], pos[2], pos[3] = reclX, reclPos[2], reclZ
            end
            local mass = recl.mass
            data.mass = mass
            data.max = mass
            data.count = 1
        end
    end

    for i = index + 1, lastDataSize do
        dataPool[i].mass = 0
    end

    return index
end
local t = 0
---@param parent ReclaimLabelGroup parent of any newly created relcaim labels
---@param reclaimData UserReclaimData[] reclaim data to display
---@param reclaimDataSize number size of reclaim data
---@param labelPool WorldLabel[] pool of labels to reuse
---@param lastLabelCount number number of labels used last update
local function DisplayReclaim(parent, reclaimData, reclaimDataSize, labelPool, lastLabelCount)
    local IsDestroyed = IsDestroyed
    if reclaimDataSize < lastLabelCount then
        -- Hide labels we won't use
        for i = reclaimDataSize + 1, lastLabelCount do
            local label = labelPool[i]
            if label then
                if IsDestroyed(label) then
                    labelPool[i] = nil
                elseif not label:IsHidden() then
                    label:Hide()
                end
            end
        end
    end
    local timer = GetSystemTimeSeconds()
    for i = 1, reclaimDataSize do
        local label = labelPool[i]
        local data = reclaimData[i]
        if label == nil or IsDestroyed(label) then
            label = CreateReclaimLabel(parent, data)
            labelPool[i] = label
        else
            label:DisplayReclaim(data)
        end
    end
    t = GetSystemTimeSeconds() - timer
end

function UpdateLabels()
    local timer = GetSystemTimeSeconds()
    local dataPool, dataPoolSize, maxLabels = DataPool, DataPoolSize, MaxLabels

    local view = GetView()

    local reclaim, count = GetInViewReclaim(view, Reclaim, MinAmount)

    if DoCombineLabels() then
        local size = CombineReclaim(reclaim, dataPool, LastDataSize)
        if dataPoolSize < size then
            DataPoolSize = size
        end
        LastDataSize = size
        reclaim, count = dataPool, size
    end
    if count > maxLabels then
        count = maxLabels
        TableSort(dataPool, CompareMass)
    end

    DisplayReclaim(view.ReclaimGroup, reclaim, count, LabelPool, LastLabelCount)
    LastLabelCount = count
    if count > LabelPoolSize then
        LabelPoolSize = count
    end
end

---@param view WorldView
function InitReclaimGroup(view)
    if not view.ReclaimGroup or IsDestroyed(view.ReclaimGroup) then
        local camera = GetCamera("WorldCamera")
        ---@type ReclaimLabelGroup
        local rgroup = Layouter(Group(view))
            :Fill(view)
            :DisableHitTest()
            :NeedsFrameUpdate(true)
            :End()
        rgroup.view = view
        rgroup.prevPos = camera:GetFocusPosition()
        rgroup.OnFrame = function(self, delta)
            local curPos = camera:GetFocusPosition()
            local prevPos = self.prevPos
            self.isMoving = curPos[1] ~= prevPos[1] or curPos[2] ~= prevPos[2] or curPos[3] ~= prevPos[3]
            self.prevPos = curPos
        end

        view.ReclaimGroup = rgroup
    end

    view.ReclaimGroup:Show()
    view.NewViewing = true
end

---@param watch_key string
function ShowReclaimThread(watch_key)
    local view = GetView()
    InitReclaimGroup(view)
    local camera = GetCamera("WorldCamera")
    local oldZoom, oldPosition

    while view.ShowingReclaim and (not watch_key or IsKeyDown(watch_key)) do
        if IsDestroyed(camera) then
            break
        end
        local zoom = camera:GetZoom()
        local position = camera:GetFocusPosition()
        if ReclaimChanged or
            view.NewViewing or
            oldZoom ~= zoom or
            oldPosition[1] ~= position[1] or
            oldPosition[2] ~= position[2] or
            oldPosition[3] ~= position[3]
        then
            UpdateLabels()
            ReclaimChanged = false
            view.NewViewing = false
            oldZoom = zoom
            oldPosition = position
        end
        WaitSeconds(0.1)

    end

    if not IsDestroyed(view) then
        view.ReclaimThread = nil
        view.ReclaimGroup:Hide()
    end
end

---@param show boolean
function ShowReclaim(show)
    local view = GetView()
    view.ShowingReclaim = show

    if show and not view.ReclaimThread then
        view.ReclaimThread = ForkThread(ShowReclaimThread)
    end
end





--- Called when the minimum amount is changed
--- TODO: Remove it, and the options along with it
---@deprecated
---@param value number
function updateMinAmount(value)
    MinAmount = value
    ReclaimChanged = true
end

--- Called when the maximum amount of labels is changed
--- TODO: Remove it, and the options along with it
---@deprecated
---@param value number
function updateMaxLabels(value)
    MaxLabels = value
    ReclaimChanged = true
    local LabelPool = LabelPool
    for index = MaxLabels + 1, TableGetn(LabelPool) do
        LabelPool[index]:Destroy()
        LabelPool[index] = nil
    end
end
