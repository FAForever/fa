
---@alias CommandCap
---| "RULEUCC_Move"
---| "RULEUCC_Stop"
---| "RULEUCC_Attack"
---| "RULEUCC_Guard"
---| "RULEUCC_Patrol"
---| "RULEUCC_RetaliateToggle"
---| "RULEUCC_Repair"
---| "RULEUCC_Capture"
---| "RULEUCC_Transport"
---| "RULEUCC_CallTransport"
---| "RULEUCC_Nuke"
---| "RULEUCC_Tactical"
---| "RULEUCC_Teleport"
---| "RULEUCC_Ferry"
---| "RULEUCC_SiloBuildTactical"
---| "RULEUCC_SiloBuildNuke"
---| "RULEUCC_Sacrifice"
---| "RULEUCC_Pause"
---| "RULEUCC_Overcharge"
---| "RULEUCC_Dive"
---| "RULEUCC_Reclaim"
---| "RULEUCC_SpecialAction"
---| "RULEUCC_Dock"
---| "RULEUCC_Script"
---| "RULEUCC_Invalid"

---@alias ToggleCap
---| "RULEUTC_ShieldToggle"
---| "RULEUTC_WeaponToggle"
---| "RULEUTC_JammingToggle"
---| "RULEUTC_IntelToggle"
---| "RULEUTC_ProductionToggle"
---| "RULEUTC_StealthToggle"
---| "RULEUTC_GenericToggle"
---| "RULEUTC_SpecialToggle"
---| "RULEUTC_CloakToggle"

---@alias UnitMotionType
---| "RULEUMT_None"
---| "RULEUMT_Land"
---| "RULEUMT_Air"
---| "RULEUMT_Water"
---| "RULEUMT_Biped"
---| "RULEUMT_SurfacingSub"
---| "RULEUMT_Amphibious"
---| "RULEUMT_Hover"
---| "RULEUMT_AmphibiousFloating"
---| "RULEUMT_Special"

---@alias UnitBuildRestriction
---| "RULEUBR_None"
---| "RULEUBR_Bridge"
---| "RULEUBR_OnMassDeposit"
---| "RULEUBR_OnHydrocarbonDeposit"

---@alias WeaponBallisticArc
---| "RULEUBA_None"
---| "RULEUBA_LowArc"
---| "RULEUBA_HighArc"

---@alias WeaponTargetType
---| "RULEWTT_Unit"
---| "RULEWTT_Projectile"
---| "RULEWTT_Prop"

--- the rest are not hardcoded into the engine

---@alias UnitClassification
---| 'RULEUC_Commander'
---| 'RULEUC_CounterMeasure'
---| 'RULEUC_Engineer'
---| 'RULEUC_Factory
---| 'RULEUC_MilitaryAircraft'
---| 'RULEUC_MilitaryShip'
---| 'RULEUC_MilitarySub'
---| 'RULEUC_MilitaryVehicle'
---| 'RULEUC_MiscSupport'
---| 'RULEUC_Resource'
---| 'RULEUC_Sensor'
---| 'RULEUC_Weapon'

---@alias UnitTechLevel
---| 'RULEUTL_Basic'
---| 'RULEUTL_Advanced'
---| 'RULEUTL_Secret'
---| 'RULEUTL_Experimental'
-- never implemented
---| 'RULEUTL_Munition'
