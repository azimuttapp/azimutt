import { Badge } from "@/components/ui/badge"
import { cn } from "@/lib/utils"

export interface ReportSidebarItemProps {
  label?: string
  count?: number
}

export const ReportSidebarItem = ({ label, count }: ReportSidebarItemProps) => {
  return (
    <div className={cn({ "opacity-30": count === 0 }, "flex space-y-1 w-full")}>
      <p className="grow text-left">{label}</p>
      <Badge>{count}</Badge>
    </div>
  )
}
