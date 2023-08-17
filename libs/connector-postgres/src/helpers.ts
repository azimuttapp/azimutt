export function buildSqlTable(schema: string, table: string) {
    const sqlSchema = schema ? `${escapeIfNeeded(schema)}.` : ''
    return `${sqlSchema}${escapeIfNeeded(table)}`
}

export function buildSqlColumn(column: string): string {
    return `'${column}'`
}

function escapeIfNeeded(name: string): string {
    return /[A-Z]/.test(name) ? `"${name}"` : name
}
