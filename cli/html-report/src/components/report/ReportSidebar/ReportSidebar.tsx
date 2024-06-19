import { Badge } from "@/components/ui/badge"
import { useReportContext } from "@/context/ReportContext"
import { cn } from "@/lib/utils"

export interface ReportSidebarProps {}

export const ReportSidebar = ({}: ReportSidebarProps) => {
  const report = useReportContext()
  return (
    <div className="px-1">
      <ul>
        {report.map(({ level, levelViolationsCount }: any) => (
          <li
            key={level}
            className={cn(
              { "opacity-30": levelViolationsCount === 0 },
              "flex space-y-1"
            )}>
            <p className="grow">{level}</p>
            <Badge>{levelViolationsCount}</Badge>
          </li>
        ))}
      </ul>
    </div>
  )
}
