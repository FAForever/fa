local UserDecal = import('/lua/user/UserDecal.lua').UserDecal
local Dragger = import('/lua/maui/dragger.lua').Dragger

---@class LineDrag : Dragger
---@field Origin Vector
---@field Destination Vector
---@field Trash TrashBag
---@field ShapeStart table
---@field ShapeEnd table
---@field ShapeStart1 table
---@field ShapeStart2 table
---@field ShapeEnd1 table
---@field ShapeEnd2 table
---@field Width number
---@field WorldView WorldView
---@field Callback fun(origin: Vector, destination: Vector)
RectangleDragger = Class(Dragger) {

    Size = 0.1,
    Thickness = 0.1,

    ---@param self LineDrag
    ---@param view WorldView
    ---@param callback fun(origin: Vector, destination: Vector)
    ---@param width number
    __init = function(self, view, callback, width)
        Dragger.__init(self)

        -- store parameters
        self.Width = width
        self.WorldView = view
        self.Callback = callback

        -- prepare visuals
        local trash = TrashBag()
        local mouseWorldPosition = GetMouseWorldPos()

        self.Trash = trash

        local size = self.Size
        local thickness = self.Thickness
        self.ShapeStart = { shape = 'Circle', pos = mouseWorldPosition, size = size, color = 'ffffff', thickness = thickness }
        self.ShapeEnd = { shape = 'Circle', pos = mouseWorldPosition, size = size, color = 'ffffff', thickness = thickness }
        self.ShapeStart1 = { shape = 'Circle', pos = mouseWorldPosition, size = size, color = 'ffffff', thickness = thickness }
        self.ShapeStart2 = { shape = 'Circle', pos = mouseWorldPosition, size = size, color = 'ffffff', thickness = thickness }
        self.ShapeEnd1 = { shape = 'Circle', pos = mouseWorldPosition, size = size, color = 'ffffff', thickness = thickness }
        self.ShapeEnd2 = { shape = 'Circle', pos = mouseWorldPosition, size = size, color = 'ffffff', thickness = thickness }

        self.Origin = mouseWorldPosition

        -- register the dragger
        PostDragger(view:GetRootFrame(), 'LBUTTON', self)
    end,

    ---@param self LineDrag
    ---@param x number  # x coordinate of screen position
    ---@param y number  # y coordinate of screen position
    OnMove = function(self, x, y)
        local width = self.Width
        local view = self.WorldView

        local ps = self.Origin
        local pe = UnProject(view, { x, y })

        local dx = ps[1] - pe[1]
        local dz = ps[3] - pe[3]
        local distance = math.sqrt(dx * dx + dz * dz)

        local nx = (1 / distance) * dx
        local nz = (1 / distance) * dz

        local ox = nz
        local oz = -nx

        self.ShapeStart1.pos = ({ ps[1] + width * ox, ps[2], ps[3] + width * oz })
        self.ShapeStart2.pos = ({ ps[1] - width * ox, ps[2], ps[3] - width * oz })

        self.ShapeEnd1.pos = ({ pe[1] + width * ox, pe[2], pe[3] + width * oz })
        self.ShapeEnd2.pos = ({ pe[1] - width * ox, pe[2], pe[3] - width * oz })

        self.ShapeEnd.pos = pe

        view:UI_DrawShapesRegistry(self.ShapeStart1, true)
        view:UI_DrawShapesRegistry(self.ShapeStart2, true)
        view:UI_DrawShapesRegistry(self.ShapeStart, true)
        view:UI_DrawShapesRegistry(self.ShapeEnd1, true)
        view:UI_DrawShapesRegistry(self.ShapeEnd2, true)
        view:UI_DrawShapesRegistry(self.ShapeEnd, true)
    end,

    ---@param self LineDrag
    ---@param x number  # x coordinate of screen position
    ---@param y number  # y coordinate of screen position
    OnRelease = function(self, x, y)
        -- do the callback
        local origin = self.Origin
        local destination = UnProject(self.WorldView, { x, y })
        local ok, err = pcall(self.Callback, origin, destination)
        if not ok then
            WARN(err)
        end

        self.Trash:Destroy()

        local view = self.WorldView
        view:UI_DrawShapesRegistry(self.ShapeStart1, false)
        view:UI_DrawShapesRegistry(self.ShapeStart2, false)
        view:UI_DrawShapesRegistry(self.ShapeStart, false)
        view:UI_DrawShapesRegistry(self.ShapeEnd1, false)
        view:UI_DrawShapesRegistry(self.ShapeEnd2, false)
        view:UI_DrawShapesRegistry(self.ShapeEnd, false)
    end,

    ---@param self LineDrag
    OnCancel = function(self)
        self.Trash:Destroy()

        local view = self.WorldView
        view:UI_DrawShapesRegistry(self.ShapeStart1, false)
        view:UI_DrawShapesRegistry(self.ShapeStart2, false)
        view:UI_DrawShapesRegistry(self.ShapeStart, false)
        view:UI_DrawShapesRegistry(self.ShapeEnd1, false)
        view:UI_DrawShapesRegistry(self.ShapeEnd2, false)
        view:UI_DrawShapesRegistry(self.ShapeEnd, false)
    end,
}

---@param eventKey string -- button code for the dragger, dragger will watch for this button to be released
---@param callbackTable table -- should be of the form {Func = function, Args = {}} or {Func = "$simCallbackString", Args = {}}
---@param width number
---@param maximumDistance number
function VectorDragger(eventKey, callbackTable, width, maximumDistance)

    local view = import("/lua/ui/game/worldview.lua").viewLeft
    if not view then
        WARN("AreaReclaimDragger: No view found")
        return
    end

    local trash = TrashBag()
    local dragger = trash:Add(Dragger())

    local radius = 0
    local ps = GetMouseWorldPos()
    local pe = GetMouseWorldPos()

    local decalStart = trash:Add(UserDecal())
    decalStart:SetTexture("/textures/ui/common/game/AreaTargetDecal/weapon_icon_small.dds")
    decalStart:SetScale({ 1, 1, 1 })
    decalStart:SetPosition(ps)

    local decalEnd = trash:Add(UserDecal())
    decalEnd:SetTexture("/textures/ui/common/game/AreaTargetDecal/weapon_icon_small.dds")
    decalEnd:SetScale({ 1, 1, 1 })
    decalEnd:SetPosition(pe)

    local decalStart1 = trash:Add(UserDecal())
    decalStart1:SetTexture("/textures/ui/common/game/AreaTargetDecal/weapon_icon_small.dds")
    decalStart1:SetScale({ 1, 1, 1 })
    decalStart1:SetPosition(pe)

    local decalStart2 = trash:Add(UserDecal())
    decalStart2:SetTexture("/textures/ui/common/game/AreaTargetDecal/weapon_icon_small.dds")
    decalStart2:SetScale({ 1, 1, 1 })
    decalStart2:SetPosition(pe)

    local decalEnd1 = trash:Add(UserDecal())
    decalEnd1:SetTexture("/textures/ui/common/game/AreaTargetDecal/weapon_icon_small.dds")
    decalEnd1:SetScale({ 1, 1, 1 })
    decalEnd1:SetPosition(pe)

    local decalEnd2 = trash:Add(UserDecal())
    decalEnd2:SetTexture("/textures/ui/common/game/AreaTargetDecal/weapon_icon_small.dds")
    decalEnd2:SetScale({ 1, 1, 1 })
    decalEnd2:SetPosition(pe)


    dragger.OnMove = function(self, x, y)
        pe = UnProject(view, { x, y })
        local dx = ps[1] - pe[1]
        local dz = ps[3] - pe[3]
        local distance = math.sqrt(dx * dx + dz * dz)

        radius = math.min(distance, maximumDistance)

        local nx = (1 / distance) * dx
        local nz = (1 / distance) * dz

        local ox = nz
        local oz = -nx

        decalStart1:SetPosition({ ps[1] + width * ox, ps[2], ps[3] + width * oz })
        decalStart2:SetPosition({ ps[1] - width * ox, ps[2], ps[3] - width * oz })

        decalEnd1:SetPosition({ pe[1] + width * ox, pe[2], pe[3] + width * oz })
        decalEnd2:SetPosition({ pe[1] - width * ox, pe[2], pe[3] - width * oz })

        decalEnd:SetPosition(pe)


    end

    -- When we release the mouse button, check our radius and do the callback
    dragger.OnRelease = function(self, x, y)
        if radius > 1 then
            -- add our radius to our callback parameter table
            callbackTable.Args.Distance = radius
            callbackTable.Args.Vector = pe
            if type(callbackTable.Func) == "string" then
                -- If our function in the callback table is a string, it's a SimCallback
                SimCallback(callbackTable, true)
            else
                -- Otherwise, call the function directly
                callbackTable.Func(callbackTable.Args)
            end
        end

        trash:Destroy()
    end

    -- Not sure under what conditions this would be called,
    dragger.OnCancel = function(self)
        trash:Destroy()
    end

    -- Register the dragger with the engine
    PostDragger(view:GetRootFrame(), eventKey, dragger)
end
