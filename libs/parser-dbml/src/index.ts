import {Database, ParserResult} from "@azimutt/models";
import {generate, parse} from "./dbml";

export function parseDbml(content: string, opts: { strict?: boolean, context?: Database } = {}): ParserResult<Database> {
    return parse(content)
}

export function generateDbml(database: Database, legacy: boolean = false): string {
    return generate(database)
}
