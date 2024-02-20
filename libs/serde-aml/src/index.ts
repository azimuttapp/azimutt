import {Database, Serde} from "@azimutt/database-model";
import {generate, parse} from "./aml";

export const dbml: Serde = {
    name: 'AML',
    parse: (content: string): Promise<Database> => parse(content),
    generate: (db: Database): Promise<string> => generate(db)
}
