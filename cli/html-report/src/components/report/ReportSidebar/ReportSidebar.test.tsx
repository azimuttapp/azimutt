import { render, screen } from "@testing-library/react"
import * as ReportContext from "../../../context/ReportContext"

import { ReportSidebar } from "./ReportSidebar"
import { reportContextFactory } from "@/context/reportContextTestTool"

describe("ReportSidebar", () => {
  test("Should render levels from context", () => {
    const contextValues = reportContextFactory({
      levels: [
        { level: "high", levelViolationsCount: 12, rules: [] },
        { level: "medium", levelViolationsCount: 19, rules: [] },
      ],
    })
    jest
      .spyOn(ReportContext, "useReportContext")
      .mockImplementation(() => contextValues)
    render(<ReportSidebar />)
    expect(screen.getByText("high")).toBeDefined()
    expect(screen.getByText("12")).toBeDefined()
  })

  test("Should render rules from context", () => {
    const contextValues = reportContextFactory({
      rules: [
        {
          name: "duplicated index",
          totalViolations: 5,
        },
        {
          name: "too slow query",
          totalViolations: 0,
        },
      ],
    })
    jest
      .spyOn(ReportContext, "useReportContext")
      .mockImplementation(() => contextValues)
    render(<ReportSidebar />)
    expect(screen.getByText("duplicated index")).toBeDefined()
    expect(screen.getByText("5")).toBeDefined()
  })
})
