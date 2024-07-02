import { render, screen } from "@testing-library/react"
import { ReportCategoryFilter } from "./ReportCategoryFilter"

describe("ReportCategoryFilter", () => {
  test("Should render", () => {
    render(<ReportCategoryFilter />)
    expect(screen.getByText("Categories")).toBeDefined()
  })
})
