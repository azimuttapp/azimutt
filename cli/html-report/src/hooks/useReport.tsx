import { useReportContext } from "@/context/ReportContext"
import { AnalyzeReportRule, AnalyzeReportViolation } from "@azimutt/models"
import { useMemo } from "react"

export interface FilterableAnalyzeReportRule extends AnalyzeReportRule {
  entities: string[]
}

export interface ViolationStats {
  high?: number
  medium?: number
  low?: number
  hint?: number
}

export function useReport() {
  const { report, filters } = useReportContext()

  const filterableRules = useMemo<FilterableAnalyzeReportRule[]>(() => {
    const { rules } = report
    return rules.map((rule) => ({
      ...rule,
      entities: rule.violations.reduce<string[]>((acc, violation) => {
        if (!violation?.entity) return acc
        const entity = [violation.entity.schema, violation.entity.entity].join(
          "."
        )
        if (!acc.includes(entity)) {
          acc.push(entity)
        }
        return acc
      }, []),
    }))
  }, [report])

  const filteredRules = useMemo(() => {
    return filterableRules.filter(
      (rule) =>
        rule.totalViolations > 0 &&
        (!filters?.levels?.length || filters.levels.includes(rule.level)) &&
        (!filters?.rules?.length || filters.rules.includes(rule.name)) &&
        (!filters?.tables?.length ||
          filters.tables.some((table) => rule.entities.includes(table)))
    )
  }, [filters, filterableRules])

  const rules = useMemo(() => {
    const { rules } = report
    const ruleNames = rules.reduce<string[]>((acc, rule) => {
      if (!acc.includes(rule.name)) {
        acc.push(rule.name)
      }
      return acc
    }, [])
    return ruleNames.sort()
  }, [report])

  const tables = useMemo(() => {
    const { rules } = report
    const violations = rules.reduce<AnalyzeReportViolation[]>((acc, rule) => {
      acc.push(...rule.violations)
      return acc
    }, [])
    const tables = violations.reduce<string[]>((acc, violation) => {
      if (!violation?.entity) return acc
      const fullName = [violation.entity.schema, violation.entity.entity].join(
        "."
      )
      if (!acc.includes(fullName)) {
        acc.push(fullName)
      }
      return acc
    }, [])
    return tables
  }, [report])

  const violationStats = useMemo<ViolationStats>(() => {
    const { rules } = report

    return rules.reduce<ViolationStats>((acc, rule) => {
      if (rule.level === "off") return acc
      if (!acc[rule.level]) {
        acc[rule.level] = 0
      }
      acc[rule.level]! += 1
      return acc
    }, {})
  }, [report])

  return {
    filters,
    filteredRules,
    rules,
    tables,
    violationStats,
    dbStats: report.stats,
  }
}
