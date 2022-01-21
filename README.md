
FAF Gametype | FAF Develop game type | FAF Beta balance gametype
 ------------ | ------------- | -----------
[![Build](https://github.com/FAForever/fa/actions/workflows/build.yaml/badge.svg?branch=deploy%2Ffaf)](https://github.com/FAForever/fa/actions/workflows/build.yaml) | [![Build](https://github.com/FAForever/fa/actions/workflows/build.yaml/badge.svg?branch=deploy%2Ffafdevelop)](https://github.com/FAForever/fa/actions/workflows/build.yaml) | [![Build](https://github.com/FAForever/fa/actions/workflows/build.yaml/badge.svg?branch=deploy%2Ffafbeta)](https://github.com/FAForever/fa/actions/workflows/build.yaml)

About Forged Alliance Forever
-----------------------------

![Impression of the game](/images/impression-a.jpg)

Forged Alliance Forever is a community-driven project designed to facilitate online play for Supreme Commander: Forged Alliance. Together we are a thriving community with a self-made [client](https://github.com/FAForever/downlords-faf-client), [backend](https://github.com/FAForever/server) and [website](https://github.com/FAForever/website). As an example we make an extensive library of community made maps, mods and co-op scenarios easily accessible and introduced a rating system based on [TrueSkill](https://www.microsoft.com/en-us/research/project/trueskill-ranking-system/) to provide a competitive environment through 1 vs 1, 2 vs 2 and 4 vs 4 matchmaking. 

You can download the client through our [website](https://faforever.com/). In order to registrate you'll need to sync your account with Steam to proof you have a copy of [Supreme Commander: Forged Aliance](https://store.steampowered.com/app/9420/Supreme_Commander_Forged_Alliance/). You can get in touch with the community through the [forums](https://forum.faforever.com/) and the official [Discord server](https://discord.gg/mXahVSKGVb). The developers environment can be found on [Zulip](https://zulip.com/) - you can be granted access by the admin of this repository.

About this repository
---------------------

This repository represents the updates to the Lua side of the game. Examples are balance changes, performance improvements and the introduction of additional features to the game. The repository mimics the organisation of the base game. A quick reference guide:

Folder          | Description
--------------- | -----------
`effects`       | Various blueprints, textures and meshes of effects and various HLSL shaders that are used to render the game
`engine*`       | Extensive engine documentation: all objects and their functions are documented
`env`           | Various props, decals, splats, stratum layer and environmental effects
`etc*`          | Legacy - a rudimentary implementation of versioning control 
`loc`           | Localization files for the game, see the translation guidelines
`lua`           | Various lua files that represent the game and its interactions. It describes all the behavior outside of the simulation
`meshes`        | Various meshes that do not belong to props, units or projectiles. An example is the world border
`projectiles`   | Various blueprint files, textures and meshes of projectiles
`props`         | Various blueprint files, textures and meshes of props
`schook`        | Legacy - the *s*upreme *c*ommander *h*ook folder that was used due to licensing issues
`testmaps*`     | Various test maps. As an example the benchmark map that shipped with the game
`tests*`        | Unit tests that run on various engine-oblivion functions. An example is the testing of string operations
`textures`      | Various textures used by the engine (as fallback) or by the UI
`units`         | Various blueprint files, textures and meshes of units

These folders are not complete. Files that are unchanged are retrieved from the base game. Folders with an asterisk (*) are not shipped to the user with the client. See the installation instructions in the contribution section for more information.

Repositories that are directly related to the game:
 - A [Lua profiler](https://github.com/FAForever/FAFProfiler)
 - A [Lua benchmark tool](https://gitlab.com/supreme-commander-forged-alliance/other/profiler)
 - The [executable patcher](https://github.com/FAForever/FA_Patcher)
 - The [executable patches](https://github.com/FAForever/FA-Binary-Patches)
 - A [debugger](https://github.com/FAForever/FADeepProbe) to help with exceptions 

Changelog
---------

You can find the complete [changelog](changelog.md) in a separate file. There is an [alternative changelog](http://patchnotes.faforever.com/) particular for balance patches in a more user-friendly format. 

Contributing
------------

There are installation instructions [in English](setup/readme.md) and [in Russian](setup/readme-russian.md) to help you set up your development environment. It is useful to read the [contribution guidelines](CONTRIBUTING.md) before contributing. In particular commit messages are relevant.

Translation guidelines
----------------------

The translation of both the game and the faf patch should be written in the way that they follow those guidelines. 
This goes for both future and past work on the SCFA translation and for all languages.

1) *Compliance with the game's UI*
- Text should never overflow from anywhere
- As much as possible, try to keep a few pixels of margin between the text and its parent element boundaries
- Use obvious abbreviations if a shorter translation is impossible, but the abbreviation should be made in a way that it is clear and obvious. Keywords from the game should never be abbreviated.

2) *Gender-neutral writing*
- The translation should never adopt gendered formulations when addressing the player directly, and should respect gender-neutral writing everywhere possible
- Median point and/or parentheses, or gendering a word twice, should be avoided to the maximum.

3) *Consistency of keywords*
- Game specific keywords, like unit names and building names, should always be translated in the same manner consistently across the whole game.
- If a new keyword appears, that is not translated elsewhere, it should be translated in a consistent manner regarding the other translated keywords.
