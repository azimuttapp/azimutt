import { ReportCategoryFilter } from "./filters/ReportCategoryFilter/ReportCategoryFilter"
import { ReportRuleFilter } from "./filters/ReportRuleFilter/ReportRuleFilter"
import { ReportSeverityFilter } from "./filters/ReportSeverityFilter/ReportSeverityFilter"
import { ReportTableFilter } from "./filters/ReportTableFilter/ReportTableFilter"

export interface ReportFiltersProps {}

export const ReportFilters = ({}: ReportFiltersProps) => {
  const handleSeverityChange = (severities: string[]) => {
    console.log(severities)
  }

  const handleCategoryChange = (categories: string[]) => {
    console.log(categories)
  }

  const handleRuleChange = (rules: string[]) => {
    console.log(rules)
  }

  const handleTableChange = (tables: string[]) => {
    console.log(tables)
  }

  return (
    <div className="grid gap-4 grid-cols-1 sm:grid-cols-4">
      <ReportSeverityFilter onChange={handleSeverityChange} />
      <ReportCategoryFilter onChange={handleCategoryChange} />
      <ReportRuleFilter
        rules={[]}
        selectedRules={[]}
        onChange={handleRuleChange}
      />
      <ReportTableFilter
        tables={[]}
        selectedTables={[]}
        onChange={handleTableChange}
      />
    </div>
  )
}
