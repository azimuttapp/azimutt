import {z, ZodError, ZodType} from "zod";
import {groupBy, pluralizeL} from "@azimutt/utils";

// TODO: merge both implems using libs/utils/src/result.ts

// new implem

export const zodParse = <T>(typ: ZodType<T>) => (value: any): Promise<T> => {
    const res = typ.safeParse(value)
    return res.success ? Promise.resolve(res.data) : Promise.reject(new Error(formatZodError(typ, res.error)))
}

function formatZodError<T>(typ: ZodType<T>, e: ZodError): string {
    const name = typ.description || 'ZodType'
    const len = e.issues.length
    if (len === 0) {
        return `Invalid ${name}, but no issue found...`
    } else if (len === 1) {
        const issue = e.issues[0]
        return `Invalid ${name}: ${issue.message} at ${issue.path.join('.')}`
    } else if (len <= 10) {
        return `Invalid ${name}:${e.issues.map(i => `\n- ${i.message} at ${i.path.join('.')}`).join('')}`
    } else {
        const issuesGroups = groupBy(e.issues, i => i.message + ':' + i.path.map(p => typeof p === 'number' ? '?' : p).join('.'))
        const formattedGroups = Object.entries(issuesGroups).map(([_, [issue, ...others]]) => {
            if (others.length === 0) {
                return `\n- ${issue.message} at ${issue.path.join('.')}`
            } else {
                return `\n- ${issue.message} on ${issue.path.map(p => typeof p === 'number' ? '?' : p).join('.')} (${issue.path.join('.')} and ${others.length} more)`
            }
        })
        return `Invalid ${name}, ${len} issues found in ${pluralizeL(formattedGroups, 'group')}:${formattedGroups.join('')}`
    }
}

// legacy implem

export function zodStringify<T>(value: T, zod: z.ZodType<T>, label: string): string {
    return JSON.stringify(zodValidate(value, zod, label))
}

export function zodValidate<T>(value: T, zod: z.ZodType<T>, label: string): T {
    const res = zod.safeParse(value)
    if (res.success) {
        return res.data
    } else {
        const jsonErrors = res.error.issues.map(i => issueToJson(value, i))
        const strErrors = res.error.issues.map(i => issueToString(value, i))
        // console.error(`invalid ${label}`, jsonErrors.length > 1 ? jsonErrors : jsonErrors[0], value)
        throw Error(`invalid ${label}${strErrors.length > 1 ? ` (${strErrors.length} errors)` : ''}: ${strErrors.join(', ')}`)
    }
}

function issueToString(value: any, issue: z.ZodIssue): string {
    if (issue.code === z.ZodIssueCode.unrecognized_keys) {
        return `at ${pathToString(issue.path)}: invalid additional key${issue.keys.length > 1 ? 's:' : ''} ${issue.keys.map(k => `'${k}' (${JSON.stringify(getValue(value, issue.path.concat(k)))})`).join(', ')}`
    } else if (issue.code === z.ZodIssueCode.invalid_type) {
        return `at ${pathToString(issue.path)}: expect '${issue.expected}' but got '${issue.received}' (${JSON.stringify(getValue(value, issue.path))})`
    } else if (issue.code === z.ZodIssueCode.invalid_literal) {
        return `at ${pathToString(issue.path)}: expect ${JSON.stringify(issue.expected)} but got ${JSON.stringify(getValue(value, issue.path))}`
    } else if (issue.code === z.ZodIssueCode.invalid_enum_value) {
        return `at ${pathToString(issue.path)}: expect \`${issue.options.map(o => JSON.stringify(o)).join(' | ')}\` but got ${JSON.stringify(getValue(value, issue.path))}`
    } else if (issue.code === z.ZodIssueCode.invalid_union_discriminator) {
        return `at ${pathToString(issue.path)}: expect \`${issue.options.map(o => JSON.stringify(o)).join(' | ')}\` but got ${JSON.stringify(getValue(value, issue.path))}`
    } else if (issue.code === z.ZodIssueCode.invalid_union) {
        return `at ${pathToString(issue.path)}: invalid union for ${JSON.stringify(anyTrim(getValue(value, issue.path), 3))}`
    } else {
        return issue.message
    }
}

function pathToString(path: (string | number)[]): string {
    if (path.length === 0) {
        return '_root_'
    } else {
        return `.${path.join('.')}`
    }
}

function errorToJson(value: any, error: z.ZodError): object[] {
    return error.issues.map(i => issueToJson(value, i))
}

function issueToJson(value: any, issue: z.ZodIssue): object {
    const depth = 2
    if (issue.code === z.ZodIssueCode.invalid_type) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, expected: issue.expected, received: issue.received}
    } else if (issue.code === z.ZodIssueCode.invalid_literal) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, expected: issue.expected}
    } else if (issue.code === z.ZodIssueCode.unrecognized_keys) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, keys: issue.keys}
    } else if (issue.code === z.ZodIssueCode.invalid_union) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, unionErrors: issue.unionErrors.map(e => errorToJson(value, e))}
    } else if (issue.code === z.ZodIssueCode.invalid_union_discriminator) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, options: issue.options}
    } else if (issue.code === z.ZodIssueCode.invalid_enum_value) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, options: issue.options, received: issue.received}
    } else if (issue.code === z.ZodIssueCode.invalid_arguments) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, argumentsError: issue.argumentsError}
    } else if (issue.code === z.ZodIssueCode.invalid_return_type) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, returnTypeError: issue.returnTypeError}
    } else if (issue.code === z.ZodIssueCode.invalid_date) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message}
    } else if (issue.code === z.ZodIssueCode.invalid_string) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, validation: issue.validation}
    } else if (issue.code === z.ZodIssueCode.too_small) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, type: issue.type, minimum: issue.minimum, inclusive: issue.inclusive}
    } else if (issue.code === z.ZodIssueCode.too_big) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, type: issue.type, maximum: issue.maximum, inclusive: issue.inclusive}
    } else if (issue.code === z.ZodIssueCode.invalid_intersection_types) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message}
    } else if (issue.code === z.ZodIssueCode.not_multiple_of) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, multipleOf: issue.multipleOf}
    } else if (issue.code === z.ZodIssueCode.custom) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, params: issue.params}
    } else {
        throw `Unhandled ZodIssue!`
    }
}

export function zodErrorToString(value: any, error: z.ZodError): string {
    const issues = error.issues
    return `${issues.length} validation error:${issues.map(i => `\n - ${issueToString(value, i)}`)}`
}

function getValue(value: any, path: (string | number)[]): any {
    if (path.length === 0 || value === undefined || value === null) {
        return value
    } else {
        const [head, ...tail] = path
        return getValue(value[head], tail)
    }
}

function anyTrim(value: any, depth: number): any {
    if (Array.isArray(value)) {
        return depth <= 0 ? '?' : (value.length > 3 ? value.slice(0, 3).concat(['...']) : value).map(v => anyTrim(v, depth - 1))
    } else if (value === null) {
        return value
    } else if (typeof value === 'object') {
        return depth <= 0 ? '?' : Object.fromEntries(Object.entries(value).map(([key, value]) => [key, anyTrim(value, depth - 1)]))
    } else if (typeof value === 'string') {
        return value.length > 30 ? value.substring(0, 30) + '...' : value
    } else {
        return value
    }
}
