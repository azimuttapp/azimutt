import { useReport } from "@/hooks/useReport"
import { ReportStatsGrid } from "./ReportStatsGrid"

export const ReportStats = () => {
  const { dbStats, violationStats } = useReport()

  return (
    <ReportStatsGrid
      entities={dbStats.nb_entities ?? 0}
      relations={dbStats.nb_relations ?? 0}
      queries={dbStats.nb_queries ?? 0}
      types={dbStats.nb_types ?? 0}
      rules={dbStats.nb_rules ?? 0}
      violations={violationStats}
    />
  )
}
