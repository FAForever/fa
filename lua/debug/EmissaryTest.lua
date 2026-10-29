--******************************************************************************************************
--** Emissary (uab2302) shell test, sim side. Run from the console, see FAFScripts/modules/emissary-test/run.lua.
--**
--** Run: one case at a time, spawns a fresh Emissary and fresh hostile targets, fires a real shot with an attack
--** order, and checks what the shell did from hooks on its class (hits, pass-ons, lodges) and the damage from the
--** targets' health, sampled every tick. Logs `FAFTEST PASS`/`FAFTEST FAIL` lines and sends the totals to the UI in
--** `Sync.FAFTestEmissary`.
--**
--** Visual: loops all cases at once, in a row, until StopVisual: resets the targets, then drops a shell straight onto
--** each, so the effects can be watched again and again.
--******************************************************************************************************

local Shell = import('/projectiles/AIFSonanceShell02/AIFSonanceShell02_script.lua').AIFSonanceShell02

local MathAbs = math.abs
local MathSqrt = math.sqrt

local Hostile = 'ARMY_17'
local TargetDistance = 200 -- from the Emissary along +z, past its minimum range of 150
local CaseTicks = 600      -- game ticks a case may take before it counts as stuck

-- what each shell did, by the entity id of the Emissary that fired it. Kept on the class, so that the hooks below
-- are installed once even if this module is loaded again
if not Shell.FAFTestEvents then
    Shell.FAFTestEvents = {}

    local function Record(shell, kind, targetType, target)
        local launcher = shell:GetLauncher()
        local list = launcher and Shell.FAFTestEvents[launcher.EntityId]
        if not list then
            return
        end
        local x, y, z = shell:GetPositionXYZ()
        local event = { kind = kind, tick = GetGameTick(), targetType = targetType, target = target, x = x, y = y, z = z }
        if target and not IsDestroyed(target) then
            event.tx, event.ty, event.tz = target:GetPositionXYZ()
        end
        table.insert(list, event)
    end

    -- every shot and every impact, to tell what happened when a case gets no hit
    local OnCreate = Shell.OnCreate
    Shell.OnCreate = function(self)
        OnCreate(self)
        Record(self, 'fire')
    end
    local OnImpact = Shell.OnImpact
    Shell.OnImpact = function(self, targetType, targetEntity)
        Record(self, 'impact', targetType, targetEntity)
        return OnImpact(self, targetType, targetEntity)
    end
    local OnImpactDestroy = Shell.OnImpactDestroy
    Shell.OnImpactDestroy = function(self, targetType, targetEntity)
        Record(self, 'hit', targetType, targetEntity)
        return OnImpactDestroy(self, targetType, targetEntity)
    end
    local StartPassing = Shell.StartPassing
    Shell.StartPassing = function(self)
        Record(self, 'pass')
        return StartPassing(self)
    end
    local Lodge = Shell.Lodge
    Shell.Lodge = function(self, targetType, targetEntity)
        Record(self, 'lodge', targetType, targetEntity)
        return Lodge(self, targetType, targetEntity)
    end
end
local Events = Shell.FAFTestEvents

local passed, failed = 0, 0

local function Check(name, ok, detail)
    if ok then
        passed = passed + 1
        LOG('FAFTEST PASS ' .. name)
    else
        failed = failed + 1
        WARN('FAFTEST FAIL ' .. name .. (detail ~= nil and (': ' .. tostring(detail)) or ''))
    end
end

local function Distance(x1, z1, x2, z2)
    return MathSqrt((x1 - x2) * (x1 - x2) + (z1 - z2) * (z1 - z2))
end

--- Makes the target army an enemy of yours: civilians may be set up allied or neutral, and attack orders on allied
--- units do nothing
local function MakeHostile(army)
    for index, brain in ArmyBrains do
        if brain.Name == Hostile then
            SetAlliance(army, index, 'Enemy')
            return
        end
    end
    WARN('FAFTEST emissary: this map has no ' .. Hostile)
end

--- Power for the targets' shields, near the map corner where it needs no room and nothing hits it
local function PowerHostile()
    return CreateUnitHPR('uab1301', Hostile, 20, GetSurfaceHeight(20, 20), 20, 0, 0, 0)
end

--- Checks the spots units will stand on before anything spawns. points: { x, z, under }, with `under` 'land',
--- 'water' or nil for either. Returns why the site doesn't fit, or nil
local function CheckSite(points)
    local rect = ScenarioInfo.MapData.PlayableRect or { 0, 0, ScenarioInfo.size[1], ScenarioInfo.size[2] }
    for _, point in points do
        local x, z, under = point[1], point[2], point[3]
        local where = string.format('%.0f, %.0f', x, z)
        if x < rect[1] or z < rect[2] or x > rect[3] or z > rect[4] then
            return where .. ' is outside the playable area'
        end
        local water = GetSurfaceHeight(x, z) > GetTerrainHeight(x, z)
        if under == 'land' and water then
            return where .. ' is under water'
        elseif under == 'water' and not water then
            return where .. ' is not on water'
        end
    end
end

---------------------------------------------------------------------------------------------------------------
-- A test site: the units of one case, and helpers to set it up and read what happened

local Site = {}
Site.__index = Site

local function NewSite(x, z, army)
    local site = setmetatable({ x = x, z = z, army = army, units = {}, watched = {}, health = {}, pinned = {} }, Site)
    site.emissary = site:Spawn('uab2302', army, 0, 0)
    local weapon = site.emissary:GetWeaponByLabel('MainGun')
    weapon:SetTargetingPriorities({})
    weapon:SetFiringRandomness(0)
    local bp = weapon.Blueprint
    site.damage = bp.Damage
    site.holdTicks = math.floor(10 * bp.DoTTime / (bp.DoTPulses - 1) + 0.5)
    site.events = {}
    Events[site.emissary.EntityId] = site.events
    -- attack orders on units need intel on them, and the targets are out of the Emissary's sight
    site.vision = import('/lua/ScenarioFramework.lua').CreateVisibleAreaLocation(60,
        Vector(x, 0, z + TargetDistance), 0, ArmyBrains[army])
    return site
end

--- Spawns a unit at an offset from the Emissary, optionally with more health
function Site:Spawn(bpId, army, dx, dz, maxHealth)
    local x, z = self.x + dx, self.z + dz
    local unit = CreateUnitHPR(bpId, army, x, GetSurfaceHeight(x, z), z, 0, 0, 0)
    if maxHealth then
        unit:SetMaxHealth(maxHealth)
        unit:SetHealth(unit, maxHealth)
    end
    table.insert(self.units, unit)
    return unit
end

--- Samples the health of an entity every tick from now on, under a label
function Site:Watch(label, entity)
    self.watched[label] = entity
    self.health[label] = {}
end

--- Holds a unit's shield at a health until the first hit, against its regen and recharge
function Site:Pin(unit, health)
    self.pinned[unit] = health
end

--- Waits a tick, sampling the watched entities. Sim threads run before projectiles move, so the sample of a tick is
--- from before that tick's impacts
function Site:Tick()
    local tick = GetGameTick()
    if not self:Event('hit') then
        for unit, health in self.pinned do
            if not IsDestroyed(unit) and unit.MyShield:IsUp() then
                unit.MyShield:SetHealth(unit, health)
            end
        end
    end
    for label, entity in self.watched do
        self.health[label][tick] = (not IsDestroyed(entity)) and entity:GetHealth() or 0
    end
    WaitTicks(1)
end

--- Waits until `Condition()` is true or `ticks` have passed, sampling every tick. Returns whether it became true
function Site:WaitFor(Condition, ticks)
    local deadline = GetGameTick() + ticks
    while not Condition() do
        if GetGameTick() >= deadline then
            return false
        end
        self:Tick()
    end
    return true
end

--- Waits for shields, then gives the attack order
function Site:Fire(target)
    self:WaitFor(function()
        for _, unit in self.units do
            if unit.MyShield and not unit.MyShield:IsUp() and not unit.FAFTestShieldOff then
                return false
            end
        end
        return true
    end, 50)
    IssueAttack({ self.emissary }, target)
end

--- The nth event of a kind, or nil
function Site:Event(kind, n)
    local count = 0
    for _, event in self.events do
        if event.kind == kind then
            count = count + 1
            if count == (n or 1) then
                return event
            end
        end
    end
end

--- The shots and impacts, for a case that got no hit
function Site:Describe()
    local text = 'shots fired: ' .. self:Count('fire') .. ', impacts:'
    for _, event in self.events do
        if event.kind == 'impact' then
            text = text .. string.format(' %s at tick %d (%.0f, %.0f, %.0f)', tostring(event.targetType), event.tick,
                event.x, event.y, event.z)
        end
    end
    return text
end

function Site:Count(kind)
    local count = 0
    for _, event in self.events do
        if event.kind == kind then
            count = count + 1
        end
    end
    return count
end

--- Waits for the nth hit, sampling
function Site:WaitForHit(n)
    local hit = self:WaitFor(function() return self:Event('hit', n) ~= nil end, CaseTicks)
    -- the health after the hit, for Drop
    self:WaitFor(function() return false end, 2)
    return hit
end

--- Health lost by a watched entity from the impacts of a tick
function Site:Drop(label, tick)
    local samples = self.health[label]
    local before = samples[tick] or samples[tick - 1]
    local after = samples[tick + 1] or samples[tick + 2]
    if not before or not after then
        return nil
    end
    return before - after
end

--- Checks that a drop is the weapon's damage, give or take 5%
function Site:CheckDamage(name, label, tick)
    local drop = self:Drop(label, tick)
    Check(name, drop and MathAbs(drop - self.damage) <= 0.05 * self.damage, drop)
end

--- Checks the second hit came the hold time after the first
function Site:CheckTiming(name)
    local first, second = self:Event('hit', 1), self:Event('hit', 2)
    Check(name .. ': second hit ' .. self.holdTicks .. ' ticks after the first', first and second
        and second.tick - first.tick == self.holdTicks, first and second and (second.tick - first.tick))
end

--- Destroys everything the case created, and the wrecks around it
function Site:Clear()
    Events[self.emissary.EntityId] = nil
    self.vision:Destroy()
    for _, unit in self.units do
        if not IsDestroyed(unit) then
            unit:Destroy()
        end
    end
    local found = GetReclaimablesInRect(self.x - 40, self.z - 20, self.x + 40, self.z + TargetDistance + 60)
    for _, object in found or {} do
        if IsProp(object) then
            object:Destroy()
        end
    end
end

---------------------------------------------------------------------------------------------------------------
-- Cases. Each sets up its site, fires, and checks. The target sits TargetDistance in front of the Emissary.

local D = TargetDistance

--- Pass-on checks for a shell that is let go during the hold, `freedTick` the tick it was let go
local function CheckPassOn(site, name, freedTick)
    local first, pass = site:Event('hit', 1), site:Event('pass')
    -- deaths and shield state changes can take a tick or two to reach the shell
    Check(name .. ': passes on when let go', pass and freedTick and pass.tick - freedTick <= 2,
        pass and freedTick and (pass.tick - freedTick))
    Check(name .. ': does not pass on at the first hit', pass and first and pass.tick > first.tick)
    Check(name .. ': lodges after passing on', site:Event('lodge') ~= nil)
    site:CheckTiming(name)
end

local Cases = {
    {
        name = 'ground',
        Run = function(site)
            site:Fire(Vector(site.x, GetSurfaceHeight(site.x, site.z + D), site.z + D))
            site:WaitForHit(2)
            local first, second = site:Event('hit', 1), site:Event('hit', 2)
            Check('ground: first hit on terrain', first and first.targetType == 'Terrain', first and first.targetType)
            Check('ground: second hit on terrain', second and second.targetType == 'Terrain', second and second.targetType)
            site:CheckTiming('ground')
            Check('ground: second hit where the first was', first and second
                and Distance(first.x, first.z, second.x, second.z) < 1)
            Check('ground: never passes on', site:Count('pass') == 0)
        end,
    },
    {
        name = 'unit survives',
        Run = function(site)
            local target = site:Spawn('uab1301', Hostile, 0, D, 30000)
            site:Watch('target', target)
            site:Fire(target)
            site:WaitForHit(2)
            local first, second = site:Event('hit', 1), site:Event('hit', 2)
            Check('unit survives: first hit on the unit', first and first.target == target, first and first.targetType)
            Check('unit survives: second hit on the unit', second and second.target == target, second and second.targetType)
            site:CheckTiming('unit survives')
            if first and second then
                site:CheckDamage('unit survives: first hit deals the damage', 'target', first.tick)
                site:CheckDamage('unit survives: second hit deals the damage', 'target', second.tick)
            end
            Check('unit survives: never passes on', site:Count('pass') == 0)
        end,
    },
    {
        name = 'unit dies on the first hit',
        Run = function(site)
            local target = site:Spawn('uab1301', Hostile, 0, D, 3000)
            site:Fire(target)
            site:WaitForHit(2)
            local first, pass, lodge = site:Event('hit', 1), site:Event('pass'), site:Event('lodge')
            Check('unit dies: passes on at the first hit', pass and first and pass.tick - first.tick <= 2,
                pass and first and (pass.tick - first.tick))
            Check('unit dies: lodges after passing on', lodge and lodge.target ~= target, lodge and lodge.targetType)
            site:CheckTiming('unit dies')
            local second = site:Event('hit', 2)
            Check('unit dies: second hit where it lodged', second and lodge
                and Distance(second.x, second.z, lodge.x, lodge.z) < 1)
        end,
    },
    {
        name = 'shield holds',
        Run = function(site)
            local generator = site:Spawn('uab4301', Hostile, 0, D, 30000)
            site:Watch('shield', generator.MyShield)
            site:Fire(generator)
            site:WaitForHit(2)
            local first, second = site:Event('hit', 1), site:Event('hit', 2)
            Check('shield holds: first hit on the shield', first and first.target == generator.MyShield, first and first.targetType)
            Check('shield holds: second hit on the shield', second and second.target == generator.MyShield, second and second.targetType)
            site:CheckTiming('shield holds')
            if first and second then
                site:CheckDamage('shield holds: first hit deals the damage', 'shield', first.tick)
                site:CheckDamage('shield holds: second hit deals the damage', 'shield', second.tick)
            end
            Check('shield holds: never passes on', site:Count('pass') == 0)
        end,
    },
    {
        name = 'shield collapses on the first hit',
        Run = function(site)
            local generator = site:Spawn('uab4301', Hostile, 0, D, 30000)
            site:Pin(generator, 1000)
            site:Watch('shield', generator.MyShield)
            site:Watch('generator', generator)
            site:Fire(generator)
            site:WaitForHit(2)
            local first, pass, lodge = site:Event('hit', 1), site:Event('pass'), site:Event('lodge')
            Check('shield collapses: first hit on the shield', first and first.target == generator.MyShield, first and first.targetType)
            Check('shield collapses: passes on at the first hit', pass and first and pass.tick - first.tick <= 2,
                pass and first and (pass.tick - first.tick)
                or first and ('shield health before the hit: ' .. tostring(site.health.shield[first.tick])))
            Check('shield collapses: lodges in the generator', lodge and lodge.target == generator, lodge and lodge.targetType)
            if lodge then
                Check('shield collapses: lodging deals no damage', site:Drop('generator', lodge.tick) == 0,
                    site:Drop('generator', lodge.tick))
            end
            site:CheckTiming('shield collapses')
            local second = site:Event('hit', 2)
            Check('shield collapses: second hit on the generator', second and second.target == generator, second and second.targetType)
            if second then
                site:CheckDamage('shield collapses: second hit deals the damage', 'generator', second.tick)
            end
        end,
    },
    {
        name = 'shield collapses later from other damage',
        Run = function(site)
            local generator = site:Spawn('uab4301', Hostile, 0, D, 30000)
            site:Fire(generator)
            site:WaitForHit(1)
            site:WaitFor(function() return false end, 10)
            local shield = generator.MyShield
            local freedTick = GetGameTick()
            shield:ApplyDamage(site.emissary, shield:GetHealth() + 1, Vector(0, 5, 0), 'Normal', false)
            site:WaitForHit(2)
            CheckPassOn(site, 'shield collapses later', freedTick)
        end,
    },
    {
        name = 'shield turned off',
        Run = function(site)
            local generator = site:Spawn('uab4301', Hostile, 0, D, 30000)
            site:Fire(generator)
            site:WaitForHit(1)
            site:WaitFor(function() return false end, 10)
            local freedTick = GetGameTick()
            generator.FAFTestShieldOff = true
            generator:DisableShield()
            site:WaitForHit(2)
            CheckPassOn(site, 'shield turned off', freedTick)
        end,
    },
    {
        name = 'shield generator killed',
        Run = function(site)
            local generator = site:Spawn('uab4301', Hostile, 0, D, 30000)
            site:Fire(generator)
            site:WaitForHit(1)
            site:WaitFor(function() return false end, 10)
            local freedTick = GetGameTick()
            generator:Kill()
            site:WaitForHit(2)
            CheckPassOn(site, 'shield generator killed', freedTick)
        end,
    },
    {
        name = 'held unit killed',
        Run = function(site)
            local target = site:Spawn('uab1301', Hostile, 0, D, 30000)
            site:Fire(target)
            site:WaitForHit(1)
            site:WaitFor(function() return false end, 10)
            local freedTick = GetGameTick()
            target:Kill()
            site:WaitForHit(2)
            CheckPassOn(site, 'held unit killed', freedTick)
            local second = site:Event('hit', 2)
            Check('held unit killed: second hit not on the dead unit', second and second.target ~= target)
        end,
    },
    {
        name = 'rides a moving unit',
        Run = function(site)
            local target = site:Spawn('xsl0303', Hostile, 0, D, 40000)
            site:Fire(target)
            site:WaitForHit(1)
            IssueMove({ target }, Vector(site.x + 40, GetSurfaceHeight(site.x + 40, site.z + D), site.z + D))
            site:WaitForHit(2)
            local first, second = site:Event('hit', 1), site:Event('hit', 2)
            Check('rides: first hit on the unit', first and first.target == target, first and first.targetType)
            Check('rides: second hit on the unit', second and second.target == target, second and second.targetType)
            site:CheckTiming('rides')
            Check('rides: the unit moved between the hits', first and second
                and Distance(first.x, first.z, second.x, second.z) > 3,
                first and second and Distance(first.x, first.z, second.x, second.z))
            Check('rides: second hit with the unit', second and second.tx
                and Distance(second.x, second.z, second.tx, second.tz) < 3,
                second and second.tx and Distance(second.x, second.z, second.tx, second.tz))
        end,
    },
    {
        name = 'lodges in a second shield',
        Run = function(site)
            local outer = site:Spawn('ueb4301', Hostile, 0, D, 30000)
            local inner = site:Spawn('uab4202', Hostile, 3, D, 30000)
            site:Pin(outer, 1000)
            site:Watch('outer', outer.MyShield)
            site:Watch('inner', inner.MyShield)
            site:Fire(inner)
            site:WaitForHit(2)
            local first, pass, lodge = site:Event('hit', 1), site:Event('pass'), site:Event('lodge')
            Check('second shield: first hit on the outer shield', first and first.target == outer.MyShield, first and first.targetType)
            Check('second shield: passes on at the first hit', pass and first and pass.tick - first.tick <= 2,
                pass and first and (pass.tick - first.tick)
                or first and ('outer shield health before the hit: ' .. tostring(site.health.outer[first.tick])))
            Check('second shield: lodges in the inner shield', lodge and lodge.target == inner.MyShield, lodge and lodge.targetType)
            if lodge and first and lodge.tick ~= first.tick then
                Check('second shield: lodging deals no damage', site:Drop('inner', lodge.tick) == 0, site:Drop('inner', lodge.tick))
            end
            if first then
                -- the outer shield spills a share of the hit onto the overlapping inner shield, see Shield.ApplyDamage
                LOG('FAFTEST info second shield: inner shield took ' .. tostring(site:Drop('inner', first.tick))
                    .. ' at the first hit, from the outer shield\'s overspill')
            end
            site:CheckTiming('second shield')
            local second = site:Event('hit', 2)
            Check('second shield: second hit on the inner shield', second and second.target == inner.MyShield, second and second.targetType)
            if second then
                site:CheckDamage('second shield: second hit deals the damage', 'inner', second.tick)
            end
        end,
    },
}

--- Runs every case whose name contains `filter` (all if nil), one after another, with the sim at full speed.
--- x, z: where the Emissaries stand (open, flat ground with TargetDistance + 60 free along +z). army: yours
function Run(x, z, army, filter)
    passed, failed = 0, 0
    -- the power, the Emissary, the targets and where the moving one drives to
    local problem = CheckSite({
        { x - 40, z - 15, 'land' }, { x - 30, z - 15, 'land' }, { x - 20, z - 15, 'land' }, { x, z, 'land' },
        { x, z + D, 'land' }, { x + 3, z + D, 'land' }, { x + 40, z + D, 'land' },
    })
    if problem then
        WARN('FAFTEST emissary: the site does not fit, ' .. problem)
        Sync.FAFTestEmissary = { passed = 0, failed = 0, problem = problem }
        return
    end
    MakeHostile(army)
    -- power for the Emissaries' charge, kept for the whole run
    local power = {}
    for _, dx in { -20, -30, -40 } do
        table.insert(power, CreateUnitHPR('uab1301', army, x + dx, GetSurfaceHeight(x + dx, z - 15), z - 15, 0, 0, 0))
    end
    table.insert(power, PowerHostile())
    SimConExecute('wld_RunWithTheWind 1')
    ForkThread(function()
        for _, case in Cases do
            if not filter or string.find(case.name, filter, 1, true) then
                LOG('FAFTEST case ' .. case.name)
                local site = NewSite(x, z, army)
                -- each case runs in its own thread, so that an error ends only the case: waits can't run inside pcall
                local done = false
                local thread = ForkThread(function()
                    site:WaitFor(function() return false end, 10)
                    case.Run(site)
                    done = true
                end)
                local deadline = GetGameTick() + 2 * CaseTicks
                while not done and GetGameTick() < deadline do
                    WaitTicks(1)
                end
                if not done then
                    -- so that it doesn't check on into the next case. Already dead after an error
                    pcall(KillThread, thread)
                    Check(case.name .. ': finished', false, 'timed out, or an error above')
                end
                if site:Count('hit') == 0 then
                    LOG('FAFTEST info ' .. case.name .. ': no hit. ' .. site:Describe())
                end
                site:Clear()
                WaitTicks(10)
            end
        end
        for _, unit in power do
            if not IsDestroyed(unit) then
                unit:Destroy()
            end
        end
        SimConExecute('wld_RunWithTheWind 0')
        LOG(string.format('FAFTEST emissary: %s passed, %s failed', tostring(passed), tostring(failed)))
        Sync.FAFTestEmissary = { passed = passed, failed = failed }
    end)
end

---------------------------------------------------------------------------------------------------------------
-- Visual cases, all at once in a row along +x. Each sets up its target at x, z and returns the point to drop the
-- shell on, and optionally a function to call 10 ticks after the first hit. A case can also set `site.setup`, called
-- every tick from just before the drop until the first hit. `width`: room the case needs across,
-- for the shield or else the effects (damage radius 5: the vortex reaches 6.6 out, the final rings 9)

local Visuals = {
    {
        name = 'ground',
        width = 25,
        Setup = function(site, x, z)
            return x, GetSurfaceHeight(x, z), z
        end,
    },
    {
        name = 'unit',
        width = 25,
        Setup = function(site, x, z)
            local tx, ty, tz = site:SpawnAt('uab1301', x, z, 30000):GetPositionXYZ()
            return tx, ty + 2, tz
        end,
    },
    {
        name = 'mobile',
        width = 25,
        Setup = function(site, x, z)
            local target = site:SpawnAt('xsl0303', x, z, 40000)
            local tx, ty, tz = target:GetPositionXYZ()
            return tx, ty + 2, tz, function()
                IssueMove({ target }, Vector(tx, GetSurfaceHeight(tx, tz + 30), tz + 30))
            end
        end,
    },
    {
        name = 'shield',
        width = 45, -- uab4301: 35 across
        Setup = function(site, x, z)
            local tx, ty, tz = site:SpawnAt('uab4301', x, z, 30000):GetPositionXYZ()
            return tx, ty + 5, tz
        end,
    },
    {
        name = 'breakthrough',
        width = 45,
        Setup = function(site, x, z)
            local generator = site:SpawnAt('uab4301', x, z, 30000)
            site.setup = function() generator.MyShield:SetHealth(generator, 1000) end
            local tx, ty, tz = generator:GetPositionXYZ()
            -- beside the generator, so the shell lodges in the ground under the dome
            return tx + 6, ty, tz
        end,
    },
    {
        name = 'secondshield',
        width = 54, -- ueb4301: 44 across
        Setup = function(site, x, z)
            local outer = site:SpawnAt('ueb4301', x, z, 30000)
            local inner = site:SpawnAt('uab4202', x + 3, z, 30000)
            site.setup = function() outer.MyShield:SetHealth(outer, 1000) end
            local tx, ty, tz = inner:GetPositionXYZ()
            return tx, ty + 3, tz
        end,
    },
    {
        name = 'shieldoff',
        width = 45,
        Setup = function(site, x, z)
            local generator = site:SpawnAt('uab4301', x, z, 30000)
            local tx, ty, tz = generator:GetPositionXYZ()
            return tx + 6, ty, tz, function()
                generator.FAFTestShieldOff = true
                generator:DisableShield()
            end
        end,
    },
}

local Water = {
    name = 'water',
    width = 25,
    Setup = function(site, x, z)
        return x, GetSurfaceHeight(x, z), z
    end,
}

--- Spawns a hostile unit at a point, optionally with more health
function Site:SpawnAt(bpId, x, z, maxHealth)
    return self:Spawn(bpId, Hostile, x - self.x, z - self.z, maxHealth)
end

local VisualRun = 0

--- Stops the running visual loop after its current shells
function StopVisual()
    VisualRun = VisualRun + 1
end

--- Loops the visual cases until StopVisual: all land cases in a row centred on x, z, or with `water` only the water
--- case at x, z. army: yours
function Visual(x, z, army, water)
    local cases = water and { Water } or Visuals

    -- centred on x: each case gets its width
    local total = 0
    for _, case in cases do
        total = total + case.width
    end
    local places = {}
    local left = x - total / 2
    for i, case in cases do
        places[i] = left + case.width / 2
        left = left + case.width
    end

    local points = {}
    for i, case in cases do
        local px = places[i]
        if water then
            table.insert(points, { px, z, 'water' })
        else
            -- the target, the second shield, the drop beside the dome and where the moving unit drives to
            table.insert(points, { px, z, 'land' })
            table.insert(points, { px + 6, z, 'land' })
            table.insert(points, { px, z + 30, 'land' })
        end
    end
    local problem = CheckSite(points)
    if problem then
        WARN('FAFTEST visual: the site does not fit, ' .. problem)
        return
    end
    MakeHostile(army)

    StopVisual()
    local run = VisualRun
    ForkThread(function()
        local power = PowerHostile()
        local count = 0
        while run == VisualRun do
            count = count + 1
            local site = setmetatable({ x = x, z = z, units = {} }, Site)
            local drops = {}
            for i, case in cases do
                site.setup = nil
                local tx, ty, tz, AfterFirstHit = case.Setup(site, places[i], z)
                drops[i] = { tx, ty, tz, AfterFirstHit, site.setup }
            end
            WaitTicks(15)

            -- the shells come from an Emissary that is gone in the same tick: they only need its weapon's damage
            -- data and the army. Its spot doesn't matter
            local emissary = CreateUnitHPR('uab2302', army, 0, GetSurfaceHeight(0, 0), 0, 0, 0, 0)
            local weapon = emissary:GetWeaponByLabel('MainGun')
            local shells = {}
            for i, drop in drops do
                -- from above and behind the target, flying straight at it
                local tx, ty, tz = drop[1], drop[2], drop[3]
                local sx, sy, sz = tx, ty + 30, tz - 15
                local shell = weapon:CreateProjectileForWeapon('Turret_Muzzle')
                Warp(shell, Vector(sx, sy, sz))
                local dx, dy, dz = tx - sx, ty - sy, tz - sz
                local length = MathSqrt(dx * dx + dy * dy + dz * dz)
                shell:SetBallisticAcceleration(0)
                shell:SetVelocity(40 * dx / length, 40 * dy / length, 40 * dz / length)
                shells[i] = shell
                -- as locals: a closure sees a loop variable's last value
                local AfterFirstHit, Hold = drop[4], drop[5]
                if Hold then
                    Hold()
                    ForkThread(function()
                        while not IsDestroyed(shell) and not shell.FirstImpactTick do
                            Hold()
                            WaitTicks(1)
                        end
                    end)
                end
                if AfterFirstHit then
                    ForkThread(function()
                        while not IsDestroyed(shell) and not shell.FirstImpactTick do
                            WaitTicks(1)
                        end
                        WaitTicks(10)
                        AfterFirstHit()
                    end)
                end
            end
            emissary:Destroy()
            LOG('FAFTEST visual ' .. count)

            local deadline = GetGameTick() + 200
            for _, shell in shells do
                while not IsDestroyed(shell) and GetGameTick() < deadline do
                    WaitTicks(1)
                end
            end
            -- let the explosions play out before the next round
            WaitTicks(30)
            for _, unit in site.units do
                if not IsDestroyed(unit) then
                    unit:Destroy()
                end
            end
            local found = GetReclaimablesInRect(places[1] - 30, z - 30, places[table.getn(places)] + 30, z + 50)
            for _, object in found or {} do
                if IsProp(object) then
                    object:Destroy()
                end
            end
            WaitTicks(5)
        end
        if not IsDestroyed(power) then
            power:Destroy()
        end
    end)
end
