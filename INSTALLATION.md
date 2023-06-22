# Installation Guide for Running Azimutt Container Locally

This guide will walk you through the process of running Azimutt, a containerized application, on your local machine. We will be using Docker, a platform that allows you to automate the deployment, scaling, and management of applications.

## Prerequisites

Make sure that you have Docker and Docker Compose installed on your local machine. Please refer to the [official Docker documentation](https://docs.docker.com/get-docker/) to install Docker and Docker Compose.

## Local Setup

Follow the steps below to run the Azimutt container on your local machine:


### From source code

### Step 1: Clone the Azimutt repository

Clone the Azimutt repository from GitHub to your local machine.

```bash
git clone https://github.com/azimuttapp/azimutt.git
```

### Step 2: Set up Environment Variables

Navigate to the Azimutt directory:

```bash
cd azimutt
```

Copy the `.env.example` file to a new file named `.env`:

```bash
cp .env.example .env
```

Edit the `.env` file and replace the placeholder values with your actual values for each environment variable. The possible environment variables are listed in the `.env.example` file available in the repository. 
On linux and Windows remove the `export` on the file.

### Step 3: Build the docker image

```bash
docker build -t azimutt:latest .
```

### Step 4: Run the Docker Container

Now, we'll need to run the container using the image we've just pulled. We'll use the `--env-file` option to supply our environment variables to the container. Note that you need to replace `<path_to_your_env_file>` with the actual path to your `.env` file:

```bash
docker run -d --name azimutt \
--env-file <path_to_your_env_file> \
-p 4000:4000 \
azimutt:latest
```

The Azimutt application should now be running on your local machine and accessible at `http://localhost:4000`.



### From Docker Registry
### Step 1: Pull the Docker Image

Pull the Docker image from the registry:

```bash
docker pull ghcr.io/azimuttapp/azimutt:main
```

### Step 2: Run the Docker Container

Now, we'll need to run the container using the image we've just pulled. We'll use the `--env-file` option to supply our environment variables to the container. Note that you need to replace `<path_to_your_env_file>` with the actual path to your `.env` file:

```bash
docker run -d --name azimutt \
--env-file <path_to_your_env_file> \
-p 4000:4000 \
ghcr.io/azimuttapp/azimutt:main
```

The Azimutt application should now be running on your local machine and accessible at `http://localhost:4000`.


## Env detail


| Environment Variable | Description | Required | Example |
| --- | --- | --- | --- |
| `PHX_SERVER` | Boolean flag indicating whether the Phoenix server should be launched. | Required | true/false |
| `PHX_HOST` | The host of the Phoenix server. | Required | localhost |
| `PORT` | The port on which the server will operate. | Required | 4000 |
| `DATABASE_URL` | The URL of the **postgres** database for running the application. | Required | postgresql://user:password@localhost/database |
| `DATABASE_POOL_SIZE` | The size of the database connection pool. | Optional | 10 |
| `DATABASE_ENABLE_SSL` | Boolean flag indicating whether to enable SSL for database connections. | Optional | true/false |
| `SECRET_KEY_BASE` | A secret key for verifying the integrity of signed cookies. | Required | abc...def |
| `SUPPORT_EMAIL` | The email address that will be shown in the application to contact support. | Optional | support@myapp.com |
| `SENDER_EMAIL` | The email address used when sending emails (email confirmation, password reset, organization invitation...). | Optional | sender@myapp.com |
| `GLOBAL_ORGANIZATION` | If you want all new users to be added to a specific organization. | Optional | The value of the organization -> organization_id (uuid) |
| `PUBLIC_SITE` | Boolean flag indicating if the site should be shown (please keep it to false on your instance :D ). | Optional | true/false |
| `SKIP_ONBOARDING_FUNNEL` | Flag for skipping the onboarding funnel. | Optional | true/false |
| `SKIP_EMAIL_CONFIRMATION` | Flag for skipping email confirmation upon sign up. | Optional | true/false |
| `REQUIRE_EMAIL_CONFIRMATION` | Flag for requiring email confirmation upon sign up. | Optional | true/false |
| `REQUIRE_EMAIL_ENDS_WITH` | Flag for requiring email addresses to end with a specific string upon sign up. | Optional | @mydomain.com |
| `ORGANIZATION_DEFAULT_PLAN` | The default plan for organizations in your application. | Optional | `free` or `pro` |
| `GLOBAL_ORGANIZATION_ALONE` | If activated in combination with the `GLOBAL_ORGANIZATION`, only this one is visible and no other one can be created, this fake a mono-tenancy app for simpler UI | Optional | true/false |
| `FILE_STORAGE_ADAPTER` | The file storage adapter to use. | Required | `local` or `s3` |
| `S3_BUCKET` | The name of the S3 bucket for file storage. | If `FILE_STORAGE_ADAPTER` is `s3` | my-s3-bucket |
| `S3_HOST` | The host for the S3 bucket. | If `FILE_STORAGE_ADAPTER` is `s3` | s3.amazonaws.com |
| `S3_KEY_ID` | The key ID for the S3 bucket. | If `FILE_STORAGE_ADAPTER` is `s3` | AKIAIOSFODN |
| `S3_KEY_SECRET` | The secret key for the S3 bucket. | If `FILE_STORAGE_ADAPTER` is `s3` | wJalrXUtnFEMI/K7MDEN |
| `S3_REGION` | The region of the S3 bucket. | If `FILE_STORAGE_ADAPTER` is `s3` | us-west-1 |
| `S3_FOLDER` | The folder within the S3 bucket for file storage. | Optional | my-app-data |
| `EMAIL_ADAPTER` | The email adapter to use. | Required | `mailgun`, `gmail`, or `smtp` |
| `MAILGUN_DOMAIN` | The domain for Mailgun email service. | If `EMAIL_ADAPTER` is `mailgun` | sandbox123.mailgun.org |
| `MAILGUN_API_KEY` | The API key for Mailgun email service. | If `EMAIL_ADAPTER` is `mailgun` | key-3ax6xnjp29jd6fds |
| `MAILGUN_BASE_URL` | The base URL for Mailgun email service. | If `EMAIL_ADAPTER` is `mailgun` | https://api.mailgun.net/v3 |
| `GMAIL_ACCESS_TOKEN` | The access token for Gmail email service. | If `EMAIL_ADAPTER` is `gmail` | ya29.A0AfH6SMDtBmTm- |
| `SMTP_RELAY` | The relay for SMTP email service. | If `EMAIL_ADAPTER` is `smtp` | smtp.mailtrap.io |
| `SMTP_USERNAME` | The username for SMTP email service. | If `EMAIL_ADAPTER` is `smtp` | smtp_user |
| `SMTP_PASSWORD` | The password for SMTP email service. | If `EMAIL_ADAPTER` is `smtp` | smtp_password |
| `SMTP_PORT` | The port for SMTP email service. | If `EMAIL_ADAPTER` is `smtp` | 2525 |
| `AUTH_PASSWORD` | Boolean flag indicating whether to enable password authentication. | Optional | true/false |
| `AUTH_GITHUB` | Boolean flag indicating whether to enable GitHub authentication. | Optional | true/false |
| `GITHUB_CLIENT_ID` | The client ID for GitHub authentication. | If `AUTH_GITHUB` is `true` | Iv1.1234567890abcdef |
| `GITHUB_CLIENT_SECRET` | The client secret for GitHub authentication. | If `AUTH_GITHUB` is `true` | 1234567890abcdef |
| `GITHUB_ACCESS_TOKEN` | The access token for GitHub authentication. | If `AUTH_GITHUB` is `true` | ghp_9Zt7AJKJJKL5H7GHIJKL |
| `AUTH_LINKEDIN` | Boolean flag indicating whether to enable LinkedIn authentication. (Not supported yet) | Optional | true/false |
| `AUTH_GOOGLE` | Boolean flag indicating whether to enable Google authentication. (Not supported yet) | Optional | true/false |
| `AUTH_TWITTER` | Boolean flag indicating whether to enable Twitter authentication. (Not supported yet) | Optional | true/false |
| `AUTH_FACEBOOK` | Boolean flag indicating whether to enable Facebook authentication. (Not supported yet) | Optional | true/false |
| `AUTH_SAML` | Boolean flag indicating whether to enable SAML authentication. | Optional | true/false |
| `POSTHOG` | Boolean flag indicating whether to enable Posthog for product analytics. | Optional | true/false |
| `POSTHOG_HOST` | The host for Posthog service. | If `POSTHOG` is `true` | app.posthog.com |
| `POSTHOG_KEY` | The key for Posthog service. | If `POSTHOG` is `true` | phc_ABCD_abcdefgh |
| `SENTRY` | Boolean flag indicating whether to enable Sentry for error tracking. | Optional | true/false |
| `SENTRY_BACKEND_DSN` | The DSN for Sentry backend. | If `SENTRY` is `true` | https://123abc@o123.ingest.sentry.io/1234 |
| `SENTRY_FRONTEND_DSN` | The DSN for Sentry frontend. | If `SENTRY` is `true` | https://123abc@o123.ingest.sentry.io/1234 |
| `STRIPE` | Boolean flag indicating whether to enable Stripe for payment processing. | Optional | true/false  |
| `STRIPE_API_KEY` | The API key for Stripe (required if Stripe is enabled). | If `STRIPE` is `true` | sk_test_4eC39HqLyjWDarjtT1zdp7dc |
| `STRIPE_WEBHOOK_SIGNING_SECRET` | The webhook signing secret for Stripe (required if Stripe is enabled). | If `STRIPE` is `true` | whsec_123456 |
| `STRIPE_PRICE_PRO_MONTHLY` | The monthly price in cents for Stripe (required if Stripe is enabled). | If `STRIPE` is `true` | 999 |
| `HEROKU` | Boolean flag indicating whether to enable Heroku integration. | Optional | true |
| `HEROKU_ADDON_ID` | The addon ID for Heroku. | If `HEROKU` is `true` | abcdefgh-ijkl-mnop-qrst-uvwxyz012345 |
| `HEROKU_PASSWORD` | The password for Heroku. | If `HEROKU` is `true` | myHerokuPassword |
| `HEROKU_SSO_SALT` | The SSO salt for Heroku. | If `HEROKU` is `true` | myHerokuSSOSalt |
| `BENTO` | Boolean flag indicating whether to enable Bento. | Optional | true |
| `BENTO_SITE_KEY` | The site key for Bento. | If `BENTO` is `true` | myBentoSiteKey |
| `BENTO_PUBLISHABLE_KEY` | The publishable key for Bento. | If `BENTO` is `true` | myBentoPublishableKey |
| `BENTO_SECRET_KEY` | The secret key for Bento. | If `BENTO` is `true` | myBentoSecretKey |
| `TWITTER` | Boolean flag indicating whether to enable Twitter integration. (This is used to unlock features with a tweet) | Optional | true/false |
| `TWITTER_CONSUMER_KEY` | The consumer key for Twitter. | If `TWITTER` is `true` | myTwitterConsumerKey |
| `TWITTER_CONSUMER_SECRET` | The consumer secret for Twitter. | If `TWITTER` is `true` | myTwitterConsumerSecret |
| `TWITTER_ACCESS_TOKEN` | The access token for Twitter. | If `TWITTER` is `true` | 1234567890-ZYXWVUTSR |
| `TWITTER_ACCESS_SECRET` | The access secret for Twitter. | If `TWITTER` is `true` | abcdefghijklmnopqr |

Please replace all the examples with your real data. Never share your secrets or keys in public spaces.
