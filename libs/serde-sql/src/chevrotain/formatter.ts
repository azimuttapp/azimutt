import {SelectAst, SelectColumnAst, SqlScriptAst, StatementAst} from "./ast";
import {Select, SqlScript, SqlStatement} from "../statements";
import {Column as SelectColumn} from "../statements/select";

export function format(ast: SqlScriptAst): SqlScript {
    return ast.map(formatStatement)
}

function formatStatement(stm: StatementAst): SqlStatement {
    if (stm.command === 'SELECT') {
        return formatSelect(stm)
    } else {
        throw new Error(`Unsupported command: ${stm.command}`)
    }
}

function formatSelect(select: SelectAst): Select {
    return {
        command: 'SELECT',
        language: 'DML',
        operation: 'read',
        result: {columns: select.result.columns.map(formatSelectResultColumn)},
        from: {table: {entity: select.from.table.identifier}},
        joins: []
    }
}

function formatSelectResultColumn(col: SelectColumnAst): SelectColumn {
    const alias = col.alias?.identifier
    if ('identifier' in col.column) {
        return {name: col.column.identifier, alias, content: {kind: 'column', column: [col.column.identifier], table: col.table?.identifier, schema: col.schema?.identifier}}
    } else {
        return {name: col.column.wildcard, alias, content: {kind: 'wildcard', table: col.table?.identifier, schema: col.schema?.identifier}}
    }
}
