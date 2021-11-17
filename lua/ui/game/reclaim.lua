local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')
local Prefs = import('/lua/user/prefs.lua')
local options = Prefs.GetFromCurrentProfile('options')

local MaxLabels = 1000 -- options.maximum_reclaim_count or 100 -- The maximum number of labels created in a game session
local MinAmount = options.minimum_reclaim_amount or 10

local Reclaim = {} -- int indexed list, sorted by mass, of all props that can show a label currently in the sim
local LabelPool = {} -- Stores labels up too MaxLabels
local OldZoom
local OldPosition
local ReclaimChanged = true
local PlayableArea
local OutsidePlayableAreaReclaim = {}

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

function OnScreen(view, pos)
    local proj = view:Project(Vector(pos[1], pos[2], pos[3]))
    return not (proj.x < 0 or proj.y < 0 or proj.x > view.Width() or proj.y > view:Height())
end

function InPlayableArea(pos)
    if PlayableArea then
        return not (pos[1] < PlayableArea[1] or pos[3] < PlayableArea[2] or pos[1] > PlayableArea[3] or pos[3] > PlayableArea[4])
    end
    return true
end

local WorldLabel = Class(Group) {
    __init = function(self, parent)
        Group.__init(self, parent)
        self.parent = parent
        self.position = CachedVector

        self.Top:Set(0)
        self.Left:Set(0)
        LayoutHelpers.SetDimensions(self, 25, 25)
        self:SetNeedsFrameUpdate(true)
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
        self.text.Left:Set(px + size + 2)
        self.text.Top:Set(py)

        self.mass.Left:Set(px)
        self.mass.Top:Set(py)
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


            
            local color, size = ComputeLabelProperties(mass)
            self.text:SetColor(color)
            self.text:SetFont(UIUtil.bodyFont, size)

            self.size = size
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

function UpdateLabels()

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
            label = CreateReclaimLabel(view.ReclaimGroup)
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

-- # Utility functions

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