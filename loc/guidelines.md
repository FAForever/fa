# General Localization guidelines
---

## String format

The game makes extensive of plain "ANSI" strings (in the `US` localization), indicating an original preference for logical flow over visual flow when made.
However, UTF-8 strings are supported and are indeed used in translations and modern typesetting.
- Be mindful that localization strings are currently processed as though each byte in it is a character; this shouldn't be a problem unless your code point happens to map to `{` or `}` in one of its code units.
This hasn't been an issue yet, but is currently being fixed nonetheless.

### Localization Directives

A localization directive can appear in the string in the format `{<dir> <argument>}` (where `<dir>` is the directive name and `<argument>` is text supplied to the directive).
The entire directive will be replaced, depending on the directive, with the following:
- `g`: the value of the key `<argument>` in the "**g**lobals" localization table.
Currently known keys are:
    - `PlayerName`: updated with the player name from the current profile
    - `LBrace` and `RBrace`: the strings `{` and `}`, respectively
    - `LT` and `GR`: the strings `<` and `>`, respectively
    - otherwise, the string `{unknown global: <argument>}`
- `i`: the current value of the localization key `<argument>`; "**i**ncludes" another localization string
    - otherwise, the string `{unknown key: <argument>}`
- `k`: the localized name of the **k**eybinding for an action-name `<argument>`
    - See `/lua/keymap/keyactions.lua` for possible actions.
    - otherwise, the string `{unknown action: <argument>}`
- otherwise, the string `{invalid directive: <dir> <argument>}`

## Changing Localization

Do not ever change the key name.

If the text meaning or key usage is completely changed in a way that would make existing translating inconsistent, do the following:
- Replace the existing translation with your new text, for each string database file that contains the key
    - For more non-trivial changes, you can leave the old translation in a comment at the end of the lines to help guide the future translator in how it was originally translated
- Make sure to update the fallback strings of all corresponding keys in the repository

If the change is purely typographical in nature, you do not need to go through the above.
The conventions you used may not exist or have a counterpart in other languages, and thus *cannot* be translated anyway.
Nevertheless, langauges closely related to English may benefit a look if you can determine how your change would affect a translation.
However, be wary that some languages have different expectations and rules on typography than English does (e.g. what to Title Case or which punctuation to use); use your best judgement.

## New Keys

Whenever you add a string to the game, consider whether it will end up presented to the player.
This includes any string formatters that use such a string.
If it does, look for an existing string in the `US` string database and use that key and text instead.
Not only may this already be translated in other languages, but reusing keys for the same text reduces clutter and future translation work.
If it does not exist, localize the string with a `<LOC key>fallback` tag, where you select `key` to be an available key in the localization database.
Then add the string you'd like to add to `/loc/US/strings_db.lua` as `key="text"` next to other similar keys.
- Due to `US` being the default language, the `fallback` string in the code shall be exactly the same as it appears in the `US` language database; this is how other languages without your new key will see it.
- Do not leave the `fallback` blank, as this makes it difficult to read.
(Except for one-word strings where the key already says the text; however, most of these should already exist in the database)
- Add all appropriate localization directives

Beyond each language database file being a valid Lua program, there should be no logic present in the file; it should be a "database" comprised only of assignments of raw strings to globals as a key/value pair.
This file is not meant to be handled extensively.
- Do not leave spaces around the assignment
- Use double quotes for strings (this also helps with apostrophes, should your language use them)
- Keep comments to a minimum. These will not be visible in other languages.

### Common strings

When writing localized text, please reuse existing keys.

Most common words can be accessed by prepending an underscore "_":

| Text   | Key                         |
|--------|-----------------------------|
| Back   | `_Back`                     |
| Cancel | `_Cancel` (avoid `_CANCEL`) |
| Close  | `_Close`                    |
| No     | `_No`                       |
| Off    | `_Off`                      |
| OK     | `_OK` (avoid `_Ok`)         |
| On     | `_On`                       |
| Yes    | `_Yes`                      |

In particular, faction names are already available.
Other items such as units names, abilities, and orders are also ready for inclusion.

## Addressing the Player

In general, breaking the fourth wall is discouraged to maintain game immersion; using "Commander" should suffice.
However, should the player need to be addressed directly:
- Never adopt gendered formulations, and respect gender-neutral writing everywhere possible
    - Median point and/or parentheses, or gendering a word twice, should be avoided to the maximum
- If appropriate, the player name can be directly addressed using the localization directive `{g PlayerName}`

## Consistency of Keywords

- Game specific keywords, like unit names and building names, should always be translated in the same manner consistently across the whole game
    - This should ideally involve title-casing, or some other visual indication that the keyword is taking on a specific meaning referencable to the gameplay, and is different from a mere combination of its individual words
- If a new keyword appears that is not translated elsewhere, it should be translated in a consistent manner regarding the other translated keywords

# Translation
---

## Compliance With the Game's UI

- Text should never overflow
- Maintain a few pixels of margin between the text and its parent element boundaries
- Use obvious abbreviations if a shorter translation is impossible, but the abbreviation should be made in a way that it is clear and obvious.
Keywords from the game should never be abbreviated.
