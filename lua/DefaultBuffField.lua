--****************************************************************************
--**
--**  File     :  /lua/DefaultBuffField.lua
--**  Author(s):  Brute51
--**
--**  Summary  :  Medium level buff field class
--**
--****************************************************************************
--**
--** READ DOCUMENTATION BEFORE USING THIS!!
--**
--****************************************************************************

local Game = import('/lua/game.lua')
local BuffField = import('/lua/sim/BuffField.lua').BuffField

DefaultBuffField = Class(BuffField) {
    FieldVisualEmitter = '/effects/emitters/seraphim_regenerative_aura_01_emit.bp',

    OnCreate = function(self)
        BuffField.OnCreate(self)
        local bp = self.Blueprint
        if bp.EnabledOnCreate then
            -- a warning of obsoleteness. delete this in v5
            WARN('BuffField: obsolete blueprint variable "EnabledOnCreate" used in '..repr(self.Name)..'. Use "InitiallyEnabled" instead.')
        end
    end,

    -- old code. Remove in CBFP v5
    Create = function(self, Owner, BuffFieldName)
        WARN('BuffField: Create() is a not used anymore. Use OnCreate() instead.')
        -- remark: OnCreate runs automatically
    end,
}