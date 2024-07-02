import { render, screen } from "@testing-library/react"
import { ReportSeverityFilter } from "./ReportSeverityFilter"

describe("ReportSeverityFilter", () => {
  test("Should render", () => {
    render(<ReportSeverityFilter />)
    expect(screen.getByText("Severity")).toBeDefined()
  })
})
