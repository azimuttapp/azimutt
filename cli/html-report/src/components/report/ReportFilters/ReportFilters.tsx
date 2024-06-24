import { ReportCategoryFilter } from "./filters/ReportCategoryFilter/ReportCategoryFilter"
import { ReportRuleFilter } from "./filters/ReportRuleFilter/ReportRuleFilter"
import { ReportSeverityFilter } from "./filters/ReportSeverityFilter/ReportSeverityFilter"

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

  return (
    <div>
      <ReportSeverityFilter onChange={handleSeverityChange} />
      <ReportCategoryFilter onChange={handleCategoryChange} />
      <ReportRuleFilter
        rules={[]}
        selectedRules={[]}
        onChange={handleRuleChange}
      />
    </div>
  )
}
