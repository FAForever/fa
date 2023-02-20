--****************************************************************************
--** 
--**  File     :  /cdimage/units/XSC1901/XSC1901_script.lua 
--** 
--** 
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SCivilianStructureUnit = import("/lua/seraphimunits.lua").SCivilianStructureUnit

---@class XSC1901 : SCivilianStructureUnit
XSC1901 = ClassUnit(SCivilianStructureUnit) {
	OnCreate = function(self)
		SCivilianStructureUnit.OnCreate(self)
		local army = self:GetArmy()
		--------------CreateAttachedEmitter(self,'XSC1901',army, '/effects/emitters/seraphim_rift_arch_base_01_emit.bp'):OffsetEmitter(0.00, 0.00, 0.00)
        CreateAttachedEmitter(self,'XSC1901',army, '/effects/emitters/seraphim_rift_arch_base_01_emit.bp')	-- glow
        CreateAttachedEmitter(self,'XSC1901',army, '/effects/emitters/seraphim_rift_arch_base_02_emit.bp')	-- plasma pillar
        CreateAttachedEmitter(self,'XSC1901',army, '/effects/emitters/seraphim_rift_arch_base_03_emit.bp')	-- darkening pillar
        CreateAttachedEmitter(self,'XSC1901',army, '/effects/emitters/seraphim_rift_arch_base_04_emit.bp')	-- ring outward dust/motion
        CreateAttachedEmitter(self,'XSC1901',army, '/effects/emitters/seraphim_rift_arch_base_05_emit.bp')	-- plasma pillar move
        CreateAttachedEmitter(self,'XSC1901',army, '/effects/emitters/seraphim_rift_arch_base_06_emit.bp')	-- darkening pillar move
        CreateAttachedEmitter(self,'XSC1901',army, '/effects/emitters/seraphim_rift_arch_base_07_emit.bp')	-- bright line at bottom / right side
        CreateAttachedEmitter(self,'XSC1901',army, '/effects/emitters/seraphim_rift_arch_base_08_emit.bp')	-- bright line at bottom / left side
        CreateAttachedEmitter(self,'XSC1901',army, '/effects/emitters/seraphim_rift_arch_base_09_emit.bp')	-- small flickery dots rising
        ------CreateAttachedEmitter(self,'XSC1901',army, '/effects/emitters/seraphim_rift_arch_base_10_emit.bp')	-- distortion
        CreateAttachedEmitter(self,'FX_07',army, '/effects/emitters/seraphim_rift_arch_top_01_emit.bp')		-- top part glow
        CreateAttachedEmitter(self,'FX_07',army, '/effects/emitters/seraphim_rift_arch_top_02_emit.bp')		-- top part plasma
        CreateAttachedEmitter(self,'FX_07',army, '/effects/emitters/seraphim_rift_arch_top_03_emit.bp')		-- top part darkening
        CreateAttachedEmitter(self,'FX_01',army, '/effects/emitters/seraphim_rift_arch_edge_01_emit.bp')	-- line wall
        CreateAttachedEmitter(self,'FX_02',army, '/effects/emitters/seraphim_rift_arch_edge_01_emit.bp')	-- line wall
        CreateAttachedEmitter(self,'FX_03',army, '/effects/emitters/seraphim_rift_arch_edge_01_emit.bp')	-- line wall
        CreateAttachedEmitter(self,'FX_04',army, '/effects/emitters/seraphim_rift_arch_edge_01_emit.bp')	-- line wall
        CreateAttachedEmitter(self,'FX_05',army, '/effects/emitters/seraphim_rift_arch_edge_01_emit.bp')	-- line wall
        CreateAttachedEmitter(self,'FX_06',army, '/effects/emitters/seraphim_rift_arch_edge_01_emit.bp')	-- line wall
	end,          
}


TypeClass = XSC1901

