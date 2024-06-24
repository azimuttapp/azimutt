import { ReportStatsGrid } from "./ReportStatsGrid"
import { useReportContext } from "@/context/ReportContext"

export interface ReportStatsProps {}

export const ReportStats = ({}: ReportStatsProps) => {
  const { report } = useReportContext()

  const violations = {
    high: report.stats.violations.high ?? 0,
    medium: report.stats.violations.medium ?? 0,
    low: report.stats.violations.low ?? 0,
    hint: report.stats.violations.hint ?? 0,
  }
  return (
    <ReportStatsGrid
      entities={report.stats.nb_entities ?? 0}
      relations={report.stats.nb_relations ?? 0}
      queries={report.stats.nb_queries ?? 0}
      types={report.stats.nb_types ?? 0}
      violations={violations}
      rules={report.stats.nb_rules ?? 0}
    />
  )
}
