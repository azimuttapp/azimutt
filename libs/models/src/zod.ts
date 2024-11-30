import {z, ZodError, ZodIssue, ZodType} from "zod";
import {limitDepth, getValueDeep, groupBy, pluralizeL, Result, stringify} from "@azimutt/utils";

export const zodParse = <T>(typ: ZodType<T>, label?: string) => (value: T): Result<T, string> => {
    const res = typ.safeParse(value)
    return res.success ? Result.success(res.data) : Result.failure(zodErrorToString(res.error, typ, label, value))
}

export const zodParseAsync = <T>(typ: ZodType<T>, label?: string) => (value: T): Promise<T> => zodParse(typ, label)(value).mapError(e => new Error(e)).toPromise()
export const zodStringify = <T>(typ: ZodType<T>, label?: string) => (value: T): string => JSON.stringify(zodParse(typ, label)(value).getOrThrow())

const pathToString = (path: (string | number)[]): string => path.length === 0 ? '_root_' : `.${path.join('.')}`
const normalizePath = (path: (string | number)[]): string => pathToString(path.map(p => typeof p === 'number' ? '?' : p))

function zodErrorToString<T>(e: ZodError, typ: ZodType<T>, label: string | undefined, value: any): string {
    const name = label || typ.description || 'ZodType'
    const len = e.issues.length
    if (len === 0) {
        return `Invalid ${name}, but no issue found...`
    } else if (len === 1) {
        return `Invalid ${name}, ${zodIssueToString(e.issues[0], value)}`
    } else if (len <= 10) {
        return `Invalid ${name}, ${len} issues:${e.issues.map(i => `\n- ${zodIssueToString(i, value)}`).join('')}`
    } else {
        const issuesGroups = groupBy(e.issues, i => i.message + ':' + normalizePath(i.path))
        const formattedGroups = Object.entries(issuesGroups).map(([_, [issue, ...others]]) => {
            if (others.length === 0) {
                return `\n- ${zodIssueToString(issue, value)}`
            } else {
                return `\n- at ${normalizePath(issue.path)}: ${zodIssueMessageToString(issue, value)} (${pathToString(issue.path)} and ${others.length} more)`
            }
        })
        return `Invalid ${name}, ${len} issues found in ${pluralizeL(formattedGroups, 'group')}:${formattedGroups.join('')}`
    }
}

function zodIssueToString(issue: ZodIssue, value: any): string {
    return `at ${pathToString(issue.path)}: ${zodIssueMessageToString(issue, value)}`
}

function zodIssueMessageToString(issue: ZodIssue, value: any): string {
    if (issue.code === z.ZodIssueCode.unrecognized_keys) {
        return `invalid additional key${issue.keys.length > 1 ? 's:' : ''} ${issue.keys.map(k => `'${k}' (${stringify(getValueDeep(value, issue.path.concat(k)))})`).join(', ')}`
    } else if (issue.code === z.ZodIssueCode.invalid_type) {
        return `expect '${issue.expected}' but got '${issue.received}' (${stringify(getValueDeep(value, issue.path))})`
    } else if (issue.code === z.ZodIssueCode.invalid_literal) {
        return `expect ${stringify(issue.expected)} but got ${stringify(getValueDeep(value, issue.path))}`
    } else if (issue.code === z.ZodIssueCode.invalid_enum_value) {
        return `expect \`${issue.options.map(o => stringify(o)).join(' | ')}\` but got ${stringify(getValueDeep(value, issue.path))}`
    } else if (issue.code === z.ZodIssueCode.invalid_union_discriminator) {
        return `expect \`${issue.options.map(o => stringify(o)).join(' | ')}\` but got ${stringify(getValueDeep(value, issue.path))}`
    } else if (issue.code === z.ZodIssueCode.invalid_union) {
        return `invalid union for ${stringify(limitDepth(getValueDeep(value, issue.path), 3))}`
    } else {
        return issue.message
    }
}

function zodErrorToJson(error: z.ZodError, value: any): object[] {
    return error.issues.map(i => zodIssueToJson(i, value))
}

function zodIssueToJson(issue: z.ZodIssue, value: any): object {
    const depth = 2
    if (issue.code === z.ZodIssueCode.invalid_type) {
        return {code: issue.code, path: issue.path, value: limitDepth(getValueDeep(value, issue.path), depth), message: issue.message, expected: issue.expected, received: issue.received}
    } else if (issue.code === z.ZodIssueCode.invalid_literal) {
        return {code: issue.code, path: issue.path, value: limitDepth(getValueDeep(value, issue.path), depth), message: issue.message, expected: issue.expected}
    } else if (issue.code === z.ZodIssueCode.unrecognized_keys) {
        return {code: issue.code, path: issue.path, value: limitDepth(getValueDeep(value, issue.path), depth), message: issue.message, keys: issue.keys}
    } else if (issue.code === z.ZodIssueCode.invalid_union) {
        return {code: issue.code, path: issue.path, value: limitDepth(getValueDeep(value, issue.path), depth), message: issue.message, unionErrors: issue.unionErrors.map(e => zodErrorToJson(e, value))}
    } else if (issue.code === z.ZodIssueCode.invalid_union_discriminator) {
        return {code: issue.code, path: issue.path, value: limitDepth(getValueDeep(value, issue.path), depth), message: issue.message, options: issue.options}
    } else if (issue.code === z.ZodIssueCode.invalid_enum_value) {
        return {code: issue.code, path: issue.path, value: limitDepth(getValueDeep(value, issue.path), depth), message: issue.message, options: issue.options, received: issue.received}
    } else if (issue.code === z.ZodIssueCode.invalid_arguments) {
        return {code: issue.code, path: issue.path, value: limitDepth(getValueDeep(value, issue.path), depth), message: issue.message, argumentsError: issue.argumentsError}
    } else if (issue.code === z.ZodIssueCode.invalid_return_type) {
        return {code: issue.code, path: issue.path, value: limitDepth(getValueDeep(value, issue.path), depth), message: issue.message, returnTypeError: issue.returnTypeError}
    } else if (issue.code === z.ZodIssueCode.invalid_date) {
        return {code: issue.code, path: issue.path, value: limitDepth(getValueDeep(value, issue.path), depth), message: issue.message}
    } else if (issue.code === z.ZodIssueCode.invalid_string) {
        return {code: issue.code, path: issue.path, value: limitDepth(getValueDeep(value, issue.path), depth), message: issue.message, validation: issue.validation}
    } else if (issue.code === z.ZodIssueCode.too_small) {
        return {code: issue.code, path: issue.path, value: limitDepth(getValueDeep(value, issue.path), depth), message: issue.message, type: issue.type, minimum: issue.minimum, inclusive: issue.inclusive}
    } else if (issue.code === z.ZodIssueCode.too_big) {
        return {code: issue.code, path: issue.path, value: limitDepth(getValueDeep(value, issue.path), depth), message: issue.message, type: issue.type, maximum: issue.maximum, inclusive: issue.inclusive}
    } else if (issue.code === z.ZodIssueCode.invalid_intersection_types) {
        return {code: issue.code, path: issue.path, value: limitDepth(getValueDeep(value, issue.path), depth), message: issue.message}
    } else if (issue.code === z.ZodIssueCode.not_multiple_of) {
        return {code: issue.code, path: issue.path, value: limitDepth(getValueDeep(value, issue.path), depth), message: issue.message, multipleOf: issue.multipleOf}
    } else if (issue.code === z.ZodIssueCode.custom) {
        return {code: issue.code, path: issue.path, value: limitDepth(getValueDeep(value, issue.path), depth), message: issue.message, params: issue.params}
    } else {
        throw `Unhandled ZodIssue!`
    }
}
