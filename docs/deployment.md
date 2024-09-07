---
layout: page
title: Deployment
permalink: /deploy
nav_order: 3
---

# Deployment

In this repository we can deploy to three different environments:

- `deploy/faf` - the `FAF` game type. This is the default release branch and is used by matchmaker
- `deploy/fafbeta` - the `FAF Beta Balance` game type. This branch only contains balance changes and bug fixes.
- `deploy/fafdevelop` - the `FAF Develop` game type. This branch contains all current changes that are in development.

All three branches originate from the `develop` branch, which is the default branch of the remote on Github. Pushing commits towards any of the deployment branches is sufficient to trigger a deployment to the given game type.

## Deployment procedures for the FAF game type

The deployment procedure can be a lengthy process because it involves various stages. All the stages are explained below.

### Deployment of engine patches

The deployment of engine patches to the release branch is a manual process. This is intentional as users will automatically download the executable upon launching the game. 

- (1) Make sure that any open changes that you want to include are merged to the `master` branch of the [Binary patches](https://github.com/FAForever/FA-Binary-Patches) repository.
- (2) Update the executable of the `FAF Develop` and `FAF Beta Balance` game types using the [Upload workflow](https://github.com/FAForever/FA-Binary-Patches/actions).
- (3) Ask a server administrator to prepare the executable to be updated upon the next game release.
- (4) ???

You can continue the deployment steps but you can not finalize it until the server administrator got back to you that it is set. This may take an arbitrary amount of time so make sure this is done well in advance. 

### Changelog for a deployment

- (0) Checkout on the `develop` branch and pull in the latest version. Make sure that there are no other open changes.
- (1) Create a new branch that originates from `develop`. We'll refer to this branch as the `changelog branch`.
- (2) Generate the changelog using the [Changelog generation workflow](https://github.com/FAForever/fa/actions/workflows/docs-changelog.yaml).
- (3) Once the workflow is completed, navigate to the summary section and download the artifact that is created by the workflow.
- (4) Save the generated changelog to a new file in the format `yyyy-mm-dd-game-version.md` in `docs/_posts`. As an example for a file name: `2024-08-03-3811.md`.
- (5) Verify and update the content of the changelog is complete.
- - (5.1) Add the front matter (what is in between `---`) at the top, for example:

```markdown
---
layout: post
title: Game version 3811
permalink: changelog/3811
---
```

- - (5.1) Add an introduction at the top of the changelog.
- - (5.2) Add the contributors at the bottom.

- (6) Stage, commit and push the changes to GitHub. Create a pull request on GitHub to allow other maintainers to review the changelog. Make sure the pull requests points to `develop`. 
- (7) Delete the current snippets and stage, commit and push the changes to GitHub.

You can re-use the same branch and pull request in the next phase of the deployment.

### Deployment of Lua

The following (manual) steps are relevant to create a valid deployment to the FAF game type.

- (0) Checkout on the `changelog branch` branch created in the previous step and pull in the latest version.
- (1) Update the game version in [mod_info.lua](https://github.com/FAForever/fa/blob/develop/mod_info.lua) and [version.lua](https://github.com/FAForever/fa/blob/develop/lua/version.lua).
- (3) Push everything that you want to release to the [master](https://github.com/FAForever/fa/tree/master) branch.
- (4) Use the [Deploy to FAF Workflow](https://github.com/FAForever/fa/actions/workflows/deploy-faf.yaml) to perform the deployment.
- (5) Create a [release on GitHub](https://github.com/FAForever/fa/releases) that targets the [master](https://github.com/FAForever/fa/tree/master) branch.

### Release on GitHub

Once `deploy/faf` is updated it is important to create a [release](https://github.com/FAForever/fa/releases/new) on GitHub



The last step allows us to systematically post process what we deploy. You can learn more about this by inspecting the workflow file.

## Automated deployments

There are three workflows to help with deployment:

- [FAF game type](https://github.com/FAForever/fa/blob/develop/.github/workflows/deploy-faf.yaml)
- [FAF Beta Balance game type](https://github.com/FAForever/fa/blob/develop/.github/workflows/deploy-fafbeta.yaml)
- [FAF Develop game type](https://github.com/FAForever/fa/blob/develop/.github/workflows/deploy-fafdevelop.yaml)

The workflows for Beta Balance and Develop trigger periodically. You can review when by evaluating the [cron expression](https://crontab.cronhub.io/). The [API of FAForever](https://github.com/FAForever/faf-java-api/blob/develop/src/main/java/com/faforever/api/deployment/GitHubDeploymentService.java) registers the push to a deployment branch via a webhook. The server creates (and updates) a [deployment status](https://github.com/FAForever/fa/deployments). During that process the server retrieves the game related files, processes it and when everything is fine the new game version will be available in roughly 5 to 10 minutes.

## Related deployments

A push to `deploy/faf` will also trigger secondary deployments:

- [Spooky DB](https://github.com/FAForever/fa/blob/develop/.github/workflows/spookydb-update.yaml)
- [Unit DB](https://github.com/FAForever/fa/blob/develop/.github/workflows/unitdb-update.yaml)
