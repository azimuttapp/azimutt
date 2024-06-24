import { render, screen } from "@testing-library/react"
import { ReportRuleFilter } from "./ReportRuleFilter"

describe("ReportRuleFilter", () => {
  test("Should render", () => {
    const rules = [
      { label: "Missing primary key", value: "missing-primary-key" },
    ]
    render(<ReportRuleFilter rules={rules} selectedRules={[]} />)
    expect(screen.getByText("Rules")).toBeDefined()
  })
})
