import {databaseJsonFormat as formatJson} from "@azimutt/models"
import {version} from "../package.json"
import {codeAction, codeLens, completion, createMarker, language} from "./extensions/monaco"

const monaco = {language, completion, codeAction, codeLens, createMarker}

// make it available locally: `npm run build:browser && cp out/bundle.min.js ../../backend/priv/static/elm && cp out/bundle.min.js.map ../../backend/priv/static/elm`
export * from "@azimutt/models"
export * from "./aml"
export * from "./ast"
export * from "./parser"
export {monaco}
export {formatJson, version}
