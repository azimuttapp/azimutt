import { useReportContext } from "@/context/ReportContext"
import { AnalyzeReportLevel, AnalyzeReportRule } from "@azimutt/models"
import { useCallback, useMemo } from "react"

export function useReport() {
  const { report, filters } = useReportContext()

  const filterByLevel = useCallback(
    (rule: AnalyzeReportLevel) =>
      !filters?.levels?.length || filters?.levels?.includes(rule.level),
    [filters]
  )

  const filterRule = useCallback(
    (rule: AnalyzeReportLevel) => {
      if (filters?.rules?.length) {
        const ruleNames = rule.rules.map(({ name }) => name)
        return filters.rules.some((name) => ruleNames.includes(name))
      }
      return true
    },
    [filters]
  )

  const levels = useMemo(() => {
    if (!filters?.levels?.length && !filters?.rules?.length)
      return [...report.levels]

    return report.levels.filter(
      (item) => filterByLevel(item) && filterRule(item)
    )
  }, [report, filters, filterByLevel, filterRule])

  const filteredRules = useMemo(
    () =>
      levels
        .reduce<AnalyzeReportRule[]>((acc, { rules }) => [...acc, ...rules], [])
        .filter(({ totalViolations }) => totalViolations > 0)
        .filter(
          (rule) => !filters?.rules?.length || filters.rules.includes(rule.name)
        ),
    [levels, filters]
  )

  return { levels, filteredRules }
}
