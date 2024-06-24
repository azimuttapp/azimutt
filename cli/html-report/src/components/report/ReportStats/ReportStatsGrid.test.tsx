import { render, screen } from "@testing-library/react"
import { ReportStatsGrid, ReportStatsGridProps } from "./ReportStatsGrid"

const props: ReportStatsGridProps = {
  entities: 47,
  relations: 44,
  queries: 169,
  types: 20,
  rules: 27,
  violations: {
    high: 6,
    medium: 88,
    low: 0,
    hint: 57,
  },
}

describe("ReportStat", () => {
  test("should render entities count", () => {
    render(<ReportStatsGrid {...props} />)
    expect(screen.getByText(props.entities)).toBeDefined()
  })

  test("should render relations count", () => {
    render(<ReportStatsGrid {...props} />)
    expect(screen.getByText(props.queries)).toBeDefined()
  })

  test("should render queries count", () => {
    render(<ReportStatsGrid {...props} />)
    expect(screen.getByText(props.queries)).toBeDefined()
  })

  test("should render types count", () => {
    render(<ReportStatsGrid {...props} />)
    expect(screen.getByText(props.types)).toBeDefined()
  })

  test("should render rules count", () => {
    render(<ReportStatsGrid {...props} />)
    expect(screen.getByText(props.rules)).toBeDefined()
  })

  test("should render total violations count", () => {
    const given = Object.values(props.violations).reduce(
      (sum, level) => sum + level,
      0
    )
    render(<ReportStatsGrid {...props} />)
    expect(screen.getByText(given)).toBeDefined()
  })

  test("should render high violations count", () => {
    render(<ReportStatsGrid {...props} />)
    expect(screen.getByText(props.violations.high!)).toBeDefined()
  })

  test("should render medium violations count", () => {
    render(<ReportStatsGrid {...props} />)
    expect(screen.getByText(props.violations.medium!)).toBeDefined()
  })

  test("should render low violations count", () => {
    render(<ReportStatsGrid {...props} />)
    expect(screen.getByText(props.violations.low!)).toBeDefined()
  })

  test("should render hint violations count", () => {
    render(<ReportStatsGrid {...props} />)
    expect(screen.getByText(props.violations.hint!)).toBeDefined()
  })
})
