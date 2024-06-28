import { render, screen } from "@testing-library/react"
import { ReportStatCell } from "./ReportStatCell"

describe("ReportStatCell", () => {
  test("Should render label", () => {
    const given = "My label"
    render(<ReportStatCell label={given} value="42" />)
    expect(screen.getByText(given)).toBeDefined()
  })

  test("Should render value", () => {
    const given = "603"
    render(<ReportStatCell label={"Total customers"} value={given} />)
    expect(screen.getByText(given)).toBeDefined()
  })
})
