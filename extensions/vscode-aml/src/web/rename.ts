import {CancellationToken, Position, ProviderResult, Range, RenameProvider, TextDocument, WorkspaceEdit} from "vscode";
// @ts-ignore
import {AmlAst, AmlToken, TokenInfo} from "@azimutt/aml/out/amlAst";
import {parseAmlAst} from "./aml";
import {positionToAml, tokenToRange} from "./utils";

const amlLib = import("@azimutt/aml");

export class AmlRenameProvider implements RenameProvider {
    // https://code.visualstudio.com/api/references/vscode-api#RenameProvider, no idea of `placeholder` use...
    prepareRename?(document: TextDocument, position: Position, token: CancellationToken): ProviderResult<Range | { range: Range; placeholder: string; }> {
        return useAmlAst(document, async ast => {
            const token = await findToken(ast, position)
            return token ? toRange(token.position) : Promise.reject('Unsupported rename')
        })
    }
    provideRenameEdits(document: TextDocument, position: Position, newName: string, token: CancellationToken): ProviderResult<WorkspaceEdit> {
        return useAmlAst(document, async ast => {
            const token = await findToken(ast, position)
            return token ? await computeEdits(document, token, ast, newName) : Promise.reject('Unsupported rename')
        })
    }
}

async function useAmlAst<T>(document: TextDocument, f: (ast: AmlAst) => T | Promise<T>): Promise<T> {
    const res = await parseAmlAst(document.getText())
    if (res.result) {
        return f(res.result)
    } else {
        const err = res.errors?.[0]?.message
        return Promise.reject('Unable to rename' + (err ? ': ' + err : ' 😅'))
    }
}

async function findToken(ast: AmlAst, position: Position): Promise<AmlToken | undefined> {
    return (await amlLib).ast.findTokenAt(ast, positionToAml(position))
}

async function computeEdits(document: TextDocument, token: AmlToken, ast: AmlAst, newName: string): Promise<WorkspaceEdit> {
    const positions = (await amlLib).ast.collectTokenPositions(ast, token)
    const edits = new WorkspaceEdit()
    positions.forEach(pos => edits.replace(document.uri, toRange(pos), newName))
    return edits
}

const toRange = (token: TokenInfo): Range => tokenToRange(token.position)
