---
title: Changelog
layout: page
nav_order: 2
permalink: /changelog
---

# Changelog

A changelog describes the changes that are made to a project. Usually a changelog is written for developers. In FAForever the changelog is orientated towards the community. Because of that some technical details that may be relevant to developers are not in the changelog. Usually the changelog references the pull requests that are responsible. We encourage contributors to document the technical details in the description and/or conversation of a pull request.

## Changelog folder

All changelogs can be found in the [changelog](../changelog/) folder. Each game version has a separate file with the changelog notes in them. Each changelog file closely matches with a corresponding [release note](https://github.com/FAForever/fa/releases). The release note is better formatted by GitHub and we encourage you to read the release notes instead.

## Changelog snippets

We use snippets to reduce the burden on maintainers to write an accurate changelog and at the same time enable contributors to describe the changes of a pull request. A contributor is encouraged to create a snippet before a pull request is merged. All snippets reside in the [snippets folder](../changelog/snippets/). We use a [workflow](./workflows/changelog.yaml) to compile the snippets into a typical changelog file. This changelog file can then be tweaked, spell checked and be used as (intermediate) release notes.

### Format of a snippet

All current snippets can be found in the [snippets folder](../changelog/snippets/). A snippet has two relevant aspects:

- The structure of the name of the file
- The content of the file

The structure of the file name is `XXX.ABCDE.md`, where `XXX` is one of the snippet types and `ABCD` is the pull request number. The available snippet types are `fix`, `features`, `balance`, `graphics`, `ai`, `performance` or `other`. The content of a snippet is similar to a commit message. The first line is a title that starts with the relevant pull requests and a concise description of the changes, as an example: ` - (#PR1, #PR2, ...) <concise description of changes>` . The remainder of the file can be used to provide additional and more detailed information about the changes. The file should be formatted using a Markdown formatter, one example is the use of [prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode).

## Sources and inspiration

We did not come up with this approach ourselves. We took inspiration from similar solutions of projects that experienced similar problems:

- [Issue of the PrefectHQ project](https://github.com/PrefectHQ/prefect/issues/2311)
- [Towncrier](https://github.com/twisted/towncrier)
