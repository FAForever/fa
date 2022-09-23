local MathMax = math.max
local MathMin = math.min
local TableGetn = table.getn

local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')
local Prefs = import('/lua/user/prefs.lua')
local options = Prefs.GetFromCurrentProfile('options')

---@class UIReclaimDataPoint
---@field mass number
---@field position Vector

---@class UIReclaimDataCombined
---@field mass number
---@field position Vector
---@field count number
---@field max number

---@type number
local HEIGHT_RATIO = 0.012

--- Reclaim is no longer combined once this threshold is met, the value (150) is the same
--- camera distance that allows for the reclaim command to work. Guarantees that the
--- labels represent where you can reclaim.
---@type number
local ZOOM_THRESHOLD = 150

--- TODO: remove the options
---@type number
local MaxLabels = options.maximum_reclaim_count or 1000

--- TODO: remove the options
---@type number
local MinAmount = options.minimum_reclaim_amount or 10

---@type table<EntityId, UIReclaimDataPoint>
local Reclaim = {}

---@type table<EntityId, UIReclaimDataPoint>
local OutsidePlayableAreaReclaim = {}

---@type UIReclaimDataCombined[]
local reclaimDataPool = {}

---@type number
local totalReclaimData = 0

---@type WorldLabel[]
local LabelPool = {}

---@type number
local OldZoom

---@type Vector
local OldPosition

---@type boolean
local ReclaimChanged = true
local PlayableArea

---@class WorldLabel : Group
---@field parent WorldView
---@field position Vector
---@field mass Bitmap
---@field text Text
local WorldLabel = Class(Group) {
    __init = function(self, parent, position)
        Group.__init(self, parent)
        self.parent = parent
        self.position = position
        self._project = true

        self.Top:Set(0)
        self.Left:Set(0)
        LayoutHelpers.SetDimensions(self, 25, 25)

        self.mass = Bitmap(self)
        self.mass:SetTexture(UIUtil.UIFile('/game/build-ui/icon-mass_bmp.dds'))
        LayoutHelpers.AtLeftIn(self.mass, self)
        LayoutHelpers.AtVerticalCenterIn(self.mass, self)
        LayoutHelpers.SetDimensions(self.mass, 14, 14)

        self.text = UIUtil.CreateText(self, "", 10, UIUtil.bodyFont)
        self.text:SetColor('ffc7ff8f')
        self.text:SetDropShadow(true)
        LayoutHelpers.AtLeftIn(self.text, self, 16)
        LayoutHelpers.AtVerticalCenterIn(self.text, self)

        self:DisableHitTest(true)
        self:SetNeedsFrameUpdate(true)
    end,

    --- Updates the reclaim that this label displays
    ---@param self WorldLabel
    ---@param r any
    DisplayReclaim = function(self, r)
        if self:IsHidden() then
            self:Show()
        end

        self.position = r.position
        if r.mass ~= self.oldMass then
            local mass = tostring(math.floor(0.5 + r.mass))
            self.text:SetText(mass)
            self.oldMass = r.mass
        end
    end,

    --- Called each frame by the engine
    ---@param self WorldLabel
    ---@param delta number
    OnFrame = function(self, delta)
        if self._project then
            local view = self.parent.view
            local proj = view:Project(self.position)
            self.Left:SetValue(proj.x - 0.5 * self.Width())
            self.Top:SetValue(proj.y - 0.5 * self.Height() + 1)
        end
        self._project = self.parent.isMoving
    end,

    --- Called when the control is hidden or shown, used to start updating
    ---@param self WorldLabel
    ---@param hidden boolean
    OnHide = function(self, hidden)
        self:SetNeedsFrameUpdate(not hidden)
    end,
}

---
---@param a UIReclaimDataPoint
---@param b UIReclaimDataPoint
---@return boolean
local function CompareMass(a, b)
    return a.mass > b.mass
end

---@type number
local mapWidth = 0

---@type number
local mapHeight = 0

--- Retrieves the map size, storing it in `mapHeight` and `mapWidth`
function SetMapSize()
    mapWidth = SessionGetScenarioInfo().size[1]
    mapHeight = SessionGetScenarioInfo().size[2]
end

--- Used to determine if the whole map is in view, taking into account the playable area if available
---@param pos Vector
---@return boolean
local function IsInMapArea(pos)
    if PlayableArea then
        return pos[1] > PlayableArea[1] and
            pos[1] < PlayableArea[3] or
            pos[3] > PlayableArea[2] and
            pos[3] < PlayableArea[4]
    else
        return pos[1] > 0 and
            pos[1] < mapWidth or
            pos[3] > 0 and
            pos[3] < mapHeight
    end
end

--- Determines if the point is in the playable area, if available.
---@param pos Vector
---@return boolean
function InPlayableArea(pos)
    if PlayableArea then
        return pos[1] > PlayableArea[1] and
            pos[1] < PlayableArea[3] and
            pos[3] > PlayableArea[2] and
            pos[3] < PlayableArea[4]
    end
    return true
end

--- Called when the playable area is changed
---@param rect table<number>
function SetPlayableArea(rect)
    ReclaimChanged = true
    PlayableArea = rect

    -- TODO: performs a deep copy, that is not strictly required
    local newReclaim = {}
    local newOutsidePlayableAreaReclaim = {}
    local ReclaimLists = { Reclaim, OutsidePlayableAreaReclaim }
    for _, reclaimList in ReclaimLists do
        for id, r in reclaimList do
            if InPlayableArea(r.position) then
                newReclaim[id] = r
            else
                newOutsidePlayableAreaReclaim[id] = r
            end
        end
    end
    Reclaim = newReclaim
    OutsidePlayableAreaReclaim = newOutsidePlayableAreaReclaim
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
    for index = MaxLabels + 1, table.getn(LabelPool) do
        LabelPool[index]:Destroy()
        LabelPool[index] = nil
    end
end

--- Adds to and updates the set of reclaim labels
---@param reclaimPoints UIReclaimDataPoint[]
function UpdateReclaim(reclaimPoints)
    ReclaimChanged = true
    for id, reclaimPoint in reclaimPoints do
        if not reclaimPoint.mass then
            Reclaim[id] = nil
            OutsidePlayableAreaReclaim[id] = nil
        else
            if InPlayableArea(reclaimPoint.position) then
                Reclaim[id] = reclaimPoint
                OutsidePlayableAreaReclaim[id] = nil
            else
                Reclaim[id] = nil
                OutsidePlayableAreaReclaim[id] = reclaimPoint
            end
        end
    end
end

-- Creates an empty reclaim label
function CreateReclaimLabel(view)
    local label = WorldLabel(view, Vector(0, 0, 0))
    return label
end

--- Combines the reclaim by summing them up together, averages position based on mass value
---@param r1 UIReclaimDataCombined
---@param r2 UIReclaimDataPoint
---@return any
local function SumReclaim(r1, r2)
    local massSum = r1.mass + r2.mass
    r1.count = r1.count + (r2.count or 1)
    r1.position[1] = (r1.mass * r1.position[1] + r2.mass * r2.position[1]) / massSum
    r1.position[3] = (r1.mass * r1.position[3] + r2.mass * r2.position[3]) / massSum
    r1.max = MathMax(r1.max or r1.mass, r2.mass)
    r1.mass = massSum
    return r1
end

---@param reclaim UIReclaimDataPoint
---@return boolean | number         # Returns the number of labels, or false if the zoom threshold is
local function _CombineReclaim(reclaim)

    local zoom = GetCamera('WorldCamera'):SaveSettings().Zoom

    if zoom < ZOOM_THRESHOLD then
        return false
    end

    local minDist = zoom * HEIGHT_RATIO
    local minDistSq = minDist * minDist
    local index = 0

    local added

    local x1
    local x2
    local y1
    local y2
    local dx
    local dy

    --- O(n)
    for _, r in reclaim do

        added = false
        x1 = r.position[1]
        y1 = r.position[3]

        --- TODO: use a basic grid query (quad tree overcomplicates it) -> O(k), where k is strictly smaller than n
        --- O(n)
        for i = 1, index do
            cr = reclaimDataPool[i]
            x2 = cr.position[1]
            y2 = cr.position[3]
            dx = x1 - x2
            dy = y1 - y2
            if dx * dx + dy * dy < minDistSq then
                added = true
                SumReclaim(cr, r)
                break
            end
        end

        if not added then
            index = index + 1
            if index > totalReclaimData then
                reclaimDataPool[index] = {
                    mass = r.mass,
                    position = Vector(0, 0, 0),
                    count = 1
                }
                totalReclaimData = totalReclaimData + 1
            end
            local rd = reclaimDataPool[index]
            rd.mass = r.mass
            rd.max = r.mass
            rd.count = 1
            local v = rd.position
            v[1] = x1
            v[2] = r.position[2]
            v[3] = y1
        end
    end

    for i = index + 1, totalReclaimData do
        reclaimDataPool[i].mass = 0
    end

    return index
end

local function ContainsWholeMap(minX, minY, maxX, maxY)
    if PlayableArea then
        return minX < PlayableArea[1] and
            maxX > PlayableArea[3] and
            minY < PlayableArea[2] and
            maxY > PlayableArea[4]
    else
        return minX < 0 and
            maxX > mapWidth and
            minY < 0 and
            maxY > mapHeight
    end
end

function UpdateLabels()

    if table.getn(Reclaim) < totalReclaimData then
        totalReclaimData = 0
        reclaimDataPool = {}
    end

    local view = import('/lua/ui/game/worldview.lua').viewLeft -- Left screen's camera
    local onScreenReclaimIndex = 1
    local onScreenReclaims = {}

    local tl = UnProject(view, Vector2(view.Left(), view.Top()))
    local tr = UnProject(view, Vector2(view.Right(), view.Top()))
    local br = UnProject(view, Vector2(view.Right(), view.Bottom()))
    local bl = UnProject(view, Vector2(view.Left(), view.Bottom()))




    local x0
    local y0
    local x1 = tl[1]
    local y1 = tl[3]
    local x2 = tr[1]
    local y2 = tr[3]
    local x3 = br[1]
    local y3 = br[3]
    local x4 = bl[1]
    local y4 = bl[3]

    local minX = MathMin(x1, x2, x3, x4)
    local maxX = MathMax(x1, x2, x3, x4)
    local minY = MathMin(y1, y2, y3, y4)
    local maxY = MathMax(y1, y2, y3, y4)

    local checkForContainment = not ContainsWholeMap(minX, minY, maxX, maxY)

    local y21 = (y2 - y1)
    local y32 = (y3 - y2)
    local y43 = (y4 - y3)
    local y14 = (y1 - y4)
    local x21 = (x2 - x1)
    local x32 = (x3 - x2)
    local x43 = (x4 - x3)
    local x14 = (x1 - x4)

    local s1
    local s2
    local s3
    local s4

    local function Contains(point)
        x0 = point[1]
        y0 = point[3]
        if x0 < minX or x0 > maxX or y0 < minY or y0 > maxY then
            return false
        end
        s1 = (x1 - x0) * y21 - x21 * (y1 - y0)
        s2 = (x2 - x0) * y32 - x32 * (y2 - y0)
        s3 = (x3 - x0) * y43 - x43 * (y3 - y0)
        s4 = (x4 - x0) * y14 - x14 * (y4 - y0)
        return (s1 > 0 and s2 > 0 and s3 > 0 and s4 > 0)
    end

    for _, r in Reclaim do
        if r.mass >= MinAmount and (not checkForContainment or Contains(r.position)) then
            onScreenReclaims[onScreenReclaimIndex] = r
            onScreenReclaimIndex = onScreenReclaimIndex + 1
        end
    end


    local size = _CombineReclaim(onScreenReclaims)

    table.sort(reclaimDataPool, CompareMass)

    local labelIndex = 1
    if size then
        for i = 1, size do
            recl = reclaimDataPool[i]
            if labelIndex > MaxLabels then
                break
            end
            local label = LabelPool[labelIndex]
            if label and IsDestroyed(label) then
                label = nil
            end
            if not label then
                label = CreateReclaimLabel(view.ReclaimGroup)
                LabelPool[labelIndex] = label
            end

            label:DisplayReclaim(recl)
            labelIndex = labelIndex + 1
        end

    else
        for _, recl in onScreenReclaims do
            if labelIndex > MaxLabels then
                break
            end
            local label = LabelPool[labelIndex]
            if label and IsDestroyed(label) then
                label = nil
            end
            if not label then
                label = CreateReclaimLabel(view.ReclaimGroup)
                LabelPool[labelIndex] = label
            end

            label:DisplayReclaim(recl)
            labelIndex = labelIndex + 1
        end
    end
    -- Hide labels we didn't use
    for index = labelIndex, MaxLabels do
        local label = LabelPool[index]
        if label then
            if IsDestroyed(label) then
                LabelPool[index] = nil
            elseif not label:IsHidden() then
                label:Hide()
            end
        end
    end
end

local ReclaimThread
function ShowReclaim(show)
    local view = import('/lua/ui/game/worldview.lua').viewLeft
    view.ShowingReclaim = show

    if show and not view.ReclaimThread then
        view.ReclaimThread = ForkThread(ShowReclaimThread)
    end
end

function InitReclaimGroup(view)
    if not view.ReclaimGroup or IsDestroyed(view.ReclaimGroup) then
        local camera = GetCamera("WorldCamera")
        local rgroup = Group(view)
        rgroup.view = view
        rgroup:DisableHitTest()
        LayoutHelpers.FillParent(rgroup, view)
        rgroup:Show()

        view.ReclaimGroup = rgroup
        rgroup:SetNeedsFrameUpdate(true)
        rgroup._prevPos = camera:GetFocusPosition()
        rgroup.OnFrame = function(self, delta)
            local curPos = camera:GetFocusPosition()
            local prevPos = self._prevPos
            self.isMoving = curPos[1] ~= prevPos[1] or curPos[2] ~= prevPos[2] or curPos[3] ~= prevPos[3]
            self._prevPos = curPos
        end
    else
        view.ReclaimGroup:Show()
    end

    view.NewViewing = true
end

function ShowReclaimThread(watch_key)
    local view = import('/lua/ui/game/worldview.lua').viewLeft
    local camera = GetCamera("WorldCamera")

    InitReclaimGroup(view)

    while view.ShowingReclaim and (not watch_key or IsKeyDown(watch_key)) do
        if not IsDestroyed(camera) then
            local zoom = camera:GetZoom()
            local position = camera:GetFocusPosition()
            if ReclaimChanged
                or view.NewViewing
                or OldZoom ~= zoom
                or OldPosition[1] ~= position[1]
                or OldPosition[2] ~= position[2]
                or OldPosition[3] ~= position[3] then
                UpdateLabels()
                OldZoom = zoom
                OldPosition = position
                ReclaimChanged = false
            end

            view.NewViewing = false
        end
        WaitSeconds(.1)
    end

    if not IsDestroyed(view) then
        view.ReclaimThread = nil
        view.ReclaimGroup:Hide()
    end
end

function ToggleReclaim()
    local view = import('/lua/ui/game/worldview.lua').viewLeft
    ShowReclaim(not view.ShowingReclaim)
end

local CommandGraphActive = false
function OnCommandGraphShow(bool)
    local view = import('/lua/ui/game/worldview.lua').viewLeft
    if view.ShowingReclaim and not CommandGraphActive then return end -- if on by toggle key

    CommandGraphActive = bool
    if CommandGraphActive then
        ForkThread(function()
            local keydown
            while CommandGraphActive do
                keydown = IsKeyDown('Control')
                if keydown ~= view.ShowingReclaim then -- state has changed
                    ShowReclaim(keydown)
                end
                WaitSeconds(.1)
            end

            ShowReclaim(false)
        end)
    else
        CommandGraphActive = false -- above coroutine runs until now
    end
end
