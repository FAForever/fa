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

        local update = false
        update = update or (zoom ~= self.OldCameraZoom)
        update = update or (position[1] ~= self.OldCameraPosition[1])
        update = update or (position[2] ~= self.OldCameraPosition[2])
        update = update or (position[3] ~= self.OldCameraPosition[3])

        if update then 
            LazyView:Set(self.View)

            self.OldCameraZoom = zoom 
            self.OldCameraPosition = position
        end
    end,
}

local Label = Class(Group) {
    __init = function(self, parent)
        Group.__init(self, parent)
        self.parent = parent

        -- default values
        self.Top:Set(0)
        self.Left:Set(0)
        self.Width:Set(25)
        self.Height:Set(25)
    end,
}

-- Creates an empty reclaim label
function CreateReclaimLabel(root)

    ReclaimLabelsMade = ReclaimLabelsMade + 1
    local label = Label(root)

    -- mass bitmap
    label.mass = Bitmap(label)
    label.mass:SetTexture(UIUtil.UIFile('/game/build-ui/icon-mass_bmp.dds'))
    LayoutHelpers.AtLeftIn(label.mass, label)
    LayoutHelpers.AtVerticalCenterIn(label.mass, label)
    LayoutHelpers.SetDimensions(label.mass, 14, 14)

    -- text information
    label.text = UIUtil.CreateText(label, "", 10, UIUtil.bodyFont)
    label.text:SetColor('ffc7ff8f')
    label.text:SetDropShadow(true)
    LayoutHelpers.AtLeftIn(label.text, label, 16)
    LayoutHelpers.AtVerticalCenterIn(label.text, label)

    -- disable various settings
    label:DisableHitTest(true)

    -- display properties
    label.DisplayReclaim = function(self, label)

        -- show us 
        if self:IsHidden() then
            self:Show()
        end

        -- change our position
        self.Position = label.position

        -- update mass
        if label.mass ~= self.oldMass then
            local mass = tostring(math.floor(0.5 + label.mass))
            self.text:SetText(mass)
            self.oldMass = label.mass
        end
    end

    -- update left position
    label.Left:Set(
        function()
            local view = LazyView()

            if view then 
                UpdateLeft = UpdateLeft + 1
                local projected = view:Project(label.Position)
                local value = (projected.x - 12) / LayoutHelpers.GetPixelScaleFactor()
                return value
            else 
                return 0
            end
        end
    )

    -- update right position
    label.Top:Set(
        function()
            local view = LazyView()

            if view then 
                UpdateTop = UpdateTop + 1
                local projected = view:Project(label.Position)
                local value = (projected.y - 13) / LayoutHelpers.GetPixelScaleFactor()
                return value
            else 
                return 0 
            end
        end
    )

    return label
end

local onScreenReclaims = {}
function UpdateLabels(root)

    local view = import('/lua/ui/game/worldview.lua').viewLeft -- Left screen's camera

    local onScreenReclaimIndex = 1

    once = false
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

function ShowReclaimThread(watch_key)
    local view = import('/lua/ui/game/worldview.lua').viewLeft
    local camera = GetCamera("WorldCamera")

    LOG("ShowReclaimThread")
    if not RootOfLabels then 
        RootOfLabels = RootLabel(GetFrame(0), view, camera)
        RootOfLabels.Left:Set(0)
        RootOfLabels.Top:Set(0)
        RootOfLabels.Width:Set(1)
        RootOfLabels.Height:Set(1)
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
                LOG(keydown)
                if keydown then 
                    ShowReclaim(true)
                    
                    if not Thread then 
                        LOG("Creating reclaim thread!")
                        Thread = ForkThread(ShowReclaimThread)
                    end
                end

                LOG("UpdateLeft: " .. tostring(UpdateLeft))
                LOG("UpdateTop: " .. tostring(UpdateTop))
                LOG("ReclaimLabelsMade: " .. tostring(ReclaimLabelsMade))

                WaitSeconds(.1)
            end

            KillThread(Thread)
            ShowReclaim(false)
        end)
    else
        CommandGraphActive = false -- above coroutine runs until now
    end
end
