import { Badge } from "@/components/ui/badge"
import { cn } from "@/lib/utils"

export interface ReportSidebarItemProps {
  label?: string
  count?: number
}

export const ReportSidebarItem = ({ label, count }: ReportSidebarItemProps) => {
  return (
    <div
      className={cn(
        { "opacity-30": count === 0 },
        "flex space-y-1 w-full items-center"
      )}
    >
      <p className="w-40 text-left text-ellipsis overflow-hidden">{label}</p>
      <div className="grow flex justify-end">
        <Badge>{count}</Badge>
      </div>
    </div>
  )
}
