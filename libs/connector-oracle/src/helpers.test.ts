import { describe, expect, test } from "@jest/globals"
import { buildSqlColumn, buildSqlTable } from "./helpers"

describe("helpers", () => {
  test("buildSqlTable", () => {
    expect(buildSqlTable({ entity: "events" })).toEqual(`"events"`)
    expect(buildSqlTable({ schema: "", entity: "events" })).toEqual(`"events"`)
    expect(buildSqlTable({ schema: "public", entity: "events" })).toEqual(
      `"public"."events"`
    )
  })
  test("buildSqlColumn", () => {
    expect(buildSqlColumn(["name"])).toEqual(`"name"`)
    expect(buildSqlColumn(["data", "email"])).toEqual(`"data"->'email'`)
  })
})
