# Azimutt browser extension

Goal of this extension:

- open Azimutt when clicking on it
- add a button in sql GitHub files to open them in Azimutt (ex: https://github.com/prisma/database-schema-examples/blob/main/postgres/basic-blog/schema.sql)

This extension is published on:

- https://chrome.google.com/webstore/detail/azimutt/bpifdkechgdibghkkpaioccoijeoebjf

## Development

Do an `pnpm install` and then run `pnpm start` to build the extension in live.

To do a build you can do `pnpm run build` (needed when changing the manifest)

## Publish extension

### Chrome

- increase the `version` in `manifest.json`
- build package: `pnpm run build`
- make a zip from `/dist`
- open `https://chrome.google.com/u/2/webstore/devconsole`
- open the extension, go on `package` section and click `import new package` to import your zip

More on https://developer.chrome.com/docs/webstore/publish

## Inspirations

- https://github.com/momo3038/another-pomodoro-webextension
- https://github.com/antfu/vitesse-webext
- https://github.com/papyrs/markdown-plugin
