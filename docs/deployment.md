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

The deployment of engine patches to the release branch is a manual process. This is intentional from a security perspective - it provides a second pair of eyes from a server administrator who is usually not directly related to the game team.

- (1) Make sure that any open changes that you want to include are merged to the `master` branch of the [Binary patches](https://github.com/FAForever/FA-Binary-Patches) repository.
- (2) Update the executable of the `FAF Develop` and `FAF Beta Balance` game types using the [Upload workflow](https://github.com/FAForever/FA-Binary-Patches/actions).

The workflow requires an approval of another maintainer. Once approved, wait for the workflow to finish.

- (3) Verify the executable on the `FAF Develop` game type.
- (4) Ask a server administrator to prepare the executable to be updated upon the next game release. This practically involves a copy operation where the server administrator verifies the executable of FAF Develop and copies it to a different location.

You can continue the deployment steps, but you can not finalize it until the server administrator got back to you that it is set. This may take an arbitrary amount of time so make sure this is done well in advance.

### Deployment of Lua

- (0) Checkout on the [develop](https://github.com/FAForever/fa/tree/develop) branch and pull in the latest version. Make sure that there are no other open changes.
- (1) Create a new branch that originates from [develop](https://github.com/FAForever/fa/tree/develop). We'll refer to this branch as the `changelog branch`.
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

- - (5.2) Add an introduction at the top of the changelog.
- - (5.3) Add the contributors at the bottom.

- (6) Stage, commit and push the changes to GitHub. Create a pull request on GitHub to allow other maintainers to review the changelog. Make sure the pull request points to [develop](https://github.com/FAForever/fa/tree/develop).
- (7) Delete the current snippets and stage, commit and push the changes to GitHub.
- (8) Update the game version in [mod_info.lua](https://github.com/FAForever/fa/blob/develop/mod_info.lua) and [version.lua](https://github.com/FAForever/fa/blob/develop/lua/version.lua) and stage, commit and push the changes to GitHub.

At this point you need to wait until the `changelog branch` is merged.

- (9) Push everything that you want to release from [develop](https://github.com/FAForever/fa/tree/develop) to the [master](https://github.com/FAForever/fa/tree/master) branch.

### Deployment - final steps

- (1) Create a [release on GitHub](https://github.com/FAForever/fa/releases) that targets the [master](https://github.com/FAForever/fa/tree/master) branch.
- - (1.1) Set the tag with the game version.
- - (1.2) Match the format of the title with that of previous releases.
- - (1.3) Copy and paste the changelog into the description. Make sure to remove the title as a release has its own title.
- - (1.4) Create the release.
- (2) Use the [Deploy to FAF Workflow](https://github.com/FAForever/fa/actions/workflows/deploy-faf.yaml) to perform the deployment.

The workflow requires an approval of another maintainer. Once approved, wait for the workflow to finish.

- (3) Use the [Update SpookyDB](https://github.com/FAForever/fa/actions/workflows/spookydb-update.yaml) workflow to update [SpookyDB](https://github.com/FAForever/spooky-db)
- (4) Use the [Update UnitDB](https://github.com/FAForever/fa/actions/workflows/unitdb-update.yaml) workflow to update [UnitDB](https://github.com/FAForever/UnitDB)

Once all this is run you can review the status of the deployment by the server in the [production environment](https://github.com/FAForever/fa/deployments/production). Once that returns green the deployment succeeded and you can inform the community of the deployment. Congratulations!

## Automation

Some facets of deployment are automated to make development easier.

### Staging

There are two workflows for staging changes:

- [Stage FAF Beta Balance game type](https://github.com/FAForever/fa/blob/develop/.github/workflows/stage-fafbeta.yaml)
- [Stage FAF Develop game type](https://github.com/FAForever/fa/blob/develop/.github/workflows/stage-fafdevelop.yaml)

Relevant branches for the respective game types:

- FAF: `master`
- FAF Beta Balance: `staging/fafbeta`
- FAF Develop: `staging/fafdevelop`

Staging branches make it easier to:

- **Test individual changes or commits**: Force push the `master` branch to a staging branch, proceed to cherry-pick the desired changes and then trigger the deployment workflow.
- **Test experimental changes from a pull request**: Force push the branch to a staging branch, then trigger the deployment workflow.

Staging branches are periodically updated automatically to keep them aligned with ongoing development. You can review the schedule by evaluating the [cron expression](https://crontab.cronhub.io/) in the workflow files.

### Deployment

There are three workflows for deployment:

- [Deploy FAF game type](https://github.com/FAForever/fa/blob/develop/.github/workflows/deploy-faf.yaml)
- [Deploy FAF Beta Balance game type](https://github.com/FAForever/fa/blob/develop/.github/workflows/deploy-fafbeta.yaml)
- [Deploy FAF Develop game type](https://github.com/FAForever/fa/blob/develop/.github/workflows/deploy-fafdevelop.yaml)

Each deployment workflow picks up commits from a staging branch, post-processes them, and force pushes them to a branch that triggers deployment. Relevant branches:

- FAF: `master` -> `deploy/faf`
- FAF Beta Balance: `staging/fafbeta` -> `staging/fafbeta`
- FAF Develop: `staging/fafdevelop` -> `staging/fafdevelop`

The deployment workflows for FAF Beta Balance and FAF Develop are triggered periodically. You can review the schedule by evaluating the [cron expression](https://crontab.cronhub.io/) in the workflow files.

The [FAForever API](https://github.com/FAForever/faf-java-api/blob/develop/src/main/java/com/faforever/api/deployment/GitHubDeploymentService.java) registers the push to a deployment branch via webhook. The server creates and updates a [deployment status](https://github.com/FAForever/fa/deployments). During this process, the server retrieves and processes the relevant game files. If successful, the new game version becomes available within approximately 5 to 10 minutes.

## Related deployments

A push to `deploy/faf` will also trigger secondary deployments:

- [Spooky DB](https://github.com/FAForever/fa/blob/develop/.github/workflows/spookydb-update.yaml)
- [Unit DB](https://github.com/FAForever/fa/blob/develop/.github/workflows/unitdb-update.yaml)
