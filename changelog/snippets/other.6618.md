- (#6618) Add missing localization entries and update Traditional Chinese translations.

  [Game Options](/lua/options/options.lua):

  - <details><summary>Seperate shared LOC entries for the following 6 options:</summary>

    ```
    <LOC selectionsets0001>Steal from other control groups
    <LOC selectionsets0002>Double tap control group decay (in ms)
    <LOC ASSIST_TO_UPGRADE_MASS>Assist to upgrade mass extractors
    <LOC ASSIST_TO_UPGRADE_RADAR>Assist to upgrade radars
    <LOC structure_ringing_artillery_title>Assist to cap tech 2 artillery with power
    <LOC structure_ringing_heavy_artillery_title>Assist to cap end game artillery with power
    ```

    </details>

  - <details><summary>Fix invalid LOC entries for the following 2 options:</summary>
    
    ```
    <LOC strat_icon_scale_150>150% (may cause distortions)
    <LOC strat_icon_scale_200>200%
    ```
    
    </details>

  - <details><summary>Add LOC entries for the following 4 options:</summary>

    ```
    <LOC OPTIONS_0327>Building
    <LOC OPTIONS_0328>Misc
    <LOC OPTIONS_0329>Casting tools
    <LOC OPTIONS_EXTENDED_GRAPHICS>Extended graphics
    ```

    </details>

  [Unit creation dialog](/lua/ui/dialogs/createunit.lua):

  - <details><summary>Add LOC entries for the following 25 options:</summary>

      ```
      <LOC spawn_filter_title>Debug Spawn and Army Focus
      <LOC spawn_debug_000>Debug Options
      <LOC spawn_debug_001>Spawn menu mode:
      <LOC spawn_debug_002>Unit spawn
      <LOC spawn_debug_003>Template spawn
      <LOC spawn_debug_004>Prop spawn
      <LOC spawn_debug_005>Unit spawn settings:
      <LOC spawn_debug_006>Spawn structure tarmacs
      <LOC spawn_debug_007>Spawn mesh entites instead of units
      <LOC spawn_debug_008>Clear spawned entity meshes
      <LOC spawn_debug_009>Position camera for build icon on spawn
      <LOC spawn_debug_010>Ignore terrain blocking (disables preview)
      <LOC spawn_debug_011>Show raised platforms
      <LOC spawn_debug_012>Unit spawn filter settings:
      <LOC spawn_debug_013>Include build-menu filters
      <LOC spawn_debug_014>Include visibility filters
      <LOC spawn_debug_015>Include source filters
      <LOC spawn_debug_016>Split core game source filter
      <LOC spawn_debug_017>Filter Type by motion type
      <LOC spawn_debug_018>Filter Type by category
      <LOC spawn_debug_019>Display settings:
      <LOC spawn_debug_020>Show item icons
      <LOC spawn_debug_021>Army focus cell minimum width:
      <LOC spawn_debug_022>Dialogue transparency:
      <LOC spawn_debug_023>Show text input instead of sliders
      ```

    </details>

  [Unit Description](lua/ui/game/unitviewDetail.lua):

  - <details><summary>Add a gsub function to replace "-" with space:</summary>

      `id = id:gsub('%-', '_')`

    </details>

    - <details><summary>Add LOC entries for the following 2 options:</summary>

      ```
      <LOC uvd_cost>Charge Cost: -%d E (-%d E/s)
      <LOC uvd_missile>Missile Cost: %d M, %d E, %d BT
      ```

    </details>

  [Mod Manager](/lua/ui/lobby/ModsManager.lua):

  - <details><summary>Add LOC entries for the following 19 options:</summary>

    ```
    <LOC uiunitmanager_20>Activate Favorite Mods 
    <LOC uiunitmanager_21>Activate mods that you marked as your favorite mods. \nFor host player, left click activates your favorite UI mods and GAME mods. \nFor other players, left click activates only your favorite UI mods. \n\nFor any player, right click clears the list of your favorite mods.
    <LOC uiunitmanager_22>Toggle Mod List
    <LOC uiunitmanager_23>Toggle visibility of mod icons and descriptions in the list below
    <LOC uiunitmanager_24>Remove this mod from the list of favorite mods
    <LOC uiunitmanager_25>Add this mod to the list of favorite mods that you can later activate by clicking on the Star button located in top left corner of this dialog
    <LOC uiunitmanager_26>Toggle Favorite Mod
    <LOC uiunitmanager_27>Sort Mod List
    <LOC uiunitmanager_28>Sort mods by
    <LOC uiunitmanager_29>Status
    <LOC uiunitmanager_30>sorts mods by activation status
    <LOC uiunitmanager_31>Type
    <LOC uiunitmanager_32>sorts mods by type and name
    <LOC uiunitmanager_33>Name
    <LOC uiunitmanager_34>sorts mods by name
    <LOC uiunitmanager_35>Author
    <LOC uiunitmanager_36>sorts mods by author and name
    <LOC uiunitmanager_37>Version
    <LOC uiunitmanager_38>sorts mods by version and name
    ```

    </details>

  [Lobby](/lua/ui/lobby/lobby.lua):

  - Add LOC entriy for the following option:

    `<LOC _Briefing>Briefing`
