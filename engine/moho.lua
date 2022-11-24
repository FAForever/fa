---@meta

--- none of this code is executed, it is for example only

moho = {
    -- sim

    AimManipulator = require("/engine/sim/CAimManipulator.lua"),
    AnimationManipulator = require("/engine/Sim/CAnimationManipulator.lua"),
    BoneEntityManipulator = require("/engine/Sim/CBoneEntityManipulator.lua"),
    BuilderArmManipulator = require("/engine/Sim/CBuilderArmManipulator.lua"),
    CDamage = require("/engine/Sim/CDamage.lua"),
    CDecalHandle = require("/engine/Sim/CDecalHandle.lua"),
    CollisionBeamEntity = require("/engine/Sim/CollisionBeamEntity.lua"),
    CollisionManipulator = require("/engine/Sim/CCollisionManipulator.lua"),
    EconomyEvent = require("/engine/Sim/CEconomyEvent.lua"),
    FootPlantManipulator = require("/engine/Sim/CFootPlantManipulator.lua"),
    IEffect = require("/engine/Sim/IEffect.lua"),
    MotorFallDown = require("/engine/Sim/MotorFallDown.lua"),
    RotateManipulator = require("/engine/Sim/CRotateManipulator.lua"),
    SlaveManipulator = require("/engine/Sim/CSlaveManipulator.lua"),
    SlideManipulator = require("/engine/Sim/CSlideManipulator.lua"),
    StorageManipulator = require("/engine/Sim/CStorageManipulator.lua"),
    ThrustManipulator = require("/engine/Sim/CThrustManipulator.lua"),

    aibrain_methods = require("/engine/Sim/CAiBrain.lua"),
    aipersonality_methods = require("/engine/Sim/CAiPersonality.lua"),
    CAiAttackerImpl_methods = require("/engine/Sim/CAiAttackerImpl.lua"),
    blip_methods = require("/engine/Sim/ReconBlip.lua"),
    entity_methods = require("/engine/Sim/Entity.lua"),
    manipulator_methods = require("/engine/Sim/IAniManipulator.lua"),
    navigator_methods = require("/engine/Sim/CAiNavigatorImpl.lua"),
    projectile_methods = require("/engine/Sim/Projectile.lua"),
    prop_methods = require("/engine/Sim/Prop.lua"),
    ScriptTask_Methods = require("/engine/Sim/CUnitScriptTask.lua"),
    shield_methods = require("/engine/Sim/Shield.lua"),
    unit_methods = require("/engine/Sim/Unit.lua"),
    weapon_methods = require("/engine/Sim/UnitWeapon.lua"),
    platoon_methods = require("/engine/Sim/CPlatoon.lua"),

    -- core (both sim and user)

    sound_methods = require("/engine/core/csound.lua"),
    EntityCategory = require("/engine/core/entitycategory.lua"),
    CPrefetchSet = require("/engine/core/cprefetchset.lua"),

    -- user

    bitmap_methods = require("/engine/User/CMauiBitmap.lua"),
    border_methods = require("/engine/User/CMauiBorder.lua"),
    control_methods = require("/engine/User/CMauiControl.lua"),
    cursor_methods = require("/engine/User/CMauiCursor.lua"),
    discovery_service_methods = require("/engine/User/CDiscoveryService.lua"),
    dragger_methods = require("/engine/User/CMauiLuaDragger.lua"),
    edit_methods = require("/engine/User/CMauiEdit.lua"),
    frame_methods = require("/engine/User/CMauiFrame.lua"),
    group_methods = require("/engine/User/CMauiGroup.lua"),
    histogram_methods = require("/engine/User/CMauiHistogram.lua"),
    item_list_methods = require("/engine/User/CMauiItemList.lua"),
    lobby_methods = require("/engine/User/CLobby.lua"),
    mesh_methods = require("/engine/User/CMauiMesh.lua"),
    movie_methods = require("/engine/User/CMauiMovie.lua"),
    PathDebugger_methods = require("/engine/User/CPathDebugger.lua"),
    scrollbar_methods = require("/engine/User/CMauiScrollbar.lua"),
    text_methods = require("/engine/User/CMauiText.lua"),
    UIWorldView = require("/engine/User/CUIWorldView.lua"),
    userDecal_methods = require("/engine/User/ScriptedDecal.lua"),
    WldUIProvider_methods = require("/engine/User/CLuaWldUIProvider.lua"),
    world_mesh_methods = require("/engine/User/CUIWorldMesh.lua"),
}
