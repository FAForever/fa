#
# Ability Definitions
#

abilities = {
    ['TargetLocation'] = {
        preferredSlot = 7,
        script = 'TargetLocation',
    },
	['Recall'] = {
        bitmapId = 'teleport',
        enabled = true,
		callBack = 'ToggleRecall',
        helpText = 'recall',
        preferredSlot = 1,
        script = 'Recall',
    },
	['CallReinforcement'] = {
        bitmapId = 'deploy',
        cursor = 'RULEUCC_Guard',
        enabled = true,
        helpText = 'specabil_reinforcement',
        MouseDecal = {
            decal = true,
            size = 1,
            texture = '/game/AreaTargetDecal/weapon_icon_small.dds',
        },
        preferredSlot = 2,
        script = 'Recall',
        usage = 'Event',
    },	
}
