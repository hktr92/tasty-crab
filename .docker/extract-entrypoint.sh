#!/usr/bin/env bash

docker run --rm -it --entrypoint /bin/bash public.ecr.aws/lambda/provided:al2023 -c "cat /lambda-entrypoint.sh" > lambda-entrypoint.sh