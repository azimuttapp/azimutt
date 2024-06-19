import { render, screen } from "@testing-library/react"
import * as ReportContext from "../../../context/ReportContext"

import { ReportSidebar } from "./ReportSidebar"
import { AnalyzeReportLevel } from "@azimutt/models"

describe("ReportSidebar", () => {
  test("Should render with context", () => {
    const contextValues: AnalyzeReportLevel[] = [{ level: "high", levelViolationsCount: 12, rules: [] }]
    jest
      .spyOn(ReportContext, "useReportContext")
      .mockImplementation(() => contextValues)
    render(<ReportSidebar />)
    expect(screen.getByText("high")).toBeDefined()
    expect(screen.getByText("12")).toBeDefined()
  })
})
