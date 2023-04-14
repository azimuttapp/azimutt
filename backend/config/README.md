# Environment variables

## Technical requirements

- `PORT` (required): the port the server will listen to (ex: `4000`)
- `PHX_HOST` (required): host of the deployed website (ex: `azimutt.app` in our case), it's used to build absolute urls
- `PHX_SERVER` (optional): if `true`, start the server in server mode
- `DATABASE_URL` (required): the whole url to connect to the database (ex: `postgresql://<user>:<pass>@<host>:<port>/<database>`)
  - `DATABASE_POOL_SIZE` (optional, default: `10`): the database connection pool size
  - `DATABASE_IPV6` (optional): if `true`, the database driver will use IPV6
- `FILE_STORAGE_ADAPTER` (required, values: `local` or `s3`): file storage is used to store project json files
  - if `s3`
    - `S3_BUCKET` (required): the bucket used to store project json
    - `S3_HOST` (optional): the s3 host (if you don't use s3 profiles)
    - `S3_KEY_ID` & `S3_KEY_SECRET` (optional): credentials to connect to the s3 (if you don't use s3 profiles)
    - `S3_PREFIX` (optional): if you need to prefix stored files with a specific value
- `EMAIL_ADAPTER` (optional, values: `mailgun`, `gmail` or `smtp`): the service to use to send emails (user email confirmation & organization invitations)
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
- `SECRET_KEY_BASE` (required): the secret used for encryption (cookies and others)
- `SUPPORT_EMAIL` (optional, default `contact@azimutt.app`): email we show in several place if users need to ask questions
- `SENDER_EMAIL` (optional, default `contact@azimutt.app`): email we set as sender for emails

## Key features

- `AUTH_PASSWORD` (optional): if `true`, enable email/password authentication
- `AUTH_GITHUB` (optional): if `true`, enable GitHub sso
  - `GITHUB_CLIENT_ID` (required)
  - `GITHUB_CLIENT_SECRET` (required)

## Optional services

- `SKIP_PUBLIC_SITE` (optional): if `true`, will not show the public site, home will redirect to login
- `GLOBAL_ORGANIZATION` (optional): an organization id, all new users will be added to it if specified
  - `GLOBAL_ORGANIZATION_ALONE` (optional): if `true`, only the global organization is shown (allows to work like a mono-tenant app)
- `STRIPE` (optional): if `true`, allow to purchase plans with [Stripe](https://stripe.com)
  - `STRIPE_API_KEY` (required): Stripe api key (ex: `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`)
  - `STRIPE_WEBHOOK_SIGNING_SECRET` (required): Stripe webhook secret (ex: `whsec_ayZAyKqOLy34UKNeI3eq4icXVWJam0IW`)
  - `STRIPE_PRICE_PRO_MONTHLY` (required): the Stripe price for the pro plan (ex: `price_uJINukB78aAbajUQHy6Ra523`)
- `TWITTER` (optional): if `true`, allow to use Twitter API to fetch tweets & unlock features (change table color)
  - `TWITTER_CONSUMER_KEY` (required)
  - `TWITTER_CONSUMER_SECRET` (required)
  - `TWITTER_ACCESS_TOKEN` (required)
  - `TWITTER_ACCESS_SECRET` (required)
- `SENTRY` (optional): if `true`, add [Sentry](https://sentry.io) integration
  - `SENTRY_BACKEND_DSN` (optional): your Sentry DSN (ex: `https://2g4ks8n9zxeqkfzven08yvayzz1bol0x@062prn3b.ingest.sentry.io/6050617`)
  - `SENTRY_FRONTEND_DSN` (optional): your Sentry DSN (ex: `https://qo83sgd9ojxwpydce1am5byd2o1y86zi@zqwwq6tu.ingest.sentry.io/8470350`)
- `HEROKU` (optional): if `true`, enable auth & hooks for [Heroku Add-on](https://elements.heroku.com/addons)
  - `HEROKU_ADDON_ID` (required)
  - `HEROKU_PASSWORD` (required)
  - `HEROKU_SSO_SALT` (required)
- `BENTO` (optional): if `true`, forward events to [Bento](https://bentonow.com)
  - `BENTO_SITE_KEY` (required)
  - `BENTO_PUBLISHABLE_KEY` (required)
  - `BENTO_SECRET_KEY` (required)
- `GITHUB` (optional): if `true`, allow to use GitHub API, no real usage for now
  - `GITHUB_ACCESS_TOKEN` (required)
