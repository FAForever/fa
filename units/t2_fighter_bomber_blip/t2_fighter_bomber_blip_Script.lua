#*************************************************************************
#** 
#**  File     :  t2_fighter_bomber_blip_script.lua 
#**  Author   :  Resin_Smoker
#**  Summary  :  T2 Fighter / Bomber Jamming Blip
#** 
#**  Copyright © 2008 4th Dimension
#*************************************************************************
local AdvancedJammerBlip = import('/mods/Advanced_Jamming/hook/lua/AdvancedJamming.lua').AdvancedJammerBlip

t2_fighter_bomber_blip = Class(AdvancedJammerBlip) {}

TypeClass = t2_fighter_bomber_blip