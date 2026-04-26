
local MauiWrapText = import("/lua/maui/text.lua").WrapText

-------------------------------------------------------------------------------
-- Shared, view-agnostic helpers for the chat tree. Each function operates
-- on a `UIChatEntry` (or related primitive) and stays free of any one
-- view's internal layout — anything that both `ChatLinesInterface` and
-- `ChatFeedInterface` (or future views) can reuse without coupling them
-- to each other lives here.

--- Maximum allowed UTF-8 character length for a chat message body. The
--- edit box enforces this on input via `Edit:SetMaxChars`; the receive
--- path uses it as a hard validator so a peer with a tampered or buggy
--- sender can't push us into laying out arbitrarily long lines.
MaxMessageLength = 200

--- 8-colour swatch palette indexed by `ChatConfigModel` colour keys
--- (`all_color`, `allies_color`, `priv_color`, `link_color`,
--- `notify_color`). The config dialog renders these as `BitmapCombo`
--- choices; `ChatLineInterface.SetHeader` looks them up at render time
--- via `entry.ColorKey` so palette changes take effect on the next
--- `CalcVisible` pass without a full rebuild.
ColorPalette = {
    'ffffffff', -- 1: white
    'ffff4242', -- 2: red
    'ffefff42', -- 3: yellow
    'ff4fff42', -- 4: green
    'ff42fff8', -- 5: cyan
    'ff424fff', -- 6: blue
    'ffff42eb', -- 7: magenta
    'ffff9f42', -- 8: orange
}

--- Wraps an entry's body text against `measureLine`'s row width and stores
--- the result as `entry.WrappedText`. The first wrapped chunk reserves
--- horizontal space for the entry's name prefix (so the body starts
--- after `Name.Right + 4`); subsequent chunks span the full body width
--- starting from the team-colour column.
---
--- Always overwrites `entry.WrappedText` — callers gate (`if not
--- entry.WrappedText then ... end`) for the cache-hit path; resize and
--- font-size changes call this directly to force a fresh wrap.
---
--- With `measureLine == nil` we degrade to a single-chunk wrap that just
--- hands back the raw text; lets callers without a measurement source
--- (an empty pool, a standalone-launched debug feed) still produce
--- something renderable instead of crashing on the missing controls.
---@param entry UIChatEntry
---@param measureLine UIChatLineInterface | nil
function WrapEntry(entry, measureLine)
    if not measureLine then
        entry.WrappedText = { entry.Text or '' }
        return
    end

    local name = entry.Name or ''
    local lines = MauiWrapText(entry.Text or '',
        function(lineIndex)
            if lineIndex == 1 then
                return measureLine.Right()
                    - (measureLine.Name.Left() + measureLine.Name:GetStringAdvance(name) + 4)
            else
                return measureLine.Right()
                    - (measureLine.Name.Left() + 4)
            end
        end,
        function(textChunk)
            return measureLine.Text:GetStringAdvance(textChunk)
        end)

    if table.empty(lines) then lines = { '' } end
    entry.WrappedText = lines
end

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
