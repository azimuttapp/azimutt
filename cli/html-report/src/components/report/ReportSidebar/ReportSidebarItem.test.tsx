import { render, screen } from "@testing-library/react"
import { ReportSidebarItem } from "./ReportSidebarItem"

describe("ReportSidebarItem", () => {
  test("Should render label and badge", () => {
    const label = "My rule"
    const count = 4

    render(<ReportSidebarItem label={label} count={count} />)

    expect(screen.getAllByText(label)).toBeDefined()
    expect(screen.getAllByText(count)).toBeDefined()
  })
})
