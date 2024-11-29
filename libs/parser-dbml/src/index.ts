import {DatabaseSchema as schemaJsonDatabase, generateJsonDatabase, parseJsonDatabase} from "@azimutt/models";
import packageJson from "../package.json";
import {generateDbml, parseDbml} from "./dbml";

const monaco = {}
const version = packageJson.version

// make it available locally: `npm run build:browser && cp out/bundle.min.js ../../backend/priv/static/elm/dbml.min.js && cp out/bundle.min.js.map ../../backend/priv/static/elm/dbml.min.js.map`
/*
FIXME: errors in the rollup build:
> @azimutt/parser-dbml@0.1.0 build:browser
> rollup --config rollup.config.ts --configPlugin typescript

loaded rollup.config.ts with warnings
(!) [plugin typescript] @rollup/plugin-typescript: Rollup requires that TypeScript produces ES Modules. Unfortunately your configuration specifies a "module" other than "esnext". Unless you know what you're doing, please change "module" to "esnext" in the target tsconfig.json file or plugin options.
(!) [plugin typescript] src/dbml.ts (1:1): @rollup/plugin-typescript TS2354: This syntax requires an imported helper but module 'tslib' cannot be found.
libs/parser-dbml/src/dbml.ts:1:1

1 import * as dbml from "@dbml/core";
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

(!) [plugin typescript] src/index.ts (10:1): @rollup/plugin-typescript TS2354: This syntax requires an imported helper but module 'tslib' cannot be found.
libs/parser-dbml/src/index.ts:10:1

10 export * from "@azimutt/models"
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

(!) [plugin typescript] @rollup/plugin-typescript: Rollup 'sourcemap' option must be set to generate source maps.

src/index.ts → out/bundle.min.js...
(!) [plugin typescript] @rollup/plugin-typescript: Rollup requires that TypeScript produces ES Modules. Unfortunately your configuration specifies a "module" other than "esnext". Unless you know what you're doing, please change "module" to "esnext" in the target tsconfig.json file or plugin options.
(!) [plugin typescript] src/dbml.ts (1:1): @rollup/plugin-typescript TS2354: This syntax requires an imported helper but module 'tslib' cannot be found.
libs/parser-dbml/src/dbml.ts:1:1

1 import * as dbml from "@dbml/core";
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

(!) [plugin typescript] src/index.ts (10:1): @rollup/plugin-typescript TS2354: This syntax requires an imported helper but module 'tslib' cannot be found.
libs/parser-dbml/src/index.ts:10:1

10 export * from "@azimutt/models"
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

created out/bundle.min.js in 1.2s
 */
export * from "@azimutt/models"
export {parseDbml, generateDbml, parseJsonDatabase, generateJsonDatabase, schemaJsonDatabase, monaco, version}
