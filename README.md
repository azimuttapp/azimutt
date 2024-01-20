<p align="center">
    <a href="https://azimutt.app" target="_blank" rel="noopener">
        <picture>
          <source media="(prefers-color-scheme: dark)" srcset="assets/azimutt-logo-light.png">
          <source media="(prefers-color-scheme: light)" srcset="assets/azimutt-logo-dark.png">
          <img alt="Azimutt logo" src="assets/azimutt-logo-dark.png">
        </picture>
    </a>
</p>
<p align="center">
    <b>Next-Gen ERD</b>: Design, Explore, Document and Analyze your database, schema and data
</p>
<p align="center">
  <a href="https://azimutt.app" target="_blank" rel="noopener">azimutt.app</a> •
  <a href="https://github.com/orgs/azimuttapp/projects/5" target="_blank" rel="noopener">roadmap</a> •
  <a href="https://twitter.com/azimuttapp" target="_blank" rel="noopener">@azimuttapp</a>
</p>
<p align="center">
    <a href="https://www.producthunt.com/posts/azimutt?utm_source=badge-featured&utm_medium=badge&utm_souce=badge-azimutt" target="_blank"><img src="https://api.producthunt.com/widgets/embed-image/v1/featured.svg?post_id=390699&theme=light" alt="Azimutt - Easily explore and analyze your database with your team | Product Hunt" style="width: 250px; height: 54px;" width="250" height="54" /></a>
    <a href="https://azimutt.app/slack" target="_blank"><img src="assets/slack-join.svg" alt="Join us on Slack" style="width: 216px; height: 54px;" width="216" height="54"></a>
</p>

Azimutt is a full-stack database exploration tool, from modern ERD made for real world databases (big & messy), to fast data navigation, but also documentation everywhere and whole database analysis.

[![Azimutt screenshot](docs/_assets/azimutt.png)](https://azimutt.app/gallery/gospeak)

**Why building Azimutt?**

Databases existed for more than 40 years and despite a lot of tool around them, we couldn't find any providing a great exploration experience.

- **Database clients** focus on querying experience, with auto-completion and table/column lists but no visual help
- **ERDs** have a great diagram UI but fall short when schema is growing (real-world use cases)
- **Data catalogs** are focused on data governance and lineage for data teams, miss relational db for developers

So we decided to built it 💪

Azimutt started as a schema exploration tool for databases with hundreds of tables, but now it has grown a lot:

[![Azimutt roadmap](docs/_assets/roadmap.png)](https://mm.tt/map/2434161843?t=N2yWZj1pc1)

- Design your schema using [AML](docs/aml/README.md) for a fast diagramming
- Explore your database schema using search everywhere, display only useful tables/columns and follow relations
- Query your data like never before, follow forign keys and display entities in diagram
- Document using table/column notes and tags and layouts and memos for use cases, features or team scopes
- Analyze it to discover inconsistencies and best practices to apply

Azimutt goal is to be your ultimate tool to understand your database.

## Self hosted

You can use our [Docker image](https://github.com/azimuttapp/azimutt/pkgs/container/azimutt) to easily deploy it. Here is the [full guide](INSTALL.md).


## Local development

Azimutt is built with [Elixir](https://elixir-lang.org)/[Phoenix](https://www.phoenixframework.org) (backend & admin) and [Elm](https://elm-lang.org)/[elm-spa](https://www.elm-spa.dev) (editor).

For local development you will need to set up the environment:

- install `npm`, [Elm](https://guide.elm-lang.org/install/elm.html) & [elm-spa](https://www.elm-spa.dev)
- install [Phoenix](https://hexdocs.pm/phoenix/installation.html) and [Elixir](https://elixir-lang.org/install.html) if needed (use [asdf](https://asdf-vm.com))
- install [PostgreSQL](https://www.postgresql.org/download), create a user `postgres` with password `postgres` and a database `azimutt_dev` (see `DATABASE_URL` in `.env` later)
- install [pre-commit](https://pre-commit.com) and run `pre-commit install` before committing
- copy `.env.example` to `.env` and adapt values
- source your environment and install dependencies: `source .env && npm run setup`
- you can now start the Azimutt server: `source .env && npm start`
- and finally navigate to [localhost:4000](http://localhost:4000) 🎉
- you can login with `admin@azimutt.app` email & `admin` password

Other things:

- API documentation is accessible at [`/api/v1/swagger`](http://localhost:4000/api/v1/swagger)
- You can use `npm run elm:book` to start Elm design system & components, and access it with [localhost:4002](http://localhost:4002)


### npm command semantics

We have a lot of projects with a lot of commands, here is how they are structured:

- each project has its own commands (mostly npm but also elixir), the root project has global commands to launch them using a prefix
- `setup` is a one time command to install what is required
- `install` download dependencies, should be run when new ones are added
- `start` launch project in dev mode
- `test` allows to run tests
- `format` allows to run execute code formatting
- `lint` allows to run execute linters
- `build` generate compilation output
- `docker` same as `build` but in the docker image (paths are different 😕)
- `update` bumps library versions

Prefixes in front of the command in root folder:

- `libs:` run the command for every library in `libs` folder
- `ex:` meaning elixir, it targets the backend (mostly running `mix` commands)
- `fe:` meaning frontend, target the frontend project with Elm, TypeScript & Tailwind
- `elm:` targets only Elm in the frontend project
- `ts:` targets only TypeScript in the frontend project
- `cli:` run the command for the `cli` project
- `desktop:` run the command for the `desktop` project
- `be:` meaning browser extension run the command for the `browser-extension` project

And then "special" commands:

- `elm:book`: launch elm-book, the design system for Elm


### Development commands

- `npm run elm:book` to launch the Elm design system


### Setup Stripe

#### Config

- Install [Stripe CLI](https://stripe.com/docs/stripe-cli) and login with `stripe login`
- Run `stripe listen --forward-to localhost:4000/webhook/stripe`
- Copy your webhook signing secret to your `.env`, it's look like (`whsec_XXX`)
- Go to [your Stripe dashboard](https://dashboard.stripe.com/test/apikeys) to obtain your API Key and copy it into `STRIPE_API_KEY` in your `.env` file.


#### Payments

When testing interactively, use a card number, such as `4242 4242 4242 4242`. Enter the card number in the Dashboard or in any payment form.
Use a valid future date, such as `12/34`.
Use any three-digit CVC like `123` (four digits for American Express cards).
Use any value you like for other form fields.

See more in the [stripe testing documentation](https://stripe.com/docs/testing)


## Stack

* [Production](https://azimutt.app) & [Staging](https://azimutt.dev)
* [Error logs](https://sentry.io/organizations/azimuttapp/issues/?project=6635088) with [Sentry](https://sentry.io)
* Design using [TailwindCSS Framework](https://tailwindcss.com)
* [Credo](http://credo-ci.org) for static code analysis (automatically run with pre-commit)

## License

The tool is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
