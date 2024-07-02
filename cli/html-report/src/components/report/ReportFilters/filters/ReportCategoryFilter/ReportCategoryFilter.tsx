import { MultiSelect } from "@/components/ui/multi-select"

const CATEGORIES = [
  {
    label: "Schema design",
    value: "schema-design",
  },
  {
    label: "Performance",
    value: "performance",
  },
  {
    label: "DB Health",
    value: "db-health",
  },
]

export interface ReportCategoryFilterProps {
  selected?: string[]
  onChange?: (value: string[]) => void
}

export const ReportCategoryFilter = ({
  selected,
  onChange,
}: ReportCategoryFilterProps) => {
  return (
    <MultiSelect
      options={CATEGORIES}
      defaultValue={selected ?? []}
      onValueChange={(value) => onChange?.(value)}
      placeholder="Categories"
    />
  )
}
