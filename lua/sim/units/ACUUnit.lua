local CommandUnit = import("/lua/sim/units/commandunit.lua").CommandUnit

---@class deathReason
---@field strings string[]
---@field damageType? DamageType
---@field category? EntityCategory
---@field useInistigatorName? boolean
---@field deathLayer? Layer

--- First conditions take priority
---@type deathReason[]
local deathReasons = {
    {
        damageType = "Deathnuke",
        category = categories.COMMAND,
        strings = {
            "%s drew with %s", "%s blasted off with %s", "%s and %s nuked it out", "%s enjoyed %s's fireworks"
            , "%s was terribly sunburnt by %s", "%s couldn't take %s's fiery love", "%s was hugged by %s"
            , "%s and %s broke up", "%s got disintegrated with %s", "%s and %s went out with a bang", "%s 1 - %s 1"
        },
        useInistigatorName = true
    },
    {
        damageType = "Normal",
        category = categories.COMMAND,
        strings = {
            "%s lost a duel with %s", "%s was pwned by %s", "%s was shift-g'd by %s", "%s ate %s's gun"
            , "%s 0 - %s 1", "%s lost %s's staring contest", "%s was farmed by %s", "%s duked it out with %s"
            , "%s lost rating to %s", "[%s was kicked by %s]", "%s got blasted by %s", "%s "
        },
        useInistigatorName = true
    },
    {
        deathLayer = 'Seabed',
        category = categories.ANTINAVY,
        strings = {
            "%s swam with the fishies", "%s swam too far from the shore", "%s was fished up", "%s couldn't find deep-sea treasure"
            , "%s was a mere landlubber", "%s - underwater explorer", "%s should've stayed in the kiddie pool", "%s pretended to be a submarine"
            , "A pirate's life was not for %s"
        },
    },
    {
        category = categories.url0402,
        strings = {
            "%s was microwaved", "%s didn't see the ML coming", "%s, conquered by Lord of Monkeys", "%s died of arachnophobia"
        },
    },
    {
        category = categories.xrl0403,
        strings = {
            "%s was snibbity snabbed :D", "%s was Mega destroyed", "%s touched the Crab's eggs"
        },
    },
    {
        category = categories.ual0401,
        strings = {
            "%s was melted", "%s made a colossal mistake", "%s was sent to another galaxy"
        },
    },
    {
        category = categories.xsl0401,
        strings = {
            "%s chickened out", "%s was roasted", "%s went to the other side", "%s insulted Ythotha's little brother"
        },
    },
    {
        category = categories.xsl0402,
        strings = {
            "%s was struck by lightning", "%s died in Boss Phase 2", "%s wasn't in the eye of the storm"
        }
    },
    {
        category = categories.NUKE,
        strings = {
            "%s needed more antinukes", "%s was annihilated by a sun", "%s - Boom, baby!", "%s - Ka-Boom!"
        },
    },
    {
        category = categories.AIR * (categories.BOMBER + categories.GROUNDATTACK),
        strings = {
            "Death from above, %s!", "%s was sniped", "%s died to lost air", "%s didn't have enough flak", "%s couldn't dodge it all"
            , '%s: "Air Player!?"', "%s left due to bad weather"
        },
    },
    {
        category = categories.AEON,
        strings = {
            "%s was shown The Way", "%s was illuminated", "%s didn't like the Princess"
        },
    },
    {
        category = categories.SERAPHIM,
        strings = {
            "%s didn't bow to the Seraphim", "%s received a supreme Seraphim honour"
        },
    },
    {
        category = categories.CYBRAN,
        strings = {
            "%s learned of Brackman's genius", "%s's destruction is now 100% certain"
        },
    },
    {
        category = categories.UEF,
        strings = {
            "%s wasn't much on tactics", "%s could not stop the UEF"
        },
    },
}

local transportDeathStrings = {
    "%s didn't stick the landing", "%s didn't fly so good", "%s was transported to the afterlife", "%s experienced turbulence", "%s should've flown Continental class"
}

local friendlyFireDeathStrings = {
    "%s was betrayed", "%s stood too close to their bombs", "%s - wrong place, wrong time", "%s had a booming economy"
}

---@class ACUUnit : CommandUnit
---@field TickCreated number
---@field CustomName string
ACUUnit = ClassUnit(CommandUnit) {
    ---@param self ACUUnit
    OnCreate = function(self)
        CommandUnit.OnCreate(self)
        self.TickCreated = GetGameTick()
    end,

    -- The "commander under attack" warnings.
    ---@param self ACUUnit
    ---@param bpShield any
    CreateShield = function(self, bpShield)
        CommandUnit.CreateShield(self, bpShield)

        local aiBrain = self:GetAIBrain()

        -- Mutate the OnDamage function for this one very special shield.
        local oldApplyDamage = self.MyShield.ApplyDamage
        self.MyShield.ApplyDamage = function(...)
            oldApplyDamage(unpack(arg))
            aiBrain:OnPlayCommanderUnderAttackVO()
        end
    end,

    ---@param self ACUUnit
    ---@param enh string
    CreateEnhancement = function(self, enh)
        CommandUnit.CreateEnhancement(self, enh)

        self:SendNotifyMessage('completed', enh)
        self:SetImmobile(false)
    end,

    ---@param self ACUUnit
    ---@param work string
    ---@return boolean
    OnWorkBegin = function(self, work)
        local legalWork = CommandUnit.OnWorkBegin(self, work)
        if not legalWork then return end

        self:SendNotifyMessage('started', work)

        -- No need to do it for AI
        self:SetImmobile(true)
        return true
    end,

    ---@param self ACUUnit
    ---@param work string
    OnWorkFail = function(self, work)
        self:SendNotifyMessage('cancelled', work)
        self:SetImmobile(false)

        CommandUnit.OnWorkFail(self, work)
    end,

    ---@param self ACUUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        CommandUnit.OnStopBeingBuilt(self, builder, layer)
        ArmyBrains[self.Army]:SetUnitStat(self.UnitId, "lowest_health", self:GetHealth())
        self.WeaponEnabled = {}
    end,

    ---@param self ACUUnit
    ---@param instigator Unit
    ---@param amount number
    ---@param vector Vector
    ---@param damageType DamageType
    DoTakeDamage = function(self, instigator, amount, vector, damageType)
        -- Handle incoming OC damage
        if damageType == 'Overcharge' then
            local wep = instigator:GetWeaponByLabel('OverCharge')
            amount = wep.Blueprint.Overcharge.commandDamage
        end

        CommandUnit.DoTakeDamage(self, instigator, amount, vector, damageType)
        local aiBrain = self:GetAIBrain()
        if aiBrain then
            aiBrain:OnPlayCommanderUnderAttackVO()
        end

        if self:GetHealth() < ArmyBrains[self.Army]:GetUnitStat(self.UnitId, "lowest_health") then
            ArmyBrains[self.Army]:SetUnitStat(self.UnitId, "lowest_health", self:GetHealth())
        end
    end,

    ---@param self ACUUnit
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        CommandUnit.OnKilled(self, instigator, type, overkillRatio)

        -- If there is a killer, and it's not me
        if instigator and instigator.Army ~= self.Army then
            local instigatorBrain = ArmyBrains[instigator.Army]

            Sync.EnforceRating = true
            WARN('ACU kill detected. Rating for ranked games is now enforced.')

            -- If we are teamkilled, filter out death explostions of allied units that were not coused by player's self destruct order
            -- Damage types:
            --     'DeathExplosion' - when normal unit is killed
            --     'Nuke' - when Paragon is killed
            --     'Deathnuke' - when ACU is killed
            if IsAlly(self.Army, instigator.Army) and
                not
                ((type == 'DeathExplosion' or type == 'Nuke' or type == 'Deathnuke') and not instigator.SelfDestructed) then
                WARN('Teamkill detected')
                Sync.Teamkill = { killTime = GetGameTimeSeconds(), instigator = instigator.Army, victim = self.Army }
            end

            -- prepare sync
            local sync = Sync
            local events = sync.Events or {}
            sync.Events = events
            local acuDestroyed = events.ACUDestroyed or {}
            events.ACUDestroyed = acuDestroyed

            -- sync the event
            table.insert(acuDestroyed, {
                Timestamp = GetGameTimeSeconds(),
                InstigatorArmy = instigator.Army,
                KilledArmy = self.Army
            })

        end
        ArmyBrains[self.Army].CommanderKilledBy = (instigator or self).Army

        self:SpawnTombstone(instigator, type)
    end,

    ---@param self ACUUnit
    ---@param instigator Unit
    ---@param damageType DamageType
    SpawnTombstone = function(self, instigator, damageType)
        local px, _, pz = self:GetPositionXYZ()
        px, pz = math.floor(px) + 0.5, math.floor(pz) + 0.5
        local orient = {0,0,0,1}

        local tombstone = CreateUnit('rip0001', self.Army, px, GetTerrainHeight(px, pz), pz, orient[1], orient[2], orient[3], orient[4], 'Land')

        local nickname = self.CustomName
        if not nickname then
            local ainames = import('/lua/ui/lobby/aiNames.lua').ainames[string.lower(self.Blueprint.FactionCategory)]
            if ainames then
                nickname = tostring(table.random(ainames))
            else
                nickname = "John Doe"
            end
        end

        local deathMessage
        if self.UseTransportDeathMessage then
            deathMessage = string.format(table.random(transportDeathStrings), nickname)
        elseif self.Army == instigator.Army then
            deathMessage = string.format(table.random(friendlyFireDeathStrings), nickname)
        else
            -- ipairs to preserve order
            for _, t in ipairs(deathReasons) do
                if (t.category and EntityCategoryContains(t.category, instigator))
                    and (not t.deathLayer or t.deathLayer == self.Layer)
                    and (not t.damageType or t.damageType == damageType)
                then
                    deathMessage = table.random(t.strings)
                    if t.useInistigatorName then
                        local customName = instigator.CustomName
                        if not customName then
                            local ainames = import('/lua/ui/lobby/aiNames.lua').ainames[string.lower(self.Blueprint.FactionCategory)]
                            if ainames then
                                customName = tostring(table.random(ainames))
                            else
                                continue
                            end
                        end
                        deathMessage = string.format(deathMessage, nickname, customName)
                    else
                        deathMessage = string.format(deathMessage, nickname)
                    end
                    break
                end
            end
            if not deathMessage then
                deathMessage = string.format('RIP %s %d - %d', nickname, self.TickCreated, GetGameTick())
            end
        end
        tombstone:SetCustomName(deathMessage)

        -- let the tombstone survive a Yolona or other in-flight damage
        ForkThread(function()
            tombstone.CanTakeDamage = false
            WaitTicks(17)
            tombstone.CanTakeDamage = true
        end)

        -- tombstone should be relatively easy to kill either by reclaiming or dealing 10000 aoe groundfire damage
        -- so it blocking things won't be an issue
    end,

    ---@param self ACUUnit
    ---@param name string
    SetCustomName = function(self, name)
        CommandUnit.SetCustomName(self, name)
        self.CustomName = name
    end,

    ---@param self ACUUnit
    ResetRightArm = function(self)
        CommandUnit.ResetRightArm(self)

        self:SetWeaponEnabledByLabel('OverCharge', false)
        self:SetWeaponEnabledByLabel('AutoOverCharge', false)

        -- Ugly hack to re-initialise auto-OC once a task finishes
        local wep = self:GetWeaponByLabel('AutoOverCharge')
        wep:SetAutoOvercharge(wep.AutoMode)
    end,

    ---@param self ACUUnit
    OnPrepareArmToBuild = function(self)
        CommandUnit.OnPrepareArmToBuild(self)
        self:SetWeaponEnabledByLabel('OverCharge', false)
        self:SetWeaponEnabledByLabel('AutoOverCharge', false)
    end,

    ---@param self ACUUnit
    GiveInitialResources = function(self)
        WaitTicks(1)
        local bp = self.Blueprint
        local aiBrain = self:GetAIBrain()
        aiBrain:GiveResource('Energy', bp.Economy.StorageEnergy)
        aiBrain:GiveResource('Mass', bp.Economy.StorageMass)
    end,

    ---@param self ACUUnit
    BuildDisable = function(self)
        while self:IsUnitState('Building') or self:IsUnitState('Enhancing') or self:IsUnitState('Upgrading') or
            self:IsUnitState('Repairing') or self:IsUnitState('Reclaiming') do
            WaitSeconds(0.5)
        end

        for label, enabled in self.WeaponEnabled do
            if enabled then
                self:SetWeaponEnabledByLabel(label, true, true)
            end
        end
    end,

    -- Store weapon status on upgrade. Ignore default and OC, which are dealt with elsewhere
    ---@param self ACUUnit
    ---@param label string
    ---@param enable boolean
    ---@param lockOut boolean
    SetWeaponEnabledByLabel = function(self, label, enable, lockOut)
        CommandUnit.SetWeaponEnabledByLabel(self, label, enable)

        -- Unless lockOut specified, updates the 'Permanent record' of whether a weapon is enabled. With it specified,
        -- the changing of the weapon on/off state is more... temporary. For example, when building something.
        if label ~= self.rightGunLabel and label ~= 'OverCharge' and label ~= 'AutoOverCharge' and not lockOut then
            self.WeaponEnabled[label] = enable
        end
    end,

    ---@param self ACUUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        CommandUnit.OnStartBuild(self, unitBeingBuilt, order)

        -- Disable any active upgrade weapons
        local fork = false
        for label, enabled in self.WeaponEnabled do
            if enabled then
                self:SetWeaponEnabledByLabel(label, false, true)
                fork = true
            end
        end

        if fork then
            self:ForkThread(self.BuildDisable)
        end
    end,
}
