---
layout: page
title: Deployment
permalink: /deploy
nav_order: 3
---

# Deployment

In this repository we can deploy to three different environments:

- `deploy/faf` - the `FAF` game type. This is the default release branch and is used by the matchmaker
- `deploy/fafbeta` - the `FAF Beta` game type. This branch is for experimental changes that should not be part of `FAF Develop` for whatever reason.
- `deploy/fafdevelop` - the `FAF Develop` game type. This branch contains all current changes that are meant to be included in the next game patch.

All three branches originate from the `develop` branch, which is the default branch of the remote on GitHub.

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
Most of the preparation steps are automated to reduce the likelihood of errors.

- (1) Push everything that you want to release from [develop](https://github.com/FAForever/fa/tree/develop) to the [staging/faf](https://github.com/FAForever/fa/tree/staging/faf) branch.
- (2) Generate the necessary file changes and a changelog file using the [Prepare release workflow](https://github.com/FAForever/fa/actions/workflows/prepare-release.yaml). Add the correct date of the release.
- (3) Once the workflow is completed, navigate to the pull request that has been created.
- (4) Review the changelog and update the following:

- - (4.1) Add an introduction at the top of the changelog.
- - (4.2) Add the contributors at the bottom.
- - (4.3) If it is not one of the quarterly patches, change the title from `Game patch` to `Hotfix`

- (5) Commit these changes to the changelog branch.
- (6) Allow some time for the other maintainers to review the changelog.

At this point you need to wait until the changelog branch is merged.

- (7) Create a [release on GitHub](https://github.com/FAForever/fa/releases) that targets the [develop](https://github.com/FAForever/fa/tree/develop) branch.
- - (7.1) Set the tag with the game version.
- - (7.2) Match the format of the title with that of previous releases.
- - (7.3) Paste a link to our changelog website.
- - (7.4) Create the release.

This step is not technically necessary for the deployment, but it keeps the information on github in sync with our website.

### Deployment - final steps

Update the [staging/faf](https://github.com/FAForever/fa/tree/staging/faf) branch once more to include the committed changelog branch.

Use the [Deploy to FAF Workflow](https://github.com/FAForever/fa/actions/workflows/deploy-faf.yaml) to perform the deployment.

The workflow requires an approval of another maintainer. Once approved, wait for the workflow to finish.
You can then review the status of the deployment by the server in the [production environment](https://github.com/FAForever/fa/deployments/production). Once that returns green the deployment succeeded and you can inform the community of the deployment. Congratulations!

## Deployment procedures for the development game types

This section applies to both the FAF Beta Balance and the FAF Develop game types. The usual flow is to:

- `develop` -> force push -> `staging/fafbeta` -> [workflow](https://github.com/FAForever/fa/blob/develop/.github/workflows/deploy-fafbeta.yaml) -> `deploy/fafbeta`
- `develop` -> force push -> `staging/fafdevelop` -> [workflow](https://github.com/FAForever/fa/blob/develop/.github/workflows/deploy-fafdevelop.yaml) -> `deploy/fafdevelop`

You can also choose to force push another branch onto the staging area. This allows you to deploy a different branch than `develop`. This is useful to test experimental changes, without polluting `develop` and without changing the pull request status. A manual force push does not include the pull requests that are [labeled for testing](#testing-pull-requests-with-labels), they are only included again by the next run of the staging workflow.

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

#### Testing pull requests with labels

Pull requests can be included in a development game type without merging them into `develop` by adding a label:

- `Testing: FAF Beta`: included in `staging/fafbeta`
- `Testing: FAF Develop`: included in `staging/fafdevelop`

The labels are defined in [staging-labels.json](https://github.com/FAForever/fa/blob/develop/.github/workflows/scripts/staging-labels.json). Each run of the staging workflow merges all open pull requests with the label on top of `develop`, in order of their number. Deployment is not immediate: the game types keep their files for a month or a week so that replays remain playable. All times are in UTC:

- FAF Beta Balance: staged on the 1st of every month at 22:00 and deployed at 23:00
- FAF Develop: staged every Thursday at 20:00 and deployed at 21:00

Pull requests are squash merged. Pull requests that share commits with another labeled pull request are merged with a merge commit instead, see the conflicts below. The deployment workflow runs the tests on the staging branch, including the labeled pull requests, before it deploys.

**Approval**: adding the label approves the commit that the pull request is at in that moment. Later commits are only included when the author of the pull request has write access to this repository. For other authors, the status comment shows a checkbox to approve the latest commit, which only works for members with write access. This prevents unreviewed changes from reaching players. If the approved commit no longer exists, for example because the branch was force pushed, the pull request is left out until the latest commit is approved.

**Status comments**: the [check workflow](https://github.com/FAForever/fa/blob/develop/.github/workflows/check-staging-labels.yaml) keeps a status comment on each labeled pull request up to date. It runs when a label is added or removed, when a labeled pull request receives commits, when the approval checkbox is ticked and when `develop` changes. The staging and deployment workflows update it too. The comment shows:

- the deployment: ✅ what is live and since when, 🌐 not deployed yet, or ❌ why the last deployment failed or left the pull request out
- the queue: 🕒 when the next scheduled deployment is and which commit it includes, or ❌ why it is not included
- the actionable items: ✅ when there is nothing to do, ⚠️ with approvals, merge conflicts and invalid changelog snippets otherwise. A merge conflict shows the conflicting lines and how to resolve it

The comment is reposted with a mention to notify:

- whoever added the label, once the check finished
- whoever pushed, when the push causes a merge conflict or adds an invalid changelog snippet
- whoever approved last, when new commits need approval
- the author and whoever approved last, when a change to `develop` or another pull request causes a merge conflict, or when the pull request is left out of a deployment because of a merge conflict
- the author and whoever approved last, when someone else removes the label

When the label is removed or the pull request is merged, the comment shows which commits were deployed, when, and for how long in total. A pull request that is deployed when its label is removed stays deployed until the next deployment. Merging a pull request into `develop` removes its label. Adding the label again continues the history.

The comments are written with the `GITHUB_TOKEN` and show as `github-actions[bot]`. The times of the next stage run and deployment are read from the schedules of the workflows that [staging-labels.json](https://github.com/FAForever/fa/blob/develop/.github/workflows/scripts/staging-labels.json) names, and the game type name from the label.

**Conflicts**: pull requests that do not merge cleanly are left out and reported in the status comment, the run summary and as a warning on the workflow run. Changes are picked up until the staging workflow runs, the status comment shows when that is.

- A conflict with `develop`: merge `develop` into the pull request and resolve the conflicts.
- A conflict with another labeled pull request: the pull request with the higher number is left out. Merge the other pull request into yours and resolve the conflicts, or remove the label from one of them. Pull requests that share commits are merged with a merge commit so that your resolution applies.

**Changelog snippets**: a pull request is left out while it adds a [changelog snippet](https://faforever.github.io/fa/development/changelog#format-of-a-snippet) that the changelog workflow rejects, such as the `category.<number>.md` template that is added when the pull request is opened. One invalid snippet would otherwise fail the deployment of all labeled pull requests. The `changelog` folder of the staged result is checked before and after each pull request with the same script and in the same way as the changelog workflow, so new rules in that script apply here too.

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

## Related deployments

A push to `deploy/faf` will also automatically trigger deployments of the unit databases to keep their info up-to-date:

- [Unit DB](https://github.com/FAForever/fa/blob/develop/.github/workflows/unitdb-update.yaml)
- [Spooky DB](https://github.com/FAForever/fa/blob/develop/.github/workflows/spookydb-update.yaml)
- [ETFreeman DB](https://github.com/FAForever/fa/blob/develop/.github/workflows/etfreeman-db-update.yaml)


# FAQ

## The deployment is not working

This could be one of many reasons:

> Deployment to [production](https://github.com/FAForever/fa/deployments/production) failed.

This means there's an internal server error. You can not investigate this without access to the server. Reach out to a server administrator to search through the relevant logs for you. This happened once when the deployed commit contained emoticons.

> Deployment to [production](https://github.com/FAForever/fa/deployments/production) succeeded, but the client is not downloading the latest files.

The server keeps track of the latest game version. If you push changes that have a lower game version then the deployment 'succeeds', but it does not actually deploy. This can happen when you push relatively old pull requests to the staging area to deploy. This is common after a release just happened.
