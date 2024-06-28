import { reportContextFactory } from "@/context/reportContextTestTool"
import * as ReportContext from "@/context/ReportContext"
import { ReportStats } from "./ReportStats"
import { render, screen } from "@testing-library/react"
import { AnalyzeReportHtmlStats } from "@azimutt/models"

describe("ReportStats", () => {
  test("Should render stats from context", () => {
    const given: AnalyzeReportHtmlStats = {
      nb_entities: 34,
      nb_relations: 45,
      nb_queries: 193,
      nb_types: 46,
      nb_rules: 29,
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
  })
})
