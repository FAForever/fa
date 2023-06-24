# Game version 3758 (24th of June, 2023)



With appreciation towards all the contributors that made this patch possible,

Jip

## Features

- (#3823) Improve the auto-balance feature by shuffling the pairs of players

- (#4997) Add a hotkey to select the nearest idle tech 1 engineer

- (#5040) Docked engineering drones are now ignored by anti-air weapons

- (#5134) The recall feature now requires teams of three (remaining alive) players to all agree on a recall

  We received complaints of people being recalled in the recently introduced 3v3 matchmaker without their consent. The recall feature was implemented when this matchmaker queue did not exist yet. As such we adjust the threshold slightly to prevent the negative aspects in the matchmaker while still allowing you to recall without the complete consent of a team in large team games

- (#5133) Personal shields now remain enabled in transports

  This behavior does not apply to bubble shields. This prevents the recharge cycle from being reset moving units around in transports. This specifically applies to ACUs with a personal shield enhancement

## Bug fixes

- (#4820) Fix 'OnGiven' callbacks not working properly, most notable in various campaign maps

- (#4824) Fix the teleport delay of ACUs being too short due to a bug. They are now 25 seconds again

- (#4774) Fix variables being in global scope while they should be in the local scope

- (#4862) Fix a bug where stationary launchers would end up launching missiles into the terrain

- (#4863) Fix a bug where states were unable to call their base class

- (#4867, #15) Fix a bug where missile progression was not transferred when gifting a unit building a missile

- (#4869) Fix a bug where tarmacs of structures would be duplicated when transferring a structure

- (#4904) Fix a bug where the Cybran tech 1 land scout can gain veterancy

- (#4877) Fix blocking of sound banks falsely identified as duplications

- (#4928) Fix a rare bug with the veterancy system that would prevent experience distribution

- (#5027) Fix a bug where the Quantum Optics Facility was being self-conscious, refusing to be turned off

- (#5028) Fix a bug where engineering drones (of the UEF) would be ignored by anti-air weapons

- (#5034, #15) Fix a bug where adjacency would not apply immediately to units that are building a missile

- (#5089) Fix a bug where the team color options window can have multiple instances

- (#5092) Fix a bug where civilians would sometimes not be revealed

- (#5092, #5130) Fix a bug where the game would adjust alliances with civilians after the game has started

  Most notable on scripted maps that adjust the alliance with civilians to suit the need of the map

- (#5123) Fix a bug where the 'OnUnitKilled' callback did not trigger

  Most notable on the 'Zone control' maps that relied on this callback to provide credits for destroying other units

- (#5131) Fix a bug where projectiles would have no launcher defined

- (#5136) Fix a bug where vision markers would not align with the terrain

  This does not impact your intel, it fixes a visual artifact

## AI

This update addresses several long-standing issues that affected the custom AI that FAF introduces. Further developments and improvements to AI will remain our focus in future updates.

Additionally, we would like to remind people that there are various mods that provide different AI experiences. We can highly recommend you download them from the vault and give them a spin too.

A short list of AIs we recommend at this point:

- M27: made by Maudlin
- RNGAI, as made by Relent0r
- Sorian Edit, as made by Marlo
- Uveso AI, as made by Uveso
- Dilli Dally, as made by Softles
- Swarm AI, as made by Azraeel

And not to forget the AI that ships with the Total Annihilation mod that is maintained by Dragun.

### Improved AI framework

Github references: #4693, #4858, #4898, #4923, #4921, #4961, #4901, #4970, #4971, #4872, #5008, #5009, #5072, #5068, #5071, #5087, #5084, #5101, #5099, #4879, #5141, #5139

Before this patch, there was no 'natural' approach to creating an AI that would be entirely separate from all the other AIs. It wasn't uncommon for AIs to be (temporarily) incompatible because of this. With this new AI framework, you can create a new AI that is guaranteed to be entirely separate from other AI instances.

As a consequence of this, all AI mods need to update how they set up their AI. We informed them of this months ago and helped them with these changes throughout June and we expect to see quick updates right after the patch of the AI mods that are still actively maintained.

One notable change is the integration done by Relent0r of the transport logic of the LOUD AI that is developed by Sprouto. Our gratitude towards Sprouto for turning the transport logic into a module and the willingness to share that with us

### Improved Adaptive AI

Github references: #4825, #4836, #4849, #4832, #4880, #4888, #4859

With this patch, the first notable improvements specifically the adaptive AI are in! It can by no means compete with AIs such as M27, but at least the AI won't bug out as often as it used to. This represents the first step in the right direction where a lot of time was put into creating a more consistent foundation.

### Reclaim grid

Github references: #4811, #4819, #4825, #4832, #4861, #4919

The reclaim grid represents an abstract, highly efficient data structure that the AI can use to make more informed decisions based on reclaim values. Includes a UI window to visualize the data structure

### Presence grid

Github references: #4930

The presence grid represents an abstract, efficient data structure that the AI can use to make more informed decisions based on what area of the map the AI thinks it controls. It divides the map into sections that are considered 'allied', 'contested' or 'hostile' while taking into account the path ability of the map. Includes a UI window to visualize the data structure

### Navigational mesh

Github references: #4589, #4874, #4876, #4909, #4899, #4918, #4922, #4919, #4925, #4929, #5023, #5031, #5032, #4879

## Graphics

- (#4826) Improve the fidelity of debris of units being destroyed

- (#4828) Improve the quality of the explosions of units

- (#4881) Enable all props (rocks, trees) to cast and receive shadows

- (#4914) Add a bloom intensity slider to the graphics settings

- (#4915) Reduce decal flickering on maps with noisy heightmaps

  A note to people that create maps: this engine is not built for sharp edges and in general noisy-like terrain. It doesn't just hurt gameplay but it can also introduce various visual artifacts

- (#4995) Fix an inconsistency when the effects of the Seraphim regeneration field are applied to underwater units

- (#4977) Improve the death animations of the Colossus, Spiderbot, Megalith and the Fatboy

- (#5033) Death weapons can now knock over trees

- (#5066, #5079) Add the impact effect of the Wasp

### Physics-based rendering (PBR)

Github references: #4738, #4737, #4870, #4963, #4999, #5004

We started the path toward physics-based shaders in the first developer iteration of 2023. In this second iteration, we continue making preparations and improvements to be able to release the full potential of what this game can look like visually.

One notable change is the introduction of a texture channel that was missing for the majority of the Cybran units. As a result, Cybran feels less bland and bits that represent lights now also appear to emit light accordingly.

### Adjustments to water

Github references: #4900, #4931, #4895, ##4896, #4964, #5005

Over time various visual artifacts related to water were introduced by FAF. Thanks to BlackYps we did not only tackle those inconsistencies but also improved the fidelity of the water in general. Units now really feel submerged in water, especially noticeable for large units (wrecks).

### Terrain shaders

Github references: #4902, #4972

We've learned a lot while working on the physics-based shaders for units. Empowered with that knowledge we'll also be tackling the terrain shaders. The direction is not yet set in stone but the first improvements are in that allow map authors to add map-wide normals and map-wide shadows that are part of the rendering pipeline of the terrain, instead of 'plastered' on top afterward!

## Performance

- (#4801) Reduce the overhead of the economy status bar

- (#4810) Improve the performance of LazyVars by reducing table trashing

- (#4831, #4835) Improve performance of shield effects by reducing table trashing

- (#4624) Improve the performance of projectiles by reducing table trashing

- (#4848) Improve performance of `table.getsize`, `table.empty` and `table.getn` with assembly alternatives

  One notable change is that these functions now expect a table, as suggested by it being a table function

- (#4853) Improve performance of the builder manager of AIs

- (#5021) Further sanitize the LODs of units, props and tarmacs

  In the first development iteration, we introduced a blueprint procedure to allow us to tweak the Level of Detail (LOD) of all units and props in the game. The initial parameters were too optimistic and traded in average unnecessary detail for quite a dip in performance on weaker systems

- (#5124, #5132) Improve performance by prefetching assets that the game would otherwise trash again and again

  To reduce the memory footprint various assets are only temporarily allocated. A common example is a unit animation. When a unit starts an animation the asset is loaded and interpreted from disk. When all animation instances are destroyed the asset is removed from memory again. Each time the asset is retrieved it involves a disk operation, and disk operations are expensive

  We've experimented with prefetching before but this time is different. We found a way to see exactly what the engine is doing. As a result, we know what assets are constantly being trashed, just to load them again not long after. In a fifteen-minute replay, some assets could be reloaded up to 50 times, which is rather excessive.

  With that information available we now apply targeted prefetching: we prefetch all assets surrounding projectiles, effects and animations.

## Other

- (#4787) Remove generated indices in AI tables

- (#4698) Improve the wording of the recall feature

- (#4654, #4643, #4847, #4651, #4651, #4850, #4865, #4652, #4655, #4968, #4868, #4993, #4998) Tidy up various scripts

- (#4885) Fix an inconsistency where the construction menu of the Megalith had a different order of units than the land factory

- (#4912) Fix an inconsistency with the strategic icons applied to Cybran shields

- (#4973) Introduce a hotkey to store a camera position across games, useful for taking a screenshot with exactly the same angle

- (#4994) Removal of the following hotkeys:

  - Recheck targets of weapons of selected units
  - Filter the selection to the most advanced engineer, all other engineers assist that engineer

  The latter didn't fit in with the idea of automation. Instead, you can do this manually by using the selection subgroups functionality

- (#4960) Introduce extensive documentation on how mods work in FAF

- (#5024) Add various anti-cheat guards for UI callbacks

## Mod incompatibility

There appears to be an issue with the UI mod 'Supreme Economy v2.3'. We've notified the maintainer.

## Contributors

- BlackYps (#4737, #4738, #4881, ##4896, #4895, #4931 #4900, #4902, #4964, #4963, #5005, #5004, #4972)
- 4z0t (#4787, #4820)
- Jip (#4801, #4811, #4819, #4824, #4835, #4825, #4836, #4693, #4624, #4848, #4847, #4846, #4853, #4861, #4862, #4863, #4867, #4589, #4869, #4874, #4876, #4858, #4898, #4909, #4899, #4914, #4915, #4918, #4922, #4921, #4919, #4925, #4927, #4877, #4928, #4928, #4929, #4902, #4942, #4930, #4961, #4901, #4970, #4973, #4992, #4993, #4998, #4994, #5008, #5009, #5021, #5023, #5026, #5028, #5031, #5032, #5034, #5033, #5040, #5066, #5079, #5024, #5107, #5092, #5123, #5099, #5130, #5124, #5131, #5132, #5135, #5141)
- Relentor (#4811, #4774, #4849, #4832, #4880, #4888, #4971, #4872, #5072, #5068, #5071, #5087, #5084, #5101, #5099, #4879, #5139)
- Hdt80bro (#4698, #4960, #5089)
- Scarress (#4831)
- Rowey (#4654, #4643, #4651, #4850, #4865, #4904, #4912, #4652, #4655, #4968, #4868)
- KionX (#4848)
- Penguin (#3823)
- Strogo (#15)
- MadMax (#4885)
- Evildrew (#4885)
