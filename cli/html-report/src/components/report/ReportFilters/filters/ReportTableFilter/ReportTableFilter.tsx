import { MultiSelect } from "@/components/ui/multi-select"

export interface ReportTableFilterProps {
  tables: string[]
  selected: string[]
  onChange?: (values: string[]) => void
}

export const ReportTableFilter = ({
  tables,
  selected,
  onChange,
}: ReportTableFilterProps) => {
  return (
    <MultiSelect
      options={tables.map((table) => ({ label: table, value: table }))}
      defaultValue={selected}
      onValueChange={(value) => onChange?.(value)}
      placeholder="Tables"
    />
  )
}
