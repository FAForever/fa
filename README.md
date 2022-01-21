
FAF Gametype | FAF Develop game type | FAF Beta balance gametype
 ------------ | ------------- | -----------
[![Build Status](https://travis-ci.org/FAForever/fa.svg?branch=deploy/faf)](https://travis-ci.org/FAForever/fa) | [![Build Status](https://travis-ci.org/FAForever/fa.svg?branch=deploy/fafdevelop)](https://travis-ci.org/FAForever/fa) | [![Build Status](https://travis-ci.org/FAForever/fa.svg?branch=deploy/fafbeta)](https://travis-ci.org/FAForever/fa)

Changelog
---------

You can find the complete [changelog](changelog.md) in a separate file. There is an [alternative changelog](http://patchnotes.faforever.com/) particular for balance patches in a more user-friendly format. 

Contributing
------------

There are installation instructions [in English](setup/readme.md) and [in Russian](setup/readme-russian.md) to help you set up your development environment. It is useful to read the [contribution guidelines](CONTRIBUTING.md) before contributing. In particular commit messages are relevant.

Related repositories:
 - The [executable patcher](https://github.com/FAForever/FA_Patcher)
 - The [executable patches](https://github.com/FAForever/FA-Binary-Patches)
 - A [Lua profiler](https://github.com/FAForever/FAFProfiler)
 - A [Lua benchmark tool](https://gitlab.com/supreme-commander-forged-alliance/other/profiler)
 - A [debugger](https://github.com/FAForever/FADeepProbe) to help with exceptions 

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
