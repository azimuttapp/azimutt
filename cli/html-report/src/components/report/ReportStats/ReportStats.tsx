export interface ReportStatsProps {
  entities: number
  relations: number
  queries: number
  types: number
  violations: number
  rules: {
    count: number
    high: number
    medium: number
    low: number
    hint: number
  }
}

export const ReportStats = ({ entities }: ReportStatsProps) => {
  return (
    <dl className="mt-5 grid grid-cols-1 gap-5 sm:grid-cols-3">
      <div className="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6">
        <dt className="truncate text-sm font-medium text-gray-500">Entities</dt>
        <dd className="mt-1 text-3xl font-semibold tracking-tight text-gray-900">
          {entities}
        </dd>
      </div>
    </dl>
  )
}
