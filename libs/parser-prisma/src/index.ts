import {Database, ParserResult} from "@azimutt/models";
import {generate, parse} from "./prisma";

export function parsePrisma(content: string, opts: { strict?: boolean, context?: Database } = {}): ParserResult<Database> {
    return parse(content)
}

export function generatePrisma(database: Database, legacy: boolean = false): string {
    return generate(database)
}
