import { REPORT } from "@/constants/report.constants"
import { createContext, useContext } from "react"

const ReportContext = createContext<any[]>(REPORT)

export const useReportContext = () => useContext(ReportContext)
export default ReportContext
