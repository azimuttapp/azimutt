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
            {rule.violations.map(({ message }) => (
              <pre key={message}>{message}</pre>
            ))}
          </CardContent>
        </Card>
      ))}
    </div>
  )
}
