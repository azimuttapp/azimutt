import {AttributePath, EntityRef, SqlFragment} from "@azimutt/database-model";

export function buildSqlTable(ref: EntityRef): SqlFragment {
    // TODO: escape tables with special names (keywords or non-standard)
    return `${ref.schema ? `${ref.schema}.` : ''}${ref.entity}`
}

export function buildSqlColumn(path: AttributePath): SqlFragment {
    return path.join('.') // FIXME: handle nested columns (JSON)
}
