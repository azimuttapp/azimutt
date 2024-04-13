import {Database} from "@azimutt/models";
import {SqlScript} from "./statements";

export function importDatabase(script: SqlScript): Database {
    return {extra: {source: 'serde-SQL'}}
}
