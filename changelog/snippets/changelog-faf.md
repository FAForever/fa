## Bug fixes

- (#6982) Change 3 prop normal textures from size 518x518 to 512x512 to make them compatible with BC3 texture compression and allow the FAF map editor to load everything from the ancient-earth props section.

- (#7075) Fixed veterancy health bonuses being truncated instead of rounded to the nearest whole number. Example:

  - Old HP of T2 Cybran ACU with 3 vets: 15599
  - New HP of T2 Cybran ACU with 3 vets: 15600


## Graphics

- (#7041) Fix the normals of rotated texture layers (Only affects maps that use the Terrain200 shader). 

## Other changes

- (#6473) Rework the patchnotes dialog in the lobby.
  
  This is a big internal change, which will make delivering accurate changelogs easier in the future. It also stops the game from keeping 5MB worth of changelog text loaded while you play. The button to view the changelog online now points to a new website where all the changelogs are available. This will be the new default website to read about game patches.

- (#6633) Improve documentation of the terrain type features


