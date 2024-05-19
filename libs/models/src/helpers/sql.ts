import {maxLen, removeUndefined} from "@azimutt/utils";
import {EntityRef} from "../database";

export function getMainEntity(sql: string): EntityRef | undefined {
    const [, res] = sql.match(/\s+FROM\s+((?:["'`\[]?\b\w+\b["'`\]]?\.)?["'`\[]?\b\w+\b["'`\]]?)(?:\s|;)/) || []
    const [entity, schema] = res?.replaceAll(/["'`\[\]]/g, '')?.split('.')?.reverse() || []
    return entity ? removeUndefined({entity, schema}) : undefined
}

export function formatSql(sql: string): string {
    const maxLength = 200
    const singleLine = sql.split('\n')
        .map(line => line.replaceAll(/\s+/g, ' ').replaceAll(/--.*/g, '').trim())
        .map((line, i) => i === 0 || line.startsWith(',') ? line : ' ' + line)
        .join('')
    if (singleLine.length > maxLength) {
        const [, select, other] = singleLine.match(/^SELECT\s+(.+)\s+FROM(.*)/) || []
        return maxLen(select ? `SELECT ${maxLen(select, 40)} FROM${other}` : singleLine, maxLength)
    } else {
        return singleLine
    }
}
