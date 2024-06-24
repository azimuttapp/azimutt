import { reportContextFactory } from "@/context/reportContextTestTool"
import * as ReportContext from "@/context/ReportContext"
import { ReportStats } from "./ReportStats"
import { render, screen } from "@testing-library/react"
import { AnalyzeStats } from "@azimutt/models"

describe("ReportStats", () => {
  test("Should render stats from context", () => {
    const given: AnalyzeStats = {
      nb_entities: 34,
      nb_relations: 45,
      nb_queries: 193,
      nb_types: 46,
      nb_rules: 29,
      nb_violations: 140,
      violations: {
        high: 12,
        medium: 38,
        low: 4,
        hint: 86,
      },
    }

    const contextValues = reportContextFactory({
      stats: given,
    })
    jest
      .spyOn(ReportContext, "useReportContext")
      .mockImplementation(() => contextValues)
    render(<ReportStats />)
    expect(screen.getByText(given.nb_entities)).toBeDefined()
    expect(screen.getByText(given.nb_relations)).toBeDefined()
    expect(screen.getByText(given.nb_queries)).toBeDefined()
    expect(screen.getByText(given.nb_types)).toBeDefined()
    expect(screen.getByText(given.nb_rules)).toBeDefined()
    expect(screen.getByText(given.violations.high!)).toBeDefined()
    expect(screen.getByText(given.violations.medium!)).toBeDefined()
    expect(screen.getByText(given.violations.low!)).toBeDefined()
    expect(screen.getByText(given.violations.hint!)).toBeDefined()
  })
})
