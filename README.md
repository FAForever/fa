
# About Forged Alliance Forever

![Impression of the game](/images/impression-a.jpg)

Forged Alliance Forever is a vibrant, community-driven [project](https://github.com/FAForever) designed to enhance the gameplay of [Supreme Commander: Forged Alliance](https://store.steampowered.com/app/9420). Our active community has developed a custom [client](https://github.com/FAForever/downlords-faf-client), [backend](https://github.com/FAForever/server) and [website](https://github.com/FAForever/website). We provide a rich gaming experience with an extensive library of community-made maps, mods and co-op scenarios. The project can be financially supported through [Patreon](https://www.patreon.com/faf).

## Getting started playing

- [Register](https://faforever.com/account/register) through our [website](https://faforever.com/) and verify through either [Steam](https://store.steampowered.com/) or [GOG](https://www.gog.com/) your ownership of a copy of Supreme Commander: Forged Alliance.
- Download the client from our [website](https://faforever.com/).
- Log in using the account you registered and host a game with AIs and/or players, queue up for matchmaker or upload your own content to our vaults for other players to enjoy.
- Engage with the community through the [forums](https://forum.faforever.com/) using the account you registered or join us on the official [Discord server](https://discord.gg/mXahVSKGVb).

## Changelog

The changelog is split across multiple files. Each file represents a release. You can find them in the [changelog](./changelog/) folder. Some changes are also described in an [alternative format](http://patchnotes.faforever.com/) that makes them easier to read for the community.

## Contributing

There are instructions [in English](setup/setup-english.md) and [in Russian](setup/setup-russian.md) to help you set up a development environment. It is important that you discuss your contributions beforehand. You can do this by making a comment on an existing issue or, if it doesn't exist yet, by opening a new issue. Not all pull requests are merged by default. It is important that the changes align with the vision of the project.

There's an [extensive guide](./setup/setup-english.md) to help you setup a debug environment. Everyone that contributes must adhere to the [rules](https://www.faforever.com/rules) and apply the [contribution guidelines](https://forum.faforever.com/topic/2051/faf-contribution-guidelines) as they discuss issues with other community members.

## Deployment

There are three branches branches that deployable and are available for players to play on. The deployment procedure is automated. Pushing commits to one of these branches is sufficient to trigger the deployment. 

- (1) `deploy/faf` is the production branch that maps to the FAF gametype.
- (2) `deploy/fafdevelop` is a development branch that maps to the FAF Develop gametype.
- (3) `deploy/fafbeta` is a development branch that maps to the FAF Beta Balance gametype.

### Deployment of a development branch

There are no requirements to a deployment to a development branch. A push of a commit is sufficient to trigger a deployment. The development branches are unaware of history. For example, A replay will always start using the last deployment. All replays that used a previous deployment when the game was played is guaranteed to desync.

### Deployment of the production branch

There are various requirements when deploying to production:

- (1) Update the game version in [mod_info.lua](/mod_info.lua) and [version.lua](/lua/version.lua).
- (2) Update the game executable. This needs to be done by a server administrator. This is only required when there are changes to the executable.
- (3) Update the changelog in [changelog.md](/changelog.md) and [changelogData.lua](/lua/ui/lobby/changelogData.lua).
- (4) Update the game version in [changelogData.lua](/lua/ui/lobby/changelogData.lua).
- (5) Create a new release with the changelog that points to a commit on the [develop]() branch
  
Specifically steps (1), (2) and (5) are required to create a functioning deployment where even replays can retrieve the proper configuration to prevent desyncs.

## Related repositories

### Campaign or co-op content

- [Campaign/co-op featured mod](https://github.com/FAForever/fa-coop)
- [Campaign/co-op maps](https://github.com/FAForever/faf-coop-maps)

### Lua plugin

 - [FA Lua intellisense extension](https://github.com/FAForever/fa-lua-vscode-extension)
 - [FA Lua intellisense langauge server](https://github.com/FAForever/fa-lua-language-server)

### Assembly patches

 - [Executable patcher](https://github.com/FAForever/FA_Patcher)
 - [Executable patches](https://github.com/FAForever/FA-Binary-Patches)
 - [Exception debugger](https://github.com/FAForever/FADeepProbe)
