
-- upvalue for performance
local MathClamp = math.clamp

--- Adds in a ratio chart that uses the entire width available.
-- @param data The data for the ratio chart. Format is { { value = double, color = string }, ... }.
-- @param dividerWidth the width of the dividers between data points, defaults to 2.
function RatioChart(window, data, dividerWidth)

    dividerWidth = dividerWidth or 2

    -- compute total value
    local total = 0
    local numberOfDividers = -1
    for k, entry in data do 
        total = total + entry.value

        if entry.value > 0 then 
            numberOfDividers = numberOfDividers + 1
        end
    end

    local width = window.main.Right() - window.main.Left() - 2 * window.outline - dividerWidth * numberOfDividers

    -- no values set, default
    if total == 0 then 
        -- create a bitmap that stretches
        local bitmap = window:AllocateBitmap("ffffffff")

        -- position it
        LayoutHelpers.AtLeftTopIn(bitmap, window.main, window.outline, window.offset)

        -- scale it
        bitmap.Left:Set( function() return window.main.Left() + window.outline end )
        bitmap.Right:Set( function() return window.main.Right() - window.outline end )
        bitmap.Height:Set(5)
    else 
        -- position the bitmaps that make up the chart
        local bitmapPrev = false
        for k, entry in data do 
            if entry.value > 0 then 
                local bitmap = window:AllocateBitmap(entry.color)

                -- determine bitmap location
                -- fine-tune bitmap location

                if bitmapPrev then 
                    -- lock to previous bitmap
                    LayoutHelpers.RightOf(bitmap, bitmapPrev, RatioChartDividerWidth)

                    -- add small black divider
                    local divider = window:AllocateBitmap("ff000000")
                    LayoutHelpers.RightOf(divider, bitmapPrev, 0)
                    divider.Right:Set(function() return bitmap.Left() end)
                    divider.Height:Set(5)
                else 
                    -- lock to main window
                    LayoutHelpers.AtLeftTopIn(bitmap, window.main, window.outline, window.offset)
                end

                -- determine width (todo: make this more dynamic?)
                local bitmapWidth = (entry.value / total) * width
                bitmap.Right:Set(function() return bitmap.Left() + bitmapWidth end)
                bitmap.Height:Set(5)

                -- keep track of internal state
                bitmapPrev = bitmap
            end
        end
    end

    -- update internal state
    window:UpdateOffset(7)
end

--- Constructs a progress bar computed as current / max, capped at 0.0 and 1.0. Uses the entire width available.
-- @param current The current value.
-- @param max The maximum value.
function ProgressBar(window, identifier, current, max)

    if window:HasSufficientSpace(10) then 
        local background = window:AllocateBitmap("ff000000")
        LayoutHelpers.AtLeftTopIn(background, window.main, window.outline, window.offset + 3)

        local progress = window:AllocateBitmap("ffffffff")
        LayoutHelpers.AtLeftTopIn(progress, window.main, window.outline, window.offset + 3)
        progress.Right:Set(function() return background.Left() + MathClamp(current / max, 0.0, 1.0) * (background.Right() - background.Left()) end )
    end

    window:UpdateOffset(10)
end