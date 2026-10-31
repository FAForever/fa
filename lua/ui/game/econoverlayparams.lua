local uiScale = import("/lua/maui/layouthelpers.lua").GetPixelScaleFactor()

-- textures are only available for these scales
local scaleSuffix = {
    [0.8] = '_0.8x',
    [1] = '',
    [1.25] = '_1.25x',
    [1.5] = '_1.5x',
    [1.75] = '_1.75x',
    [2] = '_2.0x',
}

-- pick the texture suffix whose scale is closest to the UI scale
local econScale = 1
for available, _ in scaleSuffix do
    if math.abs(available - uiScale) < math.abs(econScale - uiScale) then
        econScale = available
    end
end
local suffix = scaleSuffix[econScale]

---@param number number
---@return integer
local function ScaleNumber(number)
    return math.floor(number * econScale)
end

EconOverlayParams = {
    positiveColor = "FF00D000",
    negativeColor = "red",
    leftTexture = import("/lua/ui/uiutil.lua").UIFile("/game/economic-overlay/econ_bmp_l" .. suffix .. ".dds"),
    midTexture = import("/lua/ui/uiutil.lua").UIFile("/game/economic-overlay/econ_bmp_m" .. suffix .. ".dds"),
    rightTexture = import("/lua/ui/uiutil.lua").UIFile("/game/economic-overlay/econ_bmp_r" .. suffix .. ".dds"),
    fontName = "Ariel",
    fontSize = ScaleNumber(9),
    energyTopOffset = ScaleNumber(13.0),
    massTopOffset = ScaleNumber(1.0),
}
