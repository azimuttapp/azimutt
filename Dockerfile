# Find eligible builder and runner images on Docker Hub. We use Ubuntu/Debian instead of
# Alpine to avoid DNS resolution issues in production.
#
# https://hub.docker.com/r/hexpm/elixir/tags?page=1&name=ubuntu
# https://hub.docker.com/_/ubuntu?tab=tags
#
#
# This file is based on these images:
#
#   - https://hub.docker.com/r/hexpm/elixir/tags - for the build image
#   - https://hub.docker.com/_/debian?tab=tags&page=1&name=bullseye-20210902-slim - for the release image
#   - https://pkgs.org/ - resource for finding needed packages
#   - Ex: hexpm/elixir:1.12.0-erlang-24.0.1-debian-bullseye-20210902-slim
#

ARG ELIXIR_VERSION=1.14.3
ARG OTP_VERSION=25.2.2
ARG DEBIAN_VERSION=bullseye-20230109-slim

ARG S3_KEY_ID
ARG S3_HOST
ARG S3_KEY_SECRET
ARG S3_BUCKET
ARG HOST
ARG GITHUB_CLIENT_SECRET
ARG GITHUB_CLIENT_ID
ARG STRIPE_API_KEY
ARG STRIPE_WEBHOOK_SIGNING_SECRET
ARG PHX_SERVER
ARG DATABASE_URL

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM --platform=linux/amd64 ${BUILDER_IMAGE} as builder


# install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git nodejs npm curl wget \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*
RUN curl -fsSL https://deb.nodesource.com/setup_19.x | bash - \
  && apt-get install -y nodejs
RUN npm install -g npm@latest
RUN wget -O - 'https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz' \
    | gunzip -c >/usr/local/bin/elm

# make the elm compiler executable
RUN chmod +x /usr/local/bin/elm

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY backend/mix.exs backend/mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY backend/config/config.exs backend/config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY backend/priv priv

# note: if your project uses a tool like https://purgecss.com/,
# which customizes asset compilation based on what it finds in
# your Elixir templates, you will need to move the asset compilation
# step down so that `lib` is available.
COPY backend/assets assets

COPY frontend/ frontend

RUN npm run docker --prefix frontend

# Compile the release
COPY backend/lib lib

# compile assets
RUN mix assets.deploy

RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY backend/config/runtime.exs config/

COPY backend/rel rel
RUN mix release

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM --platform=linux/amd64 ${RUNNER_IMAGE}

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ENV S3_KEY_ID=${S3_KEY_ID}
ENV S3_HOST=${S3_HOST}
ENV S3_KEY_SECRET=${S3_KEY_SECRET}
ENV S3_BUCKET=${S3_BUCKET}
ENV HOST=${HOST}
ENV GITHUB_CLIENT_SECRET=${GITHUB_CLIENT_SECRET}
ENV GITHUB_CLIENT_ID=${GITHUB_CLIENT_ID}
ENV STRIPE_API_KEY=${STRIPE_API_KEY}
ENV STRIPE_WEBHOOK_SIGNING_SECRET=${STRIPE_WEBHOOK_SIGNING_SECRET}
ENV PHX_SERVER="true"
ENV DATABASE_URL=${DATABASE_URL}

WORKDIR "/app"
RUN chown nobody /app

# set runner ENV
ENV MIX_ENV="prod"
ENV PHX_SERVER="true"

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/azimutt ./
RUN mkdir -p ./app/bin/priv/static/
COPY --from=builder --chown=nobody:root /app/priv/static/blog ./bin/priv/static/blog

USER nobody

CMD ["sh", "-c", "/app/bin/migrate && /app/bin/server"]
