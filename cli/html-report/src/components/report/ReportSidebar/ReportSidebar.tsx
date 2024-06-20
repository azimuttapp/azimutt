import { useReportContext } from "@/context/ReportContext"
import { ReportSidebarItem } from "./ReportSidebarItem"
import { Button } from "@/components/ui/button"
import { RuleLevel } from "@azimutt/models"

export interface ReportSidebarProps {
  onLevelClick?: (level: RuleLevel) => void
  onRuleClick?: (rule: string) => void
}

export const ReportSidebar = ({
  onLevelClick,
  onRuleClick,
}: ReportSidebarProps) => {
  const { report, filters } = useReportContext()

  return (
    <div className="px-2">
      <div className="mx-1 my-4">
        <h4>Levels</h4>
      </div>
      <nav className="grid gap-1 px-2 group-[[data-collapsed=true]]:justify-center group-[[data-collapsed=true]]:px-2">
        {report.levels.map(({ level, levelViolationsCount }) => (
          <Button
            key={level}
            variant={filters?.levels?.includes(level) ? "default" : "outline"}
            disabled={!levelViolationsCount}
            onClick={() => onLevelClick?.(level)}
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
          <Button
            key={name}
            variant={filters?.rules?.includes(name) ? "default" : "outline"}
            disabled={!totalViolations}
            onClick={() => onRuleClick?.(name)}
          >
            <ReportSidebarItem label={name} count={totalViolations} />
          </Button>
        ))}
      </nav>
    </div>
  )
}
