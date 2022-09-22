import {ZodError, ZodIssue, ZodIssueCode} from "zod";
import {ZodType} from "zod/lib/types";

export function validate<T>(value: any, zod: ZodType<T>): T {
    try {
        return zod.parse(value)
    } catch (e) {
        if (e instanceof ZodError) {
            throw Error(errorToString(value, e))
        } else {
            throw e
        }
    }
}

function issueToString(value: any, issue: ZodIssue): string {
    if (issue.code === ZodIssueCode.unrecognized_keys) {
        return `${pathToString(issue.path)}: invalid additional key${issue.keys.length > 1 ? 's:' : ''} ${issue.keys.map(k => `'${k}' (${JSON.stringify(getValue(value, issue.path.concat(k)))})`).join(', ')}`
    } else if (issue.code === ZodIssueCode.invalid_type) {
        return `${pathToString(issue.path)}: expect '${issue.expected}' but got '${issue.received}' (${JSON.stringify(getValue(value, issue.path))})`
    } else if (issue.code === ZodIssueCode.invalid_literal) {
        return `${pathToString(issue.path)}: expect ${JSON.stringify(issue.expected)} but got ${JSON.stringify(getValue(value, issue.path))}`
    } else if (issue.code === ZodIssueCode.invalid_enum_value) {
        return `${pathToString(issue.path)}: expect \`${issue.options.map(o => JSON.stringify(o)).join(' | ')}\` but got ${JSON.stringify(getValue(value, issue.path))}`
    } else if (issue.code === ZodIssueCode.invalid_union_discriminator) {
        return `${pathToString(issue.path)}: expect \`${issue.options.map(o => JSON.stringify(o)).join(' | ')}\` but got ${JSON.stringify(getValue(value, issue.path))}`
    } else if (issue.code === ZodIssueCode.invalid_union) {
        return `${pathToString(issue.path)}: invalid union for ${JSON.stringify(anyTrim(getValue(value, issue.path), 3))}`
    } else {
        return issue.message
    }
}

function pathToString(path: (string | number)[]): string {
    if (path.length === 0) {
        return '_root_'
    } else {
        return `'${path.join('.')}'`
    }
}

function errorToJson(value: any, error: ZodError): object[] {
    return error.issues.map(i => issueToJson(value, i))
}

function issueToJson(value: any, issue: ZodIssue): object {
    const depth = 2
    if (issue.code === ZodIssueCode.invalid_type) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, expected: issue.expected, received: issue.received}
    } else if (issue.code === ZodIssueCode.invalid_literal) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, expected: issue.expected}
    } else if (issue.code === ZodIssueCode.unrecognized_keys) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, keys: issue.keys}
    } else if (issue.code === ZodIssueCode.invalid_union) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, unionErrors: issue.unionErrors.map(e => errorToJson(value, e))}
    } else if (issue.code === ZodIssueCode.invalid_union_discriminator) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, options: issue.options}
    } else if (issue.code === ZodIssueCode.invalid_enum_value) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, options: issue.options, received: issue.received}
    } else if (issue.code === ZodIssueCode.invalid_arguments) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, argumentsError: issue.argumentsError}
    } else if (issue.code === ZodIssueCode.invalid_return_type) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, returnTypeError: issue.returnTypeError}
    } else if (issue.code === ZodIssueCode.invalid_date) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message}
    } else if (issue.code === ZodIssueCode.invalid_string) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, validation: issue.validation}
    } else if (issue.code === ZodIssueCode.too_small) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, type: issue.type, minimum: issue.minimum, inclusive: issue.inclusive}
    } else if (issue.code === ZodIssueCode.too_big) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, type: issue.type, maximum: issue.maximum, inclusive: issue.inclusive}
    } else if (issue.code === ZodIssueCode.invalid_intersection_types) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message}
    } else if (issue.code === ZodIssueCode.not_multiple_of) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, multipleOf: issue.multipleOf}
    } else if (issue.code === ZodIssueCode.custom) {
        return {code: issue.code, path: issue.path, value: anyTrim(getValue(value, issue.path), depth), message: issue.message, params: issue.params}
    } else {
        throw `Unhandled ZodIssue!`
    }
}

export function errorToString(value: any, error: ZodError): string {
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
        return depth <= 0 ? [] : (value.length > 3 ? value.slice(0, 3).concat(['...']) : value).map(v => anyTrim(v, depth - 1))
    } else if (typeof value === null) {
        return value
    } else if (typeof value === 'object') {
        return depth <= 0 ? {} : Object.fromEntries(Object.entries(value).map(([key, value]) => [key, anyTrim(value, depth - 1)]))
    } else if (typeof value === 'string') {
        return value.length > 20 ? value.substring(0, 20) + '...' : value
    } else {
        return value
    }
}
