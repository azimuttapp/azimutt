import {groupBy, Logger} from "@azimutt/utils";
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
    logger.log(`\nFound ${violations.length} violations: ${RuleLevel.options.map(l => `${(violationsByLevel[l] || []).length} ${l}`).join(', ')}\n`)
    Object.entries(violationsByLevel).forEach(([level, levelViolations]) => {
        logger.log(`${levelViolations.length} ${level} violations:`)
        Object.entries(groupBy(levelViolations, v => v.ruleId)).forEach(([ruleId, ruleViolations]) => {
            logger.log(`  ${ruleViolations.length} ${ruleViolations[0].ruleName} violations:`)
            ruleViolations.slice(0, 3).forEach(violation => {
                logger.log(`    ${violation.message}`)
            })
            if (ruleViolations.length > 3) {
                logger.log(`    ${ruleViolations.length - 3} more...`)
            }
        })
    })
    logger.log(`\nFound ${violations.length} violations: ${RuleLevel.options.map(l => `${(violationsByLevel[l] || []).length} ${l}`).join(', ')}\n`)
}
