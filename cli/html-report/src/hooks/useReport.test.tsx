import { renderHook } from "@testing-library/react"
import { useReport } from "./useReport"
import * as ReportContext from "@/context/ReportContext"
import { reportContextFactory } from "@/context/reportContextTestTool"

describe("useReport", () => {
  test("should return levels by default", () => {
    const contextValues = reportContextFactory({
      levels: [
        { level: "high", levelViolationsCount: 12, rules: [] },
        { level: "medium", levelViolationsCount: 19, rules: [] },
      ],
    })
    jest
      .spyOn(ReportContext, "useReportContext")
      .mockImplementation(() => contextValues)

    const { result } = renderHook(() => useReport())
    expect(result.current.levels).toBeDefined()
    expect(result.current.levels).toHaveLength(2)
  })

  test("should filter by level", () => {
    const contextValues = reportContextFactory(
      {
        levels: [
          { level: "high", levelViolationsCount: 12, rules: [] },
          { level: "medium", levelViolationsCount: 19, rules: [] },
        ],
      },
      { levels: ["high"] }
    )
    jest
      .spyOn(ReportContext, "useReportContext")
      .mockImplementation(() => contextValues)

    const { result } = renderHook(() => useReport())
    expect(result.current.levels).toHaveLength(1)
    expect(result.current.levels[0].level).toBe("high")
  })

  test("should filter by rule", () => {
    const contextValues = reportContextFactory(
      {
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
      },
      { rules: ["duplicated index"] }
    )

    jest
      .spyOn(ReportContext, "useReportContext")
      .mockImplementation(() => contextValues)

    const { result } = renderHook(() => useReport())
    expect(result.current.levels).toHaveLength(1)
    expect(result.current.levels[0].rules).toHaveLength(1)
    expect(result.current.levels[0].rules[0].name).toBe("duplicated index")
  })

  test("should filter and flat rules", () => {
    const contextValues = reportContextFactory(
      {
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
      },
      { rules: ["duplicated index", "entity not clean"] }
    )
    jest
      .spyOn(ReportContext, "useReportContext")
      .mockImplementation(() => contextValues)

    const { result } = renderHook(() => useReport())
    const filteredNames = Array.from(
      new Set(result.current.filteredRules.map(({ name }) => name))
    )

    expect(result.current.filteredRules).toHaveLength(2)
    expect(filteredNames).toHaveLength(2)
    expect(filteredNames).toContain("duplicated index")
    expect(filteredNames).toContain("entity not clean")
  })

  test("Should extract tables", () => {
    const contextValues = reportContextFactory(
      {
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
      },
      { rules: ["duplicated index", "entity not clean"] }
    )
    jest
      .spyOn(ReportContext, "useReportContext")
      .mockImplementation(() => contextValues)

    const { result } = renderHook(() => useReport())
    expect(result.current.tables).toHaveLength(1)
    expect(result.current.tables).toContain("public.events")
  })

  test("Should extract distinct tables", () => {
    const contextValues = reportContextFactory(
      {
        levels: [
          {
            level: "high",
            levelViolationsCount: 12,
            rules: [
              {
                name: "duplicated index",
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
      },
      { rules: ["duplicated index", "entity not clean"] }
    )

    jest
      .spyOn(ReportContext, "useReportContext")
      .mockImplementation(() => contextValues)

    const { result } = renderHook(() => useReport())
    expect(result.current.tables).toHaveLength(1)
    expect(result.current.tables).toContain("public.events")
  })
})
