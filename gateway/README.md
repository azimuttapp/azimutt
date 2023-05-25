# Azimutt Gateway

This is a small Node.js server (Fastify), responsible to proxy database connections to enable browser clients to access database features.
The other way is to use the [desktop app](../desktop) for this, keeping everything local and accessing local databases.

Project boilerplate from [yonathan06/fastify-typescript-starter](https://github.com/yonathan06/fastify-typescript-boilerplate).

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

Run tests on push/PR to 'main' branch
Check `.github/workflows/CI.yml`
