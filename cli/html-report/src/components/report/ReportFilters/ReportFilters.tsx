import { ReportCategoryFilter } from "./filters/ReportCategoryFilter/ReportCategoryFilter"
import { ReportRuleFilter } from "./filters/ReportRuleFilter/ReportRuleFilter"
import { ReportSeverityFilter } from "./filters/ReportSeverityFilter/ReportSeverityFilter"
import { ReportTableFilter } from "./filters/ReportTableFilter/ReportTableFilter"

export interface ReportFiltersProps {}

export const ReportFilters = ({}: ReportFiltersProps) => {
  const handleSeverityChange = (severity: string) => {
    console.log(severity)
  }

  const handleCategoryChange = (category: string) => {
    console.log(category)
  }

  const handleRuleChange = (rules: string[]) => {
    console.log(rules)
  }

  const handleTableChange = (tables: string[]) => {
    console.log(tables)
  }

  return (
    <div>
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
