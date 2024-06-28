# Azimutt Gateway

Small Node server to proxy database connections and enable browsers to access database features.

The other way is to use the [desktop app](../desktop) for this, keeping everything local and accessing local databases.


## Set Up

- copy `.env.example` to `.env` and adapt values
- run `pnpm install` to install dependencies
- start dev server with `pnpm start`


## Env vars

Loaded from `.env` file, with schema validation


## Backend API Development

There are a number of handy commands you can run to help with development.

| Command              | Action                                                             |
|----------------------|--------------------------------------------------------------------|
| `pnpm start`          | Run the server in dev mode, automatically restarts on file change |
| `pnpm run build`      | Compile TypeScript to JavaScript                                  |
| `pnpm run preview`    | Start JavaScript from 'build' directory                           |
| `pnpm test`           | Run unit tests (run `pnpm run build` before)                      |
| `pnpm run test:watch` | Run backend tests in watch mode, running on changed test files    |
| `pnpm run lint`       | Run eslint                                                        |
| `pnpm run lint:fix`   | Run eslint in fix mode                                            |


## CI

Run tests on push/PR to `main` branch
Check `.github/workflows/CI.yml`


## Deploy

Digital Ocean uses the `package-lock.json` to deploy, to generate it use `npm i --package-lock-only`.
The `workspace:^` can't be used there...


## Publish

- update `package.json` and `src/version.ts` versions
- update lib versions (`pnpm -w run update` + manual)
- test with `pnpm run dry-publish` and check `azimutt-gateway-x.y.z.tgz` content
- launch `pnpm publish --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/gateway).


## Dev

If you need to develop on multiple libs at the same time (ex: want to update a connector and try it through the CLI), depend on local libs but publish & revert before commit.

- Depend on a local lib: `pnpm add <lib>`, ex: `pnpm add @azimutt/models`
- "Publish" lib locally by building it: `pnpm run build`
