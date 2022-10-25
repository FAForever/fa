local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local UIUtil = import("/lua/ui/uiutil.lua")

local Group = import("/lua/maui/group.lua").Group
local ColorHSV = import("/lua/shared/color.lua").ColorHSV

local Layouter = LayoutHelpers.ReusedLayoutFor
local Scale = LayoutHelpers.ScaleNumber

local MathClamp = math.clamp
local MathFloor = math.floor
local MathLog = math.log
local MathMax = math.max
local TableGetn = table.getn
local TableSort = table.sort


---@class UserReclaimData : BaseReclaimData
---@field count number
---@field max number

---@alias InViewReclaimStruct table<UserReclaimData[]>

---@class ReclaimLabelGroup : Group
---@field view WorldView
---@field isMoving boolean
---@field prevPos Vector


local HeightRatio = 0.012
--- Reclaim is no longer combined once this threshold is met, the value (150) is the same camera
--- distance that allows for the reclaim command to work. Guarantees that the  labels represent
--- where you can reclaim.
local ZoomThreshold = 150
local MaxLabels = 500


---@type table<EntityId, PropSyncData>
local Reclaim
---@type table<EntityId, PropSyncData>
local OutsidePlayableAreaReclaim

---@type UserReclaimData[], number, number
local DataPool, DataPoolSize, DataPoolUse
---@type WorldLabel[], number, number
local LabelPool, LabelPoolSize, LabelPoolUse

---@type UserRect
local PlayableArea
---@type number, number
local MapWidth, MapHeight

---@type boolean
local CommandGraphActive
---@type boolean
local ReclaimChanged


function Init()
    Reclaim = {}
    OutsidePlayableAreaReclaim = {}

    DataPool, DataPoolSize, DataPoolUse = {}, 0, 0
    LabelPool, LabelPoolSize, LabelPoolUse = {}, 0, 0
    setmetatable(LabelPool, WeakValueMetatable)

    PlayableArea = nil
    local size = SessionGetScenarioInfo().size
    MapWidth, MapHeight = size[1], size[2]

    CommandGraphActive = false
    ReclaimChanged = false
end


---@class WorldLabel : Group
---@field icon Bitmap
---@field text Text
---
---@field parent ReclaimLabelGroup
---@field position Vector
---@field reproject boolean
---@field mass number
---@field max number
---@field count number
local WorldLabel = Class(Group) {
    ---@param self WorldLabel
    ---@param parent ReclaimLabelGroup
    ---@param data UserReclaimData
    __init = function(self, parent, data)
        Group.__init(self, parent)

        self.parent = parent
        self.position = data.position
        self.mass = data.mass or 0
        self.max = data.max or self.mass
        self.count = data.count or 1

        self.icon = UIUtil.CreateBitmapStd(self, "/game/build-ui/icon-mass")
        self.text = UIUtil.CreateText(self, "", self:GetTextSize(), UIUtil.bodyFont, true)

        self:Update()
    end;

    OnLayout = function(self)
        self.Width:SetFunction(function()
            return self.icon.Width() + Scale(2) + self.text.Width()
        end)
        self.Height:SetFunction(function()
            return MathMax(self.icon.Height(), self.text.Height())
        end)
        self:UpdatePosition()
    end;

    Layout = function(self)
        local size = self:GetIconSize()
        local icon = Layouter(self.icon)
            :AtLeftCenterIn(self)
            :Over(self, 3)
            :End()
        -- bypass UI scaling
        icon.Width:SetValue(size)
        icon.Height:SetValue(size)

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
        local mass = self.mass - 10 -- fit to minimum
        if mass <= 0 then
            return "7FC7FF8F"
        end

        -- We'd like to scale the hue of the label based on the logarithm of the mass value clamped
        -- to 1 at some cutoff point. We'd also like to approximate this in the more commonly-used
        -- small end of the scale using a proportional quadratic function up to a threshold. This
        -- also ends up flattening it into something more useful, rather than a quarter of the
        -- function being between 0 and 5.
        -- 
        -- Thus, we have three parameters to consider for our function
        --    base: how quickly the function scales a mass value to hue
        --    cutoff: when the function meets 1
        --    thres: when the logarithm stops being approximated
        --
        -- We use the nominal logarithm scaling function
        --    nominal(x) = log_{base}(x / scale + 1)
        --               = ln(x + scale)/ln(base) - ln(scale)/ln(base)
        -- where `scale` depends on the cutoff value:
        --             1 = nominal(cutoff)
        --             1 = log_{base}(cutoff / scale + 1)
        --         scale = cutoff / (base - 1)
        -- 
        -- The approximating function is `a x^2 + b x` where we choose `a` and `b` such that the
        -- slopes of the approximating function and the nominal function are smooth up to the first
        -- derivative at the threshold point:
        --     approx(thres) = nominal(thres)
        --     approx'(thres) = nominal'(thres)
        -- "it is left as an exercise to the reader to validate the solutions for `a` and `b`:"
        --     a = -((ln(thres + scale) - ln(scale)) / thres - 1 / (thres + scale)) / ln(base)thres
        --     b = (2(ln(thres + scale) - ln(scale)) / thres - 1 / (thres + scale)) / ln(base)
        --
        -- We now up it all together in a piecewise function for the hue:
        --        hue(x) = { x <= thres  : approx(x)     => A x (x + B)
        --                 { x >= cutoff : 1
        --                 { else        : nominal(x)    => ln(x + S) * C + D
        -- where
        --             S = cutoff / (base - 1)
        --             C = 1 / ln(base)
        --             D = -C ln(S)
        --             A = -((C ln(thres + S) + D) / thres - C / (thres + S)) / thres
        --             B = (2(C ln(thres + S) + D) / thres - C / (thres + S)) / A
        --
        -- the current parameter values are:
        --     threshold = 94.5692754978 (chosen to split the function in half)
        --          base = 100000
        --        cutoff = 30000
        -- which yield the following constants:
        --         scale = 0.30000300003
        --             A = -0.0000462260645186
        --             B = -208.944779635
        --             C = 0.0868588963807
        --             D = 0.104574880463

        local hue
        if mass <= 94.5692754978 then
            hue = -0.0000462260645186 * mass * (mass - 208.944779635)
        elseif mass >= 30000 then
            hue = 1
        else
            hue = MathLog(mass + 0.30000300003) * 0.0868588963807 - 0.104574880463
        end

        -- saturation will just be an abstract indicator of how "compact" the label is
        local sat = MathClamp(self.max / mass, 0, 1)

        -- we now have a number 0-1 of the hue & saturation range we want to use; transform them
        -- into the proper ranges
        hue = 0.31 - 0.3 * hue
        sat = 0.75 + 0.25 * sat
        return ColorHSV(hue, sat)
    end;

    --- Returns the text of the reclaim label
    ---@param self WorldLabel
    ---@return LocalizedString | number
    GetText = function(self)
        local mass = self.mass
        if mass < 1 then
            return "<1"
        end
        if mass < 10 then
            return ("%.2f"):format(mass + 0.005)
        end
        return MathFloor(mass + 0.5)
    end;

    ---@param self WorldLabel
    GetTextSize = function(self)
        return Scale(10)
    end;

    ---@param self WorldLabel
    GetIconSize = function(self)
        return Scale(14)
    end;

    ---@param self WorldLabel
    Update = function(self)
        local text = self.text
        text:SetText(self:GetText())
        text:SetColor(self:GetColor())
        local textsize = self:GetTextSize()
        local fontsize = text._font._pointsize
        if textsize ~= fontsize() then
            fontsize:SetValue(textsize)
        end

        local icon = self.icon
        local iconsize = self:GetIconSize()
        local iconwidth = icon.Width
        if iconsize ~= iconwidth() then
            iconwidth:SetValue(iconsize)
            icon.Height:SetValue(iconsize)
        end
    end;

    --- Updates the reclaim that this label displays
    ---@param self WorldLabel
    ---@param reclaim UserReclaimData
    DisplayReclaim = function(self, reclaim)
        local mass = reclaim.mass or 0
        local count = reclaim.count or 1
        local max = reclaim.max or mass
        if mass ~= self.mass or count ~= self.count or max ~= self.max then
            self.mass = mass
            self.count = count
            self.max = max
            self:Update()
        end
        self:MoveTo(reclaim.position)
        self:Show()
    end;

    ---@param self WorldLabel
    ---@param position Vector
    MoveTo = function(self, position)
        self.position = position
        self:UpdatePosition()
    end;

    ---@param self WorldLabel
    UpdatePosition = function(self)
        local proj = self.parent.view:Project(self.position)
        self.Left:SetValue(proj[1] - 0.5 * self.icon.Width())
        self.Top:SetValue(proj[2] - 0.5 * self.Height())
    end;

    ---@param self WorldLabel
    OnFrame = function(self)
        if self.parent.isMoving then
            self:UpdatePosition()
        end
    end;

    --- Called when the control is hidden or shown, used to start updating
    ---@param self WorldLabel
    ---@param hidden boolean
    OnHide = function(self, hidden)
        self:SetNeedsFrameUpdate(not hidden)
    end;
}

--- Creates an empty reclaim label
---@param labelGroup ReclaimLabelGroup
---@param data UserReclaimData
---@return WorldLabel
function CreateReclaimLabel(labelGroup, data)
    return Layouter(WorldLabel(labelGroup, data))
        :End()
end


---@return WorldView
function GetView()
    return import("/lua/ui/game/worldview.lua").viewLeft
end

--- Determines if the point is in the playable area, if available
---@param pos Vector
---@return boolean
function InPlayableArea(pos)
    local x, z = pos[1], pos[3]
    local playableArea = PlayableArea
    if playableArea then
        return x > playableArea[1] and x < playableArea[3] and
               z > playableArea[2] and z < playableArea[4]
    end
    -- default to map size
    return x > 0 and x < MapWidth and
           z > 0 and z < MapHeight
end

--- Called when the playable area is changed
---@param rect UserRect
function SetPlayableArea(rect)
    if not Reclaim then
        Init()
    end
    local InPlayableArea = InPlayableArea
    local reclaim = Reclaim
    local offmapReclaim = OutsidePlayableAreaReclaim

    -- set up-front so that `InPlayableArea()` works
    PlayableArea = rect

    -- add to a separate table so we don't recheck it
    local nowOffmap = {}
    for id, r in reclaim do
        if not InPlayableArea(r.position) then
            reclaim[id] = nil
            nowOffmap[id] = r
        end
    end

    for id, r in offmapReclaim do
        if InPlayableArea(r.position) then
            reclaim[id] = r
            offmapReclaim[id] = nil
        end
    end

    -- now add the offmapping reclaim
    for id, r in nowOffmap do
        offmapReclaim[id] = r
    end

    ReclaimChanged = true
end


--- Adds to and updates the set of reclaim labels
---@param propData table<EntityId, PropSyncData>
function UpdateReclaim(propData)
    local InPlayableArea = InPlayableArea
    local reclaim = Reclaim
    if not reclaim then
        Init()
        reclaim = Reclaim
    end
    local offmapReclaim = OutsidePlayableAreaReclaim

    for id, prop in propData do
        if prop.mass then
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

    ReclaimChanged = true
end

---@param show boolean
function OnCommandGraphShow(show)
    if not Reclaim then
        Init()
    end
    local view = GetView()
    if view.ShowingReclaim and not CommandGraphActive then return end -- if on by toggle key

    CommandGraphActive = show

    if show then
        ForkThread(function()
            while CommandGraphActive do
                local keydown = IsKeyDown("Control")
                if keydown ~= view.ShowingReclaim then -- state has changed
                    ShowReclaim(keydown)
                end
                WaitSeconds(0.1)

            end
            ShowReclaim(false)
        end)
    end
end

function ToggleReclaim()
    if not Reclaim then
        Init()
    end
    ShowReclaim(not GetView().ShowingReclaim)
end

---@param show boolean
function ShowReclaim(show)
    if not Reclaim then
        Init()
    end
    local view = GetView()
    view.ShowingReclaim = show

    if show and not view.ReclaimThread then
        view.ReclaimThread = ForkThread(ShowReclaimThread, view)
    end
end
function ShowReclaimThread(view)
    local camera = GetCamera("WorldCamera")
    InitReclaimGroup(view, camera)
    local oldZoom, oldPosition

    while view.ShowingReclaim do
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
            UpdateLabels(view, zoom)
            ReclaimChanged = false
            view.NewViewing = false
            oldZoom = zoom
            oldPosition = position
        end
        WaitSeconds(0.1)

    end

    if not IsDestroyed(view) then
        HideUnusedLabels(LabelPool, 0, LabelPoolUse)
        LabelPoolUse = 0
    end
    view.ReclaimGroup:SetNeedsFrameUpdate(false)
    view.ReclaimThread = nil

    if not CommandGraphActive then
        -- check if it's worth freeing the memory
        if TableGetn(Reclaim) * 2 > DataPoolSize then
            DataPool = {}
            DataPoolSize = 0
        end
        if LabelPoolSize * 2 > MaxLabels then
            LabelPool = {}
            LabelPoolSize = 0
        end
    end
end

---@param view WorldView
---@param camera Camera
function InitReclaimGroup(view, camera)
    ---@type ReclaimLabelGroup
    local reclaimGroup = view.ReclaimGroup
    if not reclaimGroup or IsDestroyed(reclaimGroup) then
        reclaimGroup = Layouter(Group(view))
            :Fill(view)
            :DisableHitTest()
            :NeedsFrameUpdate(true)
            :End()
        reclaimGroup.view = view
        reclaimGroup.prevPos = camera:GetFocusPosition()
        reclaimGroup.OnFrame = function(self, delta)
            local curPos = camera:GetFocusPosition()
            local prevPos = self.prevPos
            if curPos[1] ~= prevPos[1] or curPos[2] ~= prevPos[2] or curPos[3] ~= prevPos[3] then
                self.isMoving = true
            else
                self.isMoving = false
            end
            self.prevPos = curPos
        end

        view.ReclaimGroup = reclaimGroup
        reclaimGroup:Show()
    end
    reclaimGroup:SetNeedsFrameUpdate(true)
    view.NewViewing = true
end

--- Given four lines (where the three parameters correspond to standard form), returns if the
--- playable area is entirely contained by that quadrilateral. The points that generate the lines
--- must in cyclical-clockwise order, that is, the inside of each line will considered to be to the
--- right from the perspective of the starting point that calculated the values as from the equation  
---    `(y - startY) (endX - startX) = (x - startX) (endY - startY)`  
--- and thus simplifies to the less-than inequality in standard form   
---    `a x + b y < c`
---@param a1 number
---@param b1 number
---@param c1 number
---@param a2 number
---@param b2 number
---@param c2 number
---@param a3 number
---@param b3 number
---@param c3 number
---@param a4 number
---@param b4 number
---@param c4 number
---@return boolean
local function ViewContainsPlayableArea(a1, b1, c1, a2, b2, c2, a3, b3, c3, a4, b4, c4)
    local playableArea = PlayableArea
    if playableArea then
        -- we'll reuse these values
        local x1, z1 = playableArea[1], playableArea[2]
        local x2, z2 = playableArea[3], playableArea[4]

        local left1p1, right1p1 = b1 * x1, a1 * z1
        local left2p1, right2p1 = b2 * x1, a2 * z1
        local left3p1, right3p1 = b3 * x1, a3 * z1
        local left4p1, right4p1 = b4 * x1, a4 * z1

        -- upper-left is in-view
        if  left1p1 + right1p1 >= c1 or
            left2p1 + right2p1 >= c2 or
            left3p1 + right3p1 >= c3 or
            left4p1 + right4p1 >= c4
        then
            return false
        end

        local left1p2 = b1 * x2
        local left2p2 = b2 * x2
        local left3p2 = b3 * x2
        local left4p2 = b4 * x2

        -- upper-right is in-view
        if  left1p2 + right1p1 >= c1 or
            left2p2 + right2p1 >= c2 or
            left3p2 + right3p1 >= c3 or
            left4p2 + right4p1 >= c4
        then
            return false
        end

        local right1p2 = a1 * z2
        local right2p2 = a2 * z2
        local right3p2 = a3 * z2
        local right4p2 = a4 * z2

        -- lower-right is in-view
        if  left1p2 + right1p2 >= c1 or
            left2p2 + right2p2 >= c2 or
            left3p2 + right3p2 >= c3 or
            left4p2 + right4p2 >= c4
        then
            return false
        end

        -- lower-left is in-view
        if  left1p1 + right1p2 >= c1 or
            left2p1 + right2p2 >= c2 or
            left3p1 + right3p2 >= c3 or
            left4p1 + right4p2 >= c4
        then
            return false
        end

        -- all playable area corners are in-view!
        return true
    end

    -- use the map size if there isn't a playable area set
    local x, z = MapWidth, MapHeight

    -- upper-left is in-view
    if 0 >= c1 or 0 >= c2 or 0 >= c3 or 0 >= c4 then
        return false
    end

    local left1 = b1 * x
    local left2 = b2 * x
    local left3 = b3 * x
    local left4 = b4 * x

    -- upper-right is in-view
    if left1 >= c1 or left2 >= c2 or left3 >= c3 or left4 >= c4 then
        return false
    end

    local right1 = a1 * z
    local right2 = a2 * z
    local right3 = a3 * z
    local right4 = a4 * z

    -- lower-right is in-view
    if  left1 + right1 >= c1 or
        left2 + right2 >= c2 or
        left3 + right3 >= c3 or
        left4 + right4 >= c4
    then
        return false
    end

    -- lower-left is in-view
    if right1 >= c1 or right2 >= c2 or right3 >= c3 or right4 >= c4 then
        return false
    end

    -- all map corners are in-view!
    return true
end

---@param view WorldView
---@param reclaim PropSyncData[]
---@return PropSyncData[] inViewReclaim
---@return number count
local function GetInViewReclaim(view, reclaim)
    local inViewReclaim = {}
    local inViewCount = 0

    local tl, tr, br, bl = view:UnProjectCorners()

    -- these must be in cyclical order to not check the quad with cross lines
    local x1, z1 = tl[1], tl[3]
    local x2, z2 = tr[1], tr[3]
    local x3, z3 = br[1], br[3]
    local x4, z4 = bl[1], bl[3]

    -- The world view is an arbitrary quadrilateral, which means in order to see if a point is
    -- inside it, we need to check if it is inside each of the four lines.
    -- The equation to check if point (x, y) falls on the right of line AB is
    --    (y - A.y) * (B.x - A.x) < (x - A.x) * (B.y - A.y)
    -- which simplifies to
    --    (A.y - B.y) * x + (B.x - A.x) * y < (A.y - B.y) * A.x + (B.x - A.x) * A.y
    -- The view is actually in 3D space, but we ignore the Y component, so for us it's
    --    (z1 - z2) * x + (x2 - x1) * z < (z1 - z2) * x1 + (x2 - x1) * z1
    -- or, with the constant terms collapsed,
    --    dz1 * x + dx1 * z < dot1
    local dx1, dz1 = x1 - x2, z2 - z1
    local dx2, dz2 = x2 - x3, z3 - z2
    local dx3, dz3 = x3 - x4, z4 - z3
    local dx4, dz4 = x4 - x1, z1 - z4
    local dot1 = dz1 * x1 + dx1 * z1
    local dot2 = dz2 * x2 + dx2 * z2
    local dot3 = dz3 * x3 + dx3 * z3
    local dot4 = dz4 * x4 + dx4 * z4

    -- first, we'll check if the playable area is entirely in-view--in that case, we know
    -- that *everything* is in-view so we don't need to check every individual prop
    if ViewContainsPlayableArea(dx1, dz1, dot1, dx2, dz2, dot2, dx3, dz3, dot3, dx4, dz4, dot4) then
        for _, recl in reclaim do
            inViewCount = inViewCount + 1
            inViewReclaim[inViewCount] = recl
        end
    else
        for _, recl in reclaim do
            local pos = recl.position
            local x, z = pos[1], pos[3]
            if  dz1 * x + dx1 * z < dot1 and
                dz2 * x + dx2 * z < dot2 and
                dz3 * x + dx3 * z < dot3 and
                dz4 * x + dx4 * z < dot4
            then
                inViewCount = inViewCount + 1
                inViewReclaim[inViewCount] = recl
            end
        end
    end

    return inViewReclaim, inViewCount
end

---@param zoom number
---@return boolean
local function DoCombineLabels(zoom)
    return zoom > ZoomThreshold
end

---@param zoom number
---@return number
local function GetCombineDistance(zoom)
    return zoom * HeightRatio
end

---@param a UserReclaimData
---@param b UserReclaimData
---@return boolean
local function ReclaimComparator(a, b)
    -- If you change this function, make sure that all data with a mass value of 0 (or whatever you
    -- make happen in `UnsortUnusedReclaimData()`) sorts lower than everything else
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

---@param dataPool UserReclaimData[] pool of combined reclaim data
---@param reclaim PropSyncData[] raw reclaim data
---@param maxDist number maximum distane to combine reclaim
---@return number  # number of combined labels
local function CombineReclaim(dataPool, reclaim, maxDist)
    local SumReclaim, Vector = SumReclaim, Vector

    -- we square this to avoid an expensive square root
    maxDist = maxDist * maxDist
    local index = 0

    for _, recl in reclaim do
        local combined
        local reclPos = recl.position
        local reclX, reclZ = reclPos[1], reclPos[3]

        --- TODO: use a basic grid query (quad tree overcomplicates it)
        for i = 1, index do
            local cur = dataPool[i]
            local curPos = cur.position
            local dx, dz = reclX - curPos[1], reclZ - curPos[3]
            if dx*dx + dz*dz < maxDist then
                combined = true
                SumReclaim(cur, recl)
                break
            end
        end

        if not combined then
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

    return index
end

---@param dataPool UserReclaimData[] pool of combined reclaim data
---@param newDataSize number size of reclaim data
---@param lastDataSize number number of datum used last update
local function UnsortUnusedReclaimData(dataPool, newDataSize, lastDataSize)
    for i = newDataSize + 1, lastDataSize do
        dataPool[i].mass = 0
    end
end

---@param labelPool WorldLabel[] pool of labels to reuse
---@param parent ReclaimLabelGroup parent of any newly created relcaim labels
---@param reclaimData UserReclaimData[] reclaim data to display
---@param count number size of reclaim data
local function DisplayReclaim(labelPool, parent, reclaimData, count)
    local IsDestroyed, CreateReclaimLabel = IsDestroyed, CreateReclaimLabel

    for i = 1, count do
        local label = labelPool[i]
        local data = reclaimData[i]
        if label == nil or IsDestroyed(label) then
            labelPool[i] = CreateReclaimLabel(parent, data)
        else
            label:DisplayReclaim(data)
        end
    end
end

---@param labelPool WorldLabel[] pool of labels to reuse
---@param newLabelCount number size of reclaim data
---@param lastLabelCount number number of labels used last update
function HideUnusedLabels(labelPool, newLabelCount, lastLabelCount)
    local IsDestroyed = IsDestroyed

    for i = newLabelCount + 1, lastLabelCount do
        local label = labelPool[i]
        if label ~= nil then
            if not IsDestroyed(label) then
                label:Hide()
            end
            label.mass = nil
            labelPool[i] = nil
        end
    end
end

---@param view WorldView
---@param zoom number
function UpdateLabels(view, zoom)
    local dataPool, dataPoolUse = DataPool, DataPoolUse
    local labelPool, labelPoolUse = LabelPool, LabelPoolUse

    local dataSize = 0

    -- gathering
    local labelData, labelCount = GetInViewReclaim(view, Reclaim)

    if labelCount > 0 then
        -- combining
        if DoCombineLabels(zoom) then
            dataSize = CombineReclaim(dataPool, labelData, GetCombineDistance(zoom))

            labelData, labelCount = dataPool, dataSize
        end

        if labelCount > 0 then
            -- filtering
            -- usually localized upvalues go up at the top of the scope, but there's no harm in
            -- letting this one change at any time up to this point
            local maxLabels = MaxLabels
            if labelCount > maxLabels then
                labelCount = maxLabels
            end

            TableSort(labelData, ReclaimComparator)

            if labelCount > 0 then
                -- displaying
                DisplayReclaim(labelPool, view.ReclaimGroup, labelData, labelCount)
            end
        end
    end

    -- cleanup

    if dataSize < dataPoolUse then
        UnsortUnusedReclaimData(dataPool, dataSize, dataPoolUse)
    elseif DataPoolSize < dataSize then
        DataPoolSize = dataSize
    end
    DataPoolUse = dataSize

    if labelCount < labelPoolUse then
        HideUnusedLabels(labelPool, labelCount, labelPoolUse)
    elseif LabelPoolSize < labelCount then
        LabelPoolSize = labelCount
    end
    LabelPoolUse = labelCount
end


-- Update reclaim tables when the disk watcher reloads the module

-- old module
function __moduleinfo.OnReload(newmod)
    newmod.RecieveOldModuleData(Reclaim, OutsidePlayableAreaReclaim)
    Reclaim, OutsidePlayableAreaReclaim = nil, nil
end
-- new module
function RecieveOldModuleData(reclaim, offmapReclaim)
    Reclaim, OutsidePlayableAreaReclaim = reclaim, offmapReclaim
end