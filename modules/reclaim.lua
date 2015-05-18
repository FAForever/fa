local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')
local Prefs = import('/lua/user/prefs.lua')
local options = Prefs.GetFromCurrentProfile('options')

local labels = {}
local queued = {}

local showingReclaim = false

function Init()
    if queued then -- queued due to worldView not created
        for _, q in queued do
            CreateReclaimLabel(q)
        end
        queued = {}
    end
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
        showingReclaim = action == 'Show'
        for _, l in labels do
            l[action](l)
            l:SetNeedsFrameUpdate(showingReclaim)
        end
    end
end


function CreateReclaimLabel(reclaim)
    local worldView = import('/lua/ui/game/worldview.lua').viewLeft

    if not worldView then
        table.insert(queued, reclaim)
        return
    end

    local label = Bitmap(worldView)
    local pos = reclaim.position
    local position = Vector(pos[1], pos[2], pos[3])

    label.mass = Bitmap(label)
    label.mass:SetTexture(UIUtil.UIFile('/game/build-ui/icon-mass_bmp.dds'))
    LayoutHelpers.AtLeftIn(label.mass, label)
    LayoutHelpers.AtVerticalCenterIn(label.mass, label)
    label.mass.Height:Set(14)
    label.mass.Width:Set(14)

    label.text = UIUtil.CreateText(label, math.floor(0.5+reclaim.mass), 10, UIUtil.bodyFont)
    label.text:SetColor('ffc7ff8f')
    label.text:SetDropShadow(true)
    LayoutHelpers.AtLeftIn(label.text, label, 16)
    LayoutHelpers.AtVerticalCenterIn(label.text, label)

    label:SetNeedsFrameUpdate(false)
    label:Hide()

    label.OnFrame = function(self, delta)
        local pos = worldView:Project(position)
        LayoutHelpers.AtLeftTopIn(label, worldView, pos.x - label.Width() / 2, pos.y - label.Height() / 2 + 1)
    end


    labels[reclaim.id] = label
end

function DestroyReclaimLabel(id)
    local label = labels[id]

    if label then
        label:Destroy()
        labels[id] = nil
    end
end

function DestroyLabels()
    for id, l in labels do
        l:Destroy()
        labels[id] = nil
    end
end
