import {ZodError, ZodType} from "zod";
import {groupBy, pluralizeL} from "@azimutt/utils";

export * from "./common"
export * from "./database"
export * from "./databaseDiff"
export * from "./databaseUrl"
export * from "./databaseUtils"
export * from "./inferSchema"
export * from "./interfaces/connector"
export * from "./interfaces/desktopBridge"
export * from "./interfaces/serde"
export * from "./legacy/legacyDatabase"
export * from "./legacy/legacyQuery"
export * from "./legacy/legacyStats"

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
