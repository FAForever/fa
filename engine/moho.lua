---@meta
--- none of this code is executed, it is for example only
---@declare-global
moho = {
    -- sim

    AimManipulator = require('/engine/Sim/CAimManipulator.lua'),
    AnimationManipulator = require('/engine/Sim/CAnimationManipulator.lua'),
    BoneEntityManipulator = require('/engine/Sim/CBoneEntityManipulator.lua'),
    BuilderArmManipulator = require('/engine/Sim/CBuilderArmManipulator.lua'),
    CDamage = require('/engine/Sim/CDamage.lua'),
    CDecalHandle = require('/engine/Sim/CDecalHandle.lua'),
    CollisionBeamEntity = require('/engine/Sim/CollisionBeamEntity.lua'),
    CollisionManipulator = require('/engine/Sim/CCollisionManipulator.lua'),
    EconomyEvent = require('/engine/Sim/CEconomyEvent.lua'),
    FootPlantManipulator = require('/engine/Sim/CFootPlantManipulator.lua'),
    IEffect = require('/engine/Sim/IEffect.lua'),
    MotorFallDown = require('/engine/Sim/MotorFallDown.lua'),
    RotateManipulator = require('/engine/Sim/CRotateManipulator.lua'),
    SlaveManipulator = require('/engine/Sim/CSlaveManipulator.lua'),
    SlideManipulator = require('/engine/Sim/CSlideManipulator.lua'),
    StorageManipulator = require('/engine/Sim/CStorageManipulator.lua'),
    ThrustManipulator = require('/engine/Sim/CThrustManipulator.lua'),

    aibrain_methods = require('/engine/Sim/CAiBrain.lua'),
    aipersonality_methods = require('/engine/Sim/CAiPersonality.lua'),
    CAiAttackerImpl_methods = require('/engine/Sim/CAiAttackerImpl.lua'),
    blip_methods = require('/engine/Sim/ReconBlip.lua'),
    entity_methods = require('/engine/Sim/Entity.lua'),
    manipulator_methods = require('/engine/Sim/IAniManipulator.lua'),
    navigator_methods = require('/engine/Sim/CAiNavigatorImpl.lua'),
    projectile_methods = require('/engine/Sim/Projectile.lua'),
    prop_methods = require('/engine/Sim/Prop.lua'),
    ScriptTask_Methods = require('/engine/Sim/CUnitScriptTask.lua'),
    shield_methods = require('/engine/Sim/Shield.lua'),
    unit_methods = require('/engine/Sim/Unit.lua'),
    weapon_methods = require('/engine/Sim/UnitWeapon.lua'),
    platoon_methods = require('/engine/Sim/CPlatoon.lua'),

    -- user

    control_methods = require('/engine/user/cmauicontrol.lua'),
    edit_methods = require('/engine/user/cmauiedit.lua'),
    frame_methods = require('/engine/user/cmauiframe.lua'),
    text_methods = require('/engine/user/cmauitext.lua'),
    item_list_methods = require('/engine/user/cmauiitemlist.lua'),
    bitmap_methods = require('/engine/user/cmauibitmap.lua'),
    cursor_methods = require('/engine/user/cmauicursor.lua'),
    UIWorldView = require('/engine/user/cuiworldview.lua'),
    lobby_methods = require('/engine/user/clobby.lua')
}
