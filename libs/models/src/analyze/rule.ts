import {number, z, ZodType} from "zod";
import {Timestamp} from "../common";
import {AttributePath, Database, EntityRef} from "../database";
import {DatabaseQuery} from "../interfaces/connector";

export interface Rule<Conf extends RuleConf = RuleConf> {
    id: RuleId
    name: RuleName
    conf: Conf
    zConf: ZodType<Conf>
    analyze(conf: Conf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[], reference: AnalyzeReportViolation[]): RuleViolation[]
}

export const RuleId = z.string()
export type RuleId = z.infer<typeof RuleId>
export const RuleName = z.string()
export type RuleName = z.infer<typeof RuleName>
export const RuleLevel = z.enum(['high', 'medium', 'low', 'hint', 'off']) // from highest to lowest
export type RuleLevel = z.infer<typeof RuleLevel>
export const ruleLevelsShown = RuleLevel.options.filter(l => l !== RuleLevel.enum.off)
export const RuleConf = z.object({
    level: RuleLevel
}).strict().describe('RuleConf')
export type RuleConf = z.infer<typeof RuleConf>
export const RuleViolation = z.object({
    ruleId: RuleId,
    ruleName: RuleName,
    ruleLevel: RuleLevel,
    message: z.string(),
    // entity & attribute allow to locate the violation
    entity: EntityRef.optional(),
    attribute: AttributePath.optional(),
    // extra allow to keep structured information about the violation
    extra: z.record(z.any()).optional()
}).strict()
export type RuleViolation = z.infer<typeof RuleViolation>

export const AnalyzeReportViolation = z.object({
    message: z.string(),
    entity: EntityRef.optional(),
    attribute: AttributePath.optional(),
    extra: z.record(z.any()).optional(),
}).strict().describe('AnalyzeReportViolation')
export type AnalyzeReportViolation = z.infer<typeof AnalyzeReportViolation>

export const AnalyzeReportRule = z.object({
    name: z.string(),
    level: RuleLevel,
    conf: z.record(z.string(), z.any()),
    violations: AnalyzeReportViolation.array()
}).strict().describe('AnalyzeReportRule')
export type AnalyzeReportRule = z.infer<typeof AnalyzeReportRule>

export const AnalyzeReportResult = z.record(RuleId, AnalyzeReportRule)
export type AnalyzeReportResult = z.infer<typeof AnalyzeReportResult>

export const AnalyzeReport = z.object({
    analysis: AnalyzeReportResult,
    // TODO: insights: z.object({mostUsedEntities: z.object({entity: EntityRef, queries: QueryId.array()}).array().optional()}).optional()
    database: Database,
    queries: DatabaseQuery.array(),
}).strict().describe('AnalyzeReport')
export type AnalyzeReport = z.infer<typeof AnalyzeReport>

export const AnalyzeHistory = z.object({
    report: z.string(),
    date: Timestamp,
    database: Database,
    queries: DatabaseQuery.array(),
}).strict().describe('AnalyzeHistory')
export type AnalyzeHistory = z.infer<typeof AnalyzeHistory>

export const AnalyzeReportLevel = z.object({
    level: RuleLevel,
    levelViolationsCount: z.number(),
    rules: z.array(AnalyzeReportRule)
})
export type AnalyzeReportLevel = z.infer<typeof AnalyzeReportLevel>
