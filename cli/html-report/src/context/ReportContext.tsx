import { REPORT } from "@/constants/report.constants"
import { AnalyzeReportHtmlResult, RuleLevel } from "@azimutt/models"
import { createContext, useContext } from "react"

export interface ReportContext {
  report: AnalyzeReportHtmlResult
  filters?: { levels?: RuleLevel[]; rules?: string[] }
}

export const ReportContext = createContext<ReportContext>({ report: REPORT })

export const useReportContext = () => useContext(ReportContext)
