import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardHeader } from "@/components/ui/card"

export interface ViolationsListItemProps {
  name: string
  level: string
  violations?: { message: string }[]
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
        <p>{name}</p>
        <Badge>{level}</Badge>
      </CardHeader>
      <CardContent>
        {Boolean(violations?.length) && (
          <div className="relative rounded bg-muted px-[0.3rem] py-[0.2rem] font-mono text-sm flex flex-col">
            {violations?.map(({ message }) => (
              <code key={message}>{message}</code>
            ))}
          </div>
        )}
        {moreViolations > 0 && (
          <div className="my-2 font-sm">{moreViolations} more</div>
        )}
      </CardContent>
    </Card>
  )
}
