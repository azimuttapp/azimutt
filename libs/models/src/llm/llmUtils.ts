import {isNotUndefined} from "@azimutt/utils";
import {Database, Entity, Relation} from "../database";
import {attributePathToId, entityRefToId, entityToId} from "../databaseUtils";

export function dbToPrompt(db: Database): string {
    const entities = (db.entities || []).map(entityToPrompt).filter(isNotUndefined)
    const relations = (db.relations || []).map(relationToPrompt)
    return `\`\`\`
${entities.concat(relations).join('\n')}
\`\`\``
}

export function entityToPrompt(e: Entity): string | undefined {
    if (e.kind === undefined || e.kind === 'table') {
        return `CREATE TABLE ${entityToId(e)} (${e.attrs.map(a => `${a.name} ${a.type}`).join(', ')});`
    } else {
        return undefined
    }
}

export function relationToPrompt(r: Relation): string {
    const src = entityRefToId(r.src)
    const ref = entityRefToId(r.ref)
    const srcAttrs = r.attrs.map(a => attributePathToId(a.src)).join(', ')
    const refAttrs = r.attrs.map(a => attributePathToId(a.ref)).join(', ')
    return `ALTER TABLE ${src} ADD CONSTRAINT ${r.name || ''} FOREIGN KEY (${srcAttrs}) REFERENCES ${ref} (${refAttrs});`
}
