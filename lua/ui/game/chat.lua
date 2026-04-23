--- Called by the engine when the user presses Enter outside the chat edit
--- box — the default "open chat" shortcut. Thin shim that delegates to the
--- chat controller, which picks the initial recipient from `send_type` and
--- the Shift modifier before toggling the window.
---@param modifiers? table  # {Shift, Ctrl, Alt, ...}
function ActivateChat(modifiers)
    import("/lua/ui/game/chat/ChatController.lua").ActivateChat(modifiers)
end
