import {mapEntriesDeep} from "@azimutt/utils";
import {
    Database,
    DatabaseSchema as schemaJsonDatabase,
    generateJsonDatabase,
    parseJsonDatabase,
    ParserError,
    ParserResult
} from "@azimutt/models";
import packageJson from "../package.json";
import * as amlAst from "./amlAst";
import {isTokenInfo} from "./amlAst";
import {parseAmlAst} from "./amlParser";
import {buildDatabase} from "./amlBuilder";
import {genDatabase} from "./amlGenerator";
import {samples} from "./amlSamples";
import {codeAction, codeLens, completion, createMarker, language} from "./extensions/monaco";
import {generateDot} from "./dotGenerator";
import {generateMermaid} from "./mermaidGenerator";
import {generateMarkdown} from "./markdownGenerator";

// TODO: warning is one-to-one relation don't have a unique constraint
// TODO: add column order for indexes in AML: `  name varchar index(pos: 1)=name_idx` (have properties in parentheses)
// TODO: allow several identical constraints in columns, ex: `  email varchar index index=other_index check(`email <> ''`) check(`len(email) > 3`)`

function parseAml(content: string, opts: {
    strict?: boolean, // stop at first error (instead of adding missing tokens to continue parsing)
    context?: Database // know external context to be more accurate on duplicate warnings and missing targets
} = {}): ParserResult<Database> {
    const start = Date.now()
    return parseAmlAst(content.trimEnd() + '\n', opts).flatMap(ast => {
        const parsed = Date.now()
        const astErrors: ParserError[] = []
        mapEntriesDeep(ast, (path, value) => {
            if (isTokenInfo(value) && value.issues) {
                value.issues.forEach(i => astErrors.push({...i, offset: value.offset, position: value.position}))
            }
            return value
        })
        const {db, errors: dbErrors} = buildDatabase(ast, start, parsed)
        return new ParserResult(db, astErrors.concat(dbErrors).sort((a, b) => a.offset.start - b.offset.start))
    })
}

function generateAml(database: Database, legacy: boolean = false): string {
    return genDatabase(database, legacy)
}

const ast = {...amlAst, parseAmlAst}
const monaco = {language, completion, codeAction, codeLens, createMarker}
const version = packageJson.version


// make it available locally: `npm run build:browser && cp out/bundle.min.js ../../backend/priv/static/elm/aml.min.js && cp out/bundle.min.js.map ../../backend/priv/static/elm/aml.min.js.map`
// update `backend/lib/azimutt_web/templates/website/_editors-script.html.heex` to use local files
export * from "@azimutt/models"
export {parseAml, generateAml, parseJsonDatabase, generateJsonDatabase, schemaJsonDatabase, generateDot, generateMermaid, generateMarkdown, samples, ast, monaco, version}
