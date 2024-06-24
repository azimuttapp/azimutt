import { MultiSelect } from "@/components/ui/multi-select"

export interface ReportRuleFilterProps {
  rules: { label: string; value: string }[]
  selectedRules: string[]
  onChange?: (values: string[]) => void
}

export const ReportRuleFilter = ({
  rules,
  selectedRules,
  onChange,
}: ReportRuleFilterProps) => {
  return (
    <MultiSelect
      options={rules}
      defaultValue={selectedRules}
      onValueChange={(value) => onChange?.(value)}
      placeholder="Rules"
    />
  )
}
