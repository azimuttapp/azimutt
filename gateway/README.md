# Azimutt Gateway

Small Node server to proxy database connections and enable browsers to access database features.

The other way is to use the [desktop app](../desktop) for this, keeping everything local and accessing local databases.

## Set Up

- Install the dependencies:

```bash
npm install
```

- Start the server in development mode:

```bash
npm start
```

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

- update `package.json` version
- test with `npm run dry-publish` and check `azimutt-gateway-x.y.z.tgz` content
- launch `npm publish --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/gateway).
