import { MultiSelect } from "@/components/ui/multi-select"

export interface ReportRuleFilterProps {
  rules: string[]
  selected: string[]
  onChange?: (values: string[]) => void
}

export const ReportRuleFilter = ({
  rules,
  selected,
  onChange,
}: ReportRuleFilterProps) => {
  return (
    <MultiSelect
      options={rules.map((rule) => ({ label: rule, value: rule }))}
      defaultValue={selected}
      onValueChange={(value) => onChange?.(value)}
      placeholder="Rules"
    />
  )
}
