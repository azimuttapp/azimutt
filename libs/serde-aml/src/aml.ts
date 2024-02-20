import {Database} from "@azimutt/database-model";

export function parse(content: string): Promise<Database> {
    return Promise.reject(new Error('Not implemented'))
}

export function generate(database: Database): Promise<string> {
    return Promise.reject(new Error('Not implemented'))
}
