local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')
local Prefs = import('/lua/user/prefs.lua')
local options = Prefs.GetFromCurrentProfile('options')
local LazyVar = import('/lua/lazyvar.lua')

local MaxLabels = 1000 -- options.maximum_reclaim_count or 100 -- The maximum number of labels created in a game session
local MinAmount = options.minimum_reclaim_amount or 10

local OldZoom
local OldPosition
local ReclaimChanged = true
local PlayableArea
local OutsidePlayableAreaReclaim = {}

-- # Lazy evaluation

local RootOfLabels = false
local LazyView = LazyVar.Create(false)

-- # internal state

local Thread = false
local Reclaim = { }
local LabelPool = { }

-- upvalue math operations for performance
local MathSqrt = math.sqrt
local MathFloor = math.floor

-- Used for computations that require a vector, but we don't want to allocate a new one
local CachedVector = Vector(0, 0, 0)

local CachedCollection = { }
local CachedSelected = { }
local CachedUpper = { }
local CachedCenter = { }
local CachedLower = { }

-- # Debug properties

local ReclaimLabelsMade = 0
local UpdateLeft = 0
local UpdateTop = 0

-- Stores/updates a reclaim entity's data using EntityId as key
-- called from /lua/UserSync.lua
function UpdateReclaim(syncTable)
    ReclaimChanged = true
    for id, data in syncTable do
        if not data then
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

    -- step 0: (n) only keep reclaim in view
    -- step 1: (n) find min / max reclaim
    -- step 3: (n) put reclaim in bins
    -- step 4: (n) select bins until we have enough reclaim

    -- This won't be perfect, but it will be a lot better then sorting it

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
function CreateReclaimLabel(view)
    local label = WorldLabel(view, Vector(0, 0, 0))
    label.view = label.parent.view

    label.mass = Bitmap(label)
    label.mass:SetTexture(UIUtil.UIFile('/game/build-ui/icon-mass_bmp.dds'))
    label.mass.Top:Set(10)
    label.mass.Left:Set(10)
    label.mass.Width:Set(14)
    label.mass.Height:Set(14)

    -- LayoutHelpers.AtLeftIn(label.mass, label)
    -- LayoutHelpers.AtVerticalCenterIn(label.mass, label)
    -- LayoutHelpers.SetDimensions(label.mass, 14, 14)

    label.text = UIUtil.CreateText(label, "", 10, UIUtil.bodyFont)
    label.text:SetColor('ffc7ff8f')
    label.text:SetDropShadow(true)
    label.text.Top:Set(10)
    label.text.Left:Set(10)
    label.text.Width:Set(14)
    label.text.Height:Set(14)

    label.size = 10

    label:DisableHitTest(true)
    label.OnHide = function(self, hidden)
        self:SetNeedsFrameUpdate(not hidden)
    end

    label.OnFrame = function(self)
        local view = self.view
        local proj = view.Project(view, self.position)

        local px = proj.x
        local py = proj.y

        local size = self.size + 4
        local halfsize = 0.5 * size
        self.text.Left:Set(px + size + 2 - halfsize)
        self.text.Top:Set(py - halfsize)

        self.mass.Left:Set(px - halfsize)
        self.mass.Top:Set(py - halfsize)
        self.mass.Width:Set(size)
        self.mass.Height:Set(size)
    end

    label.DisplayReclaim = function(self, label)

        -- make sure we're shown
        if self:IsHidden() then
            self:Show()
        end

        -- change label
        if label.mass ~= self.oldMass then
            local mass = math.floor(0.5 + label.mass)
            self.text:SetText(tostring(mass))


            local factor = LayoutHelpers.GetPixelScaleFactor()
            local color, size = ComputeLabelProperties(mass)
            self.text:SetColor(color)
            self.text:SetFont(UIUtil.bodyFont, factor * size)

            self.size = factor * size
            self.color = color
            self.oldMass = label.mass
        end

        self.position = label.position
    end

    return label
end

--- Re-computes the label.projected property of each label.
-- @param view The view we'll use for projection.
-- @param labels The labels that we'll be projecting.
local function UpdateProjectionOfLabels(view, labels)
    -- local reference to a vector that we can reuse
    local vector = CachedVector
    local pos 

    -- for each known label
    for k, v in labels do
        
        -- retrieve position
        pos = v.position

        -- transfer into dummy vector
        vector[1] = pos[1]
        vector[2] = pos[2]
        vector[3] = pos[3]

        -- use engine to compute projection
        v.projected = view:Project(vector)
    end
end

--- Takes the hash-based labels and returns those that are on screen with an array-based table.
-- @param view The view we'll use for projection.
-- @param labels The labels that we'll be filtering.
local function FindLabelsOnScreen(view, labels)

    -- collection of labels
    local headCollection = 1 
    local collection = CachedCollection

    -- go over all known labels to determine visibility
    local viewWidth = view:Width()
    local viewHeight = view:Height()
    for _, label in labels do

        -- check whether we're valuable enough
        if label.mass >= MinAmount then

            -- check whether we're on screen
            local projected = label.projected
            if not (projected.x < 0 or projected.y < 0 or projected.x > viewWidth or projected.y > viewHeight) then 

                -- add to collection
                collection[headCollection] = label
                headCollection = headCollection + 1
            end
        end
    end

    return collection, headCollection - 1
end

--- Computes the mean and standard deviation of the collection of labels.
-- @param collection An array-based table with labels.
-- @param collectionHead the length of the 'collection' parameter.
local function ComputeMeanAndDeviation(collection, collectionCount)

    if collectionCount == 0 then 
        return 0, 0
    end

    -- compute mean
    local mean = 0 
    for k = 1, collectionCount do 
        mean = mean + collection[k].mass
    end

    mean = mean / collectionCount

    -- compute sum of squares
    local sumOfSquares = 0 
    for k = 1, collectionCount do 
        local sub = collection[k].mass - mean
        sumOfSquares = sub * sub
    end

    sumOfSquares = sumOfSquares / collectionCount

    -- compute deviation
    local deviation = MathSqrt(sumOfSquares)

    return mean, deviation
end

--- Adds all the elements of the origin table to the target table.
-- @param origin The index-based array to copy from.
-- @param originCount The number of elements in origin.
-- @param destination The index-based array to copy to.
-- @param destinationCount the number of elements in destination.
-- @param limit The maximum number of elements allowed in the destination.
local function AddToCollection(origin, originCount, destination, destinationCount, destinationLimit)
    local destinationHead = destinationCount + 1
    for k = 1, math.min(originCount, destinationLimit - destinationCount) do 
        destination[destinationHead] = origin[k]
        destinationHead = destinationHead + 1
    end

    return destination, destinationHead - 1
end

--- Filters the collection until the size criteria is met.
-- @param collection The current array-based collection of labels.
-- @param collectionCount The number of labels in the collection.
-- @param selected The current array-based selected labels.
-- @param selectedCount The number of selected labels.
-- @param criteria The number of selected labels to aim for.
local function FilterCollection(collection, collectionCount, selected, selectedCount, criteria, recursions)

    -- # O(1): recursion protection, can't keep going ad infinitum

    if recursions < 0 then 
        return selected, selectedCount
    end

    -- # O(n): Early exit: collection is small enough for criteria - just append it

    if collectionCount + selectedCount < criteria then 
        return AddToCollection(collection, collectionCount, selected, selectedCount, criteria)
    end

    -- # O(n): Compute mean / std dev

    local mean, deviation = ComputeMeanAndDeviation(collection, collectionCount)

    -- # O(n) compute elements part of upper / lower / medium

    local upper = CachedUpper
    local upperHead = 1 

    local center = CachedCenter
    local centerHead = 1 

    local lower = CachedLower
    local lowerHead = 1

    -- split up the set
    for k = 1, collectionCount do 
        local mass = collection[k].mass

        -- upper half
        if mass > mean + deviation then 
            upper[upperHead] = collection[k]
            upperHead = upperHead + 1

        -- lower half
        elseif mass < mean - deviation then 
            lower[lowerHead] = collection[k]
            lowerHead = lowerHead + 1

        -- center half
        else 
            center[centerHead] = collection[k]
            centerHead = centerHead + 1
        end
    end

    -- see if we can append the upper end
    local upperCount = upperHead - 1
    if selectedCount + upperCount < criteria then 
        selected, selectedCount = AddToCollection(upper, upperCount, selected, selectedCount, criteria)
    else 
        return FilterCollection(upper, upperCount, selected, selectedCount, criteria, recursions - 1)
    end

    -- amount of variance too low - it doesn't matter what we pick just return to the limit
    if deviation < 0.01 then 
        return AddToCollection(collection, collectionCount, selected, selectedCount, criteria)
    end

    -- see if we can append the center part
    local centerCount = centerHead - 1
    if selectedCount + centerCount < criteria then 
        selected, selectedCount = AddToCollection(center, centerCount, selected, selectedCount, criteria)
    else 
        return FilterCollection(center, centerCount, selected, selectedCount, criteria, recursions - 1)
    end

    -- just look through this last part
    local lowerCount = lowerHead - 1
    return FilterCollection(lower, lowerCount, selected, selectedCount, criteria, recursions - 1)
end

local function FilterLabels(view, labels, criteria, updateProjections)

    -- # O(n) Update projection locations on screen

    -- update the screen positions of the labels
    if updateProjections then 
        UpdateProjectionOfLabels(view, labels)
    end

    -- # O(n) Determine labels that are on screen

    collection, collectionCount = FindLabelsOnScreen(view, labels)

    -- # O(n) Compute mean and standard deviation

    local selected = CachedSelected
    local selectedCount = 0
    local recursions = 5

    return FilterCollection(collection, collectionCount, selected, selectedCount, criteria, recursions)
end

function UpdateLabels(root)

    -- import the view that we'll be using
    local view = import('/lua/ui/game/worldview.lua').viewLeft -- Left screen's camera

    -- determine labels that are visible
    local collection, collectionCount = FilterLabels(view, Reclaim, MaxLabels, true)

    -- Create/Update as many reclaim labels as we need
    local labelIndex = 1
    for k = 1, collectionCount do

        -- restrict number of labels
        if labelIndex > MaxLabels then
            break
        end

        -- retrieve a label from the pool
        local label = LabelPool[labelIndex]

        -- if the C object is destroyed then throw it away
        if label and IsDestroyed(label) then
            label = nil
        end
        
        -- if no label is retrieved, make a new one
        if not label then
            label = CreateReclaimLabel(root)
            LabelPool[labelIndex] = label
        end

        -- update the content of the label
        label:DisplayReclaim(collection[k])
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

-- Called from commandgraph.lua:OnCommandGraphShow()
local CommandGraphActive = false
function OnCommandGraphShow(bool)

    CommandGraphActive = bool
    if CommandGraphActive then
        ForkThread(
            function()
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
            end
        )
    else
        CommandGraphActive = false -- above coroutine runs until now
    end
end

-- # Utility functions

--- Determines the color and size of the reclaim labels.
-- @param mass The mass value to base the color and size on
function ComputeLabelProperties(mass)

    -- change color according to mass value
    if mass < 100 then 
        return 'ffd7ff05', 10
    end

    if mass < 300 then 
        return 'ffffeb23', 12
    end

    if mass < 600 then 
        return 'ffff9d23', 14
    end

    if mass < 1000 then 
        return 'ffff7212', 16
    end

    if mass < 2000 then 
        return 'fffb0303', 18
    end

    -- default color value
    return 'ffc7ff8f', 20
end

--- Updates the label with the data provided.
-- @param label The label to update
-- @param mass The mass value of the label
-- @param position The position of the label
function UpdateLabel(label, position, mass)
    -- show us when hidden
    if label:IsHidden() then
        label:Show()
    end

    -- update internal state
    label.Position = position
    label.Displayed = true

    -- only update the mass value if it is different
    if label.Mass ~= mass then
        -- update text
        label.Text:SetText(tostring(math.floor(0.5 + mass)))

        -- update color / size based on mass
        local factor = LayoutHelpers.GetPixelScaleFactor()
        local color, size = ComputeLabelProperties(mass)
        label.Text:SetColor(color)
        label.Text:SetFont(UIUtil.bodyFont, factor * size)

        -- update internal state
        label.Size = factor * size
        label.Color = color
        label.Mass = mass
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

-- # Deprecated functions