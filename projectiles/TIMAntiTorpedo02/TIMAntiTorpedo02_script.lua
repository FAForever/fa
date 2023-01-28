--****************************************************************************
--**
--**  File     :  /data/projectiles/TIMAntiTorpedo02/TIMAntiTorpedo02_script.lua
--**  Author(s):  Matt Vainio
--**
--**  Summary  :  Ship-based Anti-Torpedo, XES0102
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TDepthChargeProjectile = import("/lua/terranprojectiles.lua").TDepthChargeProjectile

---@class TIMAntiTorpedo02 : TDepthChargeProjectile
TIMAntiTorpedo02 = ClassProjectile(TDepthChargeProjectile) {}

TypeClass = TIMAntiTorpedo02
