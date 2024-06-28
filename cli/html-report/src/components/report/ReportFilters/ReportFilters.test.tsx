import { render } from "@testing-library/react"
import { ReportFilters } from "./ReportFilters"

describe("ReportFilters", () => {
  test("Should render", () => {
    render(
      <ReportFilters
        onSeveritiesChange={jest.fn()}
        onCategoriesChange={jest.fn()}
        onRulesChange={jest.fn()}
        onTablesChange={jest.fn()}
      />
    )
  })
})
