# Azimutt installation guide

Follow this guide to install [Azimutt](https://azimutt.app), the all-in-one app to explore and understand your database.

- [Architecture](#architecture)
- [Installation](#installation)
  - [Pre-build Docker image](#pre-build-docker-image)
  - [Build your own Docker image](#build-your-own-docker-image)
  - [Bare metal installation](#bare-metal-installation)
- [Environment variables](#environment-variables)


## Architecture

Azimutt is a web application written with [Elixir](https://elixir-lang.org)/[Phoenix](https://www.phoenixframework.org) for the backend and [Elm](https://elm-lang.org)/[TypeScript](https://www.typescriptlang.org) for the frontend.
It's backed by a [PostgreSQL](https://www.postgresql.org) database and a file storage with a [S3](https://aws.amazon.com/s3) API.
It also needs an email service for account validation, password reset and organization invitation, we currently support `smtp`, `gmail` and `mailgun` providers, but we could add more if you need.

There is also a [Node.js](https://nodejs.org) server, the [gateway](./gateway), to proxy calls to your databases.
You can install it on your infrastructure or let users call it from [Azimutt CLI](https://www.npmjs.com/package/azimutt).


## Installation

- [Pre-build Docker image](#pre-build-docker-image)
- [Build your own Docker image](#build-your-own-docker-image)
- [Bare metal installation](#bare-metal-installation)


### Pre-build Docker image

Make sure you have Docker installed on your local machine, refer to the [official Docker documentation](https://docs.docker.com/get-docker/) to install it if needed.

> Disclaimer: our pre-build image is made for Linux environment. If you need Mac or Windows, please reach out.


#### Step 1: Pull the Docker image

Pull the Docker image from the [registry](https://github.com/azimuttapp/azimutt/pkgs/container/azimutt):

```bash
docker pull ghcr.io/azimuttapp/azimutt:main
```


#### Step 2: Run the Docker container

Now, we'll need to run the container using the image we've just pulled.
But just before, you need to configure [environment variables](#environment-variables) and give them to your Docker container. For that you can use the `--env-file` option with a the `.env.example` file set up with your configuration.

```bash
docker run -d --name azimutt \
--env-file <path_to_your_env_file> \
-p 4000:4000 \
ghcr.io/azimuttapp/azimutt:main
```

Or for Apple Silicon/Arm64 users:

```bash
docker run -d --name azimutt \
--env-file <path_to_your_env_file> \
-p 4000:4000 \
--platform arm64 \
ghcr.io/azimuttapp/azimutt:main
```

The Azimutt application should now be running on `http://localhost:4000`.


### Build your own Docker image

Make sure you have Docker installed on your local machine, refer to the [official Docker documentation](https://docs.docker.com/get-docker) to install it if needed.

> Disclaimer: our Docker image is made for Linux environment. If you need Mac or Windows, please reach out.


#### Step 1: Clone the Azimutt repository

Clone the [Azimutt repository](https://github.com/azimuttapp/azimutt) on your local machine:

```bash
git clone git@github.com:azimuttapp/azimutt.git
```


#### Step 2: Set up environment variables

Define your [environment variables](#environment-variables), you can copy the `.env.exemple` to `.env` and edit it with your values:

```bash
cp .env.example .env
```

On linux and Windows remove the `export` in front of the variables in the file.


#### Step 3: Build the Docker image

```bash
docker build -t azimutt:latest .
```


#### Step 4: Run the Docker container

Now, we'll need to run the container using the image we've just built.
We'll use the `--env-file` option to supply your environment variables to the container:

```bash
docker run -d --name azimutt \
--env-file <path_to_your_env_file> \
-p 4000:4000 \
azimutt:latest
```

The Azimutt application should now be running on `http://localhost:4000`.


### Bare metal installation

TODO

But in short you will have to install Elixir & Elm on your machine and launch the backend.
Contact us if you need it, we will write this guide on demand 😉


## Environment variables

Here is the full list of environment variables you can use to set up Azimutt application.


### Technical requirements

These are the basic variables you will **need** to set up Azimutt:

- `PHX_SERVER` (optional): if `true`, start the Phoenix server in server mode
- `PHX_PROTOCOL` (optional, values: `ipv6` or `ipv4`, default: `ipv6`): if `ipv4`, the Phoenix server will listen to IPv4, otherwise IPv6
- `PHX_HOST` (required): host of the deployed website (ex: `localhost` or `azimutt.app`), it's used to build absolute urls
- `PORT` (required): the port the server will listen to (ex: `4000`)
- `SECRET_KEY_BASE` (required): the secret used for server encryption (cookies and others), should be at least 64 bytes and you probably want a random value for it
- `LICENCE_KEY` (optional): the licence key to unlock paid features, contact us if you need one (contact@azimutt.app)
- `DATABASE_URL` (required): the whole url to connect to your PostgreSQL database (ex: `postgresql://<user>:<pass>@<host>:<port>/<database>`)
    - `DATABASE_IPV6` (optional): if `true`, the database driver will use IPV6
    - `DATABASE_POOL_SIZE` (optional, default: `10`): the database connection pool size
    - `DATABASE_ENABLE_SSL` (optional): if `true`, the database driver will require SSL
- `FILE_STORAGE_ADAPTER` (required, values: `local` or `s3`): file storage is used to store project json files
    - if `s3`
        - `S3_BUCKET` (required): the bucket used to store project json
        - `S3_HOST` (optional): the s3 host (if you don't use s3 profiles)
        - `S3_KEY_ID` & `S3_KEY_SECRET` (optional): credentials to connect to the s3 (if you don't use s3 profiles)
        - `S3_FOLDER` (optional): if you want to store Azimutt files in a specific folder inside your bucket
        - `S3_REGION` (optional, default: `eu-west-1`): to specify your AWS region
    - if `local` mount a volume or path of `/app/bin/uploads` to back up JSON objects of created schemas
- `EMAIL_ADAPTER` (optional, values: `mailgun`, `gmail` or `smtp`): the service to use to send emails (email confirmation, password reset & organization invitations), contact us of you need another integration
    - if `mailgun`
        - `MAILGUN_DOMAIN` (required)
        - `MAILGUN_API_KEY` (required)
        - `MAILGUN_BASE_URL` (required)
    - if `gmail`
        - `GMAIL_ACCESS_TOKEN` (required)
    - if `smtp`
        - `SMTP_RELAY` (required)
        - `SMTP_USERNAME` (required)
        - `SMTP_PASSWORD` (required)
        - `SMTP_PORT` (required)
- `SENDER_EMAIL` (optional, default `contact@azimutt.app`): email Azimutt will us to send emails
- `CONTACT_EMAIL` (optional, default `contact@azimutt.app`): email shown in Azimutt to reach out
- `SUPPORT_EMAIL` (optional, default `contact@azimutt.app`): email shown in Azimutt when users need support
- `ENTERPRISE_SUPPORT_EMAIL` (optional, default `contact@azimutt.app`): email shown in Azimutt for high priority support


### Key features

At least one of authentication methods should be defined:

- `AUTH_PASSWORD` (optional): if `true`, enable email/password authentication
- `AUTH_GITHUB` (optional): if `true`, enable GitHub sso
    - `GITHUB_CLIENT_ID` (required)
    - `GITHUB_CLIENT_SECRET` (required)


### Optional features & services

- `GATEWAY_URL` (optional): if you deployed the [gateway](./gateway), the url where it can be reached out
- `SKIP_ONBOARDING_FUNNEL` (optional): if `true`, users will not go through the onboarding funnel on account creation
- `SKIP_EMAIL_CONFIRMATION` (optional): if `true`, users will not be asked to confirm their email (either blocked or soft)
- `REQUIRE_EMAIL_CONFIRMATION` (optional): if `true`, users will not be allowed to use Azimutt until they confirm their email, otherwise they will have a soft confirmation banner
- `REQUIRE_EMAIL_ENDS_WITH` (optional): force all users to use an email ending with a suffix, your domain name for example
- `ORGANIZATION_DEFAULT_PLAN` (optional, values: `free`, `solo`, `team`, `enterprise` or `pro`): define the plan an organization has by default when created
- `GLOBAL_ORGANIZATION` (optional): an organization id, if set, all new users will be added to this organization
    - `GLOBAL_ORGANIZATION_ALONE` (optional): if `true`, only the global organization is shown (allows to work like a mono-tenant app)
- `RECAPTCHA` (optional): if `true`, add [reCAPTCHA](https://www.google.com/recaptcha) on register and login
    - `RECAPTCHA_SITE_KEY` (required): your site key (frontend)
    - `RECAPTCHA_SECRET_KEY` (required): your secret key (backend)
    - `RECAPTCHA_MIN_SCORE` (optional): between 0.0 and 1.0
- `SENTRY` (optional): if `true`, add [Sentry](https://sentry.io) integration
    - `SENTRY_BACKEND_DSN` (optional): your Sentry DSN (ex: `https://2g4ks8n9zxeqkfzven08yvayzz1bol0x@062prn3b.ingest.sentry.io/6050617`)
    - `SENTRY_FRONTEND_DSN` (optional): your Sentry DSN (ex: `https://qo83sgd9ojxwpydce1am5byd2o1y86zi@zqwwq6tu.ingest.sentry.io/8470350`)
- `TWITTER` (optional): if `true`, allow to use Twitter API to fetch tweets & unlock features (change table color)
    - `TWITTER_CONSUMER_KEY` (required)
    - `TWITTER_CONSUMER_SECRET` (required)
    - `TWITTER_ACCESS_TOKEN` (required)
    - `TWITTER_ACCESS_SECRET` (required)


### Other features you will probably not need

- `PUBLIC_SITE` (optional): if `true`, will show the public site, otherwise home will redirect to login page (you probably don't want it)
- `GITHUB` (optional): if `true`, allow to use GitHub API, no real usage for now
    - `GITHUB_ACCESS_TOKEN` (required)
- `POSTHOG` (optional): if `true`, enable [PostHog](https://posthog.com) integration
    - `POSTHOG_HOST` (required)
    - `POSTHOG_KEY` (required)
- `BENTO` (optional): if `true`, forward events to [Bento](https://bentonow.com)
    - `BENTO_SITE_KEY` (required)
    - `BENTO_PUBLISHABLE_KEY` (required)
    - `BENTO_SECRET_KEY` (required)
- `STRIPE` (optional): if `true`, allow to purchase plans with [Stripe](https://stripe.com), you probably don't need it ^^
    - `STRIPE_API_KEY` (required): Stripe api key (ex: `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`)
    - `STRIPE_WEBHOOK_SIGNING_SECRET` (required): Stripe webhook secret (ex: `whsec_ayZAyKqOLy34UKNeI3eq4icXVWJam0IW`)
    - `STRIPE_PRICE_SOLO_MONTHLY` (required): Stripe price for the monthly solo plan (ex: `price_uJINukB78aAbajUQHy6Ra523`)
    - `STRIPE_PRICE_SOLO_YEARLY` (required): Stripe price for the yearly solo plan (ex: `price_uJINukB78aAbajUQHy6Ra523`)
    - `STRIPE_PRICE_TEAM_MONTHLY` (required): Stripe price for the monthly team plan (ex: `price_uJINukB78aAbajUQHy6Ra523`)
    - `STRIPE_PRICE_TEAM_YEARLY` (required): Stripe price for the yearly team plan (ex: `price_uJINukB78aAbajUQHy6Ra523`)
    - `STRIPE_PRODUCT_ENTERPRISE` (required): Stripe product for enterprise plan (ex: `prod_eBlQLUZPVprdAo`)
    - `STRIPE_PRICE_PRO_MONTHLY` (required): Stripe price for the monthly legacy pro plan (ex: `price_uJINukB78aAbajUQHy6Ra523`)
- `CLEVER_CLOUD` (optional): if `true`, enable auth & hooks for [Clever Cloud Add-on](https://www.clever-cloud.com/doc/extend/add-ons-api)
    - `CLEVER_CLOUD_ADDON_ID` (required)
    - `CLEVER_CLOUD_PASSWORD` (required)
    - `CLEVER_CLOUD_SSO_SALT` (required)
- `HEROKU` (optional): if `true`, enable auth & hooks for [Heroku Add-on](https://elements.heroku.com/addons)
    - `HEROKU_ADDON_ID` (required)
    - `HEROKU_PASSWORD` (required)
    - `HEROKU_SSO_SALT` (required)
- `HUBSPOT` (optional): if `true`, enable [HubSpot](https://www.hubspot.fr) integration
    - `HUBSPOT_ID` (required): your HubSpot tracking code id (ex: `483274933`)

**Never share your secrets or keys in public spaces.**
