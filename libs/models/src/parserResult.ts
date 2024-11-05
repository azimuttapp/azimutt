import {z} from "zod";
import {isNotUndefined, isObject} from "@azimutt/utils";

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

    public mapError(f: (errs: ParserError[]) => ParserError[]): ParserResult<T> {
        return new ParserResult<T>(this.result, this.errors !== undefined ? f(this.errors) : undefined)
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

export const EditorPosition = z.object({line: z.number(), column: z.number()}).strict()
export type EditorPosition = z.infer<typeof EditorPosition>
export const TokenEditor = z.object({start: EditorPosition, end: EditorPosition}).strict()
export type TokenEditor = z.infer<typeof TokenEditor>
export const TokenOffset = z.object({start: z.number(), end: z.number()}).strict()
export type TokenOffset = z.infer<typeof TokenOffset>
export const TokenPosition = z.object({offset: TokenOffset, position: TokenEditor}).strict()
export type TokenPosition = z.infer<typeof TokenPosition>
export const ParserErrorLevel = z.enum(['error', 'warning', 'info', 'hint'])
export type ParserErrorLevel = z.infer<typeof ParserErrorLevel>
export const ParserError = TokenPosition.extend({message: z.string(), kind: z.string(), level: ParserErrorLevel}).strict()
export type ParserError = z.infer<typeof ParserError>

export const isParserErrorLevel = (value: unknown): value is ParserErrorLevel => typeof value === 'string' && ['error', 'warning', 'info', 'hint'].includes(value)
export const isTokenPosition = (value: unknown): value is TokenPosition => isObject(value) && ('offset' in value && isTokenOffset(value.offset)) && ('position' in value && isTokenEditor(value.position))
export const isTokenOffset = (value: unknown): value is TokenOffset => isObject(value) && ('start' in value && typeof value.start === 'number') && ('end' in value && typeof value.end === 'number')
export const isTokenEditor = (value: unknown): value is TokenEditor => isObject(value) && ('start' in value && isEditorPosition(value.start)) && ('end' in value && isEditorPosition(value.end))
export const isEditorPosition = (value: unknown): value is EditorPosition => isObject(value) && ('line' in value && typeof value.line === 'number') && ('column' in value && typeof value.column === 'number')

export const tokenPosition = (offsetStart: number, offsetEnd: number, positionStartLine: number, positionStartColumn: number, positionEndLine: number, positionEndColumn: number): TokenPosition =>
    ({offset: {start: offsetStart, end: offsetEnd}, position: {start: {line: positionStartLine, column: positionStartColumn}, end: {line: positionEndLine, column: positionEndColumn}}})

export const mergePositions = (positions: (TokenPosition | undefined)[]): TokenPosition => {
    const pos: TokenPosition[] = positions.filter(isNotUndefined).filter(p => !!p.offset)
    return ({
        offset: {start: posStart(pos.map(p => p.offset.start)), end: posEnd(pos.map(p => p.offset.end))},
        position: {
            start: {line: posStart(pos.map(p => p.position.start.line)), column: posStart(pos.map(p => p.position.start.column))},
            end: {line: posEnd(pos.map(p => p.position.end.line)), column: posEnd(pos.map(p => p.position.end.column))}
        }
    })
}

export const positionStartAdd = <T extends TokenPosition>(pos: T, value: number): T => ({
    ...pos,
    offset: {...pos.offset, start: pos.offset.start + value},
    position: {...pos.position, start: {...pos.position.start, column: pos.position.start.column + value}}
})

export const positionEndAdd = <T extends TokenPosition>(pos: T, value: number): T => ({
    ...pos,
    offset: {...pos.offset, end: pos.offset.end + value},
    position: {...pos.position, end: {...pos.position.end, column: pos.position.end.column + value}}
})

const posStart = (values: number[]): number => {
    const valid = values.filter(n => n >= 0 && !Number.isNaN(n) && Number.isFinite(n))
    return valid.length > 0 ? Math.min(...valid) : 0
}

const posEnd = (values: number[]): number => {
    const valid = values.filter(n => n >= 0 && !Number.isNaN(n) && Number.isFinite(n))
    return valid.length > 0 ? Math.max(...valid) : 0
}
