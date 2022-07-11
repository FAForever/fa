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
