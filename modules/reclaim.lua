local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')
local Prefs = import('/lua/user/prefs.lua')
local options = Prefs.GetFromCurrentProfile('options')

local reclaim = {}

function AddReclaim(r)
    reclaim[r.id] = r
end

function RemoveReclaim(r)
    DestroyReclaimLabel(r)
    reclaim[r.id] = nil
end

local showingReclaim = false

function CreateReclaimLabel(view, r)
    local label = Bitmap(view)
    local pos = r.position
    local position = Vector(pos[1], pos[2], pos[3])

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

    label:SetNeedsFrameUpdate(false)
    label:Hide()

    label.OnFrame = function(self, delta)
        local pos = view:Project(position)
        LayoutHelpers.AtLeftTopIn(label, view, pos.x - label.Width() / 2, pos.y - label.Height() / 2 + 1)
    end

    return label
end

function DestroyReclaimLabel(r)
    local view = import('/lua/ui/game/worldview.lua').viewLeft
    local label = view and view.ReclaimLabels[r.id]
    if label then
        label:Destroy()
        view.ReclaimLabels[r.id] = nil
    end
end

function GetLabels()
    local view = import('/lua/ui/game/worldview.lua').viewLeft

    if not view.ReclaimLabels then
        view.ReclaimLabels = {}
    end

    for _, r in reclaim do
        if not view.ReclaimLabels[r.id] then
            view.ReclaimLabels[r.id] = CreateReclaimLabel(view, r)
        end
    end

    return view.ReclaimLabels
end

-- Called from commandgraph.lua:OnCommandGraphShow()
function ShowReclaim(show)
    if show and options.gui_show_reclaim then
        import('/lua/ui/game/gamemain.lua').AddBeatFunction(ShowReclaimBeat)
    else
        import('/lua/ui/game/gamemain.lua').RemoveBeatFunction(ShowReclaimBeat)
        ShowReclaimBeat('Hide')
    end
end

function ShowReclaimBeat(action)
    local keydown

    if not action then
        if options.gui_show_reclaim == 0 then
            keydown = false
        else
            keydown = IsKeyDown('Control')
        end

        if showingReclaim and not keydown then
            action = 'Hide'
        elseif keydown and not showingReclaim then
            action = 'Show'
        end
    end

    if action then
        local labels = GetLabels()
        showingReclaim = action == 'Show'
        for _, l in labels do
            l[action](l)
            l:SetNeedsFrameUpdate(showingReclaim)
        end
    end
end
