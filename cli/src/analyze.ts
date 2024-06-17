import chalk from "chalk";
import {
    dateFromIsoFilename,
    dateToIsoFilename,
    emailParse,
    groupBy,
    isNotUndefined,
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
    AnalyzeHistory,
    AnalyzeReport,
    AnalyzeReportRule,
    azimuttEmail,
    Connector,
    Database,
    DatabaseQuery,
    DatabaseUrlParsed,
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
import {version} from "./version.js";
import {loggerNoOp} from "./utils/logger.js";
import {fileExists, fileList, fileReadJson, fileWriteJson, mkParentDirs} from "./utils/file.js";

export type Opts = {
    folder?: string
    email?: string
    size?: number
    only?: string
    key?: string
    ignoreViolationsFrom?: string
}

export async function launchAnalyze(url: string, opts: Opts, logger: Logger): Promise<void> {
    const dbUrl: DatabaseUrlParsed = parseDatabaseUrl(url)
    const connector: Connector | undefined = getConnector(dbUrl)
    if (!connector) return Promise.reject(`Invalid connector for ${dbUrl.kind ? `${dbUrl.kind} db` : `unknown db (${dbUrl.full})`}`)
    if (opts.email && !isValidEmail(dbUrl, opts.email, logger)) return Promise.reject(`Invalid email (${opts.email})`)
    if (opts.key && !isValidKey(dbUrl, opts.email, opts.key, logger)) return Promise.reject(`Invalid key (${opts.key})`)
    if (opts.ignoreViolationsFrom && !opts.key) return Promise.reject(`You need a 'key' to ignore violations from a report`)

    // TODO: extend config for user, database, queries, data... ({user: {}, database: {}, queries: {}, data: {}, rules: {}})
    const app = 'azimutt-analyze'
    const folder = opts.folder || `~/.azimutt/analyze${dbUrl.db ? '/' + dbUrl.db : ''}`
    const now = Date.now()
    const conf: RulesConf = await loadConf(folder, logger)
    const history = opts.key ? await loadHistory(folder, logger) : []
    const referenceReport: AnalyzeReport | undefined = opts.ignoreViolationsFrom ? await loadReferenceReport(folder, opts.ignoreViolationsFrom, logger) : undefined
    const connectorLogger = conf.database?.logQueries ? logger : loggerNoOp
    const db: Database = await connector.getSchema(app, dbUrl, {...conf.database, logger: connectorLogger})
    const queries: DatabaseQuery[] = await connector.getQueryHistory(app, dbUrl, {database: dbUrl.db, logger: connectorLogger}).catch(err => {
        if (typeof err === 'string' && err === 'Not implemented') logger.log(chalk.blue(`Query history is not supported yet on ${dbUrl.kind}, ping us ;)`))
        if (typeof err === 'object' && 'message' in err && err.message.indexOf('"pg_stat_statements" does not exist')) logger.log(chalk.blue(`Can't get query history as pg_stat_statements is not enabled. Enable it for a better db analysis.`))
        return []
    })
    const rules: Record<RuleId, RuleAnalyzed> = analyzeDatabase(conf, now, db, queries, history, referenceReport?.analysis, opts.only?.split(',') || [])
    const [offRules, usedRules] = partition(Object.values(rules), r => r.conf.level === RuleLevel.enum.off)
    const rulesByLevel: Record<RuleLevel, RuleAnalyzed[]> = groupBy(usedRules, r => r.conf.level)
    const stats = buildStats(db, queries, rulesByLevel)
    track('cli__analyze__run', removeUndefined({version, database: dbUrl.kind, ...stats, email: opts.email, key: opts.key}), 'cli').then(() => {})
    await updateConf(folder, conf, rules)

    if (opts.email) {
        const maxShown = opts.size || 3
        printReport(offRules, rulesByLevel, maxShown, stats, logger)
        const report = buildReport(db, queries, rules)
        await writeReport(folder, report, logger)
        if (opts.key) {
            logger.log(chalk.blue('Thanks for using Azimutt analyze!'))
            logger.log(chalk.blue(`For any question or suggestion, reach out to ${azimuttEmail}.`))
            logger.log(chalk.blue(`Cheers!`))
            logger.log('')
        } else {
            logger.log(chalk.blue('Hope you like Azimutt analyze!'))
            logger.log(chalk.blue('Get even more from it with a license key, enabling historical analysis to identify:'))
            logger.log(chalk.blue('- degrading queries'))
            logger.log(chalk.blue('- unused indexes'))
            logger.log(chalk.blue('- fastest growing tables'))
            logger.log(chalk.blue('- and more...'))
            logger.log(chalk.blue(`Reach out to ${azimuttEmail} to buy one.`))
            logger.log(chalk.blue(`See you ;)`))
            logger.log('')
        }
    } else {
        const maxShown = 3
        printReport(offRules, rulesByLevel, maxShown, stats, logger)
        logger.log(chalk.blue('Had useful insights using Azimutt analyze?'))
        logger.log(chalk.blue('Add your professional email (ex: `--email your.name@company.com`) to get the full report in JSON.'))
        logger.log(chalk.blue(`Reach out to ${azimuttEmail} for feedback or suggest improvements ;)`))
        logger.log(chalk.blue(`Cheers!`))
        logger.log('')
    }
}

function isValidEmail(dbUrl: DatabaseUrlParsed, email: string, logger: Logger): boolean {
    const parsed = emailParse(email.trim())
    if (parsed.domain) {
        if (parsed.domain === 'azimutt.app') {
            logger.log(chalk.red(`Do you really have an 'azimutt.app' email? Good try ;)`))
            return false
        } else if (publicEmailDomains.includes(parsed.domain)) {
            track('cli__analyze__run', removeUndefined({version, database: dbUrl.kind, email, error: 'wrong email'}), 'cli').then(() => {})
            logger.log(chalk.red(`Got email param, please use your professional one instead ;)`))
            return false
        } else {
            return true
        }
    } else {
        logger.log(chalk.red(`Unrecognized email (${email}), try adding quotes around it.`))
        return false
    }
}

function isValidKey(dbUrl: DatabaseUrlParsed, email: string | undefined, key: string, logger: Logger): boolean {
    if (!email) {
        logger.log(chalk.red(`You must provide your email alongside your key.`))
        return false
    } else if (key !== 'sesame') {
        logger.log(chalk.red(`Unrecognized key for ${email}, reach out to ${azimuttEmail} for help.`))
        track('cli__analyze__run', removeUndefined({version, database: dbUrl.kind, email, key, error: 'wrong key'}), 'cli').then(() => {})
        return false
    } else {
        return true
    }
}

const confPath = (folder: string): string => pathJoin(`${folder}`, 'conf.json')

async function loadConf(folder: string, logger: Logger): Promise<RulesConf> {
    const path = confPath(folder)
    if (fileExists(path)) {
        logger.log(`Loading conf from ${path}`)
        return await fileReadJson<RulesConf>(path).then(zodParseAsync(RulesConf, `RulesConf reading ${path}`))
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
        logger.log(`${levelViolationsCount} ${level} violations (${pluralizeL(levelRules, 'rule')}):`)
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
    logger.log(`Found ${stats.nb_violations} violations using ${stats.nb_rules} rules: ${ruleLevelsShown.map(l => `${(stats.violations[l] || 0)} ${l}`).join(', ')}.`)
    logger.log('')
}

function buildReport(database: Database, queries: DatabaseQuery[], rules: Record<RuleId, RuleAnalyzed>): AnalyzeReport {
    return zodParse(AnalyzeReport)({
        analysis: Object.fromEntries(Object.entries(rules)
            .filter(([, r]) => r.violations.length > 0)
            .map(([id, r]) => [id, buildRuleReport(r)])),
        database,
        queries,
    }).getOrThrow()
}

function buildRuleReport(rule: RuleAnalyzed): AnalyzeReportRule {
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
    logger.log('')
}

async function loadReferenceReport(folder: string, report: string, logger: Logger): Promise<AnalyzeReport> {
    const path = pathJoin(folder, report)
    const res = await fileReadJson<AnalyzeReport>(path).then(zodParseAsync(AnalyzeReport))
    logger.log(`Loaded reference report from ${path}`)
    return res
}

async function loadHistory(folder: string, logger: Logger): Promise<AnalyzeHistory[]> {
    const files = await fileList(folder)
    const history = files
        .map(file => {
            const [, date] = file.match(/^report_([0-9-TZ]{24})\.azimutt\.json$/) || []
            return date ? {date: dateFromIsoFilename(date).getTime(), path: pathJoin(folder, file)} : undefined
        })
        .filter(isNotUndefined)
        .map(({date, path}) =>
            fileReadJson<AnalyzeReport>(path)
                .then(zodParseAsync(AnalyzeReport))
                .then(report => ({report: path, date, database: report.database, queries: report.queries}))
        )
    const res = await Promise.all(history)
    logger.log(`Loaded ${pluralizeL(res, 'previous report')} from ${folder}`)
    return res
}
