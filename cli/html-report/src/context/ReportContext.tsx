import { REPORT } from "@/constants/report.constants"
import { AnalyzeReportHtmlResult, RuleLevel } from "@azimutt/models"
import { createContext, useContext } from "react"

export interface ReportContextFilters {
  levels?: RuleLevel[]
  rules?: string[]
}

export interface ReportContext {
  report: AnalyzeReportHtmlResult
  filters?: ReportContextFilters
}

export const ReportContext = createContext<ReportContext>({ report: REPORT })

export const useReportContext = () => useContext(ReportContext)
