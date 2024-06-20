import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardHeader } from "@/components/ui/card"
import { useReportContext } from "@/context/ReportContext"
import { AnalyzeReportRule } from "@azimutt/models"

export interface ViolationsListProps {}

export const ViolationsList = ({}: ViolationsListProps) => {
  const report = useReportContext()

  const rules = report.levels
    .reduce<AnalyzeReportRule[]>((acc, { rules }) => [...acc, ...rules], [])
    .filter(({ totalViolations }) => totalViolations > 0)

  return (
    <div className="grid gap-4">
      {rules.map((rule) => (
        <Card key={rule.name}>
          <CardHeader className="flex flex-row justify-between items-center">
            <p>{rule.name}</p>
            <Badge>{rule.level}</Badge>
          </CardHeader>
          <CardContent>
            <div className="relative rounded bg-muted px-[0.3rem] py-[0.2rem] font-mono text-sm flex flex-col">
              {rule.violations.map(({ message }) => (
                <code key={message}>{message}</code>
              ))}
            </div>
          </CardContent>
        </Card>
      ))}
    </div>
  )
}
