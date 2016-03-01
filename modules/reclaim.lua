local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')
local Prefs = import('/lua/user/prefs.lua')

local reclaim = {}

local WorldLabel = Class(Group) {
    __init = function(self, parent, position)
        Group.__init(self, parent)
        self.proj = nil
        if position then self:SetPosition(position) end

        -- XXX
        self.Top:Set(0)
        self.Left:Set(0)
        self.Width:Set(50)
        self.Height:Set(50)
        self:DisableHitTest()
        self.view = import('/lua/ui/game/worldview.lua').viewLeft

        self:Update()
        self:SetNeedsFrameUpdate(true)
    end,

    SetPosition = function(self, position)
        self.position = position
    end,

    Update = function(self)
        local view = self.view
        local pos
        if not self.position.x then -- dynamic position, i.e. entity
            pos = self.position:GetPosition()
        else
            pos = self.position
        end

        local proj = self.view:Project(pos)

        if not self.proj or self.proj.x ~= proj.x or self.proj.y ~= self.proj.y then
            LayoutHelpers.AtLeftTopIn(self, view, proj.x - self.Width() / 2, proj.y - self.Height() / 2 + 1)
            self.proj = proj
        end
        
    end,

    OnFrame = function(self, delta)
        if not self:IsHidden() then
            self:Update()
        end
    end
}

function UpdateReclaim(r)
    reclaim[r.id] = r.mass and r.mass >= 1 and r or nil
end

function NearestCluster(point, clusters)
    function Distance(a, b)
        return math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2))
    end

    local min_dist = 999999999
    local index
    for i, cluster in clusters do
        local d = Distance(point, cluster)
        if d < min_dist then
            min_dist = d
            index = i
        end
    end

    return index, min_dist
end

function kpp(points, clusters, max_distance)
    max_distance = max_distance or 100

    clusters[1] = table.deepcopy(points[1])

    for c, cluster in clusters do
        for i, point in points do
            local _, d = NearestCluster(point, clusters)
            if d > max_distance then
                table.insert(clusters, table.deepcopy(point))
            end
        end
    end

    for _, point in points do
        point.cluster = NearestCluster(point, clusters)
    end
end

function ClusterPoints(points, max_distance)
    local n_points = table.getsize(points)
    if n_points == 0 then return {} end

    local clusters = {}

    kpp(points, clusters, max_distance)

    local min_changed = table.getn(points)*0.001
    local done = false
    while not done do
        clusters = {}
        for _, point in points do
            local cluster = clusters[point.cluster] or {x=0, y=0, n_points=0, mass=0}
            cluster.n_points = cluster.n_points + 1
            cluster.mass = cluster.mass + point.mass
            cluster.x = cluster.x + point.x
            cluster.y = cluster.y + point.y
            clusters[point.cluster] = cluster
        end

        for _, cluster in clusters do
            cluster.x = cluster.x / cluster.n_points
            cluster.y = cluster.y / cluster.n_points
        end

        local changed = 0
        for _, point in points do
            local c, d = NearestCluster(point, clusters)
            point.distance = d
            if c ~= point.cluster then
                point.cluster = c
                changed = changed + 1
            end
        end

        if changed <= min_changed then
            done = true
        end
    end

    for _, point in points do
        local cluster = clusters[point.cluster]
        cluster.radius = math.max(cluster.radius or 0, point.distance)
    end

    return clusters
end

function OnScreen(view, pos)
    local proj = view:Project(Vector(pos[1], pos[2], pos[3]))
    return not (proj.x < 0 or proj.y < 0 or proj.x > view.Width() or proj.y > view:Height())
end

function GetVisibleReclaim()
    local view = import('/lua/ui/game/worldview.lua').viewLeft
    local points = {}

    for id, r in reclaim do
         if OnScreen(view, r.position) then 
            table.insert(points, {x=r.position[1], y=r.position[3], mass=r.mass})
        end
    end

    return points
end

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

    if r.n_points and r.n_points > 1 then -- cluster
        local camera = GetCamera("WorldCamera")
        local zoom, max = camera:GetZoom(), camera:GetMaxZoom()
        label.circle = Bitmap(label)
        label.circle:SetTexture('/textures/mass_ring.png')
        label.circle.Height:Set(r.radius * (max / zoom) * 2)
        label.circle.Width:Set(r.radius * (max / zoom) * 2)
        LayoutHelpers.AtCenterIn(label.circle, label)

        label.circle.OnFrame = function(self, delta)
            if not SameZoom(camera) then
                local zoom = camera:GetZoom()
                self.Height:Set(r.radius * (max / zoom) * 2)
                self.Width:Set(r.radius * (max / zoom) * 2)
            end
        end

        label.circle:SetNeedsFrameUpdate(true)
    end

    return label
end

local labelGroup = nil
function UpdateLabels()
    local view = labelGroup

    for _, c in view.ReclaimLabels or {} do
        c:Destroy()
    end

    labelGroup.ReclaimLabels = {}

    local points
    local camera = GetCamera("WorldCamera")
    local points = GetVisibleReclaim()
    local max_zoom = camera:GetMaxZoom()
    local zoom = camera:GetZoom()
    local max_distance = zoom > 125 and math.max(200 * (camera:GetZoom() / max_zoom), 10) or 0

    if max_distance > 0 and table.getsize(points) > 25 then
        points = ClusterPoints(points, max_distance)
    end

    for id, p in points do
        p.position = Vector(p.x, 20, p.y)
        table.insert(labelGroup.ReclaimLabels, CreateReclaimLabel(view, p))
    end

    return labelGroup.ReclaimLabels
end


function HideLabels()
    for _, c in labelGroup.ReclaimLabels or {} do
        c:SetNeedsFrameUpdate(false)
    end

    labelGroup:Hide()    
end

-- Called from commandgraph.lua:OnCommandGraphShow()
local ReclaimThread
function ShowReclaim(show)
    local options = Prefs.GetFromCurrentProfile('options')
    if show and options.gui_show_reclaim == 1 then
        ReclaimThread = ForkThread(ShowReclaimThread)
    else
        if ReclaimThread then
            KillThread(ReclaimThread)
        end

        if labelGroup then
            HideLabels()
        end
    end
end

local ShowingReclaim = false

local oldZoom
function SameZoom(camera)
    return not oldZoom or camera:GetZoom() == oldZoom
end

function ShowReclaimThread()
    local i = 0
    local lastUpdate = 9999
    local view = import('/lua/ui/game/worldview.lua').viewLeft
    local camera = GetCamera("WorldCamera")

    if not labelGroup or IsDestroyed(labelGroup) then
        labelGroup = Group(view)
        labelGroup:DisableHitTest()
        LayoutHelpers.FillParent(labelGroup, view)
    end

    oldZoom = nil
    while true do
        local keydown = IsKeyDown('Control')
        local action

        if ShowingReclaim and not keydown then
            action = 'Hide'
        elseif keydown then
            action = 'Show'
            if lastUpdate > 1 and SameZoom(camera) then
                UpdateLabels()
                lastUpdate = 0
            end
        end

        if action then
            ShowingReclaim = action == 'Show'
            labelGroup[action](labelGroup)
        end

        lastUpdate = lastUpdate + 0.1
        oldZoom = camera:GetZoom()
        WaitSeconds(0.1)
    end
end
