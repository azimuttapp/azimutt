import {CancellationToken, Position, ProviderResult, Range, RenameProvider, TextDocument, WorkspaceEdit} from "vscode";
// @ts-ignore
import {AmlAst, EntityRefAst, IdentifierAst, NamespaceRefAst, TokenInfo} from "@azimutt/aml/out/amlAst";
import {parseAmlAst} from "./aml";
import {amlPositionToVSRange, flattenAttrs, isInside} from "./utils";
import {arraySame, findMap} from "@azimutt/utils";

export class AmlRenameProvider implements RenameProvider {
    // https://code.visualstudio.com/api/references/vscode-api#RenameProvider, no idea of `placeholder` use...
    prepareRename?(document: TextDocument, position: Position, token: CancellationToken): ProviderResult<Range | { range: Range; placeholder: string; }> {
        return useAmlAst(document, ast => {
            const token = findToken(ast, position)
            return token?.range || Promise.reject('Unsupported rename')
        })
    }
    provideRenameEdits(document: TextDocument, position: Position, newName: string, token: CancellationToken): ProviderResult<WorkspaceEdit> {
        return useAmlAst(document, ast => {
            const token = findToken(ast, position)
            return token ? computeEdits(document, token, ast, newName) : undefined
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

type RenameToken = { range: Range } & ({kind: 'Database', database: string}
    | {kind: 'Catalog', catalog: string, database?: string}
    | {kind: 'Schema', schema: string, catalog?: string, database?: string}
    | {kind: 'Entity', entity: string, schema?: string, catalog?: string, database?: string}
    | {kind: 'Attribute', path: string[], entity: string, schema?: string, catalog?: string, database?: string}
    | {kind: 'Type', type: string, schema?: string, catalog?: string, database?: string})

function findToken(ast: AmlAst, position: Position): RenameToken | undefined {
    const s = ast.statements.find(s => isInside(position, s.meta.position))
    if (s?.kind === 'Entity') {
        if (inside(position, s.name)) return entityRename({...s, entity: s.name})
        if (s.schema && inside(position, s.schema)) return schemaRename(s.schema, s)
        // TODO: if (s.catalog && inside(position, s.catalog)) return {kind: 'Catalog', range: toRange(s.catalog), catalog: s.catalog.value, database: s.database?.value}
        // TODO: if (s.database && inside(position, s.database)) return {kind: 'Database', range: toRange(s.database), database: s.database.value}
        const a = flattenAttrs(s.attrs).find(a => isInside(position, a.meta.position))
        if (a) {
            const name = a.path[a.path.length - 1]
            if (name && inside(position, name)) return {kind: 'Attribute', range: toRange(name), path: a.path.map(p => p.value), entity: s.name.value, schema: s.schema?.value, catalog: s.catalog?.value, database: s.database?.value}
            const r = findMap(a.constraints || [], (c): RenameToken | undefined => {
                if (c.kind === 'Relation') {
                    if (inside(position, c.ref.entity)) return entityRename(c.ref)
                    if (c.ref.schema && inside(position, c.ref.schema)) return schemaRename(c.ref.schema, c.ref)
                    // TODO: rename attribute
                }
            })
            if (r) return r
        }
    } else if (s?.kind === 'Relation') {
        if (inside(position, s.src.entity)) return entityRename(s.src)
        if (inside(position, s.ref.entity)) return entityRename(s.ref)
        if (s.src.schema && inside(position, s.src.schema)) return schemaRename(s.src.schema, s.src)
        if (s.ref.schema && inside(position, s.ref.schema)) return schemaRename(s.ref.schema, s.ref)
        // TODO: rename attribute
    }
    // TODO: else if (s?.kind === 'Type') {}
    // TODO: else if (s?.kind === 'Namespace') {}
    return undefined
}

function computeEdits(document: TextDocument, token: RenameToken, ast: AmlAst, newName: string): WorkspaceEdit {
    const edits = new WorkspaceEdit()
    ast.statements.forEach(statement => {
        if (statement.kind === 'Entity') {
            if (token.kind === 'Entity' && token.entity === statement.name.value) edits.replace(document.uri, toRange(statement.name), newName)
            if (token.kind === 'Schema' && token.schema === statement.schema?.value) edits.replace(document.uri, toRange(statement.schema), newName)
            flattenAttrs(statement.attrs).forEach(attr => {
                if (token.kind === 'Attribute' && token.entity === statement.name.value && arraySame(token.path, attr.path.map(p => p.value))) edits.replace(document.uri, toRange(attr.path[attr.path.length - 1]), newName)
                attr.constraints?.forEach(c => {
                    if (c.kind === 'Relation') {
                        if (token.kind === 'Entity' && token.entity === c.ref.entity.value) edits.replace(document.uri, toRange(c.ref.entity), newName)
                        if (token.kind === 'Schema' && token.schema === c.ref.schema?.value) edits.replace(document.uri, toRange(c.ref.schema), newName)
                        c.ref.attrs.forEach(a => {
                            if (token.kind === 'Attribute' && token.entity === c.ref.entity.value && arraySame(token.path, [...(a.path || []).map(p => p.value), a.value])) edits.replace(document.uri, toRange(a), newName)
                        })
                    }
                })
            })
        } else if (statement.kind === 'Relation') {
            if (token.kind === 'Entity' && token.entity === statement.src.entity.value) edits.replace(document.uri, toRange(statement.src.entity), newName)
            if (token.kind === 'Entity' && token.entity === statement.ref.entity.value) edits.replace(document.uri, toRange(statement.ref.entity), newName)
            if (token.kind === 'Schema' && token.schema === statement.src.schema?.value) edits.replace(document.uri, toRange(statement.src.schema), newName)
            if (token.kind === 'Schema' && token.schema === statement.ref.schema?.value) edits.replace(document.uri, toRange(statement.ref.schema), newName)
            statement.src.attrs.forEach(a => {
                if (token.kind === 'Attribute' && token.entity === statement.src.entity.value && arraySame(token.path, [...(a.path || []).map(p => p.value), a.value])) edits.replace(document.uri, toRange(a), newName)
            })
            statement.ref.attrs.forEach(a => {
                if (token.kind === 'Attribute' && token.entity === statement.ref.entity.value && arraySame(token.path, [...(a.path || []).map(p => p.value), a.value])) edits.replace(document.uri, toRange(a), newName)
            })
        }
    })
    return edits
}

const inside = (position: Position, value: {token: TokenInfo}): boolean => isInside(position, value.token.position)
const toRange = (value: {token: TokenInfo}): Range => amlPositionToVSRange(value.token.position)
const entityRename = (ref: EntityRefAst): RenameToken => ({kind: 'Entity', range: toRange(ref.entity), entity: ref.entity.value, schema: ref.schema?.value, catalog: ref.catalog?.value, database: ref.database?.value})
const schemaRename = (schema: IdentifierAst, n: NamespaceRefAst): RenameToken => ({kind: 'Schema', range: toRange(schema), schema: schema.value, catalog: n.catalog?.value, database: n.database?.value})
