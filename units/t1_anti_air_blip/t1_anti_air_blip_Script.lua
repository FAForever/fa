#*************************************************************************
#** 
#**  File     :  t1_anti_air_blip_script.lua 
#**  Author   :  Resin_Smoker
#**  Summary  :  T1 Tank Blip
#** 
#**  Copyright © 2008 4th Dimension
#*************************************************************************
local AdvancedJammerBlip = import('/mods/Advanced_Jamming/hook/lua/AdvancedJamming.lua').AdvancedJammerBlip

t1_anti_air_blip = Class(AdvancedJammerBlip) {}

TypeClass = t1_anti_air_blip