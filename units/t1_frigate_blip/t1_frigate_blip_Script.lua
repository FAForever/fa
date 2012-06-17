#*************************************************************************
#** 
#**  File     :  t1_frigate_blip_script.lua 
#**  Author   :  Resin_Smoker
#**  Summary  :  T1 frigate Blip
#** 
#**  Copyright © 2008 4th Dimension
#*************************************************************************
local AdvancedJammerBlip = import('/mods/Advanced_Jamming/hook/lua/AdvancedJamming.lua').AdvancedJammerBlip

t1_frigate_blip = Class(AdvancedJammerBlip) {}

TypeClass = t1_frigate_blip