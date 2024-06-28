import { render, screen } from "@testing-library/react"
import { ReportRuleFilter } from "./ReportRuleFilter"

describe("ReportRuleFilter", () => {
  test("Should render", () => {
    const rules = ["missing primary key"]
    render(<ReportRuleFilter rules={rules} selected={[]} />)
    expect(screen.getByText("Rules")).toBeDefined()
  })
})
