import {DatabaseSchema as schemaJsonDatabase, generateJsonDatabase, parseJsonDatabase} from "@azimutt/models";
import packageJson from "../package.json";
import {generatePrisma, parsePrisma} from "./prisma";

const monaco = {}
const version = packageJson.version

// make it available locally: `npm run build:browser && cp out/bundle.min.js ../../backend/priv/static/elm/prisma.min.js && cp out/bundle.min.js.map ../../backend/priv/static/elm/prisma.min.js.map`
/*
FIXME: errors in the rollup build:
(!) Missing shims for Node.js built-ins
Creating a browser bundle that depends on "util". You might need to include https://github.com/FredKSchott/rollup-plugin-polyfill-node
(!) Circular dependencies
../utils/out/any.js -> ../utils/out/object.js -> ../utils/out/any.js
../../node_modules/.pnpm/zod-to-json-schema@3.23.3_zod@3.23.8/node_modules/zod-to-json-schema/dist/cjs/parseDef.js -> ../../node_modules/.pnpm/zod-to-json-schema@3.23.3_zod@3.23.8/node_modules/zod-to-json-schema/dist/cjs/parsers/array.js -> ../../node_modules/.pnpm/zod-to-json-schema@3.23.3_zod@3.23.8/node_modules/zod-to-json-schema/dist/cjs/parseDef.js
../../node_modules/.pnpm/zod-to-json-schema@3.23.3_zod@3.23.8/node_modules/zod-to-json-schema/dist/cjs/parseDef.js -> ../../node_modules/.pnpm/zod-to-json-schema@3.23.3_zod@3.23.8/node_modules/zod-to-json-schema/dist/cjs/parsers/branded.js -> ../../node_modules/.pnpm/zod-to-json-schema@3.23.3_zod@3.23.8/node_modules/zod-to-json-schema/dist/cjs/parseDef.js
...and 28 more
(!) Missing global variable name
https://rollupjs.org/configuration-options/#output-globals
Use "output.globals" to specify browser global variable names corresponding to external modules:
util (guessing "require$$0$2")
*/
export * from "@azimutt/models"
export {parsePrisma, generatePrisma, parseJsonDatabase, generateJsonDatabase, schemaJsonDatabase, monaco, version}
