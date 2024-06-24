import { useReportContext } from "@/context/ReportContext"
import {
  AnalyzeReportLevel,
  AnalyzeReportRule,
  AnalyzeReportViolation,
} from "@azimutt/models"
import { useCallback, useMemo } from "react"

export function useReport() {
  const { report, filters } = useReportContext()

  const filterByLevel = useCallback(
    (rule: AnalyzeReportLevel) =>
      !filters?.levels?.length || filters?.levels?.includes(rule.level),
    [filters]
  )

  const filterByRule = useCallback(
    (rule: AnalyzeReportLevel) => {
      if (filters?.rules?.length) {
        const ruleNames = rule.rules.map(({ name }) => name)
        return filters.rules.some((name) => ruleNames.includes(name))
      }
      return true
    },
    [filters]
  )

  const filterByEntity = useCallback(
    (rule: AnalyzeReportLevel) => {
      if (filters?.tables?.length) {
        const entities = rule.rules.reduce<string[]>((acc, rule) => {
          const { violations } = rule
          acc.push(
            ...violations
              .filter((violation) => Boolean(violation.entity))
              .reduce<string[]>((tables, violation) => {
                const table = `${violation.entity!.schema}.${violation.entity!.entity}`
                if (!tables.includes(table)) {
                  tables.push(table)
                }
                return tables
              }, [])
          )
          return acc
        }, [])
        return filters.tables.some((table) => entities.includes(table))
      }
      return true
    },
    [filters]
  )

  const levels = useMemo(() => {
    if (!filters?.levels?.length && !filters?.rules?.length)
      return [...report.levels]

    return report.levels.filter(
      (item) =>
        filterByLevel(item) && filterByRule(item) && filterByEntity(item)
    )
  }, [report, filters, filterByLevel, filterByRule, filterByEntity])

  const filteredRules = useMemo(
    () =>
      levels
        .reduce<AnalyzeReportRule[]>((acc, { rules }) => {
          acc.push(...rules)
          return acc
        }, [])
        .filter(({ totalViolations }) => totalViolations > 0)
        .filter(
          (rule) => !filters?.rules?.length || filters.rules.includes(rule.name)
        ),
    [levels, filters]
  )

  const rules = useMemo(() => {
    const { levels } = report
    const rules = levels.reduce<string[]>((acc, level) => {
      acc.push(...level.rules.map((rule) => rule.name))
      return acc
    }, [])
    return rules.sort()
  }, [report])

  const tables = useMemo(() => {
    const { levels } = report
    const rules = levels.reduce<AnalyzeReportRule[]>((acc, level) => {
      acc.push(...level.rules)
      return acc
    }, [])
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

  return { filters, levels, filteredRules, rules, tables }
}
