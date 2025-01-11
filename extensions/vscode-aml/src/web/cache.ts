import {TextDocument} from "vscode";
import {Database, ParserError} from "@azimutt/models";
// @ts-ignore
import {AmlAst} from "@azimutt/aml/out/amlAst";
import {parseAmlAst} from "./aml";

const amlLib = import("@azimutt/aml");

export type AmlDocument = {text: string, ast?: AmlAst, schema?: Database, errors: ParserError[]}
const cache: {[uri: string]: AmlDocument} = {}

export function getDocument(document: TextDocument): Promise<AmlDocument> {
    const doc = cache[document.uri.toString()]
    return doc ? Promise.resolve(doc) : setDocument(document)
}

export async function setDocument(document: TextDocument): Promise<AmlDocument> {
    const text = document.getText()
    const now = Date.now()
    const ast = await parseAmlAst(text) // FIXME: merge namespaces into entities, types & relations...
    const db = (await amlLib).ast.amlToDatabase(ast, now)
    const doc: AmlDocument = {text, ast: ast.result, schema: db.result, errors: db.errors || []}
    cache[document.uri.toString()] = doc
    return doc
}
