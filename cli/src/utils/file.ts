import * as fs from "node:fs";
import os from "os";
import {pathParent} from "@azimutt/utils";

export type FilePath = string
export type FileFormat = 'json' | 'sql'

export const mkParentDirs = (path: string): void => { fs.mkdirSync(pathResolve(pathParent(path)), {recursive: true}) }
export const fileExists = (path: string): boolean => fs.existsSync(pathResolve(path))
export const fileReadJson = <T extends object>(path: string): Promise<T> => fs.promises.readFile(pathResolve(path)).then(str => JSON.parse(str.toString()))
export const fileWriteJson = <T extends object>(path: string, json: T): Promise<void> => fs.promises.writeFile(pathResolve(path), JSON.stringify(json, null, 2) + '\n')

export const userHome = (): string => os.homedir()
export const pathResolve = (path: string): string => path.startsWith('~/') ? path.replace(/^~/, userHome()) : path
