import {Database} from "@azimutt/database-model";
import {SqlScript} from "./statements";

export function importDatabase(script: SqlScript): Database {
    return {extra: {source: 'serde-SQL'}}
}
