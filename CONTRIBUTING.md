# Contributing
---

To contribute, please fork this repository and make pull requests to the `deploy/fafdevelop` branch.

Please make sure "allow edits by maintainers" is checked. The person merging may have a few trivial edits to make before merging that would take much longer if they had to go through you first (we will not fork your pull request, commit to & merge the fork, and then close yours).

Use the normal git conventions for commit messages, with the following rules:
  - Write in the declarative mood (i.e. it should make sense when used in the sentence "When merged, this pull request will <message>")
  - Subject line shorter than 80 characters
  - No trailing period
  - For non-trivial commits, always include a commit message body, describing the change in detail
  - If there are related issues, reference them in the commit message footer

We use [git flow](http://nvie.com/posts/a-successful-git-branching-model/) for our branch conventions.

Your pull request will not be merged until reviewed and all conversation have been resolved. Please let the reviewer resolve each conversation after you process their feedback or it may end up getting unresolved again and overlooked by you. If you notice your pull request isn't progressing, check the conversation for feedback you may have missed - the reviewer will likely not take the time to remind you of unprocessed feedback or repeat previous comments. However, in the event you find yourself simply waiting on the reviewer for a long time without hearing anything, speak up - a miscommunication likely occurred and further communication is required for you to understand each other. At the very worst, you'll find that they're a busy person

## Code Contributions

For file encoding, use UTF-8 and unix-style file endings (LF only) in the repository (Set core.autocrlf).

Your contribution license should be compatible with the open-source vision of the Forged Alliance Forever community - use the MIT license if you're unsure. Note that unlicensed work is presumed to have its copyright fully protected by its author in most jurisdictions and may not be accepted.

Follow the [code style guidelines](codestyle.md) and the [annotation guidelines](annotation.md).

When possible, write a test for your contribution in (/lua/tests/) in a file starting with `test_` (Use the "luft" unit tester; see existing files for usage). This will make your contribution easier to maintain and continue to get used (In addition, if you write the test before you start on the bulk of the contribution, it'll be even easier to debug while you write it).

When making *backwards incompatible API changes*, do so with a stub function and put in a logging statement including traceback. This gives time for mod authors to change their code, as well as for us to catch any incompatibilities introduced by the change.

## Translation Contributions

This will entail a change in a file in `/loc/<LA>/strings_db.lua` (where `<LA>` is the language code). If you do not find the language you would like to translate, contact an administrator to set it up for you.

If you are an individual blessed with the ability to translate more than one language, please put the translations for each language in a separate pull request, unless the langauges are similar enough for it to make less sense to do so.

Please adhere to the [localization guidelines](loc/guidelines.md).

## Asset Contributions

TODO
