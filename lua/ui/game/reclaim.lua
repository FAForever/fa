-- # Imports

local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')
local Prefs = import('/lua/user/prefs.lua')
local options = Prefs.GetFromCurrentProfile('options')
local LazyVar = import('/lua/lazyvar.lua')

-- # Settings

local MaxLabels = 1000 -- The maximum number of labels created in a game session
local MinAmount = options.minimum_reclaim_amount or 10

-- # Lazy evaluation

local RootOfLabels = false
local LazyView = LazyVar.Create(false)

-- # internal state

local Thread = false

local Reclaim = { } -- int indexed list, sorted by mass, of all props that can show a label currently in the sim
local LabelPool = { } -- Stores labels up too MaxLabels
local OldZoom
local OldPosition
local ReclaimChanged = true
local PlayableArea
local OutsidePlayableAreaReclaim = {}

-- # Debug properties

local ReclaimLabelsMade = 0
local UpdateLeft = 0
local UpdateTop = 0

-- # sources
-- 

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
    local ReclaimLists = {Reclaim, OutsidePlayableAreaReclaim}
    for _,reclaimList in ReclaimLists do
        for id,r in reclaimList do
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

function OnScreen(view, pos)
    local proj = view:Project(pos)
    return not (proj.x < 0 or proj.y < 0 or proj.x > view.Width() or proj.y > view:Height())
end

function InPlayableArea(pos)
    if PlayableArea then
        return not (pos[1] < PlayableArea[1] or pos[3] < PlayableArea[2] or pos[1] > PlayableArea[3] or pos[3] > PlayableArea[4])
    end
    return true
end

local RootLabel = Class(Group) {
    __init = function(self, parent, view, camera)
        Group.__init(self, parent)

        -- Allows us to keep track of updating
        self.View = view
        self.Camera = camera
        self.OldCameraPosition = camera:GetFocusPosition()
        self.OldCameraZoom = camera:GetZoom()

        -- default values
        self.Top:Set(0)
        self.Left:Set(0)
        self.Width:Set(1)
        self.Height:Set(1)
    end,

    -- stop updating when we're hidden
    OnHide = function (self, hidden)
        self:SetNeedsFrameUpdate(not hidden)
    end,

    -- update all labels 
    OnFrame = function(self)
        local zoom = self.Camera:GetZoom()
        local position = self.Camera:GetFocusPosition()

        local update = ReclaimChanged
        update = update or (zoom ~= self.OldCameraZoom)
        update = update or (position[1] ~= self.OldCameraPosition[1])
        update = update or (position[2] ~= self.OldCameraPosition[2])
        update = update or (position[3] ~= self.OldCameraPosition[3])

        if update then 

            -- LOG("update")

            -- keep track of current zoom / position
            self.OldCameraZoom = zoom 
            self.OldCameraPosition = position

            -- retrieve pixel factor
            local pixelFactor = LayoutHelpers.GetPixelScaleFactor()

            -- for each displayed label: project and position it
            local view = self.View
            -- local width = view:Width()
            -- local height = view:Height()

            local project = self.View.Project 
            local label, projected, px, py
            local left, top, width, height
            local element

            -- local DummyVector2 = Vector2(0, 0)
            -- local topLeft, topRight, bottomLeft, bottomRight 

            -- DummyVector2[1] = 0 
            -- DummyVector2[2] = 0
            -- topLeft = UnProject(view, DummyVector2)

            -- DummyVector2[1] = width 
            -- DummyVector2[2] = 0
            -- topRight = UnProject(view, DummyVector2)

            -- DummyVector2[1] = 0 
            -- DummyVector2[2] = height
            -- bottomLeft = UnProject(view, DummyVector2)

            -- DummyVector2[1] = width 
            -- DummyVector2[2] = height
            -- bottomRight = UnProject(view, DummyVector2)

            -- LOG("topLeft: " .. repr(topLeft))
            -- LOG("topRight: " .. repr(topRight))
            -- LOG("bottomLeft: " .. repr(bottomLeft))
            -- LOG("bottomRight: " .. repr(bottomRight))
            -- LOG("GetMouseScreenPos: " .. repr(GetMouseScreenPos()))
            -- LOG("GetMouseWorldPos: " .. repr(GetMouseWorldPos()))

            for k = 1, MaxLabels do 
                label = LabelPool[k]
                if label and label.Displayed then 

                    -- determine projected position: this introduces a ton of small blocks!
                    projected = project(view, label.Position)
                    px = projected[1]
                    py = projected[2]

                    -- determine position and size of bitmap
                    left = pixelFactor * (px - 12)
                    top = pixelFactor * (py - 13)
                    width = pixelFactor * 14 
                    height = pixelFactor * 14 

                    element = label.mass
                    element.Left[1] = (left)
                    element.Top[1] = (top)
                    element.Right[1] = (left + width)
                    element.Bottom[1] = (top + height)

                    -- determine position and size of text
                    left = pixelFactor * (px + 4)
                    top = pixelFactor * (py - 13)
                    width = pixelFactor * 25 
                    height = pixelFactor * 25 

                    element = label.text
                    element.Left[1] = (left)
                    element.Top[1] = (top)
                    element.Right[1] = (left + width)
                    element.Bottom[1] = (top + height)
                end
            end
        end
    end,
}

local Label = Class(Group) {
    __init = function(self, parent)
        Group.__init(self, parent)
        self.parent = parent

        -- default values
        self.Top:SetValue(0)
        self.Left:SetValue(0)
        self.Right:SetValue(25)
        self.Bottom:SetValue(25)
        self.Width:SetValue(25)
        self.Height:SetValue(25)
    end,
}

-- Creates an empty reclaim label
function CreateReclaimLabel(root)

    ReclaimLabelsMade = ReclaimLabelsMade + 1


    return label
end

local onScreenReclaims = {}
function UpdateLabels(root)

    local view = import('/lua/ui/game/worldview.lua').viewLeft -- Left screen's camera

    local onScreenReclaimIndex = 1

    -- One might be tempted to use a binary insert; however, tests have shown that it takes about 140x more time
    for _, r in Reclaim do
        r.onScreen = OnScreen(view, r.position)
        if r.onScreen and r.mass >= MinAmount then
            onScreenReclaims[onScreenReclaimIndex] = r
            onScreenReclaimIndex = onScreenReclaimIndex + 1
        end
    end

    -- table.sort(onScreenReclaims, function(a, b) return a.mass > b.mass end)

    -- Create/Update as many reclaim labels as we need
    local labelIndex = 1
    for _, r in onScreenReclaims do
        if labelIndex > MaxLabels then
            break
        end
        local label = LabelPool[labelIndex]
        if label and IsDestroyed(label) then
            label = nil
        end
        if not label then
            label = CreateReclaimLabel(root, r)
            LabelPool[labelIndex] = label
        end

        label:DisplayReclaim(r)
        labelIndex = labelIndex + 1
    end

    -- Hide labels we didn't use
    for index = labelIndex, MaxLabels do
        local label = LabelPool[index]
        if label then
            if IsDestroyed(label) then
                LabelPool[index] = nil
            elseif not label:IsHidden() then
                label:Hide()
                label.Displayed = false
            end
        end
    end
end

function ShowReclaim(show)
    if show then 
        if RootOfLabels then 
            RootOfLabels:Show()
        end
    else 
        if RootOfLabels then 
            RootOfLabels:Hide()
        end
    end
end

function ShowReclaimThread()
    local view = import('/lua/ui/game/worldview.lua').viewLeft
    local camera = GetCamera("WorldCamera")

    LOG("ShowReclaimThread")
    if not RootOfLabels then 
        RootOfLabels = RootLabel(GetFrame(0), view, camera)
        RootOfLabels:Show()
    end

    while true do
        local zoom = camera:GetZoom()
        local position = camera:GetFocusPosition()
        if ReclaimChanged
            or OldZoom ~= zoom
            or OldPosition[1] ~= position[1]
            or OldPosition[2] ~= position[2]
            or OldPosition[3] ~= position[3] then

                -- update labels with regard to which ones we show
                UpdateLabels(RootOfLabels)

                OldZoom = zoom
                OldPosition = position
                ReclaimChanged = false
        end
        WaitSeconds(.1)
    end
end

-- function ToggleReclaim()
--     local view = import('/lua/ui/game/worldview.lua').viewLeft
--     ShowReclaim(not view.ShowingReclaim)
-- end

-- Called from commandgraph.lua:OnCommandGraphShow()
local CommandGraphActive = false
function OnCommandGraphShow(bool)

    CommandGraphActive = bool
    if CommandGraphActive then
        ForkThread(function()
            local keydown
            while CommandGraphActive do

                keydown = IsKeyDown('Control')
                if keydown then 
                    ShowReclaim(true)
                    
                    if not Thread then 
                        Thread = ForkThread(ShowReclaimThread)
                    end
                end

                WaitSeconds(.1)
            end

            ShowReclaim(false)
            KillThread(Thread)
            Thread = nil
        end)
    else
        CommandGraphActive = false -- above coroutine runs until now
    end
end

-- # Initialization

function AllocateAccelerationStructure(rows, columns)

end

function AllocateReclaimLabels(count, view, camera)

    local pixelScaleFactor = LayoutHelpers.GetPixelScaleFactor()

    -- construct the root
    local root = RootLabel(GetFrame(0), view, camera)

    -- common definitions for labels so that they are not duplicated unneccesarily
    local texture = UIUtil.UIFile('/game/build-ui/icon-mass_bmp.dds')
    local font = UIUtil.bodyFont

    -- construct the labels
    local cacheBitmap, cacheText = { }
    for k = 1, count do 
        -- bitmap
        cacheBitmap[k] = Bitmap(root)
        cacheBitmap[k]:SetTexture(texture)
        cacheBitmap[k].Left:SetValue(0)
        cacheBitmap[k].Top:SetValue(0)
        cacheBitmap[k].Width:SetValue(pixelScaleFactor * 14)
        cacheBitmap[k].Height:SetValue(pixelScaleFactor * 14)
        cacheBitmap[k]:DisableHitTest(true)

        -- text
        cacheText[k] = UIUtil.CreateText(root, "10", 10, font)
        cacheText[k]:SetColor('ffc7ff8f')
        cacheText[k]:SetDropShadow(true)
        cacheText[k].Left:SetValue(0)
        cacheText[k].Top:SetValue(0)
        cacheText[k]:DisableHitTest(true)
    end

    return root, cacheBitmap, cacheText
end

-- # Utility functions

function UpdateLabel(self, data)
    -- show us 
    if self:IsHidden() then
        self:Show()
    end

    -- change our position
    self.Position = label.position
    self.Displayed = true

    -- update mass
    if label.mass ~= self.oldMass then
        local mass = tostring(math.floor(0.5 + label.mass))
        self.text:SetText(mass)
        self.oldMass = label.mass
    end
end

--- Determines whether the given point is inside the provided polygon. Returns a true / false value.
-- @param polygon A table of tables with edge coordinates, e.g., { {x1, ... xn}, {y1 ... yn} }.
-- @param point A point, e.g., { [1], [2], [3] }.
function PointInPolygon(polygon, point)
    return false 
end 

--- Computes the barcy centric coordinates of the point given the triangle corners. Ouputs the u / v coordinates of the point.
-- source: https://gamedev.stackexchange.com/questions/23743/whats-the-most-efficient-way-to-find-barycentric-coordinates
-- @param t1 A point of the triangle, e.g., { [1], [2], [3] }
-- @param t2 A point of the triangle, e.g., { [1], [2], [3] }
-- @param t3 A point of the triangle, e.g., { [1], [2], [3] }
-- @param point The point we wish to compute the barycentric coordinates of, e.g., { [1], [2], [3] }
function ComputeBarycentricCoordinates(t1, t2, t3, point)

    -- retrieve data from tables
    local t1x = t1[1]
    local t1z = t1[3]

    local t2x = t2[1]
    local t2z = t2[3]

    local t3x = t3[1]
    local t3z = t3[3]

    local px = point[1]
    local pz = point[3]

    -- compute directions
    local v0x = t2x - t1x 
    local v0z = t2z - t1z 

    local v1x = t3x - t1x 
    local v1z = t3z - t1z 

    local v2x = px - t1x 
    local v2z = pz - t1z 

    local d00 = v0x * v0x + v0z * voz 
    local d01 = v0x * v1x + v0z * v1z 
    local d11 = v1x * v1x + v1z * v1z 
    local d20 = v2x * v0x + v2z * v0z 
    local d21 = v2x * v1x + v2z * v1z 

    local denom = d00 * d11 - d01 * d01

    local v = (d11 * d20 - d01 * d21) / denom
    local w = (d00 * d21 - d01 * d20) / denom
    local u = 1.0 - v - w 

    return u, v, w
end

-- # Deprecated functions