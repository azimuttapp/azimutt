import { ReportCategoryFilter } from "./filters/ReportCategoryFilter/ReportCategoryFilter"
import { ReportRuleFilter } from "./filters/ReportRuleFilter/ReportRuleFilter"
import { ReportSeverityFilter } from "./filters/ReportSeverityFilter/ReportSeverityFilter"
import { ReportTableFilter } from "./filters/ReportTableFilter/ReportTableFilter"
import { useReportContext } from "@/context/ReportContext"

export interface ReportFiltersProps {
  onSeveritiesChange: (severities: string[]) => void
  onCategoriesChange: (categories: string[]) => void
  onRulesChange: (rules: string[]) => void
  onTablesChange: (tables: string[]) => void
}

export const ReportFilters = ({
  onSeveritiesChange,
  onCategoriesChange,
  onRulesChange,
  onTablesChange,
}: ReportFiltersProps) => {
  const { filters } = useReportContext()

  return (
    <div className="grid gap-4 grid-cols-1 sm:grid-cols-4">
      <ReportSeverityFilter
        selected={filters?.levels ?? []}
        onChange={onSeveritiesChange}
      />
      <ReportCategoryFilter selected={[]} onChange={onCategoriesChange} />
      <ReportRuleFilter
        rules={[]}
        selected={filters?.rules ?? []}
        onChange={onRulesChange}
      />
      <ReportTableFilter tables={[]} selected={[]} onChange={onTablesChange} />
    </div>
  )
}
