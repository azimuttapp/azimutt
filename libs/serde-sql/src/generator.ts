import {Database, DatabaseDiff} from "@azimutt/database-model";
import {SqlScript} from "./statements";
import {exportDatabase} from "./sqlExport";

export function generateDatabase(db: Database): string {
    return generate(exportDatabase(db))
}

export function generateDatabaseDiff(diff: DatabaseDiff): string {
    return generate([])
}

export function generate(sql: SqlScript): string {
    return ''
}
