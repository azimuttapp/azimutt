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
import {isTokenInfo} from "./amlAst";
import {parseAmlAst} from "./amlParser";
import {buildDatabase} from "./amlBuilder";
import {genDatabase} from "./amlGenerator";
import {codeAction, codeLens, completion, createMarker, language} from "./extensions/monaco";
import {generateMermaid} from "./mermaidGenerator";
import {generateMarkdown} from "./markdownGenerator";

// TODO: check predicate in parenthesis? (`  age int check(age > 0)=user_age_chk`)
// TODO: check predicate in backticks? (`  age int check`age > 0`=user_age_chk`)
// TODO: several checks on a single column & check on several columns
// TODO: add index order in AML

// TODO: index props: `  name varchar index(hash)=users_name_idx`
// TODO: check props: `  name varchar check(name <> '')=users_name_chk`

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

const monaco = {language, completion, codeAction, codeLens, createMarker}
const version = packageJson.version


// make it available locally: `npm run build:browser && cp out/bundle.min.js ../../backend/priv/static/elm/aml.min.js && cp out/bundle.min.js.map ../../backend/priv/static/elm/aml.min.js.map`
export * from "@azimutt/models"
export {parseAml, generateAml, parseJsonDatabase, generateJsonDatabase, schemaJsonDatabase, generateMermaid, generateMarkdown, monaco, version}
