import { ReportSeverityFilter } from "./filters/ReportSeverityFilter/ReportSeverityFilter"

export interface ReportFiltersProps {}

export const ReportFilters = ({}: ReportFiltersProps) => {
  const handleSeverityChange = (severity: string) => {
    console.log(severity)
  }

  return (
    <div>
      <ReportSeverityFilter onChange={handleSeverityChange} />
    </div>
  )
}
