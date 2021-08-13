
local Window = import("/lua/ui/imgui//modules/window.lua")

function Entrypoint(isReplay)

    -- populate the global scope
    _G.WindowConstruct = Window.WindowConstruct
    _G.WindowDeconstruct = Window.WindowDeconstruct
    _G.WindowGet = Window.WindowGet
    _G.DearWindow = true

end
