import { useMemo } from "react"
import { ReportStatCell, ReportStatCellProps } from "./ReportStatCell"
import { ViolationStats } from "@/hooks/useReport"

export interface ReportStatsGridProps {
  entities: number
  relations: number
  queries: number
  types: number
  violations: ViolationStats
  rules: number
}

export const ReportStatsGrid = ({
  entities,
  relations,
  queries,
  types,
  violations,
  rules,
}: ReportStatsGridProps) => {
  const totalViolations = useMemo(
    () => Object.values(violations).reduce((sum, level) => sum + level, 0),
    [violations]
  )

  const databaseStats: ReportStatCellProps[] = [
    { label: "Entities", value: String(entities) },
    { label: "Relatons", value: String(relations) },
    { label: "Queries", value: String(queries) },
    { label: "Types", value: String(types) },
    { label: "Rules", value: String(rules) },
  ]

  const violationsStats: ReportStatCellProps[] = [
    { label: "Total violations", value: String(totalViolations) },
    { label: "High", value: String(violations.high ?? 0) },
    { label: "Medium", value: String(violations.medium ?? 0) },
    { label: "Low", value: String(violations.low ?? 0) },
    { label: "Hint", value: String(violations.hint ?? 0) },
  ]

  return (
    <div>
      <dl className="mt-5 grid grid-cols-1 gap-5 sm:grid-cols-5">
        {databaseStats.map((cellProps) => (
          <ReportStatCell key={cellProps.label} {...cellProps} />
        ))}
      </dl>
      <dl className="mt-5 grid grid-cols-1 gap-5 sm:grid-cols-5">
        {violationsStats.map((cellProps) => (
          <ReportStatCell key={cellProps.label} {...cellProps} />
        ))}
      </dl>
    </div>
  )
}
