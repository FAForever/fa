---@meta
--- none of this code is executed, it is for example only
---@declare-global
moho = {
    -- sim

    aibrain_methods = require('/engine/sim/caibrain.lua'),
    entity_methods = require('/engine/sim/entity.lua'),
    unit_methods = require('/engine/sim/unit.lua'),
    projectile_methods = require('/engine/sim/projectile.lua'),
    prop_methods = require('/engine/sim/prop.lua'),
    shield_methods = require('/engine/sim/shield.lua'),
    weapon_methods = require('/engine/sim/unitweapon.lua'),
    platoon_methods = require('/engine/sim/cplatoon.lua'),
    CollisionBeamEntity = require('/engine/sim/collisionbeamentity.lua'),
    SlideManipulator = require('/engine/sim/cslidemanipulator.lua'),
    IEffect = require('/engine/sim/ieffect.lua'),

    manipulator_methods = require('/engine/sim/ianimanipulator.lua'),
    BuilderArmManipulator = require('/engine/sim/cbuilderarmmanipulator.lua'),
    AimManipulator = require('/engine/sim/caimmanipulator.lua'),
    AnimationManipulator = require('/engine/sim/canimationmanipulator.lua'),
    CollisionManipulator = require('/engine/sim/ccollisionmanipulator.lua'),
    RotateManipulator = require('/engine/sim/crotatemanipulator.lua'),


    -- user

    bitmap_methods = require('/engine/User/CMauiBitmap.lua'),
    border_methods = require('/engine/User/CMauiBorder.lua'),
    control_methods = require('/engine/User/CMauiControl.lua'),
    cursor_methods = require('/engine/User/CMauiCursor.lua'),
    discovery_service_methods = require('/engine/User/CDiscoveryService.lua'),
    dragger_methods = require('/engine/User/CMauiLuaDragger.lua'),
    edit_methods = require('/engine/User/CMauiEdit.lua'),
    frame_methods = require('/engine/User/CMauiFrame.lua'),
    group_methods = require('/engine/User/CMauiGroup.lua'),
    histogram_methods = require('/engine/User/CMauiHistogram.lua'),
    item_list_methods = require('/engine/User/CMauiItemList.lua'),
    lobby_methods = require('/engine/User/CLobby.lua'),
    mesh_methods = require('/engine/User/CMauiMesh.lua'),
    movie_methods = require('/engine/User/CMauiMovie.lua'),
    PathDebugger_methods = require('/engine/User/CPathDebugger.lua'),
    scrollbar_methods = require('/engine/User/CMauiScrollbar.lua'),
    text_methods = require('/engine/User/CMauiText.lua'),
    UIWorldView = require('/engine/User/CUIWorldView.lua'),
    userDecal_methods = require('/engine/User/ScriptedDecal.lua'),
    WldUIProvider_methods = require('/engine/User/CLuaWldUIProvider.lua'),
    world_mesh_methods = require('/engine/User/CUIWorldMesh.lua'),
}
