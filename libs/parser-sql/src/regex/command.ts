import {parseSelect, SelectCommand} from "./select";

export type SqlCommand = UnknownCommand | SelectCommand
export type UnknownCommand = { command: 'UNKNOWN' }

export function parseCommand(sql: string): SqlCommand {
    if (/^\s*SELECT\s/.test(sql)) return parseSelect(sql)
    return {command: 'UNKNOWN'}
}
