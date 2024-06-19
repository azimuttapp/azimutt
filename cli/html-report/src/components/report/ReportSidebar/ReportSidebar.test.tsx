import { render, screen } from "@testing-library/react"
import * as ReportContext from "../../../context/ReportContext"

import { ReportSidebar } from "./ReportSidebar"

describe("ReportSidebar", () => {
  test("Should render with context", () => {
    const contextValues: any[] = [{ level: "test" }]
    vi.spyOn(ReportContext, "useReportContext").mockImplementation(
      () => contextValues
    )
    render(<ReportSidebar />)
    expect(screen.getByText("test")).toBeDefined()
  })
})
