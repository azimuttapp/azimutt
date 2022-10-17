# Azimutt editor

## Installation

- install `npm`, [Elm](https://guide.elm-lang.org/install/elm.html) & [elm-spa](https://www.elm-spa.dev)
- run `npm install` to download npm dependencies
- run `elm-spa build` to generate needed files (`.elm-spa/defaults` & `.elm-spa/generated`)

## Dev commands

- launch dev server: `npm run dev` (needs `npm install -g elm-live` or use `npx`)
- launch tests: `elm-test` (needs `npm install -g elm-test` or use `npx`)
- run linter: `elm-review` (needs `npm install -g elm-review` or use `npx`)
- check format: `elm-format src tests --validate` (needs `npm install -g elm-format` or use `npx`)
- run coverage: `elm-coverage --open` (needs `npm install -g elm-coverage`) (**doesn't work with elm-spa**)
- install deps `elm-json install author/package` (needs `npm install --g elm-json`)
- uninstall deps `elm-json uninstall author/package`
- update deps `elm-json upgrade` (use `--unsafe` flag for major versions)

Elm folders are `src` for sources, `tests` for tests and `public` for static assets.

When developing, please enable git hooks on your machine using: `git config --local core.hooksPath .githooks`

## Architecture

As any Elm app, the code is in `src` folder, the tests in `tests` folder and the static assets in `public` folder.

As we use [elm-spa](https://www.elm-spa.dev), the pages are in `Pages` folder following the routing pattern.
Each page has several specific files to manage the model, view and updates, they are in the `PageComponents` folder at the same location.

Some other folders have specific purpose:

- `Libs` is for libraries we build for Azimutt. They MUST have no dependency to the rest of the project and could be extracted in standalone libraries.
- `Components` is for generic components. They can only depend on `Libs` and should be showcased in elm-book.
- `DataSources` is for data sources parsers. For now, we have just SQL, but we can add others such as Rails active records. They can only depend on `Libs`.
- `Models` is for types used all across the project. They can depend on `Libs` but not on the rest of the project as they may be included anywhere.
- `Storage` is to serialize the model in a retro-compatible way. It depends on current serializers (in `Models`) but also manage some retro compatibility. It depends only on `Models` and `Libs`.
- `Pages` and `PagesComponents` handle all the app logic (Elm architecture). They depend on everything else but their code should be extracted as much as possible in generic modules (`Libs` or `Components`). Also, pages should absolutely not reference others.
- `Services` is a place where to extract some logic common at multiple pages but too specific to be in `Libs` (uses some models for example). Should not depend on anything from `Pages` or `PagesComponents`.

A few files live directly on `src` folder:

- `Shared.elm` as required by elm-spa, it contains the model shared by all pages.
- `Conf.elm` is for the constants we want to use across the app.
- `Ports.elm` is to handle all the JavaScript ports we have to use.
- `Tracking.elm` is to group all the tracking events Azimutt can generate.

Also, a convention we use a lot: when "extending" an existing library (ex: `Maybe` or `Result`), I create the same files in the same structure but under the `Libs` folder.
You can look at `Dict`, `List` but also `Html/Attributes` or `Html/Styled/Events` or even `Json/Encode`.
When I use them, most of the time I import it only with its initial.
