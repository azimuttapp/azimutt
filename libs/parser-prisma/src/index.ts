import {DatabaseSchema as schemaJsonDatabase, generateJsonDatabase, parseJsonDatabase} from "@azimutt/models";
import packageJson from "../package.json";
import {generatePrisma, parsePrisma} from "./prisma";

const monaco = {}
const version = packageJson.version

// make it available locally: `npm run build:browser && cp out/bundle.min.js ../../backend/priv/static/elm/prisma.min.js && cp out/bundle.min.js.map ../../backend/priv/static/elm/prisma.min.js.map`
// FIXME: errors in the rollup build :/
export * from "@azimutt/models"
export {parsePrisma, generatePrisma, parseJsonDatabase, generateJsonDatabase, schemaJsonDatabase, monaco, version}
