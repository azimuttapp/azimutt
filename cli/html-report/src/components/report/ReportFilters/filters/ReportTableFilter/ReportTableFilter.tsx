import { MultiSelect } from "@/components/ui/multi-select"

export interface ReportTableFilterProps {
  tables: string[]
  selectedTables: string[]
  onChange?: (values: string[]) => void
}

export const ReportTableFilter = ({
  tables,
  selectedTables,
  onChange,
}: ReportTableFilterProps) => {
  return (
    <MultiSelect
      options={tables.map((table) => ({ label: table, value: table }))}
      defaultValue={selectedTables}
      onValueChange={(value) => onChange?.(value)}
      placeholder="Tables"
    />
  )
}
