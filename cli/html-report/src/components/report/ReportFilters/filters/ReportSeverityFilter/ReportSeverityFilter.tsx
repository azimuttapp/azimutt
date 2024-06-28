import { MultiSelect } from "@/components/ui/multi-select"
import { RuleLevel } from "@azimutt/models"

const levels: RuleLevel[] = ["high", "medium", "low", "hint"]

export interface ReportSeverityFilterProps {
  selected?: string[]
  onChange?: (value: string[]) => void
}

export const ReportSeverityFilter = ({
  selected,
  onChange,
}: ReportSeverityFilterProps) => {
  return (
    <MultiSelect
      options={levels.map((level) => ({ label: level, value: level }))}
      onValueChange={(value) => onChange?.(value)}
      defaultValue={selected ?? []}
      placeholder="Severity"
    />
  )
}
