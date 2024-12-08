import {DatabaseSchema as schemaJsonDatabase, generateJsonDatabase, parseJsonDatabase} from "@azimutt/models";
import packageJson from "../package.json";
import {generateDbml, parseDbml} from "./dbml";

const monaco = {}
const version = packageJson.version

// make it available locally: `npm run build:browser && cp out/bundle.min.js ../../backend/priv/static/elm/dbml.min.js && cp out/bundle.min.js.map ../../backend/priv/static/elm/dbml.min.js.map`
/*
FIXME: errors in the rollup build:
(!) [plugin node-resolve] Could not resolve import "antlr4" in node_modules/.pnpm/@dbml+core@3.9.0/node_modules/@dbml/core/lib/parse/ANTLR/ASTGeneration/index.js using exports defined in node_modules/.pnpm/antlr4@4.13.2/node_modules/antlr4/package.json
(!) Unresolved dependencies
https://rollupjs.org/troubleshooting/#warning-treating-module-as-external-dependency
antlr4 (imported by "antlr4?commonjs-external")
(!) Missing global variable name
https://rollupjs.org/configuration-options/#output-globals
Use "output.globals" to specify browser global variable names corresponding to external modules:
antlr4 (guessing "require$$0$2")
*/
export * from "@azimutt/models"
export {parseDbml, generateDbml, parseJsonDatabase, generateJsonDatabase, schemaJsonDatabase, monaco, version}
