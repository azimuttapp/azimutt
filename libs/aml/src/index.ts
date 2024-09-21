import {DatabaseSchema as schemaJsonDatabase, generateJsonDatabase, parseJsonDatabase} from "@azimutt/models";
import packageJson from "../package.json";
import {generateAml, parseAml} from "./aml";
import {codeAction, codeLens, completion, createMarker, language} from "./extensions/monaco";

const monaco = {language, completion, codeAction, codeLens, createMarker}
const version = packageJson.version

// make it available locally: `npm run build:browser && cp out/bundle.min.js ../../backend/priv/static/elm && cp out/bundle.min.js.map ../../backend/priv/static/elm`
export * from "@azimutt/models"
export {parseAml, generateAml, parseJsonDatabase, generateJsonDatabase, schemaJsonDatabase, monaco, version}
