import {Database} from "@azimutt/models";
import packageJson from "../package.json";
import {SqlScript} from "./statements";

export function importDatabase(script: SqlScript): Database {
    return {extra: {source: `SQL parser <${packageJson.version}>`}}
}
