import { renderHook } from "@testing-library/react"
import { useReport } from "./useReport"
import * as ReportContext from "@/context/ReportContext"

describe("useReport", () => {
  test("should return levels and rules", () => {
    const contextValues: ReportContext.ReportContext = {
      report: {
        levels: [
          { level: "high", levelViolationsCount: 12, rules: [] },
          { level: "medium", levelViolationsCount: 19, rules: [] },
        ],
        rules: [],
      },
    }
    jest
      .spyOn(ReportContext, "useReportContext")
      .mockImplementation(() => contextValues)

    const { result } = renderHook(() => useReport())
    expect(result.current.report.levels).toBeDefined()
    expect(result.current.report.levels).toHaveLength(2)
    expect(result.current.report.rules).toBeDefined()
  })

  test("should filter by level", () => {
    const contextValues: ReportContext.ReportContext = {
      report: {
        levels: [
          { level: "high", levelViolationsCount: 12, rules: [] },
          { level: "medium", levelViolationsCount: 19, rules: [] },
        ],
        rules: [],
      },
      filters: { levels: ["high"] },
    }
    jest
      .spyOn(ReportContext, "useReportContext")
      .mockImplementation(() => contextValues)

    const { result } = renderHook(() => useReport())
    expect(result.current.report.levels).toHaveLength(1)
    expect(result.current.report.levels[0].level).toBe("high")
  })

  test("should filter by rule", () => {
    const contextValues: ReportContext.ReportContext = {
      report: {
        levels: [
          {
            level: "high",
            levelViolationsCount: 12,
            rules: [
              {
                name: "duplicated index",
                level: "high",
                conf: {},
                violations: [],
                totalViolations: 12,
              },
            ],
          },
          {
            level: "medium",
            levelViolationsCount: 19,
            rules: [
              {
                name: "entity not clean",
                level: "high",
                conf: {},
                violations: [
                  {
                    message:
                      "Entity public.events has old analyze (2024-06-17T10:18:35.009Z).",
                    entity: { schema: "public", entity: "events" },
                    extra: {
                      reason: "old analyze",
                      value: "2024-06-17T10:18:35.009Z",
                    },
                  },
                ],
                totalViolations: 1,
              },
            ],
          },
        ],
        rules: [],
      },
      filters: { rules: ["duplicated index"] },
    }
    jest
      .spyOn(ReportContext, "useReportContext")
      .mockImplementation(() => contextValues)

    const { result } = renderHook(() => useReport())
    expect(result.current.report.levels).toHaveLength(1)
    expect(result.current.report.levels[0].rules).toHaveLength(1)
    expect(result.current.report.levels[0].rules[0].name).toBe(
      "duplicated index"
    )
  })
})
