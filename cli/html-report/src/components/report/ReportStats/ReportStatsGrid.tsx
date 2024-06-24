import { useMemo } from "react"
import { ReportStatCell, ReportStatCellProps } from "./ReportStatCell"

export interface ReportStatsGridProps {
  entities: number
  relations: number
  queries: number
  types: number
  violations: {
    high: number
    medium: number
    low: number
    hint: number
  }
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

  const items: ReportStatCellProps[] = [
    { label: "Entities", value: String(entities) },
    { label: "Relatons", value: String(relations) },
    { label: "Queries", value: String(queries) },
    { label: "Types", value: String(types) },
    { label: "Rules", value: String(rules) },
    { label: "Total violations", value: String(totalViolations) },
    { label: "High", value: String(violations.high) },
    { label: "Medium", value: String(violations.medium) },
    { label: "Low", value: String(violations.low) },
    { label: "Hint", value: String(violations.hint) },
  ]

  return (
    <dl className="mt-5 grid grid-cols-1 gap-5 sm:grid-cols-3">
      <div className="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6">
        {items.map((cellProps) => (
          <ReportStatCell key={cellProps.label} {...cellProps} />
        ))}
      </div>
    </dl>
  )
}
