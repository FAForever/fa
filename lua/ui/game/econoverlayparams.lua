local scale = import('/lua/user/prefs.lua').GetOption('econ_overlay_scale')
local scaleSuffix = {
    [0.8] = '_0.8x',
    [1] = '',
    [1.25] = '_1.25x',
    [1.5] = '_1.5x',
    [1.75] = '_1.75x',
    [2] = '_2.0x',
}
local suffix = scaleSuffix[scale or 1] or ''
local function ScaleNumber(number)
    return math.floor(number * scale)
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