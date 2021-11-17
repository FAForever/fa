local oldOnCommandGraphShow = OnCommandGraphShow

function OnCommandGraphShow(show)
    oldOnCommandGraphShow(show)

    import('/lua/ui/game/reclaim.lua').OnShow(show)
end
