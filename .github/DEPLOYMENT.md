# Deployment

In this repository we can deploy to three different environments:

- `deploy/faf` - the `FAF` game type. This is the default release branch and is used by matchmaker
- `deploy/fafbeta` - the `FAF Beta Balance` game type. This branch only contains balance changes and bug fixes.
- `deploy/fafdevelop` - the `FAF Develop` game type. This branch contains all current changes that are in development.

All three branches originate from the `develop` branch, which is the default branch of the remote on Github. Pushing commits towards any of the deployment branches is sufficient to trigger a deployment to the given game type. \

## Automated deployments

As of [#6225](https://github.com/FAForever/fa/pull/6225) the branch `deploy/fafdevelop` is updated on a weekly basis by pushing `develop` to it. 