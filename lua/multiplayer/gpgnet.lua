local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group

function CreateUI()
    if HasCommandLineArg("/syncreplay") and HasCommandLineArg("/gpgnet") then
        import("/lua/ui/uiutil.lua").QuickDialog(GetFrame(0), "Connection failed to\n" .. GetCommandLineArg('/gpgnet',1)[1], "Exit", function() ExitApplication() end)
    else
        local mainFrame = GetFrame(0)
        local mainGroup = Group(mainFrame, "gpgnetgroup")
        LayoutHelpers.FillParentFixedBorder(mainGroup, mainFrame, 20)
    end
end

