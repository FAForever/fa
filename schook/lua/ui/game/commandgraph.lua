local oldOnCommandGraphShow = OnCommandGraphShow

function OnCommandGraphShow(show)
    oldOnCommandGraphShow(show)

    import('/modules/reclaim.lua').OnCommandGraphShow(show)
end
