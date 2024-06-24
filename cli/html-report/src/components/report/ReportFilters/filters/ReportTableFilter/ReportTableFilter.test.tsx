import { render, screen } from "@testing-library/react"
import { ReportTableFilter } from "./ReportTableFilter"

describe("ReportTableFilter", () => {
  test("Should render", () => {
    const tables = ["public.users"]
    render(<ReportTableFilter tables={tables} selectedTables={[]} />)
    expect(screen.getByText("Tables")).toBeDefined()
  })
})
