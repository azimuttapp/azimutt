import { ReportCategoryFilter } from "./filters/ReportCategoryFilter/ReportCategoryFilter"
import { ReportSeverityFilter } from "./filters/ReportSeverityFilter/ReportSeverityFilter"

export interface ReportFiltersProps {}

export const ReportFilters = ({}: ReportFiltersProps) => {
  const handleSeverityChange = (severity: string) => {
    console.log(severity)
  }

  const handleCategoryChange = (category: string) => {
    console.log(category)
  }

  return (
    <div>
      <ReportSeverityFilter onChange={handleSeverityChange} />
      <ReportCategoryFilter onChange={handleCategoryChange} />
    </div>
  )
}
