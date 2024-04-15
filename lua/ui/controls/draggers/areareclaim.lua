local CommandMode = import("/lua/ui/game/commandmode.lua")
local UserDecal = import('/lua/user/UserDecal.lua').UserDecal
local Dragger = import('/lua/maui/dragger.lua').Dragger

function AreaReclaimDragger(command)

    local view = import("/lua/ui/game/worldview.lua").viewLeft
    local targetPos = GetMouseWorldPos()
    local worldPos
    local dragger = Dragger()
    local decal
    local rad = 0

    dragger.OnMove = function(dr, x, y)
        worldPos = UnProject(view, {x,y})
        rad = VDist2(targetPos[1], targetPos[3], worldPos[1], worldPos[3])
        if not decal then
            decal = UserDecal()
            decal:SetTexture("/textures/ui/common/game/AreaTargetDecal/weapon_icon_small.dds")
            decal:SetScale({ 2, 1, 2 })
            decal:SetPosition(targetPos)
        elseif decal then
            decal:SetScale({ rad * 2, 1, rad * 2 })
            decal:SetPosition(targetPos)
        end
    end

    dragger.OnRelease = function(dr, x, y)
        if rad > 1 then
            SimCallback({ Func = 'ExtendReclaimOrder', Args = {
                Radius = rad
            } }, true)
        end
        if decal then decal:Destroy() end
        dr:Destroy()
    end

    dragger.OnCancel = function(dr)
        if decal then decal:Destroy() end
        dr:Destroy()
    end

    PostDragger(view:GetRootFrame(), '1', dragger)
end