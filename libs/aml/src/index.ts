import {
    generateJsonDatabase,
    parseJsonDatabase,
    DatabaseSchema as schemaJsonDatabase
} from "@azimutt/models";
import packageJson from "../package.json";
import {codeAction, codeLens, completion, createMarker, language} from "./extensions/monaco";

const monaco = {language, completion, codeAction, codeLens, createMarker}
const version = packageJson.version

// make it available locally: `npm run build:browser && cp out/bundle.min.js ../../backend/priv/static/elm && cp out/bundle.min.js.map ../../backend/priv/static/elm`
export * from "@azimutt/models"
export * from "./aml"
export {monaco}
export {generateJsonDatabase, parseJsonDatabase, schemaJsonDatabase, version}
