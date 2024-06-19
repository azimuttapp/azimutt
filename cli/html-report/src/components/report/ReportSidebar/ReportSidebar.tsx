import { useReportContext } from "@/context/ReportContext"
import { ReportSidebarItem } from "./ReportSidebarItem"

export interface ReportSidebarProps {}

export const ReportSidebar = ({}: ReportSidebarProps) => {
  const report = useReportContext()
  return (
    <div className="px-2">
      <div className="m-1">
        <h4>Levels</h4>
      </div>
      <ul>
        {report.levels.map(({ level, levelViolationsCount }) => (
          <ReportSidebarItem
            key={level}
            label={level}
            count={levelViolationsCount}
          />
        ))}
      </ul>
      <div className="m-1">
        <h4>Rules</h4>
      </div>
      <ul>
        {report.rules.map(({ name, totalViolations }) => (
          <ReportSidebarItem key={name} label={name} count={totalViolations} />
        ))}
      </ul>
    </div>
  )
}
