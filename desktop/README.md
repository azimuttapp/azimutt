# Azimutt Desktop

This application is a native wrapper around the [Azimutt](https://azimutt.app) website and extend it with native capabilities.

The most important one:

- query databases from the user workstation (on https://azimutt.app we need a proxy server and a database accessible on internet)

## Development

- run `pnpm start`

Sometimes the application refuse to close, kill it manually (find it with `ps aux | grep "electron \."`)

## Packaging

Setup:
- install `rpmbuild`

Build:
- run `pnpm run build`

## Publish

- run `pnpm run publish`
