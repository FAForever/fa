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
        LayoutHelpers.AtLeftTopIn(self, self.parent, (proj.x - self.Width() / 2) / LayoutHelpers.GetPixelScaleFactor(), (proj.y - self.Height() / 2 + 1) / LayoutHelpers.GetPixelScaleFactor())
        self.proj = {x=proj.x, y=proj.y }

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

function UpdateLabels()
    local view = import('/lua/ui/game/worldview.lua').viewLeft -- Left screen's camera

    local onScreenReclaimIndex = 1
    local onScreenReclaims = {}

    -- One might be tempted to use a binary insert; however, tests have shown that it takes about 140x more time
    for _, r in Reclaim do
        r.onScreen = OnScreen(view, r.position)
        if r.onScreen and r.mass >= MinAmount then
            onScreenReclaims[onScreenReclaimIndex] = r
            onScreenReclaimIndex = onScreenReclaimIndex + 1
        end
    end

    table.sort(onScreenReclaims, function(a, b) return a.mass > b.mass end)

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
            label = CreateReclaimLabel(view.ReclaimGroup, r)
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
