---
title: Deployment
layout: page
nav_order: 3
permalink: /deploy
---

# Deployment

In this repository we can deploy to three different environments:

- `deploy/faf` - the `FAF` game type. This is the default release branch and is used by matchmaker
- `deploy/fafbeta` - the `FAF Beta Balance` game type. This branch only contains balance changes and bug fixes.
- `deploy/fafdevelop` - the `FAF Develop` game type. This branch contains all current changes that are in development.

All three branches originate from the `develop` branch, which is the default branch of the remote on Github. Pushing commits towards any of the deployment branches is sufficient to trigger a deployment to the given game type.

## Deployment procedures for the FAF game type

The following (manual) steps are relevant to create a valid deployment to the FAF game type.

- (1) Update the game version in [mod_info.lua](https://github.com/FAForever/fa/blob/c36404675c7a95cda20fe867d78bd1c01c7df103/mod_info.lua) and [version.lua](https://github.com/FAForever/fa/blob/c36404675c7a95cda20fe867d78bd1c01c7df103/lua/version.lua).
- (2) Update the game executable. This needs to be done by a server administrator. This is only required when there are changes to the executable.
- (3) Update the changelog in [changelog.md](/changelog) and [changelogData.lua](https://github.com/FAForever/fa/blob/c36404675c7a95cda20fe867d78bd1c01c7df103/lua/ui/lobby/changelogData.lua).
- (4) Update the game version in [changelogData.lua](https://github.com/FAForever/fa/blob/c36404675c7a95cda20fe867d78bd1c01c7df103/lua/ui/lobby/changelogData.lua).

## Automated deployments

There are three workflows to help with deployment:

- [FAF game type](https://github.com/FAForever/fa/blob/develop/.github/workflows/deploy-faf.yaml)
- [FAF Beta Balance game type](https://github.com/FAForever/fa/blob/develop/.github/workflows/deploy-faf.yaml)
- [FAF Develop game type](https://github.com/FAForever/fa/blob/develop/.github/workflows/deploy-faf.yaml)

The workflows for Beta Balance and Develop trigger periodically. You can review when by evaluating the [cron expression](https://crontab.cronhub.io/). The [API of FAForever](https://github.com/FAForever/faf-java-api/blob/develop/src/main/java/com/faforever/api/deployment/GitHubDeploymentService.java) registers the push to a deployment branch via a webhook. The server creates (and updates) a [deployment status](https://github.com/FAForever/fa/deployments). During that process the server retrieves the game related files, processes it and when everything is fine the new game version will be available in roughly 5 to 10 minutes.

## Related deployments

A push to `deploy/faf` will also trigger secondary deployments:

- [Spooky DB](https://github.com/FAForever/fa/blob/develop/.github/workflows/spookydb-update.yaml)
- [Unit DB](https://github.com/FAForever/fa/blob/develop/.github/workflows/unitdb-update.yaml)
