import { useReport } from "@/hooks/useReport"
import { ReportCategoryFilter } from "./filters/ReportCategoryFilter/ReportCategoryFilter"
import { ReportRuleFilter } from "./filters/ReportRuleFilter/ReportRuleFilter"
import { ReportSeverityFilter } from "./filters/ReportSeverityFilter/ReportSeverityFilter"
import { ReportTableFilter } from "./filters/ReportTableFilter/ReportTableFilter"

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
  const { filters, rules, tables } = useReport()

  return (
    <div className="grid gap-4 grid-cols-1 sm:grid-cols-4">
      <ReportSeverityFilter
        selected={filters?.levels ?? []}
        onChange={onSeveritiesChange}
      />
      <ReportCategoryFilter selected={[]} onChange={onCategoriesChange} />
      <ReportRuleFilter
        rules={rules}
        selected={filters?.rules ?? []}
        onChange={onRulesChange}
      />
      <ReportTableFilter
        tables={tables}
        selected={filters?.tables ?? []}
        onChange={onTablesChange}
      />
    </div>
  )
}
