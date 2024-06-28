import { useReport } from "@/hooks/useReport"
import { ViolationsListItem } from "./ViolationsListItem"

export interface ViolationsListProps {}

export const ViolationsList = () => {
  const { filteredRules } = useReport()

  return (
    <div className="grid gap-4">
      {filteredRules.map((rule) => (
        <ViolationsListItem
          key={rule.name}
          name={rule.name}
          level={rule.level}
          violations={rule.violations}
          totalViolations={rule.totalViolations}
        />
      ))}
    </div>
  )
}
