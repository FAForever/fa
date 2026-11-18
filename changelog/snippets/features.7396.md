- Add an "Abandoned ACU" lobby option for what happens when a player leaves the game, replacing the hidden disconnect share options (#7396).
  - Recall (the new default, also in matchmaker games): an ally receives the player's ACU and all units. The ACU shows the player's color around its strategic icon and a countdown, and doesn't keep its holder in the game. If it survives for 30 seconds, it recalls and the ally keeps the units. If it is destroyed first, the share condition applies to the units, wherever they are.
  - Explode: the previous behavior. The ACU explodes and the share condition applies.
  - Other players now see "X has abandoned their army" instead of "X has been defeated!".

- Strategic icon mods can replace the underlay of a recalling ACU per unit by adding `AbandonedUnderlay` to an entry of `UnitIconAssignments`. The textures are named `<prefix>_<rrggbb>_rest.dds`, one per color, and the variant closest to the player's color is used (#7396).
