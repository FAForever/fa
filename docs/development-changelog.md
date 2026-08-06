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

All changelogs can be found in the [changelog folder](https://github.com/FAForever/fa/blob/develop/docs/_posts/). Each game version has a separate file with the changelog notes in them. These files are conveniently available as [web pages](../changelog).

## Changelog snippets

We use snippets to reduce the burden on maintainers to write an accurate changelog and at the same time enable contributors to describe the changes of a pull request. A contributor is required to create a snippet before a pull request is merged. Remember that the target audience of the changelog are the players, so try to make the changelog easily understandable. All snippets reside in the [snippets folder](https://github.com/FAForever/fa/blob/develop/changelog/snippets/). We use a [workflow](https://github.com/FAForever/fa/blob/develop/.github/workflows/docs-generate-changelog.yaml) to compile the snippets into a typical changelog file. This changelog file can then be tweaked, spell checked and be used as (intermediate) release notes.

### Format of a snippet

The structure of the file name is `XXX.ABCD.md`, where `XXX` is one of the snippet types and `ABCD` is the pull request number. The available snippet types are `fix`, `features`, `balance`, `graphics`, `ai`, `performance` or `other`.

The format of a snippet depends on whether it is a [balance snippet](../development/changelog/balance-snippet) or [any other category](../development/changelog/other-snippet).

### Choosing a category

1. `graphics` is everything graphics-related.
2. `ai` is everything AI-related, for example new features that AI modders can use, or new capabilities of the AI.
3. `performance` is for changes that were made to increase the performance of the game.
4. `balance` are changes that are made to improve the balance of the game.
5. `features` is for new features that are available for the players in the game.
6. `fix` is for fixes of bugs in the game. Bugs regarding intellisense or other areas outside of the game should go into `other`.
7. `other` is for Refactors, changes for developers and modders, code annotations and the like fall into this category.

If multiple categories are fitting, use the one that appears first in this list.

## Sources and inspiration

We did not come up with this approach ourselves. We took inspiration from similar solutions of projects that experienced similar problems:

- [Issue of the PrefectHQ project](https://github.com/PrefectHQ/prefect/issues/2311)
- [Towncrier](https://github.com/twisted/towncrier)
