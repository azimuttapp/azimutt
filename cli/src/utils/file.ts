import * as fs from "node:fs";
import os from "os";
import {pathParent} from "@azimutt/utils";
import { fileURLToPath } from "node:url";
import { dirname } from "node:path";

export type FilePath = string
export type FileFormat = 'json' | 'sql'

export const mkParentDirs = (path: string): void => { fs.mkdirSync(pathResolve(pathParent(path)), {recursive: true}) }
export const fileExists = (path: string): boolean => fs.existsSync(pathResolve(path))
export const fileList = (path: string): Promise<string[]> => fs.promises.readdir(pathResolve(path))
export const fileReadJson = <T extends object>(path: string): Promise<T> => fs.promises.readFile(pathResolve(path)).then(str => JSON.parse(str.toString()))
export const fileRead = (path: string): Promise<string> => fs.promises.readFile(pathResolve(path)).then(str => str.toString())
export const fileWriteJson = <T extends object>(path: string, json: T): Promise<void> => fs.promises.writeFile(pathResolve(path), JSON.stringify(json, null, 2) + '\n')
export const fileWrite = (path: string, content: string): Promise<void> => fs.promises.writeFile(pathResolve(path), content)

export const userHome = (): string => os.homedir()
export const pathResolve = (path: string): string => path.startsWith('~/') ? path.replace(/^~/, userHome()) : path

export const __filename = fileURLToPath(import.meta.url);
export const __dirname = dirname(__filename);
