local UserDecal = import('/lua/user/UserDecal.lua').UserDecal
local Dragger = import('/lua/maui/dragger.lua').Dragger

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
        pe = UnProject(view, {x,y})
        local dx = ps[1] - pe[1]
        local dz = ps[3] - pe[3]
        local distance = math.sqrt(dx * dx + dz * dz)

        radius = math.min(distance, maximumDistance)

        local nx = (1/distance) * dx
        local nz = (1/distance) * dz

        local ox = nz
        local oz = -nx

        decalStart1:SetPosition({ps[1] + width * ox, ps[2], ps[3] + width * oz})
        decalStart2:SetPosition({ps[1] - width * ox, ps[2], ps[3] - width * oz})

        decalEnd1:SetPosition({pe[1] + width * ox, pe[2], pe[3] + width * oz})
        decalEnd2:SetPosition({pe[1] - width * ox, pe[2], pe[3] - width * oz})

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