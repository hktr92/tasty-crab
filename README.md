# Tasty Crab

Tasty Crab is a Docker image that provides an image for Rust app development and
deployment to AWS.

## Flavors

The Dockerfile contains 4 layers:

- `foundation` -> the base runtime for everything;
- `foundation-lambda` -> the base runtime for AWS Lambda, containing the
  `lambda-entrypoint.sh`;
- `tasty-crab` -> THE most important layer, as it has Rust in it;
- `buildkit` -> a special layer that contains various toolchains to build stuff.

## Included tools

The `tasty-crab` layer contains:

- `cargo-binstall` -> a quick and nice way to install Rust binaries;
- `cargo-chef` -> optimizes Rust in Docker;
- `cargo-nextest` -> `cargo test`, but on steroids;
- `cargo-deny` -> audit utility that everyone should have.

## Usage

In order to get started, I've provided an example directory.

The `Dockerfile` contains how it should hypothetically work and build the app.
It uses cargo-chef for this.

In order to integrate it to your CI/CD pipeline, you'll need to build the
runkit:

```
docker build --file Dockerfile --target=runkit . --tag awesome-app/runkit
```

then, run it:

```
alias audit="docker run --rm awesome-app/runkit deny --workspace --all-features -L error check"
alias test="docker run --rm awesome-app/runkit nextest run --workspace --all-features"
```

In order to build your app for deployment, please use the `-runtime` layer,
e.g.:

```
docker build --file Dockerfile --target=awesome-app-runtime . --tag cool-project/awesome-app
```
