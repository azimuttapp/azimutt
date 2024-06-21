import { AnalyzeReportHtmlResult } from "@azimutt/models"
import type { ReportContext, ReportContextFilters } from "./ReportContext"

export const reportContextFactory = (
  report?: Partial<AnalyzeReportHtmlResult>,
  filters?: Partial<ReportContextFilters>
): ReportContext => ({
  report: {
    levels: [],
    rules: [],
    database: {},
    queries: [],
    ...(report ?? {}),
  },
  filters,
})
