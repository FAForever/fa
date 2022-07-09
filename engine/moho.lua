---@meta
--- none of this code is executed, it is for example only
---@declare-global
moho = {
    -- sim

    AimManipulator = require('/engine/sim/caimmanipulator.lua'),
    AnimationManipulator = require('/engine/sim/canimationmanipulator.lua'),
    --BoneEntityManipulator
    BuilderArmManipulator = require('/engine/sim/cbuilderarmmanipulator.lua'),
    --CDamage
    --CDecalHandle
    CollisionBeamEntity = require('/engine/sim/collisionbeamentity.lua'),
    CollisionManipulator = require('/engine/sim/ccollisionmanipulator.lua'),
    --EconomyEvent
    --FootPlantManipulator
    IEffect = require('/engine/sim/ieffect.lua'),
    --MotorFallDown
    RotateManipulator = require('/engine/sim/crotatemanipulator.lua'),
    --SlaveManipulator
    SlideManipulator = require('/engine/sim/cslidemanipulator.lua'),
    --StorageManipulator
    --ThrustManipulator

    aibrain_methods = require('/engine/sim/caibrain.lua'),
    --aipersonality_methods
    --CAiAttackerImpl_methods
    --blip_methods
    entity_methods = require('/engine/sim/entity.lua'),
    manipulator_methods = require('/engine/sim/ianimanipulator.lua'),
    navigator_methods = require('/engine/sim/cainavigatorimpl.lua'),
    projectile_methods = require('/engine/sim/projectile.lua'),
    prop_methods = require('/engine/sim/prop.lua'),
    --ScriptTask_Methods
    shield_methods = require('/engine/sim/shield.lua'),
    unit_methods = require('/engine/sim/unit.lua'),
    weapon_methods = require('/engine/sim/unitweapon.lua'),
    platoon_methods = require('/engine/sim/cplatoon.lua'),

    -- core (both sim and user)

    sound_methods = require('/engine/core/csound.lua'),
    EntityCategory = require('/engine/core/entitycategory.lua'),
    CPrefetchSet = require('/engine/core/cprefetchset.lua'),

    -- user

    UIWorldView = require('/engine/user/cuiworldview.lua'),
    WldUIProvider_methods = require('/engine/user/cluawlduiprovider.lua'),
    PathDebugger_methods = require('/engine/user/cpathdebugger.lua'),

    bitmap_methods = require('/engine/user/cmauibitmap.lua'),
    border_methods = require('/engine/user/cmauiborder.lua'),
    control_methods = require('/engine/user/cmauicontrol.lua'),
    cursor_methods = require('/engine/user/cmauicursor.lua'),
    discovery_service_methods = require('/engine/user/cdiscoveryservice.lua'),
    dragger_methods = require('/engine/user/cmauiluadragger.lua'),
    edit_methods = require('/engine/user/cmauiedit.lua'),
    frame_methods = require('/engine/user/cmauiframe.lua'),
    group_methods = require('/engine/user/cmauigroup.lua'),
    histogram_methods = require('/engine/user/cmauihistogram.lua'),
    item_list_methods = require('/engine/user/cmauiitemlist.lua'),
    lobby_methods = require('/engine/user/clobby.lua'),
    mesh_methods = require('/engine/user/cmauimesh.lua'),
    movie_methods = require('/engine/user/cmauimovie.lua'),
    scrollbar_methods = require('/engine/user/cmauiscrollbar.lua'),
    text_methods = require('/engine/user/cmauitext.lua'),
    userDecal_methods = require('/engine/user/scripteddecal.lua'),
    world_mesh_methods = require('/engine/user/cuiworldmesh.lua'),
}
