import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { RuleLevel } from "@azimutt/models"

const levels: RuleLevel[] = ["high", "medium", "low", "hint"]

export interface ReportSeverityFilterProps {
  onChange?: (value: string) => void
}

export const ReportSeverityFilter = ({
  onChange,
}: ReportSeverityFilterProps) => {
  return (
    <Select onValueChange={onChange}>
      <SelectTrigger>
        <SelectValue placeholder="Severity" />
      </SelectTrigger>
      <SelectContent>
        {levels.map((level) => (
          <SelectItem key={level} value={level}>
            {level}
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  )
}
