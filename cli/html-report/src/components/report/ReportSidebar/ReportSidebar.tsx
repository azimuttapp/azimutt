import { useReportContext } from "@/context/ReportContext"
import { ReportSidebarItem } from "./ReportSidebarItem"

export interface ReportSidebarProps {}

export const ReportSidebar = ({}: ReportSidebarProps) => {
  const report = useReportContext()
  return (
    <div className="px-1">
      <ul>
        {report.map(({ level, levelViolationsCount }: any) => (
          <ReportSidebarItem
            key={level}
            label={level}
            count={levelViolationsCount}
          />
        ))}
      </ul>
    </div>
  )
}
