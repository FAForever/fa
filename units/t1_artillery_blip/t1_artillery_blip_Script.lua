#*************************************************************************
#** 
#**  File     :  t1_artillery_blip_script.lua 
#**  Author   :  Resin_Smoker
#**  Summary  :  T1 Artillery Blip
#** 
#**  Copyright © 2008 4th Dimension
#*************************************************************************
local AdvancedJammerBlip = import('/mods/Advanced_Jamming/hook/lua/AdvancedJamming.lua').AdvancedJammerBlip

t1_artillery_blip = Class(AdvancedJammerBlip) {}

TypeClass = t1_artillery_blip