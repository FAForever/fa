local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')
local Prefs = import('/lua/user/prefs.lua')

local Reclaim = {}

-- called from schook/lua/UserSync.lua
local NeedUpdate = false
function UpdateReclaim(r)
    r.updated = true
    Reclaim[r.id] = r
end

local OldZoom
function SameZoom(camera)
    if not OldZoom or camera:GetZoom() == OldZoom then
        return true
    end

    return false
end

function OnScreen(view, pos)
    local proj = view:Project(Vector(pos[1], pos[2], pos[3]))
    return not (proj.x < 0 or proj.y < 0 or proj.x > view.Width() or proj.y > view:Height())
end

local WorldLabel = Class(Group) {
    __init = function(self, parent, position)
        Group.__init(self, parent)
        self.parent = parent
        self.proj = nil
        if position then self:SetPosition(position) end

        self.Top:Set(0)
        self.Left:Set(0)
        self.Width:Set(25)
        self.Height:Set(25)
        self:SetNeedsFrameUpdate(true)
    end,

    Update = function(self)
    end,

    SetPosition = function(self, position)
        self.position = position
    end,

    OnFrame = function(self, delta)
        if not self:IsHidden() then
            self:Update()
        end
    end
}

function CreateReclaimLabel(view, r)
    local pos = r.position
    local label = WorldLabel(view, Vector(pos[1], pos[2], pos[3]))

    label.mass = Bitmap(label)
    label.mass:SetTexture(UIUtil.UIFile('/game/build-ui/icon-mass_bmp.dds'))
    LayoutHelpers.AtLeftIn(label.mass, label)
    LayoutHelpers.AtVerticalCenterIn(label.mass, label)
    label.mass.Height:Set(14)
    label.mass.Width:Set(14)

    label.text = UIUtil.CreateText(label, math.floor(0.5+r.mass), 10, UIUtil.bodyFont)
    label.text:SetColor('ffc7ff8f')
    label.text:SetDropShadow(true)
    LayoutHelpers.AtLeftIn(label.text, label, 16)
    LayoutHelpers.AtVerticalCenterIn(label.text, label)

    label:DisableHitTest(true)
    label.Update = function(self)
        if self.parent:IsHidden() then return end

        local view = self.parent.view
        local proj = view:Project(pos)
        if not self.proj or self.proj.x ~= proj.x or self.proj.y ~= self.proj.y then
            LayoutHelpers.AtLeftTopIn(self, self.parent, proj.x - self.Width() / 2, proj.y - self.Height() / 2 + 1)
            self.proj = proj
        end
    end

    label.UpdateMass = function(self, r)
        local mass = tostring(math.floor(0.5+r.mass))
        if mass ~= self.text:GetText() then
            self.text:SetText(mass)
        end
    end

    label:Update()

    return label
end

function UpdateLabels()
    local view = import('/lua/ui/game/worldview.lua').viewLeft
    local n_visible = 0

    for id, r in Reclaim do
        local label = view.ReclaimGroup.ReclaimLabels[id]

        if not r.mass or r.mass < 1 then
            if label then
                label:Destroy()
                view.ReclaimGroup.ReclaimLabels[id] = nil
                label = nil
            end
            Reclaim[id] = nil
        elseif OnScreen(view, r.position) then
            if not label then
                label = CreateReclaimLabel(view.ReclaimGroup, r)
                view.ReclaimGroup.ReclaimLabels[id] = label
            else
                label:Show()
                n_visible = n_visible + 1
            end
        elseif label then
            label:Hide()
        end

        if label and r.updated then
            label:UpdateMass(r)
            r.updated = false
            NeedUpdate = true
        end
    end

    return view.ReclaimGroup.ReclaimLabels, n_visible
end

local ReclaimThread
function ShowReclaim(show)
    local view = import('/lua/ui/game/worldview.lua').viewLeft

    if show then
        view.ShowingReclaim = true
        if not view.ReclaimThread then
            view.ReclaimThread = ForkThread(ShowReclaimThread)
        end
    else
        view.ShowingReclaim = false
    end
end

function InitReclaimGroup(view, camera)
    if not view.ReclaimGroup or IsDestroyed(view.ReclaimGroup) then
        local rgroup = Group(view)
        rgroup.view = view
        rgroup:DisableHitTest()
        LayoutHelpers.FillParent(rgroup, view)
        rgroup:Show()
        rgroup.ReclaimLabels = {}

        rgroup.OnFrame = function(self)
            if not self.update then return end
            if SameZoom(camera) then
                self:Show()
                self:SetNeedsFrameUpdate(false)
                self.update = false
            else
                self:Hide()
            end
        end

        view.ReclaimGroup = rgroup
        NeedUpdate = true
    else
        view.ReclaimGroup:Show()
    end

end

function ShowReclaimThread(watch_key)
    local i = 0
    local camera = GetCamera("WorldCamera")
    local view = import('/lua/ui/game/worldview.lua').viewLeft

    InitReclaimGroup(view, camera)
    OldZoom = nil

    while view.ShowingReclaim and (not watch_key or IsKeyDown(watch_key)) do
        if not view or IsDestroyed(view) then
            view = import('/lua/ui/game/worldview.lua').viewLeft
            camera = GetCamera("WorldCamera")
            InitReclaimGroup(view, camera)
        end

        local sameZoom = SameZoom(camera)
        local doUpdate = NeedUpdate or not sameZoom

        if doUpdate then
            local labels, n_visible = UpdateLabels()
            if not sameZoom and n_visible > 1000 then
                view.ReclaimGroup:Hide()
                view.ReclaimGroup.update = true
                view.ReclaimGroup:SetNeedsFrameUpdate(true)
            end
            NeedUpdate = false
        end

        OldZoom = camera:GetZoom()
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
    local options = Prefs.GetFromCurrentProfile('options')

    CommandGraphActive = bool
    if CommandGraphActive and options.gui_show_reclaim == 1 then
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
