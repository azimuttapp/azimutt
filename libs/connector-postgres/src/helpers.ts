export function buildSqlTable(schema: string, table: string) {
    const sqlSchema = schema ? `${escapeIfNeeded(schema)}.` : ''
    return `${sqlSchema}${escapeIfNeeded(table)}`
}

function escapeIfNeeded(name: string): string {
    return /[A-Z]/.test(name) ? `"${name}"` : name
}
