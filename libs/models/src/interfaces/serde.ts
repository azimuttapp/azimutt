import {isNotUndefined, isObject} from "@azimutt/utils";
import {Database} from "../database";

// every serde should implement this interface
export interface Serde {
    name: string
    parse(content: string): ParserResult<Database>
    generate(db: Database): string
}

export type ParserError = { name: string, kind: ParserErrorKind, message: string } & TokenPosition
export type ParserErrorKind = 'error' | 'warning' | 'info' | 'hint'
export type TokenPosition = {offset: TokenOffset, position: TokenEditor}
export type TokenOffset = {start: number, end: number}
export type TokenEditor = {start: EditorPosition, end: EditorPosition}
export type EditorPosition = {line: number, column: number}

export const isParserErrorKind = (value: unknown): value is ParserErrorKind => typeof value === 'string' && ['error', 'warning', 'info', 'hint'].includes(value)
export const isTokenPosition = (value: unknown): value is TokenPosition => isObject(value) && ('offset' in value && isTokenOffset(value.offset)) && ('position' in value && isTokenEditor(value.position))
export const isTokenOffset = (value: unknown): value is TokenOffset => isObject(value) && ('start' in value && typeof value.start === 'number') && ('end' in value && typeof value.end === 'number')
export const isTokenEditor = (value: unknown): value is TokenEditor => isObject(value) && ('start' in value && isEditorPosition(value.start)) && ('end' in value && isEditorPosition(value.end))
export const isEditorPosition = (value: unknown): value is EditorPosition => isObject(value) && ('line' in value && typeof value.line === 'number') && ('column' in value && typeof value.column === 'number')

export const tokenPosition = (offsetStart: number, offsetEnd: number, positionStartLine: number, positionStartColumn: number, positionEndLine: number, positionEndColumn: number): TokenPosition =>
    ({offset: {start: offsetStart, end: offsetEnd}, position: {start: {line: positionStartLine, column: positionStartColumn}, end: {line: positionEndLine, column: positionEndColumn}}})

export const parserError = (name: string, kind: ParserErrorKind, message: string, offsetStart: number, offsetEnd: number, positionStartLine: number, positionStartColumn: number, positionEndLine: number, positionEndColumn: number): ParserError =>
    ({name, kind, message, ...tokenPosition(offsetStart, offsetEnd, positionStartLine, positionStartColumn, positionEndLine, positionEndColumn)})

export const mergePositions = (positions: (TokenPosition | undefined)[]): TokenPosition => {
    const pos: TokenPosition[] = positions.filter(isNotUndefined)
    return ({
        offset: {start: posStart(pos.map(p => p.offset.start)), end: posEnd(pos.map(p => p.offset.end))},
        position: {
            start: {line: posStart(pos.map(p => p.position.start.line)), column: posStart(pos.map(p => p.position.start.column))},
            end: {line: posEnd(pos.map(p => p.position.end.line)), column: posEnd(pos.map(p => p.position.end.column))}
        }
    })
}

const posStart = (values: number[]): number => {
    const valid = values.filter(n => n >= 0 && !isNaN(n) && isFinite(n))
    return valid.length > 0 ? Math.min(...valid) : 0
}

const posEnd = (values: number[]): number => {
    const valid = values.filter(n => n >= 0 && !isNaN(n) && isFinite(n))
    return valid.length > 0 ? Math.max(...valid) : 0
}

export class ParserResult<T> {
    constructor(public result?: T, public errors?: ParserError[]) {
        if (this.errors?.length === 0) this.errors = undefined
        Object.freeze(this)
    }

    public static success<U>(result: U): ParserResult<U> {
        return new ParserResult<U>(result)
    }

    public static failure<U>(errors: ParserError[]): ParserResult<U> {
        return new ParserResult<U>(undefined, errors)
    }

    public map<U>(f: (t: T) => U): ParserResult<U> {
        return new ParserResult<U>(this.result !== undefined ? f(this.result) : undefined, this.errors)
    }

    public flatMap<U>(f: (t: T) => ParserResult<U>): ParserResult<U> {
        if (this.result !== undefined) {
            const res = f(this.result)
            const errors = (this.errors || []).concat(res.errors || [])
            return new ParserResult<U>(res.result, errors)
        } else {
            return new ParserResult<U>(undefined, this.errors)
        }
    }

    public fold<U>(onSuccess: (t: T) => U, onFailure: (e: ParserError[]) => U): U {
        return this.result !== undefined ? onSuccess(this.result) : onFailure(this.errors || [])
    }
}
