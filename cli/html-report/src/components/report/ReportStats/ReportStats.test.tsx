import { render, screen } from "@testing-library/react"
import { ReportStats, ReportStatsProps } from "./ReportStats"

const props: ReportStatsProps = {
  entities: 47,
  relations: 44,
  queries: 169,
  types: 20,
  violations: 151,
  rules: {
    count: 27,
    high: 6,
    medium: 88,
    low: 0,
    hint: 57,
  },
}

describe("ReportStat", () => {
  test("should render entities count", () => {
    render(<ReportStats {...props} />)
    expect(screen.getByText("47")).toBeDefined()
  })
})
