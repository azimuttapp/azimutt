import { useReport } from "@/hooks/useReport"
import { ViolationsTableCell } from "./ViolationsTableCell"
import {
  Table,
  TableBody,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"

export interface ViolationsTableProps {}

export const ViolationsTable = () => {
  const { filteredRules } = useReport()

  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Rule</TableHead>
          <TableHead>Level</TableHead>
          <TableHead>Violations</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {filteredRules.map((rule) => (
          <TableRow key={rule.name}>
            <ViolationsTableCell
              name={rule.name}
              level={rule.level}
              violations={rule.violations}
              totalViolations={rule.totalViolations}
            />
          </TableRow>
        ))}
      </TableBody>
    </Table>
  )
}
