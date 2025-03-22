# pre-cache everything
FROM hktr92/tasty-crab:buildkit AS buildkit
FROM hktr92/tasty-crab:foundation AS foundation
FROM hktr92/tasty-crab:foundation-lambda AS foundation-lambda

# special image
FROM hktr92/tasty-crab:buildkit AS runkit
COPY . .
RUN --mount=type=cache,target=/usr/local/cargo \
    --mount=type=cache,target=/app/target \
    cargo fetch
ENTRYPOINT ["cargo"]


# cargo-chef planner step
FROM buildkit AS planner
COPY . .
RUN --mount=type=cache,target=/usr/local/cargo \
    --mount=type=cache,target=/app/target \
    cargo chef prepare --recipe-path recipe.json


# cargo-chef builder warmup
FROM buildkit AS builder
COPY --from=planner /app/recipe.json recipe.json
# Build dependencies - this is the caching Docker layer!
RUN --mount=type=cache,target=/usr/local/cargo \
    --mount=type=cache,target=/app/target \
    cargo chef cook --release --recipe-path recipe.json
# Build application
COPY . .


# build the actual app -- non-lambda
FROM builder AS awesome-app-builder
RUN --mount=type=cache,target=/usr/local/cargo \
    --mount=type=cache,target=/app/target \
    cargo build --release --bin awesome-app \
    && cp /app/target/release/awesome-app /app/awesome-app


# build the actual app -- for lambda
FROM builder AS awesome-app-lambda-builder
RUN --mount=type=cache,target=/usr/local/cargo \
    --mount=type=cache,target=/app/target \
    cargo lambda build --release --bin awesome-app-lambda --features=with-aws-secretsmanager \
    && cp /app/target/lambda/awesome-app-lambda/bootstrap /app/awesome-app-lambda


# We do not need the Rust toolchain to run the binary!
# runtime for non-lambda
FROM foundation AS awesome-app-runtime
COPY --from=awesome-app-builder /app/awesome-app .
CMD ["/app/awesome-app"]

# runtime for lambda
FROM foundation-lambda AS awesome-app-lambda-runtime
COPY --from=awesome-app-lambda-builder /app/awesome-app-lambda ${LAMBDA_RUNTIME_DIR}/bootstrap
CMD [ "handler" ]

