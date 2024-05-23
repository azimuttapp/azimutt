import chalk from "chalk";
import {z} from "zod";
import {
    dateToIsoFilename,
    emailParse,
    groupBy,
    Logger,
    mapValues,
    partition,
    pathJoin,
    pluralize,
    pluralizeL,
    publicEmailDomains,
    removeEmpty,
    removeUndefined
} from "@azimutt/utils";
import {
    analyzeDatabase,
    AttributePath,
    Connector,
    Database,
    DatabaseQuery,
    DatabaseUrlParsed,
    EntityRef,
    parseDatabaseUrl,
    RuleAnalyzed,
    RuleId,
    RuleLevel,
    ruleLevelsShown,
    RulesConf,
    zodParse,
    zodParseAsync
} from "@azimutt/models";
import {getConnector, track} from "@azimutt/gateway";
import {loggerNoOp} from "./utils/logger.js";
import {fileExists, fileReadJson, fileWriteJson, mkParentDirs} from "./utils/file.js";

export type Opts = {
    folder?: string
    email?: string
    size?: number
    only?: string
    key?: string
}

// TODO: key check => store previous results (db, queries & violations) to compute trends
// TODO: add config for user, db, query & data
export async function launchAnalyze(url: string, opts: Opts, logger: Logger): Promise<void> {
    const dbUrl: DatabaseUrlParsed = parseDatabaseUrl(url)
    const connector: Connector | undefined = getConnector(dbUrl)
    if (!connector) return Promise.reject(`Invalid connector for ${dbUrl.kind ? `${dbUrl.kind} db` : `unknown db (${dbUrl.full})`}`)
    if (opts.email && !isValidEmail(opts.email, logger)) return Promise.reject(`Invalid email (${opts.email})`)

    // if license: read previous analyses, compute trends and write result as JSON in ~/.azimutt/analyze/db_name/2024-05-19.json
    // if email: read rule conf and print them in the console, advertise about license benefits
    // if nothing: logger.log(`Found x violations from y rules, a high, b medium, c low and d hint.\nProvide your pro email as parameter (ex: --email "loic@azimutt.app") to get the detail`)
    // TODO: read config from ~/.azimutt/analyze/conf.json ({user: {}, schema: {}, queries: {}, data: {}, 'rule-1': {}...})
    const app = 'azimutt-analyze'
    const folder = opts.folder || `~/.azimutt/analyze${dbUrl.db ? '/' + dbUrl.db : ''}`
    const conf: RulesConf = await loadConf(folder, logger)
    const db: Database = await connector.getSchema(app, dbUrl, {logger: loggerNoOp})
    const queries: DatabaseQuery[] = await connector.getQueryHistory(app, dbUrl, {logger: loggerNoOp, database: dbUrl.db}).catch(err => {
        if (typeof err === 'string' && err === 'Not implemented') logger.log(`Query history is not supported yet on ${dbUrl.kind}, ping us ;)`)
        if (typeof err === 'object' && 'message' in err && err.message.indexOf('"pg_stat_statements" does not exist')) logger.log(`Can't get query history as pg_stat_statements is not enabled. Enable it for a better db analysis.`)
        return []
    })
    // TODO: const previousReports = isValidKey(dbUrl, opts.email, opts.key) ? await loadPreviousReports(folder) : []
    const rules: Record<RuleId, RuleAnalyzed> = analyzeDatabase(conf, db, queries, opts.only?.split(',') || [])
    const [offRules, usedRules] = partition(Object.values(rules), r => r.conf.level === RuleLevel.enum.off)
    const rulesByLevel: Record<RuleLevel, RuleAnalyzed[]> = groupBy(usedRules, r => r.conf.level)
    const stats = buildStats(db, queries, rulesByLevel)
    track('cli__analyze__run', removeUndefined({database: dbUrl.kind, ...stats, email: opts.email, key: opts.key}), 'cli').then(() => {})
    await updateConf(folder, conf, rules)

    if (opts.email) {
        const maxShown = opts.size || 3
        printReport(offRules, rulesByLevel, maxShown, stats, logger)
        const report = buildReport(db, queries, rules)
        await writeReport(folder, report, logger)
    } else {
        const maxShown = 3
        printReport(offRules, rulesByLevel, maxShown, stats, logger)
        logger.log(chalk.hex('#3b82f6')('Thanks for using Azimutt analyze, add your professional email (ex: `--email "loic@azimutt.app"`) to get the full report in JSON and use `size` and `only` options.'))
        logger.log('')
    }
}

export function isValidEmail(email: string | undefined, logger: Logger): boolean {
    if (email) {
        const parsed = emailParse(email.trim())
        if (parsed.domain) {
            if (parsed.domain === 'azimutt.app') {
                logger.log(chalk.hex('#ef4444')(`Do you really have an 'azimutt.app' email? Good try ;)`))
                return false
            } else if (publicEmailDomains.includes(parsed.domain)) {
                logger.log(chalk.hex('#ef4444')(`Got your email, but please use your professional email instead ;)`))
                return false
            } else {
                return true
            }
        } else {
            logger.log(chalk.hex('#ef4444')(`Unrecognized email (${email}), try adding quotes around it.`))
            return false
        }
    } else {
        return false
    }
}

const confPath = (folder: string): string => pathJoin(`${folder}`, 'conf.json')

async function loadConf(folder: string, logger: Logger): Promise<RulesConf> {
    const path = confPath(folder)
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

async function updateConf(folder: string, conf: RulesConf, rules: Record<RuleId, RuleAnalyzed>): Promise<void> {
    const path = confPath(folder)
    const usedConf: RulesConf = removeEmpty({
        ...conf,
        rules: Object.entries(rules).reduce((c, [id, {conf}]) => Object.assign(c, {[id]: conf}), conf.rules || {})
    })
    await fileWriteJson(path, usedConf)
}

type AnalyzeStats = {
    nb_entities: number,
    nb_relations: number,
    nb_queries: number,
    nb_types: number,
    nb_rules: number,
    nb_violations: number,
    violations: Record<RuleLevel, number>,
}

function buildStats(db: Database, queries: DatabaseQuery[], rulesByLevel: Record<RuleLevel, RuleAnalyzed[]>): AnalyzeStats {
    const violationsByLevel: Record<RuleLevel, number> = mapValues(rulesByLevel, rules => rules.reduce((acc, rule) => acc + rule.violations.length, 0))
    return {
        nb_entities: db.entities?.length || 0,
        nb_relations: db.relations?.length || 0,
        nb_queries: queries.length,
        nb_types: db.types?.length || 0,
        nb_rules: Object.values(rulesByLevel).reduce((acc, rules) => acc + rules.length, 0),
        nb_violations: Object.values(violationsByLevel).reduce((acc, count) => acc + count, 0),
        violations: violationsByLevel
    }
}

function printReport(offRules: RuleAnalyzed[], rulesByLevel: Record<string, RuleAnalyzed[]>, maxShown: number, stats: AnalyzeStats, logger: Logger): void {
    logger.log('')
    if (offRules.length > 0) {
        logger.log(`${pluralizeL(offRules, 'off rule')}: ${offRules.map(r => r.rule.name).join(', ')}`)
    }
    ruleLevelsShown.slice().reverse().forEach(level => {
        const levelRules = rulesByLevel[level] || []
        const levelViolationsCount = levelRules.reduce((acc, r) => acc + r.violations.length, 0)
        logger.log(`${levelViolationsCount} ${level} violations:`)
        levelRules.forEach(rule => {
            const ignores = 'ignores' in rule.conf && Array.isArray(rule.conf.ignores) ? ` (${pluralize(rule.conf.ignores.length, 'ignore')})` : ''
            logger.log(`  ${rule.violations.length} ${rule.rule.name}${ignores}${rule.violations.length > 0 ? ':' : ''}`)
            rule.violations.slice(0, maxShown).forEach(violation => {
                logger.log(`    - ${violation.message}`)
            })
            if (rule.violations.length > maxShown) {
                logger.log(`    ... ${rule.violations.length - maxShown} more`)
            }
        })
    })
    logger.log('')
    logger.log(`Found ${pluralize(stats.nb_entities, 'entity')}, ${pluralize(stats.nb_relations, 'relation')}, ${pluralize(stats.nb_queries, 'query')} and ${pluralize(stats.nb_types, 'type')} on the database.`)
    logger.log(`Found ${stats.nb_violations} violations with ${stats.nb_rules} rules: ${ruleLevelsShown.map(l => `${(stats.violations[l] || 0)} ${l}`).join(', ')}.`)
    logger.log('')
}

export const RuleReport = z.object({
    name: z.string(),
    level: RuleLevel,
    conf: z.record(z.string(), z.any()),
    violations: z.object({
        message: z.string(),
        entity: EntityRef.optional(),
        attribute: AttributePath.optional(),
        extra: z.record(z.any()).optional(),
    }).array()
}).strict()
export type RuleReport = z.infer<typeof RuleReport>

export const AnalyzeReport = z.object({
    database: Database,
    queries: DatabaseQuery.array(),
    rules: z.record(RuleId, RuleReport)
}).strict().describe('AnalyzeReport')
export type AnalyzeReport = z.infer<typeof AnalyzeReport>

function buildReport(database: Database, queries: DatabaseQuery[], rules: Record<RuleId, RuleAnalyzed>): AnalyzeReport {
    return zodParse(AnalyzeReport)({
        rules: Object.fromEntries(Object.entries(rules)
            .filter(([, r]) => r.violations.length > 0)
            .map(([id, r]) => [id, buildRuleReport(r)])),
        database,
        queries,
    }).getOrThrow()
}

function buildRuleReport(rule: RuleAnalyzed): RuleReport {
    const {level, ...conf} = rule.conf
    const violations = rule.violations.map(v => removeUndefined({
        message: v.message,
        entity: v.entity,
        attribute: v.attribute,
        extra: v.extra,
    }))
    return {name: rule.rule.name, level, conf, violations}
}

async function writeReport(folder: string, report: AnalyzeReport, logger: Logger): Promise<void> {
    const path = pathJoin(folder, `report_${dateToIsoFilename(new Date())}.azimutt.json`)
    await fileWriteJson(path, report)
    logger.log(`Analysis report written to ${path}`)
}
