#*****************************************************************************
#* File: lua/sim/Attacker.lua
#*
#* Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
#*****************************************************************************

Attacker = Class(moho.attacker_methods) {
    
    # NATIVE METHODS 
    --[[

    # Returns the unit this attacker is bound to.
    unit GetUnit()

    # Returns if the attacker has any weapon that is currently attacking any enemies
    bool AttackerWeaponsBusy()

    # Return the count of weapons.
    int GetWeaponCount()

    # Force the unit to set the given unit as its enemy. AI takes
    # care of how to attack the enemy if possible. Each of our
    # weapons has its own target, and the AI will do its best to set
    # those targets to our specified enemy, but if the weapon is
    # unable to fire upon this enemy it will continue searching for
    # other things it can attack. If it engages another enemy it
    # will continually attempt to acquire the desired target.
    nil SetDesiredTarget(AITarget)
    AITarget GetDesiredTarget()

    # Stop will cease all firing upon enemies or ground
    # positions.  However the weapons can still pick up enemies and
    # begin firing on their own. Same as SetDesiredTarget(nil)
    Stop()

    # Loop through the weapons to see if the target can be attacked
    bool CanAttackTarget(AITarget)

    # Find the best enemy target for a weapon
    entity FindBestEnemy(range)

    # Loop through the weapons to find one that we can use to attack target
    index GetTargetWeapon(AITarget)

    # Loop through the weapons to find our primary weapon
    index GetPrimaryWeapon()

    # Loop through the weapons to find the weapon with the longest range that is not manual fire
    float GetMaxWeaponRange()
    
    # Check if the target is within any weapon range
    bool IsWithinAttackRange(AITarget)
    bool IsWithinAttackRange(weaponIndex, AITarget)
    bool IsWithinAttackRange(position)
    bool IsWithinAttackRange(weaponIndex, position)

    # Check if the target is too close to our weapons
    bool IsTooClose(AITarget)

    # Check if the target is exempt from being attacked
    bool IsTargetExempt(entity)

    # Check if the attack has a slaved weapon that currently has a target
    AITarget HasSlavedTarget()

    # Reset reporting state
    ResetReportingState()

    # Force to engage enemy target
    ForceEngage(entity)
    --]]
}
