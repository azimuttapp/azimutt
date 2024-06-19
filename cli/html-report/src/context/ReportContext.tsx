import { REPORT } from "@/constants/report.constants"
import { AnalyzeReportHtmlResult } from "@azimutt/models"
import { createContext, useContext } from "react"

export const ReportContext = createContext<AnalyzeReportHtmlResult>(REPORT)

export const useReportContext = () => useContext(ReportContext)
export default ReportContext
