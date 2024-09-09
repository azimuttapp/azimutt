import {databaseJsonFormat as formatJson} from "@azimutt/models"
import {version} from "../package.json"
import {completion, language} from "./extensions/monaco"

const monaco = {language, completion}

// make it available locally: `npm run build:browser && cp out/bundle.min.js ../../backend/priv/static/elm && cp out/bundle.min.js.map ../../backend/priv/static/elm`
export * from "@azimutt/models"
export * from "./aml"
export * from "./parser"
export {monaco}
export {formatJson, version}
