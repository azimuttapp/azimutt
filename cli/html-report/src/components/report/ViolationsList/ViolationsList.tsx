import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardHeader } from "@/components/ui/card"
import { useReport } from "@/hooks/useReport"

export interface ViolationsListProps {}

export const ViolationsList = ({}: ViolationsListProps) => {
  const { filteredRules } = useReport()

  return (
    <div className="grid gap-4">
      {filteredRules.map((rule) => (
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
