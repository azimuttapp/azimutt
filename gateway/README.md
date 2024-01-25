# Azimutt Gateway

Small Node server to proxy database connections and enable browsers to access database features.

The other way is to use the [desktop app](../desktop) for this, keeping everything local and accessing local databases.

## Set Up

- copy `.env.example` to `.env` and adapt values
- run `npm install` to install dependencies
- start dev server with `npm start`


## Env vars

Loaded from `.env` file, with schema validation

## Backend API Development

There are a number of handy commands you can run to help with development.

| Command              | Action                                                            |
|----------------------|-------------------------------------------------------------------|
| `npm start`          | Run the server in dev mode, automatically restarts on file change |
| `npm run build`      | Compile TypeScript to JavaScript                                  |
| `npm run preview`    | Start JavaScript from 'build' directory                           |
| `npm test`           | Run unit tests (run `npm run build` before)                       |
| `npm run test:watch` | Run backend tests in watch mode, running on changed test files    |
| `npm run lint`       | Run eslint                                                        |
| `npm run lint:fix`   | Run eslint in fix mode                                            |

## CI

Run tests on push/PR to `main` branch
Check `.github/workflows/CI.yml`

## Publish

- update `package.json` and `src/version.ts` versions
- update lib versions (`npm run update` + manual) & run `npm install`
- test with `npm run dry-publish` and check `azimutt-gateway-x.y.z.tgz` content
- launch `npm publish --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/gateway).

## Dev

If you need to develop on multiple libs at the same time (ex: want to update a connector and try it through the CLI), depend on local libs but publish & revert before commit.

- Depend on a local lib: `npm install <path>`, ex: `npm install ../libs/connector-postgres`
- "Publish" lib locally by building it: `npm run build`
