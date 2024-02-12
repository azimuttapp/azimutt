import {Database, Serde} from "@azimutt/database-model";
import {generate, parse} from "./dbml";

export const dbml: Serde = {
    name: 'DBML',
    parse: (content: string): Promise<Database> => parse(content),
    generate: (db: Database): Promise<string> => generate(db)
}
