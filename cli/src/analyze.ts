import {groupBy, Logger, pluralizeL} from "@azimutt/utils";
import {
    analyzeDatabase,
    Connector,
    Database,
    DatabaseUrlParsed,
    parseDatabaseUrl,
    RuleLevel,
    RuleViolation
} from "@azimutt/models";
import {getConnector, track} from "@azimutt/gateway";
import {loggerNoOp} from "./utils/logger.js";

export type Opts = {
    size: number
    only?: string
}

// TODO: add config to choose and configure rules (thresholds & ignores)
export async function launchAnalyze(url: string, opts: Opts, logger: Logger): Promise<void> {
    const parsed: DatabaseUrlParsed = parseDatabaseUrl(url)
    track('cli__analyze__run', {database: parsed.kind}, 'cli').then(() => {})
    const connector: Connector | undefined = getConnector(parsed)
    if (!connector) return Promise.reject('Invalid connector')

    // TODO: allow config to get schema
    const db: Database = await connector.getSchema('azimutt-analyze', parsed, {logger: loggerNoOp})
    const violations: RuleViolation[] = analyzeDatabase(db, opts.only?.split(',') || [])

    const violationsByLevel: Record<RuleLevel, RuleViolation[]> = groupBy(violations, v => v.ruleLevel)
    RuleLevel.options.slice().reverse().forEach((level) => {
        const levelViolations = violationsByLevel[level] || []
        logger.log(`${levelViolations.length} ${level} violations:`)
        Object.values(groupBy(levelViolations, v => v.ruleId)).forEach(ruleViolations => {
            logger.log(`  ${ruleViolations.length} ${ruleViolations[0].ruleName}:`)
            ruleViolations.slice(0, opts.size).forEach(violation => {
                logger.log(`    - ${violation.message}`)
            })
            if (ruleViolations.length > opts.size) {
                logger.log(`    ... ${ruleViolations.length - opts.size} more`)
            }
        })
    })
    logger.log('')
    logger.log(`Found ${pluralizeL(db.entities || [], 'entity')}, ${pluralizeL(db.relations || [], 'relation')} and ${pluralizeL(db.types || [], 'type')} on the database.`)
    logger.log(`Found ${violations.length} violations: ${RuleLevel.options.map(l => `${(violationsByLevel[l] || []).length} ${l}`).join(', ')}.`)
    logger.log('')
}
