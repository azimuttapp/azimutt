import {Diff, Logger, minusFieldsDeep, pluralizeL, removeUndefined} from "@azimutt/utils";
import {
    Attribute,
    attributePathToId,
    Connector,
    Database,
    databaseDiff,
    DatabaseDiff,
    DatabaseUrlParsed,
    entityToId,
    Index,
    parseDatabaseUrl,
    relationToId,
    typeToId
} from "@azimutt/models";
import {getConnector, track} from "@azimutt/gateway";
import {version} from "./version.js";
import {loggerNoOp} from "./utils/logger.js";

export type Opts = {}

export async function launchDiff(leftUrl: string, rightUrl: string, opts: Opts, logger: Logger): Promise<void> {
    const leftUrlDb: DatabaseUrlParsed = parseDatabaseUrl(leftUrl)
    const rightUrlDb: DatabaseUrlParsed = parseDatabaseUrl(rightUrl)
    const leftConnector: Connector | undefined = getConnector(leftUrlDb)
    if (!leftConnector) return Promise.reject(`Invalid connector for ${leftUrlDb.kind ? `${leftUrlDb.kind} db` : `unknown db (${leftUrlDb.full})`} on the left`)
    const rightConnector: Connector | undefined = getConnector(rightUrlDb)
    if (!rightConnector) return Promise.reject(`Invalid connector for ${rightUrlDb.kind ? `${rightUrlDb.kind} db` : `unknown db (${rightUrlDb.full})`} on the right`)

    logger.log('Launching diff between db...')
    const app = 'azimutt-cli-diff'
    const leftDb: Database = await leftConnector.getSchema(app, leftUrlDb, {logger: loggerNoOp})
    const rightDb: Database = await rightConnector.getSchema(app, rightUrlDb, {logger: loggerNoOp})
    track('cli__diff__run', removeUndefined({
        version,
        left: {database: leftUrlDb.kind, nb_entities: leftDb.entities?.length || 0},
        right: {database: rightUrlDb.kind, nb_entities: rightDb.entities?.length || 0},
    }), 'cli').then(() => {})

    logger.log('')
    logger.log(`Left  db: found ${pluralizeL(leftDb.entities || [], 'entity')}, ${pluralizeL(leftDb.relations || [], 'relation')} and ${pluralizeL(leftDb.types || [], 'type')}.`)
    logger.log(`Right db: found ${pluralizeL(rightDb.entities || [], 'entity')}, ${pluralizeL(rightDb.relations || [], 'relation')} and ${pluralizeL(rightDb.types || [], 'type')}.`)
    logger.log('')

    const diff = databaseDiff(leftDb, rightDb)
    logger.log('\nWork In Progress...\n')
    /*const lines = showDatabaseDiff(diff)
    lines.forEach(l => logger.log(l))
    if (lines.length === 0) {
        logger.log('No diff found!')
    }*/
    logger.log('')
    logger.log('Database schema diff done!')
    logger.log('')
}

const indexToId = (i: Index): string => `${i.name}(${i.attrs.map(attributePathToId).join(', ')})`

/*function showDatabaseDiff(diff: DatabaseDiff): string[] {
    return ([] as string[]).concat(
        showDiff(diff.types, 'type', typeToId),
        showDiff(diff.relations, 'relation', relationToId),
        showItems(diff.entities?.left || [], 'entity', 'only on the left', entityToId),
        showItems(diff.entities?.right || [], 'entity', 'only on the right', entityToId),
        showItems(diff.entities?.both || [], 'entity', 'different on both', d => {
            const lines = ([] as string[]).concat(
                showDiff<Attribute>(d.attrs, 'attribute', a => a.name),
                showDiff(d.indexes, 'index', indexToId),
            ).map(l => `\n    ${l}`)
            return entityToId(d.left) + lines.join('')
        }),
    )
}*/

function showDiff<T extends object>(diff: Diff<T> | undefined, entity: string, show: (t: T) => string): string[] {
    return [
        ...showItems(diff?.left || [], entity, 'only on the left', show),
        ...showItems(diff?.right || [], entity, 'only on the right', show),
        ...showItems(diff?.both || [], entity, 'different on both', d => `${show(d.left)}: ${showVsObject(d.left, d.right)}`),
    ]
}

function showItems<T>(items: T[], entity: string, label: string, show: (t: T) => string): string[] {
    return items.length > 0 ? [`${pluralizeL(items, entity)} ${label}:`, ...items.map(i => `  - ${show(i)}`)] : []
}

function showVsObject(left: object, right: object): string {
    return `${JSON.stringify(minusFieldsDeep(left, right))} vs ${JSON.stringify(minusFieldsDeep(right, left))}`
}
