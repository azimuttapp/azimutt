import { useReportContext } from "@/context/ReportContext"
import type { ReportContext } from "@/context/ReportContext"
import { AnalyzeReportLevel } from "@azimutt/models"
import { useCallback, useMemo } from "react"

export function useReport() {
  const { report, filters } = useReportContext()

  const filterByLevel = useCallback(
    (rule: AnalyzeReportLevel) =>
      !Boolean(filters?.levels?.length) ||
      filters?.levels?.includes(rule.level),
    [filters, report]
  )

  const filterRule = useCallback(
    (rule: AnalyzeReportLevel) => {
      if (filters?.rules?.length) {
        const ruleNames = rule.rules.map(({ name }) => name)
        return filters.rules.some((name) => ruleNames.includes(name))
      }
      return true
    },
    [filters, report]
  )

  const levels = useMemo(() => {
    if (!filters?.levels?.length && !filters?.rules?.length)
      return [...report.levels]

    return report.levels.filter(
      (item) => filterByLevel(item) && filterRule(item)
    )
  }, [report, filters])

  return { report: { levels, rules: report.rules }, filters } as ReportContext
}
