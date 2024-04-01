import {Database, ParserResult, Serde} from "@azimutt/database-model";
import {generate, parse} from "./prisma";

export const prisma: Serde = {
    name: 'Prisma',
    parse: (content: string): ParserResult<Database> => parse(content),
    generate: (db: Database): string => generate(db)
}
