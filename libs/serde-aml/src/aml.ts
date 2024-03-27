import {Database, ParserResult} from "@azimutt/database-model";

export function parse(content: string): ParserResult<Database> {
    return ParserResult.failure([{name: 'GlobalException', message: 'Not implemented'}])
}

export function generate(database: Database): string {
    return 'Not implemented'
}
