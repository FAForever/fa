---
title: Documentation
layout: page
nav_order: 5
permalink: /documentation
---

# Documentation

This document contains various tips and tricks on how to manage and update the documentation of the repository.

## Tooling

The following tooling is necessary to compile and serve the documentation website:

- [Jekyll](https://jekyllrb.com/docs/installation/)

Jekyll requires Ruby and various additional packages. The guide on their website should be sufficient to have a working Jekyll setup. There is [significant documentation](https://jekyllrb.com/docs) on how Jekyll works in general. We use the [Just the Docs](https://github.com/just-the-docs/just-the-docs) template.

In addition we recommend the following tooling:

- [Visual Studio Code](https://code.visualstudio.com/) as your interactive development environment (IDE).
- [Github Desktop](https://github.com/apps/desktop) or [Github CLI](https://git-scm.com/) as your tool to interact with Git.

## Localhost

To run the documentations website on the localhost you need a command line where the current directory is the `docs` folder. From there you run the following commands:

- `bundle install`: Similar to `npm install` if you're familiar with the Node Package Manager. Should be necessary only once. Installs all relevant packages.
- `bundle exec jekyll server --incremental`: Once completed the website should be available on your localhost. It runs the website from the `_site` folder. The website is updated automagically on every file change but it is not refreshed automagically. You'll need to refresh the page manually.
