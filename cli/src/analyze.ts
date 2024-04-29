import {groupBy, Logger, pluralizeL} from "@azimutt/utils";
import {
    analyzeDatabase,
    Connector,
    Database,
    DatabaseUrlParsed,
    parseDatabaseUrl,
    RuleViolation,
    RuleLevel
} from "@azimutt/models";
import {getConnector} from "@azimutt/gateway";
import {loggerNoOp} from "./utils/logger.js";

export async function launchAnalyze(url: string, logger: Logger): Promise<void> {
    const parsed: DatabaseUrlParsed = parseDatabaseUrl(url)
    const connector: Connector | undefined = getConnector(parsed)
    if (!connector) return Promise.reject('Invalid connector')

    const db: Database = await connector.getSchema('azimutt-analyze', parsed, {logger: loggerNoOp})
    const violations: RuleViolation[] = analyzeDatabase(db)

    const violationsByLevel: Record<RuleLevel, RuleViolation[]> = groupBy(violations, v => v.ruleLevel)
    RuleLevel.options.slice().reverse().forEach((level) => {
        const levelViolations = violationsByLevel[level] || []
        logger.log(`${levelViolations.length} ${level} violations:`)
        Object.values(groupBy(levelViolations, v => v.ruleId)).forEach(ruleViolations => {
            logger.log(`  ${ruleViolations.length} ${ruleViolations[0].ruleName} violations:`)
            ruleViolations.slice(0, 3).forEach(violation => {
                logger.log(`    - ${violation.message}`)
            })
            if (ruleViolations.length > 3) {
                logger.log(`    ${ruleViolations.length - 3} more...`)
            }
        })
    })
    logger.log('')
    logger.log(`Found ${pluralizeL(db.entities || [], 'entity')}, ${pluralizeL(db.relations || [], 'relation')} and ${pluralizeL(db.types || [], 'type')} on the database.`)
    logger.log(`Found ${violations.length} violations: ${RuleLevel.options.map(l => `${(violationsByLevel[l] || []).length} ${l}`).join(', ')}.`)
    logger.log('')
}
