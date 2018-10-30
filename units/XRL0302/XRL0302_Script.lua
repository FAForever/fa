----------------------------------------------------------------
-- File     :  /data/units/XRL0302/XRL0302_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  Cybran Mobile Bomb Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

--[[
    Mobile land mine
    ----------------
    Gains Stealth and Cloaking while stationary for a moderate energy cost
    Detects units which come nearby, targets them, disables intel and moves to destroy
    Hold Fire should have the Beetle ignore units in range and stay hidden
    Suicide button should instantly blow up the unit

    Present Implementation Notes
    ----------------------------
    Instant suicide - Yes
    Suicide (Instant by bp flag) - Yes
    Killed by enemy - Yes
    Reclaimed by enemy - No
    Detonate button - Yes
]]--

local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit
local HiderUnit = import('/lua/defaultunits.lua').HiderUnit
local CMobileKamikazeBombWeapon = import('/lua/cybranweapons.lua').CMobileKamikazeBombWeapon

XRL0302 = Class(CWalkingLandUnit, HiderUnit) {
    Weapons = {
        Suicide = Class(CMobileKamikazeBombWeapon) {},
    },
    
    OnMotionHorzEventChange = function(self, new, old)
        CWalkingLandUnit.OnMotionHorzEventChange(self, new, old)
        self:StealthMotionHandler(new, old)
    end,
    
    -- Turn off the cloak to begin with
    OnStopBeingBuilt = function(self, builder, layer)
        CWalkingLandUnit.OnStopBeingBuilt(self, builder, layer)
        self:RevealUnit()
    end,

    -- Allow the trigger button to blow the weapon, resulting in OnKilled instigator 'nil'
    OnProductionPaused = function(self)
        self:GetWeaponByLabel('Suicide'):FireWeapon()
    end,
    
    OnKilled = function(self, instigator, type, overkillRatio)
        CWalkingLandUnit.OnKilled(self, instigator, type, overkillRatio)
        if instigator then
            self:GetWeaponByLabel('Suicide'):FireWeapon()
        end
    end,
}

TypeClass = XRL0302
