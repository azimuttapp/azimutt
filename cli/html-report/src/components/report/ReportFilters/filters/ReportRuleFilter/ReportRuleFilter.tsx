import { MultiSelect } from "@/components/ui/multi-select"

export interface ReportRuleFilterProps {
  rules: { label: string; value: string }[]
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
      options={rules}
      defaultValue={selected}
      onValueChange={(value) => onChange?.(value)}
      placeholder="Rules"
    />
  )
}
