# Deployment

In this repository we can deploy to three different environments:

- `deploy/faf` - the `FAF` game type. This is the default release branch and is used by matchmaker
- `deploy/fafbeta` - the `FAF Beta Balance` game type. This branch only contains balance changes and bug fixes.
- `deploy/fafdevelop` - the `FAF Develop` game type. This branch contains all current changes that are in development.

All three branches originate from the `develop` branch, which is the default branch of the remote on Github. Pushing commits towards any of the deployment branches is sufficient to trigger a deployment to the given game type. \

## Automated deployments

There are three workflows to help with deployment:

- [FAF game type](./workflows/deploy-faf.yaml)
- [FAF Beta Balance game type](./workflows/deploy-faf.yaml)
- [FAF Develop game type](./workflows/deploy-faf.yaml)

The workflows for Beta Balance and Develop trigger periodically. You can review when by evaluating the [cron expression](https://crontab.cronhub.io/). The [API of FAForever](https://github.com/FAForever/faf-java-api/blob/develop/src/main/java/com/faforever/api/deployment/GitHubDeploymentService.java) registers the push to a deployment branch via a webhook. The server creates (and updates) a [deployment status](https://github.com/FAForever/fa/deployments). During that process the server retrieves the game related files, processes it and when everything is fine the new game version will be available in roughly 5 to 10 minutes.

## Related deployments

A push to `deploy/faf` will also trigger secondary deployments:

- [Spooky DB](./workflows/spookydb-update.yaml)
- [Unit DB](./workflows//unitdb-update.yaml)
