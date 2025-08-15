---
layout: page
title: Development - Changelog
permalink: development/changelog
has_children: true
nav_order: 5
---

# Creating the Changelog

A changelog describes the changes that are made to a project. Usually a changelog is written for developers. In FAForever the changelog is orientated towards the community. Because of that some technical details that may be relevant to developers are not in the changelog. Usually the changelog references the pull requests that are responsible. We encourage contributors to document the technical details in the description and/or conversation of a pull request.

## Changelog folder

All changelogs can be found in the [changelog](../changelog/) folder. Each game version has a separate file with the changelog notes in them. Each changelog file closely matches with a corresponding [release note](https://github.com/FAForever/fa/releases). The release note is better formatted by GitHub and we encourage you to read the release notes instead.

## Changelog snippets

We use snippets to reduce the burden on maintainers to write an accurate changelog and at the same time enable contributors to describe the changes of a pull request. A contributor is required to create a snippet before a pull request is merged. Remember that the target audience of the changelog are the players, so try to make the changelog easily understandable. All snippets reside in the [snippets folder](../changelog/snippets/). We use a [workflow](./workflows/changelog.yaml) to compile the snippets into a typical changelog file. This changelog file can then be tweaked, spell checked and be used as (intermediate) release notes.

### Format of a snippet

All current snippets can be found in the [snippets folder](../changelog/snippets/).

The structure of the file name is `XXX.ABCD.md`, where `XXX` is one of the snippet types and `ABCD` is the pull request number. The available snippet types are `fix`, `features`, `balance`, `graphics`, `ai`, `performance` or `other`.

The content of a snippet is similar to a commit message. The first line is a title that starts with the relevant pull requests and a concise description of the changes, as an example: ` - (#PR1, #PR2, ...) <concise description of changes>`. Use a dot at the end of the first line. The remainder of the file can be used to provide additional and more detailed information about the changes. Remember to indent these additional lines, so they follow the indentation that gets created because of the list item of the first line. Add an empty line at the end of the file to make sure that the next snippet is separated by an empty line. You can make use of a Markdown formatter to ensure consistency, one example is the use of [prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode).

### Choosing a category

`graphics` is everything graphics related.
`ai` is everything AI related, for example new features that AI modders can use, or new capabilities of the AI.
`performance` is for changes that were made to increase the performance of the game.
`balance` are changes that are made to improve the balance of the game.
`features` is for new features that are available for the players in the game.
`fix` is for fixes of bugs in the game. Bugs regarding intellisense or other areas outside of the game should go into `other`.
`other` Refactors, changes for developers and modders, code annotations and the like fall into this category.

If multiple categories are fitting, use the one that appears first in this list.

### Example snippet



## Sources and inspiration

We did not come up with this approach ourselves. We took inspiration from similar solutions of projects that experienced similar problems:

- [Issue of the PrefectHQ project](https://github.com/PrefectHQ/prefect/issues/2311)
- [Towncrier](https://github.com/twisted/towncrier)
