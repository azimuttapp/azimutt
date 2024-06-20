import { TableCell } from "@/components/ui/table"

export interface ViolationsTableCellProps {
  name: string
  level: string
  violations?: { message: string }[]
  totalViolations?: number
}

export const ViolationsTableCell = ({
  name,
  level,
  violations,
  totalViolations,
}: ViolationsTableCellProps) => {
  const moreViolations =
    (totalViolations ?? violations?.length ?? 0) - (violations?.length ?? 0)

  return (
    <>
      <TableCell className="text-nowrap">{name}</TableCell>
      <TableCell>{level}</TableCell>
      <TableCell>
        {Boolean(violations?.length) && (
          <div className="relative rounded bg-muted px-[0.3rem] py-[0.2rem] font-mono text-sm flex flex-col">
            {violations?.map(({ message }) => (
              <code key={message} className="my-1">
                {message}
              </code>
            ))}
          </div>
        )}
        {moreViolations > 0 && (
          <div className="my-2 font-sm">{moreViolations} more</div>
        )}
      </TableCell>
    </>
  )
}
