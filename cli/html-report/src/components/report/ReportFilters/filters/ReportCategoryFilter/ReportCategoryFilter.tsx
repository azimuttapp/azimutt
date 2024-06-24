import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"

const CATEGORIES = [
  {
    label: "Schema design",
    value: "schema-design",
  },
  {
    label: "Performance",
    value: "performance",
  },
  {
    label: "DB Health",
    value: "db-health",
  },
]

export interface ReportCategoryFilterProps {
  onChange?: (value: string) => void
}

export const ReportCategoryFilter = ({
  onChange,
}: ReportCategoryFilterProps) => {
  return (
    <Select onValueChange={onChange}>
      <SelectTrigger>
        <SelectValue placeholder="Categories" />
      </SelectTrigger>
      <SelectContent>
        {CATEGORIES.map(({ label, value }) => (
          <SelectItem key={value} value={value}>
            {label}
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  )
}
