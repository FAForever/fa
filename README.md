
FAF Gametype | FAF Develop game type | FAF Beta balance gametype
 ------------ | ------------- | -----------
[![Build](https://github.com/FAForever/fa/actions/workflows/build.yaml/badge.svg?branch=deploy%2Ffaf)](https://github.com/FAForever/fa/actions/workflows/build.yaml) | [![Build](https://github.com/FAForever/fa/actions/workflows/build.yaml/badge.svg?branch=deploy%2Ffafdevelop)](https://github.com/FAForever/fa/actions/workflows/build.yaml) | [![Build](https://github.com/FAForever/fa/actions/workflows/build.yaml/badge.svg?branch=deploy%2Ffafbeta)](https://github.com/FAForever/fa/actions/workflows/build.yaml)

Read this in other languages: [English](README.md), [Russian](README-russian.md)

About Forged Alliance Forever
-----------------------------

![Impression of the game](/images/impression-a.jpg)

Forged Alliance Forever is a community-driven [project](https://github.com/FAForever) designed to facilitate online play for Supreme Commander: Forged Alliance. We are a thriving community with a self-made [client](https://github.com/FAForever/downlords-faf-client), [backend](https://github.com/FAForever/server) and [website](https://github.com/FAForever/website). We have an extensive library of community made maps, mods and co-op scenarios. We introduced a rating system based on [TrueSkill](https://www.microsoft.com/en-us/research/project/trueskill-ranking-system/) to provide a competitive environment with automated matchmaking. To see all that we have added it is best to experience it yourself by playing the game through the client.

You can download the client on our [website](https://faforever.com/). In order to play you will need to sync your account with Steam to prove you own a copy of [Supreme Commander: Forged Aliance](https://store.steampowered.com/app/9420/Supreme_Commander_Forged_Alliance/). You can get in touch with the community through the [forums](https://forum.faforever.com/) and the official [Discord server](https://discord.gg/mXahVSKGVb). The developers chat can be found on [Zulip](https://zulip.com/) - you can ask for access from the admin of this repository. The project is kept alive by donations to our [Patreon](https://www.patreon.com/faf).

About this repository
---------------------

This repository contains the changes to the Lua side of the game, such as balance changes, performance improvements, and additional features. The repository mimics the organization of the base game. A quick reference guide:

Folder          | Description
--------------- | -----------
`effects`       | Blueprints, textures and meshes of effects and HLSL shaders that are used to render the game
`engine*`       | Engine documentation: all objects and their functions are documented
`env`           | Props, decals, splats, stratum layer and environmental effects
`etc*`          | Legacy - a rudimentary implementation of versioning control 
`loc`           | Localization files for the game, see the translation guidelines
`lua`           | Lua files that control all the behavior outside of the physics simulation
`meshes`        | Meshes that do not belong to props, units or projectiles. E.g. the world border
`projectiles`   | Blueprint files, textures and meshes of projectiles
`props`         | Blueprint files, textures and meshes of props
`schook`        | Legacy - the **s**upreme **c**ommander **hook** folder that was used due to licensing issues
`testmaps*`     | Test maps. E.g. the benchmark map shipped with the game
`tests*`        | Unit tests that run on engine-oblivion functions. E.g. Testing string operations
`textures`      | Textures used by the engine (as fallback) and UI
`units`         | Blueprint files, textures and meshes of units

Files that are unchanged are retrieved from the base game. Folders with an asterisk (*) are not shipped to the user with the client. See the installation instructions in the contribution section for more information.

Repositories that are directly related to the game:
 - A [Lua profiler](https://github.com/FAForever/FAFProfiler)
 - A [Lua benchmark tool](https://gitlab.com/supreme-commander-forged-alliance/other/profiler)
 - The [executable patcher](https://github.com/FAForever/FA_Patcher)
 - The [executable patches](https://github.com/FAForever/FA-Binary-Patches)
 - A [debugger](https://github.com/FAForever/FADeepProbe) to help with exceptions 

Changelog
---------

Here is the complete [changelog](changelog.md). There is an [alternative changelog](http://patchnotes.faforever.com/) for balance patches in a user-friendly format. 

Contributing
------------

There are instructions [in English](setup/setup-english.md) and [in Russian](setup/setup-russian.md) to help you set up a development environment. Please read the [contribution guidelines](CONTRIBUTING.md) and the [translation guidelines](loc/guidelines.md) prior to your first PR.
