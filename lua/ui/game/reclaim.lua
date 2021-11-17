
-- # imports

local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')
local Prefs = import('/lua/user/prefs.lua')
local options = Prefs.GetFromCurrentProfile('options')
local LazyVar = import('/lua/lazyvar.lua')

local PointInPolygon = import('/lua/shared/geometry.lua').PointInPolygon

-- # Upvalues for performance

local MathSqrt = math.sqrt
local MathFloor = math.floor

-- # Caching for performance

-- Used for computations that require a vector
local CachedVector = Vector(0, 0, 0)
local CachedVector2 = Vector2(0, 0)

-- Used for computations where we require large tables transfers
local CachedCollection = { }
local CachedSelected = { }
local CachedUpper = { }
local CachedCenter = { }
local CachedLower = { }

-- # Lazy evaluation

local LazyReclaimUpdate = LazyVar.Create(false)

-- # Internal state

--- Maximum number of labels
local MaxLabels = options.maximum_reclaim_count or 100

--- Minimum amount for a label to be valid
local MinAmount = options.minimum_reclaim_amount or 10

local Thread = false
local ReclaimChanged = true
local Reclaim = { }

local RootOfLabels = false
local LabelPool = { }

local PlayableArea
local ReclaimArchived = {}

-- # Debug properties

local ReclaimLabelsMade = 0
local UpdateLeft = 0
local UpdateTop = 0

-- # Moddable functions

--- Determines the color and size of the reclaim labels.
-- @param mass The mass value to base the color and size on
function ComputeLabelProperties(mass)

    -- change color according to mass value
    if mass < 100 then 
        return 'ffd7ff05', 10
    end

    if mass < 300 then 
        return 'ffffeb23', 11
    end

    if mass < 600 then 
        return 'ffff9d23', 12
    end

    if mass < 1000 then 
        return 'ffff7212', 16
    end

    if mass < 2000 then 
        return 'fffb0303', 20
    end

    -- default color value
    return 'ffc7ff8f', 24
end

-- # Label utility functions

--- Takes the hash-based labels and returns those that are on screen with an array-based table.
-- @param view The view we'll use for projection.
-- @param labels The labels that we'll be filtering.
local function FindLabelsOnScreen(view, labels)

    -- collection of labels
    local headCollection = 1 
    local collection = CachedCollection

    local viewWidth = view:Width()
    local viewHeight = view:Height()

    -- O(1): determine corners of view in world coordinates

    local coords = CachedVector2
    local p1, p2, p3, p4

    coords[1] = 0
    coords[2] = 0
    p1 = view:UnProject(coords)

    coords[1] = width 
    coords[2] = 0 
    p2 = view:UnProject(coords)

    coords[1] = 0
    coords[2] = height
    p3 = view:UnProject(coords)

    coords[1] = width 
    coords[2] = height
    p4 = view:UnProject(coords)

    -- O(1): increase size of view in world coordinates (inset)

    -- compute center
    local points = { p1, p2, p3, p4 }
    local cx = 0.25 * (p1[1] + p2[1] + p3[1] + p4[1])
    local cz = 0.25 * (p1[3] + p2[3] + p3[3] + p4[3])

    local dx, dz
    for k = 1, 4 do 
        -- compute direction from center to point
        local point = points[k]
        dx = point[1] - cx 
        dz = point[3] - dz

        -- adjust point accordingly
        point[1] = point[1] + 0.1 * dx 
        point[3] = point[3] + 0.1 * dz
    end

    -- O(1): construct the two triangles that represent the quad
    -- note: we drop the y-axis (up / down)

    local t1 = { p1[1], p1[3], p2[1], p2[3], p3[1], p3[3] }
    local t2 = { p4[1], p4[3], p2[1], p2[3], p3[1], p3[3] }
    local triangles = { t1, t2 }

    -- O(n): determine for each label if it is in view

    -- go over all known labels to determine visibility
    for _, label in labels do

        -- check whether we're valuable enough
        if label.mass >= MinAmount then

            -- drop y-axis (up / down)
            local point = label.position 
            point[2] = point[3]

            -- check if we're in the polygon defined by the screen frustrum
            if PointInPolygon(triangles, point) then 

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
    local view = import('/lua/ui/game/worldview.lua').viewLeft

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

-- # Classes

--- A basic lable with a bitmap and text.
local Label = Class(Group) {
    __init = function(self, parent, factor)
        Group.__init(self, parent)
        self.parent = parent

        -- default values
        self.Size = 10
        self.Color = 'ffffff'
        self.Mass = 0

        self.Top:SetValue(0)
        self.Left:SetValue(0)
        self.Right:SetValue(25)
        self.Bottom:SetValue(25)
        self.Width:SetValue(25)
        self.Height:SetValue(25)

        self.Bitmap = Bitmap(root)
        self.Bitmap:SetTexture(texture)
        self.Bitmap.Left:SetValue(0)
        self.Bitmap.Top:SetValue(0)
        self.Bitmap.Width:SetValue(factor * 14)
        self.Bitmap.Height:SetValue(factor * 14)
        self.Bitmap:DisableHitTest(true)

        self.Text = UIUtil.CreateText(root, "10", 10, font)
        self.Text:SetColor('ffc7ff8f')
        self.Text:SetDropShadow(true)
        self.Text.Left:SetValue(0)
        self.Text.Top:SetValue(0)
        self.Text:DisableHitTest(true)
    end,
}

--- The root of all labels that updates all labels.
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

    -- each frame update all labels when applicable
    OnFrame = function(self)
        local zoom = self.Camera:GetZoom()
        local position = self.Camera:GetFocusPosition()

        local update = ReclaimChanged
        update = update or (zoom ~= self.OldCameraZoom)
        update = update or (position[1] ~= self.OldCameraPosition[1])
        update = update or (position[2] ~= self.OldCameraPosition[2])
        update = update or (position[3] ~= self.OldCameraPosition[3])

        if update then 

            -- update what labels are on screen (hurr)
            UpdateLabels(self)

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

-- # Interface functions

--- Called once at the start of a match to fill the caches.
function OnInit()

    local rows = 6
    local columns = 6
    AllocateAccelerationStructure(rows, columns)
    
    local count = 1000
    local camera = GetCamera("WorldCamera")
    local view = import('/lua/ui/game/worldview.lua').viewLeft
    RootOfLabels, LabelPool = AllocateReclaimLabels(count, view, camera)

end

--- Called each time labels are added, removed or adjusted by the simulation.
function OnUpdate(syncTable)
    -- something changed, always reset the view
    ReclaimChanged = true

    -- for each label in the sync table
    for id, data in syncTable do

        -- if it is not set, then we throw it out
        if not data then
            Reclaim[id] = nil
            ReclaimArchived[id] = nil

        else
            -- if it is set and in the playable area we keep track of it
            data.inPlayableArea = InPlayableArea(data.position)
            if data.inPlayableArea then
                Reclaim[id] = data
                ReclaimArchived[id] = nil

            -- if it is set but not in the playable area we archive it
            else
                Reclaim[id] = nil
                ReclaimArchived[id] = data
            end
        end
    end
end

--- Called each time the labels should be shown.
--@param isVisible Determines whether the labels should be visible.
function OnShow(isVisible)
    if RootOfLabels then 
        if isVisible then 
            RootOfLabels:Show()
        else 
            RootOfLabels:Hide()
        end
    end
end

-- # Utility functions

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

-- # Initialization

function AllocateAccelerationStructure(rows, columns)

end

function AllocateReclaimLabels(count, view, camera)

    local pixelScaleFactor = LayoutHelpers.GetPixelScaleFactor()

    -- construct the root
    local root = RootLabel(GetFrame(0), view, camera)
    root:Hide()

    -- common definitions for labels so that they are not duplicated unneccesarily
    local texture = UIUtil.UIFile('/game/build-ui/icon-mass_bmp.dds')
    local font = UIUtil.bodyFont

    -- construct the labels
    local cacheLabels = { }
    for k = 1, count do 
        cacheLabels[k] = Label(root, pixelScaleFactor)
    end

    return root, cacheLabels
end

-- # Deprecated functionality

-- TODO: updateMinAmount
-- TODO: updateMaxLabels
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

function SetPlayableArea(rect)
    ReclaimChanged = true
    PlayableArea = rect
    local newReclaim = {}
    local newOutsidePlayableAreaReclaim = {}
    local ReclaimLists = {Reclaim, ReclaimArchived}
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
    ReclaimArchived = newOutsidePlayableAreaReclaim
end

function InPlayableArea(pos)
    if PlayableArea then
        return not (pos[1] < PlayableArea[1] or pos[3] < PlayableArea[2] or pos[1] > PlayableArea[3] or pos[3] > PlayableArea[4])
    end
    return true
end