import {DatabaseSchema as schemaJsonDatabase, generateJsonDatabase, parseJsonDatabase} from "@azimutt/models";
import packageJson from "../package.json";
import {generateDbml, parseDbml} from "./dbml";

const monaco = {}
const version = packageJson.version

// make it available locally: `npm run build:browser && cp out/bundle.min.js ../../backend/priv/static/elm/dbml.min.js && cp out/bundle.min.js.map ../../backend/priv/static/elm/dbml.min.js.map`
// FIXME: errors in the rollup build :/
export * from "@azimutt/models"
export {parseDbml, generateDbml, parseJsonDatabase, generateJsonDatabase, schemaJsonDatabase, monaco, version}
