import { useReportContext } from "@/context/ReportContext"
import { ReportSidebarItem } from "./ReportSidebarItem"
import { Button } from "@/components/ui/button"

export interface ReportSidebarProps {}

export const ReportSidebar = ({}: ReportSidebarProps) => {
  const report = useReportContext()

  const totalLevelViolationsCount = report.levels.reduce(
    (sum, { levelViolationsCount }) => sum + levelViolationsCount,
    0
  )

  return (
    <div className="px-2">
      <div className="mx-1 my-4">
        <h4>Levels</h4>
      </div>
      <nav className="grid gap-1 px-2 group-[[data-collapsed=true]]:justify-center group-[[data-collapsed=true]]:px-2">
        <Button variant="default" disabled={!totalLevelViolationsCount}>
          <ReportSidebarItem label={"all"} count={totalLevelViolationsCount} />
        </Button>
        {report.levels.map(({ level, levelViolationsCount }) => (
          <Button
            key={level}
            variant="outline"
            disabled={!levelViolationsCount}
          >
            <ReportSidebarItem label={level} count={levelViolationsCount} />
          </Button>
        ))}
      </nav>

      <div className="mx-1 my-4">
        <h4>Rules</h4>
      </div>
      <nav className="grid gap-1 px-2 group-[[data-collapsed=true]]:justify-center group-[[data-collapsed=true]]:px-2">
        {report.rules.map(({ name, totalViolations }) => (
          <Button key={name} variant="outline" disabled={!totalViolations}>
            <ReportSidebarItem label={name} count={totalViolations} />
          </Button>
        ))}
      </nav>
    </div>
  )
}
