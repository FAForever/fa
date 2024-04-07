---@diagnostic disable: undefined-global
-- Info about exe patches and new lua<->engine functions

-- sim version of GetStat(). Awesome function as it already sends a string, integer and unit object to engine +
-- returns a table with values. This is basically all you need for lua<->engine communication.
--
-- "h1_SetSalemAmph" 1/0 controls amhibious mode for Salem destroyer. It takes unit's C-object and changes bp pointer
-- to a copy of urs0201 bp with bp.Footprint.MinWaterDepth = 1.5 and bp.Footprint.OccupancyCaps = 8. These 2 parameters are used in
-- movement calculation. Physics.MotionType doesn't really matter in this case and engine uses it only to
-- setup these parameters from bp.Footprint
---@param Name string
---@param defaultVal any?
function GetStat(Name,defaultVal)
    unit:GetStat("h1_SetSalemAmph", 1) -- 1 = on, 0 = off.
end