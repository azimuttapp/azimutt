# Azimutt Html Report

Azimutt Html Report generates the html template file for the `analyze cli`

## Developing

The project uses ViteJS + React.

Start by installing dependencies

```bash
pnpm install
```

Launch developer mode to visualize changes with hot reload

```bash
pnpm run dev
```

Launch tests with

```bash
pnpm run test
```

### Customize mock data

In development mode, the app loads report data from the file `src/constants/report.constants.ts`

## Publish

Build the react app

```bash
pnpm run build
```

In production mode, the data is set in the global variable `__REPORT__` each time the `analyze cli` is called.
