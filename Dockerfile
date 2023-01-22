# STEP 1 - Docker image stage for building the release
ARG MIX_ENV="prod"
ARG ELIXIR_VERSION=1.14.2
ARG OTP_VERSION=25.1.2
ARG DEBIAN_VERSION=bullseye-20221004-slim
ARG CELLAR_ADDON_KEY_ID
ARG CELLAR_ADDON_HOST
ARG CELLAR_ADDON_KEY_SECRET
ARG CELLAR_BUCKET
ARG HOST
ARG GITHUB_CLIENT_SECRET
ARG GITHUB_CLIENT_ID
ARG STRIPE_API_KEY
ARG STRIPE_WEBHOOK_SIGNING_SECRET
ARG PHX_SERVER

FROM hexpm/elixir:1.14.2-erlang-25.1-alpine-3.17.0  AS build

# Install build dependencies
RUN apk add --no-cache build-base git python3 curl

# Sets work directory
WORKDIR /app


# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

ARG MIX_ENV
ENV MIX_ENV="${MIX_ENV}"

COPY backend/mix.exs backend/mix.lock ./

RUN mix deps.get --only $MIX_ENV

# Copy compile configuration files
RUN mkdir config
COPY backend/config/config.exs backend/config/"${MIX_ENV}".exs config/

# Compile dependencies
RUN mix deps.compile

COPY backend/priv priv

# TODO : setup l'install des assets ELM

# Copy assets
# note: if your project uses a tool like https://purgecss.com/,
# which customizes asset compilation based on what it finds in
# your Elixir templates, you will need to move the asset compilation
# step down so that `lib` is available.
COPY backend/assets assets

# Compile project
COPY backend/lib lib

# IMPORTANT: Make sure asset compilation is after copying lib
# Compile assets
RUN mix assets.deploy

RUN mix compile

# Copy runtime configuration file
COPY backend/config/runtime.exs config/

# Assemble release
RUN mix release

################################################################################
# STEP 2 - Docker image stage for running the release
FROM alpine:3.17.0 AS app

ARG MIX_ENV
#ENV SECRET_KEY_BASE="$(mix phx.gen.secret)"

# Install runtime dependencies
RUN apk add --no-cache libstdc++ openssl ncurses-libs

ENV USER="azimutt"
ENV CELLAR_ADDON_KEY_ID=${CELLAR_ADDON_KEY_ID}
ENV CELLAR_ADDON_HOST=${CELLAR_ADDON_HOST}
ENV CELLAR_ADDON_KEY_SECRET=${CELLAR_ADDON_KEY_SECRET}
ENV CELLAR_BUCKET=${CELLAR_BUCKET}
ENV GITHUB_CLIENT_SECRET=${GITHUB_CLIENT_SECRET}
ENV GITHUB_CLIENT_ID=${GITHUB_CLIENT_ID}
ENV STRIPE_API_KEY=${STRIPE_API_KEY}
ENV HOST=${HOST}
ENV STRIPE_WEBHOOK_SIGNING_SECRET=${STRIPE_WEBHOOK_SIGNING_SECRET}
ENV PHX_SERVER="true"
WORKDIR "/home/${USER}/app"

# Create unprivileged user to run the release
RUN \
addgroup -g 1000 -S "${USER}" \
&& adduser \
-s /bin/sh \
-u 1000 \
-G "${USER}" \
-h "/home/${USER}" \
-D "${USER}" \
&& su "${USER}"

# run as user
USER "${USER}"

# copy release executable
COPY --from=build --chown="${USER}":"${USER}" /app/_build/"${MIX_ENV}"/rel/azimutt ./

ENTRYPOINT ["bin/azimutt"]

CMD ["eval \"Azimutt.Release.migrate\" ", "start"]