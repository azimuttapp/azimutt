import { renderHook } from "@testing-library/react"
import { useReport } from "./useReport"
import * as ReportContext from "@/context/ReportContext"
import { reportContextFactory } from "@/context/reportContextTestTool"

describe("useReport", () => {
  test("should filter by level", () => {
    const contextValues = reportContextFactory(
      {
        rules: [
          {
            level: "high",
            name: "Rule1",
            conf: {},
            violations: [],
            totalViolations: 1,
          },
          {
            level: "medium",
            name: "Rule2",
            conf: {},
            violations: [],
            totalViolations: 1,
          },
        ],
      },
      {
        levels: ["high"],
      }
    )
    jest
      .spyOn(ReportContext, "useReportContext")
      .mockImplementation(() => contextValues)

    const { result } = renderHook(() => useReport())
    expect(result.current.filteredRules).toHaveLength(1)
    expect(result.current.filteredRules[0].level).toBe("high")
  })

  test("should filter by rule", () => {
    const contextValues = reportContextFactory(
      {
        rules: [
          {
            name: "duplicated index",
            level: "high",
            conf: {},
            violations: [],
            totalViolations: 12,
          },
          {
            name: "entity not clean",
            level: "medium",
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
      { rules: ["duplicated index"] }
    )

    jest
      .spyOn(ReportContext, "useReportContext")
      .mockImplementation(() => contextValues)

    const { result } = renderHook(() => useReport())
    expect(result.current.filteredRules).toHaveLength(1)
    expect(result.current.filteredRules[0].name).toBe("duplicated index")
  })

  test("Should filter by tables", () => {
    const contextValues = reportContextFactory(
      {
        rules: [
          {
            name: "duplicated index",
            level: "high",
            conf: {},
            violations: [
              {
                message:
                  "Entity public.events has old analyze (2024-06-17T10:18:35.009Z).",
                entity: { schema: "private", entity: "logs" },
                extra: {
                  reason: "old analyze",
                  value: "2024-06-17T10:18:35.009Z",
                },
              },
            ],
            totalViolations: 12,
          },
          {
            name: "entity not clean",
            level: "medium",
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
      { tables: ["public.events"] }
    )

    jest
      .spyOn(ReportContext, "useReportContext")
      .mockImplementation(() => contextValues)

    const { result } = renderHook(() => useReport())
    expect(result.current.filteredRules).toHaveLength(1)
    expect(result.current.filteredRules[0].name).toBe("entity not clean")
  })

  test("Should extract tables", () => {
    const contextValues = reportContextFactory({
      rules: [
        {
          name: "entity not clean",
          level: "medium",
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
    })
    jest
      .spyOn(ReportContext, "useReportContext")
      .mockImplementation(() => contextValues)

    const { result } = renderHook(() => useReport())
    expect(result.current.tables).toHaveLength(1)
    expect(result.current.tables).toContain("public.events")
  })

  test("Should extract distinct tables", () => {
    const contextValues = reportContextFactory({
      rules: [
        {
          level: "high",
          name: "duplicated index",
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
          totalViolations: 12,
        },
        {
          level: "medium",
          name: "entity not clean",
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
    })

    jest
      .spyOn(ReportContext, "useReportContext")
      .mockImplementation(() => contextValues)

    const { result } = renderHook(() => useReport())
    expect(result.current.tables).toHaveLength(1)
    expect(result.current.tables).toContain("public.events")
  })
})
