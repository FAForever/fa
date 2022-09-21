local Group = import('/lua/maui/group.lua').Group
local Label = import('/lua/ui/controls/label.lua').Label
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Prefs = import('/lua/user/prefs.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local options = Prefs.GetFromCurrentProfile('options')

local MathClamp = math.clamp
local MathFloor = math.floor
local MathLog = math.log
local MathMax = math.max
local MathMin = math.min
local TableGetn = table.getn
local TableSort = table.sort

---@class UserReclaimData
---@field mass number
---@field position Vector
---@field count number
---@field max number

---@class WorldLabelGroup : Group
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


---@class WorldLabel : Label
---@field icon Bitmap
---@field text Text
---
---@field parent WorldLabelGroup
---@field position Vector
---@field reproject boolean
local WorldLabel = Class(Label) {
    ---@param self WorldLabel
    ---@param parent WorldLabelGroup
    ---@param icon? FileName
    ---@param label? UnlocalizedString
    ---@param position? Vector
    __init = function(self, parent, icon, label, position)
        Label.__init(self, parent, icon, label, 10, UIUtil.bodyFont, true)

        self.parent = parent
        self.position = position or Vector(0, 0, 0)
        self.reproject = true

        self:DisableHitTest(true)
        self:SetNeedsFrameUpdate(true)
    end;

    Layout = function(self)
        Label.Layout(self)
        local parent = self.parent
        local icon, text = self.icon, self.text
        -- Make all text show over icons
        if icon then
            LayoutHelpers.DepthOverParent(icon, parent, 3)
        end
        if text then
            LayoutHelpers.DepthOverParent(text, parent, 5)
        end
    end;

    MoveTo = function(self, position)
        self.position = position
        self:PositionAt(position)
    end;

    PositionAt = function(self, position)
        local proj = self.parent.view:Project(position)
        self:FocusOn(proj[1], proj[2])
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


---@class ReclaimLabel : WorldLabel
---@field mass number
---@field count number
local ReclaimLabel = Class(WorldLabel) {
    ---@param self ReclaimLabel
    ---@param parent WorldLabelGroup
    ---@param position Vector
    __init = function(self, parent, position)
        WorldLabel.__init(self, parent, UIUtil.UIFile("/game/build-ui/icon-mass_bmp.dds"), "", position)

        self.mass = 0
        self.count = 0
    end;
    ---@param self ReclaimLabel
    __post_init = function(self)
        self:PositionAt(self.position)
        self:Layout()
        LayoutHelpers.SetDimensions(self.icon, 14, 14)
    end;

    ---@param self ReclaimLabel
    Update = function(self)
        self.text:SetText(MathFloor(0.5 + self.mass))
    end;

    --- Updates the reclaim that this label displays
    ---@param self ReclaimLabel
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
}

--- Creates an empty reclaim label
---@param labelGroup WorldLabelGroup
---@return ReclaimLabel
function CreateReclaimLabel(labelGroup)
    return ReclaimLabel(labelGroup, Vector(0, 0, 0))
end

--- Retrieves the map size, storing it in `MapHeight` and `MapWidth`
function SetMapSize()
    local size = SessionGetScenarioInfo().size
    MapWidth = size[1]
    MapHeight = size[2]
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


--- Called when the playable area is changed
---@param rect UserRect
function SetPlayableArea(rect)
    ReclaimChanged = true
    PlayableArea = rect

    -- TODO: performs a deep copy; that is not strictly required
    local newReclaim = {}
    local newOffmapReclaim = {}
    for id, r in Reclaim do
        if InPlayableArea(r.position) then
            newReclaim[id] = r
        else
            newOffmapReclaim[id] = r
        end
    end
    for id, r in OutsidePlayableAreaReclaim do
        if InPlayableArea(r.position) then
            newReclaim[id] = r
        else
            newOffmapReclaim[id] = r
        end
    end
    Reclaim = newReclaim
    OutsidePlayableAreaReclaim = newOffmapReclaim
end

--- Adds to and updates the set of reclaim labels
---@param propData table<EntityId, PropSyncData>
function UpdateReclaim(propData)
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

---@param a UserReclaimData
---@param b UserReclaimData
---@return boolean
local function CompareMass(a, b)
    return a.mass < b.mass
end

--- Combines the reclaim by summing them up and setting the position to the weighted average
---@param r1 UserReclaimData
---@param r2 PropSyncData
---@return any
local function SumReclaim(r1, r2)
    local r1Mass, r2Mass = r1.mass, r2.mass
    local massSum = r1Mass + r2Mass
    local r1Pos, r2Pos = r1.position, r2.position
    r1Pos[1] = (r1Mass * r1Pos[1] + r2Mass * r2Pos[1]) / massSum
    r1Pos[3] = (r1Mass * r1Pos[3] + r2Mass * r2Pos[3]) / massSum
    r1.mass = massSum
    r1.count = r1.count + 1
    if r2Mass > r1.max then
        r1.max = r2Mass
    end
    return r1
end

---@param view WorldView
---@return Vector topLeft
---@return Vector topRight
---@return Vector bottomRight
---@return Vector bottomLeft
local function UnProjectView(view)
    local UnProject = UnProject

    local viewLeft = view.Left()
    local point = Vector2(viewLeft, view.Top())

    local tl = UnProject(view, point)
    point[1] = view.Right()
    local tr = UnProject(view, point)
    point[2] = view.Bottom()
    local br = UnProject(view, point)
    point[1] = viewLeft
    return tl, tr, br, UnProject(view, point)
end

---@param view WorldView
---@param reclaim PropSyncData[]
---@param minAmount number
---@return PropSyncData[] inViewReclaim
---@return number count
local function GetInViewReclaim(view, reclaim, minAmount)
    local inViewCount = 0
    local inViewReclaim = {}

    local tl, tr, br, bl = UnProjectView(view)

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
            if recl.mass >= minAmount or true then
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
            if recl.mass >= minAmount or true then
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
    return GetCamera('WorldCamera'):SaveSettings().Zoom > ZoomThreshold
end

---@param reclaim PropSyncData[] raw reclaim data
---@param dataPool UserReclaimData[] pool of combined reclaim data
---@param lastDataSize number number of entries used last update
---@return number  # number of combined labels
local function CombineReclaim(reclaim, dataPool, lastDataSize)
    local SumReclaim, Vector = SumReclaim, Vector

    local minDistSq = GetCamera('WorldCamera'):SaveSettings().Zoom * HeightRatio
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
            if data == nil then
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

---@param parent WorldLabelGroup parent of any newly created relcaim labels
---@param reclaimData UserReclaimData[] reclaim data to display
---@param reclaimDataSize number size of reclaim data
---@param labelPool ReclaimLabel[] pool of labels to reuse
---@param lastLabelCount number number of labels used last update
local function DisplayReclaim(parent, reclaimData, reclaimDataSize, labelPool, lastLabelCount)
    if reclaimDataSize < lastLabelCount then
        -- Hide labels we won't use
        for i = reclaimDataSize + 1, lastLabelCount do
            local label = labelPool[i]
            if label ~= nil then
                if IsDestroyed(label) then
                    labelPool[i] = nil
                elseif not label:IsHidden() then
                    label:Hide()
                end
            end
        end
    end
    for i = 1, reclaimDataSize do
        local label = labelPool[i]
        if label == nil or IsDestroyed(label) then
            label = CreateReclaimLabel(parent)
            labelPool[i] = label
        end

        label:DisplayReclaim(reclaimData[i])
    end
end

function UpdateLabels()
    local dataPool, dataPoolSize, maxLabels = DataPool, DataPoolSize, MaxLabels

    local view = import('/lua/ui/game/worldview.lua').viewLeft -- Left screen's camera

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
        ---@type WorldLabelGroup
        local rgroup = Group(view)
        rgroup.view = view
        rgroup:DisableHitTest()
        LayoutHelpers.FillParent(rgroup, view)
        rgroup:Show()

        view.ReclaimGroup = rgroup
        rgroup:SetNeedsFrameUpdate(true)
        rgroup.prevPos = camera:GetFocusPosition()
        rgroup.OnFrame = function(self, delta)
            local curPos = camera:GetFocusPosition()
            local prevPos = self.prevPos
            self.isMoving = curPos[1] ~= prevPos[1] or curPos[2] ~= prevPos[2] or curPos[3] ~= prevPos[3]
            self.prevPos = curPos
        end
    else
        view.ReclaimGroup:Show()
    end

    view.NewViewing = true
end

---@param watch_key string
function ShowReclaimThread(watch_key)
    local view = import('/lua/ui/game/worldview.lua').viewLeft
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
    local view = import('/lua/ui/game/worldview.lua').viewLeft
    view.ShowingReclaim = show

    if show and not view.ReclaimThread then
        view.ReclaimThread = ForkThread(ShowReclaimThread)
    end
end

function ToggleReclaim()
    local view = import('/lua/ui/game/worldview.lua').viewLeft
    ShowReclaim(not view.ShowingReclaim)
end

---@param show boolean
function OnCommandGraphShow(show)
    local view = import('/lua/ui/game/worldview.lua').viewLeft
    if view.ShowingReclaim and not CommandGraphActive then return end -- if on by toggle key

    CommandGraphActive = show
    if show then
        ForkThread(function()
            local keydown
            while CommandGraphActive do
                keydown = IsKeyDown('Control')
                if keydown ~= view.ShowingReclaim then -- state has changed
                    ShowReclaim(keydown)
                end
                WaitSeconds(0.1)

            end
            ShowReclaim(false)
            -- check if it's worth freeing the memory
            if TableGetn(Reclaim) * 2 > DataPoolSize then
                DataPool = {}
                DataPoolSize = 0
            end
            if LabelPoolSize * 2 > MaxLabels then
                LabelPool = {}
                LabelPoolSize = 0
            end
        end)
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



----------
--- Hook experiment
----------


---@param hue? number defaults to 0 degrees (red)
---@param sat? number defaults to 1.0 (fully colorful)
---@param val? number defaults to 1.0 (fully bright)
---@param alpha? number defaults to 1.0 (fully opaque)
---@return Color
function ColorHSV(hue, sat, val, alpha)
    hue = (hue or 0) * 1535
    local r, g, b = 0, 0, 0
    if sat then
        local interp = -255 * sat
        if hue < 768 then
            if hue < 256 then
                g = hue * sat + interp
                b = interp
            elseif hue < 512 then
                r = (511 - hue) * sat + interp
                b = interp
            else
                r = interp
                b = (hue - 512) * sat + interp
            end
        else
            if hue < 1024 then
                r = interp
                g = (1023 - hue) * sat + interp
            elseif hue < 1280 then
                r = (hue - 1024) * sat + interp
                b = 255
            else
                r = 255
                b = (1535 - hue) * sat + interp
            end
        end
        r, g, b = r + 255, g + 255, b + 255
    else
        if hue < 768 then
            if hue < 256 then
                r = 255
                g = hue
            elseif hue < 512 then
                r = 511 - hue
                g = 255
            else
                g = 255
                b = hue - 512
            end
        else
            if hue < 1024 then
                g = 1024 - hue
                b = 255
            elseif hue < 1280 then
                r = hue - 1024
                g = 255
            else
                g = 255
                b = 1535 - hue
            end
        end
    end
    if val then
        r, g, b = r * val, g * val, b * val
    end
    if alpha then
        return ("%02x%02x%02x%02x"):format(alpha, r, g, b)
    end
    return ("%02x%02x%02x"):format(r, g, b)
end

local oldReclaimLabel_Update = ReclaimLabel.Update
function ReclaimLabel:Update()
    oldReclaimLabel_Update(self)
    self.text._color[1] = nil
    self.text._color:OnDirty()
end

local oldCreateReclaimLabel = CreateReclaimLabel
function CreateReclaimLabel(labelGroup)
    local label = oldCreateReclaimLabel(labelGroup)
    label:SetColor(function()
        local count = label.count
        local mass = label.mass
        if count == 0 then
            return ColorHSV(0.31, 0.75)
        end
        local MathClamp, MathLog = MathClamp, MathLog
        -- hueScale = clamp(log_{100,000}((mass - MinAmount) / 100 + 1), 0, 1)
        local hueScale = MathClamp((MathLog(mass - MinAmount + 1000) - 4.60517018599) * 0.0868588963807, 0, 1)
        local satScale = 0
        if count > 1 then
            -- satScale = clamp(log_{10}((count - 1) / 10 + 1), 0, 1)
            satScale = MathClamp((MathLog(count - 9) - 2.30258509299) * 0.434294481903, 0, 1)
        end
        local col = ColorHSV(0.01 + 0.3 * (1 - hueScale), 0.75 + satScale * 0.25)
        return col
    end)
    return label
end
