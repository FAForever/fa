
local Shared = import('/lua/shared/NavGenerator.lua')

State = { 
    Profile = {
        TimeSetupCaches = 0,
        TimeLabelTrees = 0,
    },
    Layers = { }
}

for k, layer in Shared.Layers do
    State.Layers[layer] = {
        Trees = 0,
        Subdivisions = 0,
        PathableLeafs = 0,
        UnpathableLeafs = 0
    }
end

AddOnSyncCallback(
    function(Sync)
        if Sync.NavProfileData then
            State.Profile = Sync.NavProfileData
        end

        if Sync.NavLayerData then 
            reprsl(Sync.NavLayerData)
            Sync.State.Layers = Sync.NavLayerData
        end
    end,
    'NavGenerateState'
)
