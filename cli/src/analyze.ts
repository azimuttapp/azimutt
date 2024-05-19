import {groupBy, Logger, partition, pluralizeL, removeEmpty} from "@azimutt/utils";
import {
    analyzeDatabase,
    Connector,
    Database,
    DatabaseQuery,
    DatabaseUrlParsed,
    parseDatabaseUrl,
    RuleAnalyzed,
    RuleId,
    RuleLevel,
    RulesConf,
    RuleViolation,
    zodParseAsync
} from "@azimutt/models";
import {getConnector, track} from "@azimutt/gateway";
import {loggerNoOp} from "./utils/logger.js";
import {fileExists, fileReadJson, fileWriteJson, mkParentDirs} from "./utils/file.js";

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

    // if license: read previous analyses, compute trends and write result as JSON in ~/.azimutt/analyze/db_name/2024-05-19.json
    // if email: read rule conf and print them in the console, advertize about license benefits
    // if nothing: logger.log(`Found x violations from y rules, a high, b medium, c low and d hint.\nProvide your pro email as parameter (ex: --email "loic@azimutt.app") to get the detail`)
    // TODO: read config from ~/.azimutt/analyze/conf.json ({user: {}, schema: {}, queries: {}, data: {}, 'rule-1': {}...})
    const app = 'azimutt-analyze'
    const folder = `~/.azimutt/analyze${parsed.db ? '/' + parsed.db : ''}`
    const confPath = `${folder}/conf.json`
    const conf: RulesConf = await loadConf(confPath, logger)
    const db: Database = await connector.getSchema(app, parsed, {logger: loggerNoOp})
    const queries: DatabaseQuery[] = await connector.getQueryHistory(app, parsed, {logger: loggerNoOp, database: parsed.db}).catch(err => {
        if (typeof err === 'string' && err === 'Not implemented') logger.log(`Query history is not supported yet on ${parsed.kind}, ping us ;)`)
        if (typeof err === 'object' && 'message' in err && err.message.indexOf('"pg_stat_statements" does not exist')) logger.log(`Can't get query history as pg_stat_statements is not enabled. Enable it for a better db analysis.`)
        return []
    })
    const rules = analyzeDatabase(conf, db, queries, opts.only?.split(',') || [])

    await updateConf(confPath, conf, rules, logger)
    const shownLevels = RuleLevel.options.filter(l => l !== RuleLevel.enum.off)
    const [offRules, usedRules] = partition(Object.values(rules), r => r.conf.level === RuleLevel.enum.off)
    const violations: RuleViolation[] = Object.values(usedRules).flatMap(v => v.violations)
    const violationsByLevel: Record<RuleLevel, RuleViolation[]> = groupBy(violations, v => v.ruleLevel)

    logger.log('')
    if (offRules.length > 0) {
        logger.log(`${pluralizeL(offRules, 'off rule')}: ${offRules.map(r => r.rule.name).join(', ')}`)
    }
    shownLevels.slice().reverse().forEach(level => {
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
    logger.log(`Found ${pluralizeL(db.entities || [], 'entity')}, ${pluralizeL(db.relations || [], 'relation')}, ${pluralizeL(queries, 'query')} and ${pluralizeL(db.types || [], 'type')} on the database.`)
    logger.log(`Found ${violations.length} violations with ${usedRules.length} rules: ${shownLevels.map(l => `${(violationsByLevel[l] || []).length} ${l}`).join(', ')}.`)
    logger.log('')
}

async function loadConf(path: string, logger: Logger): Promise<RulesConf> {
    if (fileExists(path)) {
        logger.log(`Loading conf from ${path}`)
        return await fileReadJson<RulesConf>(path).then(zodParseAsync(RulesConf))
    } else {
        mkParentDirs(path)
        const conf: RulesConf = {} // initial conf
        await fileWriteJson<RulesConf>(path, conf)
        return conf
    }
}

async function updateConf(path: string, conf: RulesConf, rules: Record<RuleId, RuleAnalyzed>, logger: Logger): Promise<void> {
    const usedConf: RulesConf = removeEmpty({
        ...conf,
        rules: Object.entries(rules).reduce((c, [id, {conf}]) => Object.assign(c, {[id]: conf}), conf.rules || {})
    })
    await fileWriteJson(path, usedConf)
}
