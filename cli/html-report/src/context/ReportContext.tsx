import { REPORT } from "@/constants/report.constants"
import { AnalyzeReportLevel } from "@azimutt/models"
import { createContext, useContext } from "react"

const ReportContext = createContext<AnalyzeReportLevel[]>(REPORT)

export const useReportContext = () => useContext(ReportContext)
export default ReportContext
