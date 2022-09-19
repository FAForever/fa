local MathMax = math.max
local MathMin = math.min
local TableGetn = table.getn



local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')
local Prefs = import('/lua/user/prefs.lua')
local options = Prefs.GetFromCurrentProfile('options')

local MaxLabels = options.maximum_reclaim_count or 1000 -- The maximum number of labels created in a game session
local MinAmount = options.minimum_reclaim_amount or 10

local Reclaim = {} -- int indexed list, sorted by mass, of all props that can show a label currently in the sim
local LabelPool = {} -- Stores labels up too MaxLabels
local OldZoom
local OldPosition
local ReclaimChanged = true
local PlayableArea
local OutsidePlayableAreaReclaim = {}



local mapWidth = 0
local mapHeight = 0
function SetMapSize()
    mapWidth = SessionGetScenarioInfo().size[1]
    mapHeight = SessionGetScenarioInfo().size[2]
end

local function IsInMapArea(pos)
    if PlayableArea then
        return pos[1] > PlayableArea[1] and pos[1] < PlayableArea[3] or
            pos[3] > PlayableArea[2] and pos[3] < PlayableArea[4]
    else
        return pos[1] > 0 and pos[1] < mapWidth or pos[3] > 0 and pos[3] < mapHeight
    end
end

-- Stores/updates a reclaim entity's data using EntityId as key
-- called from /lua/UserSync.lua
function UpdateReclaim(syncTable)
    ReclaimChanged = true
    for id, data in syncTable do
        if not data.mass then
            Reclaim[id] = nil
            OutsidePlayableAreaReclaim[id] = nil
        else
            data.inPlayableArea = InPlayableArea(data.position)
            if data.inPlayableArea then
                Reclaim[id] = data
                OutsidePlayableAreaReclaim[id] = nil
            else
                Reclaim[id] = nil
                OutsidePlayableAreaReclaim[id] = data
            end
        end
    end
end

function SetPlayableArea(rect)
    ReclaimChanged = true
    PlayableArea = rect

    local newReclaim = {}
    local newOutsidePlayableAreaReclaim = {}
    local ReclaimLists = { Reclaim, OutsidePlayableAreaReclaim }
    for _, reclaimList in ReclaimLists do
        for id, r in reclaimList do
            r.inPlayableArea = InPlayableArea(r.position)
            if r.inPlayableArea then
                newReclaim[id] = r
            else
                newOutsidePlayableAreaReclaim[id] = r
            end
        end
    end
    Reclaim = newReclaim
    OutsidePlayableAreaReclaim = newOutsidePlayableAreaReclaim
end

function updateMinAmount(value)
    MinAmount = value
    ReclaimChanged = true
end

function updateMaxLabels(value)
    MaxLabels = value
    ReclaimChanged = true
    for index = MaxLabels + 1, table.getn(LabelPool) do
        LabelPool[index]:Destroy()
        LabelPool[index] = nil
    end
end

function InPlayableArea(pos)
    if PlayableArea then
        return not
            (
            pos[1] < PlayableArea[1] or pos[3] < PlayableArea[2] or pos[1] > PlayableArea[3] or pos[3] > PlayableArea[4]
            )
    end
    return true
end

---@class WorldLabel : Group
local WorldLabel = Class(Group) {
    __init = function(self, parent, position)
        Group.__init(self, parent)
        self.parent = parent
        self.proj = nil
        self:SetPosition(position)

        self.Top:Set(0)
        self.Left:Set(0)
        LayoutHelpers.SetDimensions(self, 25, 25)
        self:SetNeedsFrameUpdate(true)
    end,

    Update = function(self)
    end,

    SetPosition = function(self, position)
        self.position = position or {}
    end,

    OnFrame = function(self, delta)
        self:Update()
    end
}

-- Creates an empty reclaim label
function CreateReclaimLabel(view)
    local label = WorldLabel(view, Vector(0, 0, 0))

    label.mass = Bitmap(label)
    label.mass:SetTexture(UIUtil.UIFile('/game/build-ui/icon-mass_bmp.dds'))
    LayoutHelpers.AtLeftIn(label.mass, label)
    LayoutHelpers.AtVerticalCenterIn(label.mass, label)
    LayoutHelpers.SetDimensions(label.mass, 14, 14)

    label.text = UIUtil.CreateText(label, "", 10, UIUtil.bodyFont)
    label.text:SetColor('ffc7ff8f')
    label.text:SetDropShadow(true)
    LayoutHelpers.AtLeftIn(label.text, label, 16)
    LayoutHelpers.AtVerticalCenterIn(label.text, label)

    label:DisableHitTest(true)
    label.OnHide = function(self, hidden)
        self:SetNeedsFrameUpdate(not hidden)
    end

    label.Update = function(self)
        local view = self.parent.view
        local proj = view:Project(self.position)
        LayoutHelpers.AtLeftTopIn(self, self.parent, (proj.x - self.Width() / 2) / LayoutHelpers.GetPixelScaleFactor(),
            (proj.y - self.Height() / 2 + 1) / LayoutHelpers.GetPixelScaleFactor())
        self.proj = { x = proj.x, y = proj.y }

    end

    label.DisplayReclaim = function(self, r)
        if self:IsHidden() then
            self:Show()
        end
        self:SetPosition(r.position)
        if r.mass ~= self.oldMass then
            local mass = tostring(math.floor(0.5 + r.mass))
            self.text:SetText(mass)
            self.oldMass = r.mass
        end
    end

    label:Update()

    return label
end

local function SumReclaim(r1, r2)
    local massSum = r1.mass + r2.mass
    r1.count = r1.count + (r2.count or 1)
    r1.position[1] = (r1.mass * r1.position[1] + r2.mass * r2.position[1]) / massSum
    r1.position[3] = (r1.mass * r1.position[3] + r2.mass * r2.position[3]) / massSum
    r1.max = MathMax(r1.max or r1.mass, r2.mass)
    r1.mass = massSum
    return r1
end

local function CompareMass(a, b)
    return a.mass < b.mass
end

local HEIGHT_RATIO = 0.012
local ZOOM_THRESHOLD = 60

local reclaimDataPool = {}
local totalReclaimData = 0


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

    for _, r in reclaim do
        added = false
        x1 = r.position[1]
        y1 = r.position[3]
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

function UpdateLabels()

    if TableGetn(Reclaim) < totalReclaimData then
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


    local checkForContainment = IsInMapArea(tl) or IsInMapArea(tr) or IsInMapArea(bl) or IsInMapArea(br)


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
        local rgroup = Group(view)
        rgroup.view = view
        rgroup:DisableHitTest()
        LayoutHelpers.FillParent(rgroup, view)
        rgroup:Show()

        view.ReclaimGroup = rgroup
        rgroup:SetNeedsFrameUpdate(true)
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

-- Called from commandgraph.lua:OnCommandGraphShow()
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
