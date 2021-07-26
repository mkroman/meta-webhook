# Copyright (C) 2021 Mikkel Kroman <mk@maero.dk>
# All rights reserved.

FROM ruby:2.7.2-slim-buster AS builder
MAINTAINER Mikkel Kroman <mk@maero.dk>

# Install build dependencies
RUN apt-get update && \
  apt-get install -y build-essential git-core libsodium-dev

# Copy all the project files
COPY . /app

WORKDIR /app

# Install project dependencies
RUN gem update bundler \
  && bundle config set deployment 'true' \
  && bundle install -j$(nproc) \
  && bundle config

FROM ruby:2.7.2-slim-buster

# Install app runtime dependencies
RUN apt-get update \
  && apt-get install -y libsodium23 \
  && rm -rf /var/lib/apt/lists/*

# Copy all the project files.
COPY --from=builder /app /app

WORKDIR /app

RUN gem update bundler \
  && bundle config set deployment 'true' \
  && bundle install

# Set the default RACK_ENV to production
ENV RACK_ENV=production

ENTRYPOINT ["bundle", "exec", "bin/meta-webhook"]
