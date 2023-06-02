--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB5101/UAB5101_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Wall Piece Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local AWallStructureUnit = import("/lua/aeonunits.lua").AWallStructureUnit

---@class UAB5101 : AWallStructureUnit
UAB5101 = ClassUnit(AWallStructureUnit) {}

TypeClass = UAB5101