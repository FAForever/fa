# Game version 3761 (27th of June, 2023)

<intro>

Jip

## Features

- (#5197, #16) Small props and trees are ignored when building

  You can now build on top of logs, bushes, cacti, (fallen) trees and tree groups. This is a quality-of-life change to prevent your ACU or your engineers from delaying your build order because there is an invisible prop (due to Level of Details (LODs)) 'blocking' your construction site. This can significantly delay the construction. Instead the before-mentioned props are destroyed when you start the construction.

  To be specific, the following props will still block your construction site:

  - Any wreck, regardless of mass value
  - Any rock, regardless of mass value
  - Any non-tree prop of significant (>11) mass value in general

  The end goal is to allow you to entirely rely on the reclaim overview to manage your expectations of whether the construction site is blocked by props.

- (#5246) Do not immediately destroy units of recalled teams

  There is now a 10 seconds delay before destroying the units of a recalled team. This delay prevents the units from being destroyed if the game would end.

- (#5247) Re-introduce a hotkey that allows you to easily filter engineers

## AI

- (#5234) Fix a bug where nuke launchers did not generate the correct threat

  They were categorized by AI as a unit with excessive surface threat, instead of economic threat. As a result the AI would essentially never attack a base with a nuke launcher in it

- (#5234) Fix a bug where mobile artillery and missile launchers did not generate the correct threat

  They were categorized by the AI as units with economic threat instead of surface threat. As a result the AI would recognize them as bulky engineers instead of something more dangerous

## Bug fixes

- (#5218) Fix a bug when trying to give a unit a veterancy of 0

  A few campaign maps did this and the bug prevented the scripts to continue

- (#5219, #5236) Fix a bug in campaign maps related to missing categories

- (#5219, #5236) Fix a bug with the unit restrictions menu related to missing categories

- (#5162) Fix shield visibility on land-only maps

- (#5245) Fix a bug where the idle animation of the Seraphim tech 2 extractor does not stop when upgrading

## Graphics

- (#5171) Add or fix existing LODs of various Aeon units

## Performance

- (#5250) Reduce the performance impact of the AA weaponry of Seraphim frigates

## Other changes

- (#5156, #5164) Add more debug utilities for the Navigational Mesh

## Contributors

- 4z0t (#16)
- BlackYps (#5162)
- Relent0r (#5234)
- Basilisk3 (#5250)
- MadMax (#5171)
- Jip (#5156, #5164, #5197, #5219, #5245, #5247)
