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

### Preparation of engine patches

The deployment of engine patches to the release branch is a manual process. This is intentional from a security perspective - it provides a second pair of eyes from a server administrator who is usually not directly related to the game team.

- (1) Make sure that any open changes that you want to include are merged to the `master` branch of the [Binary patches](https://github.com/FAForever/FA-Binary-Patches) repository.
- (2) Update the executable of the `FAF Develop` and `FAF Beta Balance` game types using the [Upload workflow](https://github.com/FAForever/FA-Binary-Patches/actions).

The workflow requires an approval of another maintainer. Once approved, wait for the workflow to finish.

- (3) Verify the executable on the `FAF Develop` game type.
- (4) Ask a server administrator to prepare the executable to be updated upon the next game release. This practically involves a copy operation where the server administrator verifies the executable of FAF Develop and copies it to a different location.

You can continue the deployment steps, but you can not finalize it until the server administrator got back to you that it is set. This may take an arbitrary amount of time so make sure this is done at least a week in advance.

### Preparation of Lua changes

- (0) Checkout on the [develop](https://github.com/FAForever/fa/tree/develop) branch and pull in the latest version. Make sure that there are no other open changes.
- (1) Create a new branch that originates from [develop](https://github.com/FAForever/fa/tree/develop). We'll refer to this branch as the `changelog branch`.
- (2) Generate the changelog using the [Changelog generation workflow](https://github.com/FAForever/fa/actions/workflows/docs-changelog.yaml) with the develop branch as target.
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

- - (5.2) Add an introduction at the top of the changelog.
- - (5.3) Add the contributors at the bottom.

- (6) commit this file to the changelog branch.
- (7) Delete the current snippets.
- (8) Update the game version in [mod_info.lua](https://github.com/FAForever/fa/blob/develop/mod_info.lua) and [version.lua](https://github.com/FAForever/fa/blob/develop/lua/version.lua).
- (9) Update the latest version in [changelogData.lua](https://github.com/FAForever/fa/blob/develop/lua/ui/lobby/changelogData.lua) (at the top of the file) and add a short version of the patchnotes there. Add an explanation that players can use the in-game button to github to read the detailed changes.
- (10) Push the changes to GitHub. Create a pull request on GitHub to allow other maintainers to review the changelog. Make sure the pull request points to [develop](https://github.com/FAForever/fa/tree/develop).

At this point you need to wait until the `changelog branch` is merged.

- (11) Create a [release on GitHub](https://github.com/FAForever/fa/releases) that targets the [develop](https://github.com/FAForever/fa/tree/develop) branch.
- - (11.1) Set the tag with the game version.
- - (11.2) Match the format of the title with that of previous releases.
- - (11.3) Copy and paste the changelog into the description. Make sure to remove the title as a release has its own title.
- - (11.4) Create the release.

The github release will be where most players will read about the changes, so while not technically necessary for the deployment, it should be prepared before the actual deployment happens.

### Deployment - final steps

- (1) Push everything that you want to release from [develop](https://github.com/FAForever/fa/tree/develop) to the [staging/faf](https://github.com/FAForever/fa/tree/staging/faf) branch.

- (2) Use the [Deploy to FAF Workflow](https://github.com/FAForever/fa/actions/workflows/deploy-faf.yaml) to perform the deployment.

The workflow requires an approval of another maintainer. Once approved, wait for the workflow to finish.
You can then review the status of the deployment by the server in the [production environment](https://github.com/FAForever/fa/deployments/production). Once that returns green the deployment succeeded and you can inform the community of the deployment. Congratulations!

## Deployment procedures for the development game types

This section applies to both the FAF Beta Balance and the FAF Develop game types. The usual flow is to:

- `develop` -> force push -> `staging/fafbeta` -> [workflow](https://github.com/FAForever/fa/blob/develop/.github/workflows/deploy-fafbeta.yaml) -> `deploy/fafbeta`
- `develop` -> force push -> `staging/fafdevelop` -> [workflow](https://github.com/FAForever/fa/blob/develop/.github/workflows/deploy-fafdevelop.yaml) -> `deploy/fafdevelop`

You can also choose to force push another branch onto the staging area. This allows you to deploy a different branch than `develop`. This is useful to test experimental changes, without polluting `develop` and without changing the pull request status.

## Deployment workflows

Some facets of deployment are automated to make development easier.

### Staging

There are two workflows for staging changes:

- [Stage FAF Beta Balance game type](https://github.com/FAForever/fa/blob/develop/.github/workflows/stage-fafbeta.yaml)
- [Stage FAF Develop game type](https://github.com/FAForever/fa/blob/develop/.github/workflows/stage-fafdevelop.yaml)

Relevant branches for the respective game types:

- FAF: `staging/faf`
- FAF Beta Balance: `staging/fafbeta`
- FAF Develop: `staging/fafdevelop`

Staging branches make it easier to:

- **Test individual changes or commits**: Force push the `develop` branch to a staging branch, proceed to cherry-pick the desired changes and then trigger the deployment workflow.
- **Test experimental changes from a pull request**: Force push the branch to a staging branch, then trigger the deployment workflow.

Staging branches are periodically updated automatically to keep them aligned with ongoing development. You can review the schedule by evaluating the [cron expression](https://crontab.cronhub.io/) in the workflow files.

### Deployment

There are three workflows for deployment:

- [Deploy FAF game type](https://github.com/FAForever/fa/blob/develop/.github/workflows/deploy-faf.yaml)
- [Deploy FAF Beta Balance game type](https://github.com/FAForever/fa/blob/develop/.github/workflows/deploy-fafbeta.yaml)
- [Deploy FAF Develop game type](https://github.com/FAForever/fa/blob/develop/.github/workflows/deploy-fafdevelop.yaml)

Each deployment workflow picks up commits from a staging branch, post-processes them, and force pushes them to a branch that triggers deployment. Relevant branches:

- FAF: `staging/faf` -> `deploy/faf`
- FAF Beta Balance: `staging/fafbeta` -> `staging/fafbeta`
- FAF Develop: `staging/fafdevelop` -> `staging/fafdevelop`

The deployment workflows for FAF Beta Balance and FAF Develop are triggered periodically. You can review the schedule by evaluating the [cron expression](https://crontab.cronhub.io/) in the workflow files.

The [FAForever API](https://github.com/FAForever/faf-java-api/blob/develop/src/main/java/com/faforever/api/deployment/GitHubDeploymentService.java) registers the push to a deployment branch via webhook. The server creates and updates a [deployment status](https://github.com/FAForever/fa/deployments). During this process, the server retrieves and processes the relevant game files. If successful, the new game version becomes available within approximately 5 to 10 minutes.

These workflows exist to apply some post processing of blueprints and various Lua modules. Not all of the post processing is implemented yet.

# FAQ

## The deployment is not working

This could be one of many reasons:

> Deployment to [production](https://github.com/FAForever/fa/deployments/production) failed.

This means there's an internal server error. You can not investigate this without access to the server. Reach out to a server administrator to search through the relevant logs for you. This happened once when the deployed commit contained emoticons.

> Deployment to [production](https://github.com/FAForever/fa/deployments/production) succeeded, but the client is not downloading the latest files.

The server keeps track of the latest game version. If you push changes that have a lower game version then the deployment 'succeeds', but it does not actually deploy. This can happen when you push relatively old pull requests to the staging area to deploy. This is common after a release just happened.
