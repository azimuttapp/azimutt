import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardHeader } from "@/components/ui/card"
import { pluralize } from "@/lib/utils"
import { AnalyzeReportViolation } from "@azimutt/models"

export interface ViolationsListItemProps {
  name: string
  level: string
  violations?: AnalyzeReportViolation[]
  totalViolations?: number
}

export const ViolationsListItem = ({
  name,
  level,
  violations,
  totalViolations,
}: ViolationsListItemProps) => {
  const moreViolations =
    (totalViolations ?? violations?.length ?? 0) - (violations?.length ?? 0)

  return (
    <Card>
      <CardHeader className="flex flex-row justify-between items-center">
        <div className="flex items-center gap-2">
          <p className="font-semibold text-lg">{name}</p>
          <Badge>{level}</Badge>
        </div>
        <p>{pluralize(totalViolations ?? 0, "violation")}</p>
      </CardHeader>
      <CardContent>
        {Boolean(violations?.length) && (
          <div className="relative rounded bg-muted px-[0.3rem] py-[0.2rem] font-mono text-sm flex flex-col">
            {violations?.map(({ message }) => (
              <code key={message} className="my-1">
                {message}
              </code>
            ))}

            {moreViolations > 0 && (
              <code className="my-2 font-sm">
                {pluralize(moreViolations ?? 0, "more violation")}
              </code>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  )
}
