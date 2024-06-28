import { AnalyzeReportHtmlResult } from "@azimutt/models"
import type { ReportContext, ReportContextFilters } from "./ReportContext"

export const reportContextFactory = (
  report?: Partial<AnalyzeReportHtmlResult>,
  filters?: Partial<ReportContextFilters>
): ReportContext => ({
  report: {
    rules: [],
    ...(report ?? {}),

    stats: {
      nb_entities: 0,
      nb_relations: 0,
      nb_queries: 0,
      nb_types: 0,
      nb_rules: 0,
      ...(report?.stats ?? {}),
    },
  },
  filters,
})
