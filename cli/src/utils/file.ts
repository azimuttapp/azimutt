import {promises as fs} from "fs";

export type FilePath = string
export type FileFormat = 'json' | 'sql'

export function writeJsonFile(path: string, json: object): Promise<void> {
    return fs.writeFile(path, JSON.stringify(json, null, 2) + '\n')
}
