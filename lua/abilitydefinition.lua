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
}
